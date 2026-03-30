import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/workspace.dart';

class WorkspaceStore extends ChangeNotifier {
  WorkspaceStore({SupabaseClient? client}) : _client = client;

  static const _workspaceKey = 'workspaces';
  static const _selectedKey = 'selected_workspace';
  static const _personalKey = 'personal_workspace_id';

  final SupabaseClient? _client;
  final Uuid _uuid = const Uuid();
  final List<Workspace> _workspaces = [];

  bool _loaded = false;
  String? _selectedId;

  bool get isLoaded => _loaded;
  List<Workspace> get workspaces => List.unmodifiable(_workspaces);
  String? get selectedId => _selectedId;

  Workspace? get selectedWorkspace {
    if (_selectedId == null) return null;
    return _workspaces.firstWhere((workspace) => workspace.id == _selectedId, orElse: () => _workspaces.first);
  }

  Future<void> load() async {
    if (_loaded) return;
    await _loadFromLocal();
    if (_client != null && _client!.auth.currentUser != null) {
      await _loadFromRemote();
    }
    await _ensurePersonalWorkspace();
    _loaded = true;
    notifyListeners();
  }

  Future<void> selectWorkspace(String workspaceId) async {
    _selectedId = workspaceId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedKey, workspaceId);
    notifyListeners();
  }

  Future<String?> createWorkspace(String name, {bool isPersonal = false}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Workspace name is required.';

    if (isPersonal && _workspaces.any((workspace) => workspace.isPersonal)) {
      return null;
    }

    final id = _uuid.v4();
    final workspace = Workspace(
      id: id,
      name: trimmed,
      isPersonal: isPersonal,
      memberCount: 1,
    );

    _workspaces.add(workspace);
    await _persistLocal();

    await _createRemoteWorkspace(id, trimmed);

    notifyListeners();
    return null;
  }

  Future<String?> inviteMember(String workspaceId, String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty || !trimmed.contains('@')) return 'Enter a valid email.';

    if (_client != null && _client!.auth.currentUser != null) {
      try {
        await _client!.from('workspace_invites').insert({
          'workspace_id': workspaceId,
          'email': trimmed,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        });
        return null;
      } catch (_) {
        return 'Failed to create invite.';
      }
    }

    return 'Supabase is required to invite members.';
  }

  Future<void> _loadFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_workspaceKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _workspaces
          ..clear()
          ..addAll(decoded.map((item) => Workspace.fromJson(item as Map<String, dynamic>)));
      } catch (_) {
        _workspaces.clear();
      }
    }
    _selectedId = prefs.getString(_selectedKey);
  }

  Future<void> _loadFromRemote() async {
    final user = _client!.auth.currentUser;
    if (user == null) return;

    try {
      final memberRows = await _client!
          .from('workspace_members')
          .select('workspace_id')
          .eq('user_id', user.id);

      final ids = (memberRows as List<dynamic>).map((row) => row['workspace_id']).toList().cast<String>();
      if (ids.isEmpty) return;

      final quoted = ids.map((id) => '\"$id\"').join(',');
      final rows =
          await _client!.from('workspaces').select().filter('id', 'in', '($quoted)').order('created_at', ascending: true);
      final workspaces = (rows as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((row) => Workspace(
                id: row['id'] as String,
                name: row['name'] as String? ?? 'Workspace',
                isPersonal: row['name'] == 'Personal',
                memberCount: 1,
              ))
          .toList();
      if (workspaces.isNotEmpty) {
        _workspaces
          ..clear()
          ..addAll(workspaces);
        await _persistLocal();
      }
    } catch (_) {
      // Ignore remote load errors.
    }
  }

  Future<void> _ensurePersonalWorkspace() async {
    if (_workspaces.isNotEmpty) {
      if (_selectedId == null && _workspaces.isNotEmpty) {
        await selectWorkspace(_workspaces.first.id);
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final storedPersonal = prefs.getString(_personalKey);
    final personalId = storedPersonal ?? _uuid.v4();

    _workspaces.add(
      Workspace(
        id: personalId,
        name: 'Personal',
        isPersonal: true,
        memberCount: 1,
      ),
    );
    await prefs.setString(_personalKey, personalId);
    await _persistLocal();
    await selectWorkspace(personalId);

    await _createRemoteWorkspace(personalId, 'Personal');
  }

  Future<void> _createRemoteWorkspace(String id, String name) async {
    if (_client == null || _client!.auth.currentUser == null) return;
    final user = _client!.auth.currentUser!;
    try {
      final response = await _client!
          .from('workspaces')
          .insert({
            'id': id,
            'name': name,
            'owner_id': user.id,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      await _client!.from('workspace_members').insert({
        'workspace_id': response['id'] ?? id,
        'user_id': user.id,
        'role': 'owner',
      });
    } catch (_) {
      // Ignore remote failure.
    }
  }

  Future<void> _persistLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(_workspaces.map((item) => item.toJson()).toList());
    await prefs.setString(_workspaceKey, payload);
  }
}
