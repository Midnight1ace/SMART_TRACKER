import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EntitlementStore extends ChangeNotifier {
  static const _proKey = 'entitlement_pro';

  bool _loaded = false;
  bool _isPro = false;

  bool get isLoaded => _loaded;
  bool get isPro => _isPro;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _isPro = prefs.getBool(_proKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setPro(bool enabled) async {
    _isPro = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_proKey, enabled);
    notifyListeners();
  }
}
