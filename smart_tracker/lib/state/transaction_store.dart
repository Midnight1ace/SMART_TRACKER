import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction_constants.dart';
import '../models/transaction_item.dart';
import '../services/transaction_parser.dart';

class TransactionStore extends ChangeNotifier {
  TransactionStore({SupabaseClient? client}) : _client = client;

  static const _storageKey = 'transactions';

  final SupabaseClient? _client;
  final TransactionParser _parser = TransactionParser();
  final List<TransactionItem> _items = [];
  final Uuid _uuid = const Uuid();

  bool _loaded = false;

  bool get isLoaded => _loaded;
  bool get isRemoteEnabled => _client != null;

  UnmodifiableListView<TransactionItem> get transactions {
    final sorted = [..._items]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return UnmodifiableListView(sorted);
  }

  UnmodifiableListView<TransactionItem> transactionsForWorkspace(String workspaceId) {
    final filtered = _items.where((item) => item.workspaceId == workspaceId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return UnmodifiableListView(filtered);
  }

  Future<void> load() async {
    if (_loaded) return;
    await _loadFromLocal();
    await _ensureClientIds();
    _loaded = true;
    notifyListeners();
  }

  Future<String?> addManual({
    required double amount,
    required String workspaceId,
    String? currency,
    String? merchant,
    String? category,
    String? cardType,
    DateTime? timestamp,
  }) async {
    if (amount <= 0) return 'Amount must be greater than 0.';

    final clientId = _newClientId();

    final item = TransactionItem(
      id: clientId,
      clientId: clientId,
      workspaceId: workspaceId,
      amount: amount,
      currency: (currency ?? defaultCurrency).toUpperCase(),
      merchant: (merchant == null || merchant.trim().isEmpty) ? 'Unknown merchant' : merchant.trim(),
      category: (category == null || category.trim().isEmpty) ? 'other' : category.trim().toLowerCase(),
      cardType: (cardType == null || cardType.trim().isEmpty) ? 'unknown' : cardType.trim().toLowerCase(),
      timestamp: timestamp ?? DateTime.now(),
      rawText: '',
      createdAt: DateTime.now(),
    );

    _items.add(item);
    await _save();
    notifyListeners();
    return null;
  }

  Future<String?> addFromRawText(String rawText, {String? currencyFallback}) async {
    return addFromRawTextForWorkspace(rawText, workspaceId: 'personal', currencyFallback: currencyFallback);
  }

  Future<String?> addFromRawTextForWorkspace(
    String rawText, {
    required String workspaceId,
    String? currencyFallback,
  }) async {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) return 'Paste a transaction message.';

    final parsed = _parser.parse(trimmed);
    if (parsed.isRefund) return 'Refund/credit detected. Skipped.';
    if (parsed.amount == null) return 'Could not detect the amount.';

    final clientId = _newClientId();
    final item = TransactionItem(
      id: clientId,
      clientId: clientId,
      workspaceId: workspaceId,
      amount: parsed.amount!,
      currency: (parsed.currency ?? currencyFallback ?? defaultCurrency).toUpperCase(),
      merchant: parsed.merchant ?? 'Unknown merchant',
      category: parsed.category ?? 'other',
      cardType: parsed.cardType,
      timestamp: DateTime.now(),
      rawText: trimmed,
      createdAt: DateTime.now(),
    );

    _items.add(item);
    await _save();
    notifyListeners();
    return null;
  }

  Future<String?> addParsedForWorkspace({
    required ParsedTransaction parsed,
    required String rawText,
    required String workspaceId,
    String? currencyFallback,
  }) async {
    if (parsed.amount == null) return 'Could not detect the amount.';
    final clientId = _newClientId();
    final item = TransactionItem(
      id: clientId,
      clientId: clientId,
      workspaceId: workspaceId,
      amount: parsed.amount!,
      currency: (parsed.currency ?? currencyFallback ?? defaultCurrency).toUpperCase(),
      merchant: parsed.merchant ?? 'Unknown merchant',
      category: parsed.category ?? 'other',
      cardType: parsed.cardType,
      timestamp: DateTime.now(),
      rawText: rawText,
      createdAt: DateTime.now(),
    );

    _items.add(item);
    await _save();
    notifyListeners();
    return null;
  }

  Future<void> clearAll() async {
    _items.clear();
    await _save();
    notifyListeners();
  }

  Future<void> deleteById(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _save();
    notifyListeners();
  }

  String exportJson() {
    return jsonEncode(_items.map((item) => item.toJson()).toList());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  String _newClientId() => _uuid.v4();

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _items
          ..clear()
          ..addAll(decoded.map((item) => TransactionItem.fromJson(item as Map<String, dynamic>)));
      } catch (_) {
        _items.clear();
      }
    }
  }

  Future<void> _ensureClientIds() async {
    var updated = false;
    final refreshed = <TransactionItem>[];
    for (final item in _items) {
      final nextClientId = item.clientId.isNotEmpty ? item.clientId : (item.id.isNotEmpty ? item.id : _newClientId());
      final nextId = item.id.isNotEmpty ? item.id : nextClientId;
      if (nextClientId != item.clientId || nextId != item.id) {
        updated = true;
        refreshed.add(_withClientId(item, nextId, nextClientId));
      } else {
        refreshed.add(item);
      }
    }
    if (updated) {
      _items
        ..clear()
        ..addAll(refreshed);
      await _save();
    }
  }

  TransactionItem _withClientId(TransactionItem item, String id, String clientId) {
    return TransactionItem(
      id: id,
      clientId: clientId,
      workspaceId: item.workspaceId,
      amount: item.amount,
      currency: item.currency,
      merchant: item.merchant,
      category: item.category,
      cardType: item.cardType,
      timestamp: item.timestamp,
      rawText: item.rawText,
      createdAt: item.createdAt,
    );
  }

  @visibleForTesting
  static List<TransactionItem> mergeByClientId(List<TransactionItem> local, List<TransactionItem> remote) {
    final merged = <String, TransactionItem>{};
    for (final item in local) {
      final key = item.clientId.isNotEmpty ? item.clientId : item.id;
      if (key.isNotEmpty) {
        merged[key] = item;
      }
    }
    for (final item in remote) {
      final key = item.clientId.isNotEmpty ? item.clientId : item.id;
      if (key.isNotEmpty && !merged.containsKey(key)) {
        merged[key] = item;
      }
    }
    return merged.values.toList();
  }

  Future<String?> backupToSupabase() async {
    if (!isRemoteEnabled) return 'Supabase is not configured.';
    final user = _client!.auth.currentUser;
    if (user == null) return 'Please sign in to back up your data.';

    await _ensureClientIds();

    final payload = _items.map((item) {
      return {
        'user_id': user.id,
        'client_id': item.clientId,
        'workspace_id': item.workspaceId,
        'amount': item.amount,
        'currency': item.currency.toUpperCase(),
        'merchant': item.merchant,
        'category': item.category,
        'card_type': item.cardType,
        'timestamp': item.timestamp.toIso8601String(),
        'raw_text': item.rawText.isEmpty ? null : item.rawText,
        'created_at': item.createdAt.toIso8601String(),
      };
    }).toList();

    if (payload.isEmpty) return null;

    try {
      await _client!
          .from('transactions')
          .upsert(payload, onConflict: 'user_id,client_id');
      return null;
    } on PostgrestException catch (error) {
      return error.message;
    } catch (_) {
      return 'Backup failed. Please try again.';
    }
  }

  Future<String?> restoreFromSupabase({List<String>? workspaceIds}) async {
    if (!isRemoteEnabled) return 'Supabase is not configured.';
    final user = _client!.auth.currentUser;
    if (user == null) return 'Please sign in to restore your data.';

    try {
      var query = _client!.from('transactions').select();
      if (workspaceIds != null && workspaceIds.isNotEmpty) {
        final quoted = workspaceIds.map((id) => '\"$id\"').join(',');
        query = query.filter('workspace_id', 'in', '($quoted)');
      } else {
        query = query.eq('user_id', user.id);
      }
      final response = await query.order('timestamp', ascending: false);

      final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
      final remoteItems = rows.map(TransactionItem.fromSupabase).toList();
      final merged = mergeByClientId(_items, remoteItems);
      _items
        ..clear()
        ..addAll(merged);
      await _ensureClientIds();
      await _save();
      notifyListeners();
      return null;
    } on PostgrestException catch (error) {
      return error.message;
    } catch (_) {
      return 'Restore failed. Please try again.';
    }
  }
}
