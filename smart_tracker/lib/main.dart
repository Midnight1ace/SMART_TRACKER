import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/supabase_config.dart';
import 'screens/auth_gate.dart';
import 'state/auth_store.dart';
import 'state/entitlement_store.dart';
import 'state/settings_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  final settings = SettingsStore();
  final entitlement = EntitlementStore();
  await settings.load();
  await entitlement.load();
  runApp(SmartTrackerApp(settings: settings, entitlement: entitlement));
}

class SmartTrackerApp extends StatelessWidget {
  const SmartTrackerApp({super.key, required this.settings, required this.entitlement});

  final SettingsStore settings;
  final EntitlementStore entitlement;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        if (SupabaseConfig.isConfigured)
          ChangeNotifierProvider<AuthStore>(
            create: (_) => AuthStore(Supabase.instance.client),
          ),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: entitlement),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Smart Tracker',
        theme: AppTheme.lightTheme(),
        home: const AuthGate(),
      ),
    );
  }
}
