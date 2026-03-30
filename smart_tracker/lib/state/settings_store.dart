import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/transaction_constants.dart' as constants;

class SettingsStore extends ChangeNotifier {
  static const _currencyKey = 'default_currency';
  static const _budgetKey = 'monthly_budget';
  static const _smsAutomationKey = 'sms_automation';
  static const _notificationAutomationKey = 'notification_automation';
  static const _lastBackupKey = 'last_backup_at';
  static const _bankTemplateKey = 'bank_template';
  static const _allowedPackagesKey = 'allowed_notification_packages';

  bool _loaded = false;
  String _defaultCurrency = constants.defaultCurrency;
  double? _monthlyBudget;
  bool _smsAutomationEnabled = false;
  bool _notificationAutomationEnabled = false;
  DateTime? _lastBackupAt;
  String? _bankTemplateId;
  final List<String> _allowedNotificationPackages = [];

  bool get isLoaded => _loaded;
  String get defaultCurrency => _defaultCurrency;
  double? get monthlyBudget => _monthlyBudget;
  bool get smsAutomationEnabled => _smsAutomationEnabled;
  bool get notificationAutomationEnabled => _notificationAutomationEnabled;
  DateTime? get lastBackupAt => _lastBackupAt;
  String? get bankTemplateId => _bankTemplateId;
  List<String> get allowedNotificationPackages => List.unmodifiable(_allowedNotificationPackages);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _defaultCurrency = prefs.getString(_currencyKey) ?? constants.defaultCurrency;
    final budget = prefs.getDouble(_budgetKey);
    _monthlyBudget = (budget != null && budget > 0) ? budget : null;
    _smsAutomationEnabled = prefs.getBool(_smsAutomationKey) ?? false;
    _notificationAutomationEnabled = prefs.getBool(_notificationAutomationKey) ?? false;
    final lastBackupRaw = prefs.getString(_lastBackupKey);
    _lastBackupAt = lastBackupRaw == null ? null : DateTime.tryParse(lastBackupRaw);
    _bankTemplateId = prefs.getString(_bankTemplateKey);
    final allowed = prefs.getStringList(_allowedPackagesKey) ?? const [];
    _allowedNotificationPackages
      ..clear()
      ..addAll(allowed);
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateCurrency(String currency) async {
    final trimmed = currency.trim().toUpperCase();
    if (trimmed.isEmpty) return;
    _defaultCurrency = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyKey, trimmed);
    notifyListeners();
  }

  Future<void> updateMonthlyBudget(double? budget) async {
    if (budget != null && budget <= 0) return;
    _monthlyBudget = budget;
    final prefs = await SharedPreferences.getInstance();
    if (budget == null) {
      await prefs.remove(_budgetKey);
    } else {
      await prefs.setDouble(_budgetKey, budget);
    }
    notifyListeners();
  }

  Future<void> updateSmsAutomation(bool enabled) async {
    _smsAutomationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_smsAutomationKey, enabled);
    notifyListeners();
  }

  Future<void> updateNotificationAutomation(bool enabled) async {
    _notificationAutomationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationAutomationKey, enabled);
    notifyListeners();
  }

  Future<void> updateLastBackup(DateTime timestamp) async {
    _lastBackupAt = timestamp;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, timestamp.toIso8601String());
    notifyListeners();
  }

  Future<void> updateBankTemplate(String? templateId) async {
    _bankTemplateId = templateId;
    final prefs = await SharedPreferences.getInstance();
    if (templateId == null || templateId.isEmpty) {
      await prefs.remove(_bankTemplateKey);
    } else {
      await prefs.setString(_bankTemplateKey, templateId);
    }
    notifyListeners();
  }

  Future<void> addAllowedPackage(String packageName) async {
    final normalized = packageName.trim();
    if (normalized.isEmpty || _allowedNotificationPackages.contains(normalized)) return;
    _allowedNotificationPackages.add(normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_allowedPackagesKey, _allowedNotificationPackages);
    notifyListeners();
  }

  Future<void> removeAllowedPackage(String packageName) async {
    _allowedNotificationPackages.remove(packageName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_allowedPackagesKey, _allowedNotificationPackages);
    notifyListeners();
  }
}
