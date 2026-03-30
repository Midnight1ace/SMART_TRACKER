import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthStore extends ChangeNotifier {
  AuthStore(this._client) {
    _session = _client.auth.currentSession;
    _subscription = _client.auth.onAuthStateChange.listen((data) {
      _session = data.session;
      notifyListeners();
    });
  }

  final SupabaseClient _client;
  Session? _session;
  StreamSubscription<AuthState>? _subscription;

  Session? get session => _session;
  User? get user => _client.auth.currentUser;
  bool get isAuthenticated => _session != null;

  Future<AuthResponse> signIn(String email, String password) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}