import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../services/automation_service.dart';
import '../state/automation_inbox_store.dart';
import '../state/entitlement_store.dart';
import '../state/settings_store.dart';
import '../state/transaction_store.dart';
import '../state/workspace_store.dart';
import 'app_shell.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final SupabaseClient? client = SupabaseConfig.isConfigured ? Supabase.instance.client : null;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WorkspaceStore>(
          create: (_) {
            final store = WorkspaceStore(client: client);
            store.load();
            return store;
          },
        ),
        ChangeNotifierProvider<TransactionStore>(
          create: (_) {
            final store = TransactionStore(client: client);
            store.load();
            return store;
          },
        ),
        ChangeNotifierProvider<AutomationInboxStore>(
          create: (_) {
            final store = AutomationInboxStore();
            store.load();
            return store;
          },
        ),
        Provider<AutomationService>(
          create: (context) => AutomationService(
            settings: context.read<SettingsStore>(),
            inboxStore: context.read<AutomationInboxStore>(),
            entitlementStore: context.read<EntitlementStore>(),
          ),
          dispose: (_, service) => service.dispose(),
        ),
      ],
      child: const AppShell(),
    );
  }
}
