import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/automation_inbox_item.dart';

class AutomationInboxStore extends ChangeNotifier {
  static const _storageKey = 'automation_inbox';

  final Uuid _uuid = const Uuid();
  final List<AutomationInboxItem> _items = [];

  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<AutomationInboxItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _items
          ..clear()
          ..addAll(decoded.map((item) => AutomationInboxItem.fromJson(item as Map<String, dynamic>)));
      } catch (_) {
        _items.clear();
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> addItem({
    required String rawText,
    required String source,
    String? packageName,
  }) async {
    final item = AutomationInboxItem(
      id: _uuid.v4(),
      rawText: rawText,
      source: source,
      packageName: packageName,
      receivedAt: DateTime.now(),
    );
    _items.insert(0, item);
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((item) => item.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _items.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(_items.map((item) => item.toJson()).toList());
    await prefs.setString(_storageKey, payload);
  }
}
