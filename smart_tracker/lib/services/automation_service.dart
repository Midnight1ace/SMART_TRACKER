import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:telephony_fix/telephony.dart';

import '../state/settings_store.dart';
import '../state/automation_inbox_store.dart';
import '../state/entitlement_store.dart';
import 'transaction_parser.dart';

class AutomationService {
  AutomationService({
    required SettingsStore settings,
    required AutomationInboxStore inboxStore,
    required EntitlementStore entitlementStore,
  })  : _settings = settings,
        _inboxStore = inboxStore,
        _entitlementStore = entitlementStore {
    _settingsListener = _syncFromSettings;
    _settings.addListener(_settingsListener!);
    _syncFromSettings();
  }

  final SettingsStore _settings;
  final AutomationInboxStore _inboxStore;
  final EntitlementStore _entitlementStore;
  final Telephony _telephony = Telephony.instance;
  final Map<String, DateTime> _recentMessages = {};

  StreamSubscription<ServiceNotificationEvent>? _notificationSubscription;
  bool _smsListening = false;

  VoidCallback? _settingsListener;

  bool get _isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> ensureSmsPermission() async {
    if (!_isAndroid) return false;
    final bool? granted = await _telephony.requestSmsPermissions;
    return granted ?? false;
  }

  Future<bool> ensureNotificationPermission() async {
    if (!_isAndroid) return false;
    final bool granted = await NotificationListenerService.isPermissionGranted();
    if (granted) return true;
    final bool requested = await NotificationListenerService.requestPermission();
    return requested;
  }

  void dispose() {
    _settings.removeListener(_settingsListener!);
    _notificationSubscription?.cancel();
  }

  Future<void> _syncFromSettings() async {
    if (!_isAndroid) return;

    if (_settings.smsAutomationEnabled && !_smsListening) {
      await _startSmsListener();
    }

    if (!_settings.smsAutomationEnabled && _smsListening) {
      _smsListening = false;
    }

    if (_settings.notificationAutomationEnabled) {
      await _startNotificationListener();
    } else {
      await _stopNotificationListener();
    }
  }

  Future<void> _startSmsListener() async {
    final bool? granted = await _telephony.requestSmsPermissions;
    if (granted != true) {
      return;
    }

    _telephony.listenIncomingSms(
      onNewMessage: _handleIncomingSms,
      listenInBackground: false,
    );
    _smsListening = true;
  }

  void _handleIncomingSms(SmsMessage message) {
    if (!_settings.smsAutomationEnabled) return;
    final body = message.body ?? '';
    _ingestRawText(body, source: 'sms');
  }

  Future<void> _startNotificationListener() async {
    if (_notificationSubscription != null) return;

    final bool granted = await NotificationListenerService.isPermissionGranted();
    if (!granted) {
      final bool requested = await NotificationListenerService.requestPermission();
      if (!requested) return;
    }

    _notificationSubscription = NotificationListenerService.notificationsStream.listen(_handleNotificationEvent);
  }

  Future<void> _stopNotificationListener() async {
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  void _handleNotificationEvent(ServiceNotificationEvent event) {
    if (!_settings.notificationAutomationEnabled) return;
    if (event.hasRemoved == true) return;

    final title = event.title ?? '';
    final content = event.content ?? '';
    final parts = <String>[title, content];
    final combined = parts.where((value) => value.trim().isNotEmpty).join(' ');

    _ingestRawText(combined, source: 'notification', packageName: event.packageName);
  }

  void _ingestRawText(String text, {required String source, String? packageName}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    if (!_looksLikeTransaction(trimmed)) return;
    if (!_shouldProcess(trimmed, source: source, packageName: packageName)) return;
    if (!_entitlementStore.isPro) return;

    _inboxStore.addItem(rawText: trimmed, source: source, packageName: packageName);
  }

  bool _shouldProcess(String text, {required String source, String? packageName}) {
    final parsed = TransactionParser(defaultTemplateId: _settings.bankTemplateId).parse(text);
    if (parsed.isRefund) return false;
    if (source == 'notification' && _settings.allowedNotificationPackages.isNotEmpty) {
      if (packageName == null || !_settings.allowedNotificationPackages.contains(packageName)) {
        return false;
      }
    }
    final bucket = _bucketKey(DateTime.now());
    final merchant = (parsed.merchant ?? '').toLowerCase().trim();
    final amount = parsed.amount != null ? parsed.amount!.toStringAsFixed(2) : '';
    final key = merchant.isNotEmpty && amount.isNotEmpty
        ? '${source}_${packageName ?? ''}_${amount}_${merchant}_$bucket'
        : '${source}_${packageName ?? ''}_${text.toLowerCase()}_$bucket';
    final now = DateTime.now();

    _recentMessages.removeWhere(
      (_, timestamp) => now.difference(timestamp).inMinutes >= 2,
    );

    if (_recentMessages.containsKey(key)) {
      return false;
    }

    _recentMessages[key] = now;
    return true;
  }

  bool _looksLikeTransaction(String text) {
    final lower = text.toLowerCase();
    final hasAmount = RegExp(r'([0-9]+(?:[.,][0-9]{1,2})?)').hasMatch(lower);
    if (!hasAmount) return false;

    final hasCurrency = RegExp(r'(qar|sar|aed|usd|eur|gbp|inr|rs|qr|\$)').hasMatch(lower);
    final hasKeyword = [
      'spent',
      'purchase',
      'pos',
      'debited',
      'credit',
      'withdraw',
      'paid',
      'payment',
      'card',
    ].any(lower.contains);

    return hasCurrency || hasKeyword;
  }

  String _bucketKey(DateTime timestamp) {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}-${timestamp.hour.toString().padLeft(2, '0')}';
  }
}
