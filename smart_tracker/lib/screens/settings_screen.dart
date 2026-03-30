import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/supabase_config.dart';
import '../models/bank_template.dart';
import '../screens/auth_screen.dart';
import '../screens/paywall_screen.dart';
import '../state/auth_store.dart';
import '../state/entitlement_store.dart';
import '../state/settings_store.dart';
import '../state/transaction_store.dart';
import '../state/workspace_store.dart';
import '../services/automation_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currencyController = TextEditingController();
  final _budgetController = TextEditingController();
  final _packageController = TextEditingController();

  String _lastCurrency = '';

  @override
  void dispose() {
    _currencyController.dispose();
    _budgetController.dispose();
    _packageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.pageGradient),
      child: SafeArea(
        child: Consumer4<SettingsStore, TransactionStore, WorkspaceStore, EntitlementStore>(
          builder: (context, settings, store, workspaceStore, entitlement, _) {
            final auth = SupabaseConfig.isConfigured ? context.watch<AuthStore>() : null;
            final isAuthenticated = auth?.isAuthenticated ?? false;
            _syncControllers(settings);
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Customize defaults and manage your data.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Defaults',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _currencyController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Default currency',
                            hintText: 'QAR',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _budgetController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Monthly budget',
                            hintText: 'Leave blank for none',
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: () => _saveDefaults(settings),
                            child: const Text('Save defaults'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pro access',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entitlement.isPro
                              ? 'Pro is enabled on this device.'
                              : 'Unlock automation inbox, bank templates, and team workspaces.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _openPaywall(context),
                                child: const Text('View Pro'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SwitchListTile(
                                value: entitlement.isPro,
                                onChanged: (value) => entitlement.setPro(value),
                                title: const Text('Pro enabled'),
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (SupabaseConfig.isConfigured) ...[
                    if (isAuthenticated)
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              auth?.user?.email ?? 'Signed in',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: () => _signOut(auth),
                                icon: const Icon(Icons.logout),
                                label: const Text('Sign out'),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to enable cloud backup and restore.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                onPressed: () => _openSignIn(context),
                                child: const Text('Sign in'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Automation (Android)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isAndroid
                              ? (entitlement.isPro
                                  ? 'Enable automation to review SMS or notifications.'
                                  : 'Automation Inbox is a Pro feature.')
                              : 'Automation is available on Android devices.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: settings.smsAutomationEnabled,
                          onChanged: isAndroid && entitlement.isPro ? (value) => _toggleSms(context, settings, value) : null,
                          title: const Text('SMS listener'),
                          subtitle: const Text('Requires Android permissions.'),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: settings.notificationAutomationEnabled,
                          onChanged: isAndroid && entitlement.isPro ? (value) => _toggleNotifications(context, settings, value) : null,
                          title: const Text('Notification listener'),
                          subtitle: const Text('Requires notification access.'),
                        ),
                        if (!entitlement.isPro) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: FilledButton(
                              onPressed: () => _openPaywall(context),
                              child: const Text('Unlock Pro'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (entitlement.isPro) ...[
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bank template',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: settings.bankTemplateId ?? BankTemplates.defaultId,
                            items: [
                              const DropdownMenuItem(value: BankTemplates.defaultId, child: Text('Auto')),
                              ...BankTemplates.templates.map(
                                (template) => DropdownMenuItem(value: template.id, child: Text(template.name)),
                              ),
                            ],
                            onChanged: (value) => settings.updateBankTemplate(value == BankTemplates.defaultId ? null : value),
                            decoration: const InputDecoration(labelText: 'Default bank template'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (entitlement.isPro) ...[
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Allowed notification sources',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            settings.allowedNotificationPackages.isEmpty
                                ? 'All sources allowed.'
                                : 'Only the sources below will be captured.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _packageController,
                            decoration: const InputDecoration(labelText: 'Add package name (e.g. com.qnb.app)'),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () => _addPackage(settings),
                              child: const Text('Add source'),
                            ),
                          ),
                          if (settings.allowedNotificationPackages.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ...settings.allowedNotificationPackages.map(
                              (pkg) => Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(pkg)),
                                  IconButton(
                                    onPressed: () => settings.removeAllowedPackage(pkg),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Workspaces',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        if (!workspaceStore.isLoaded)
                          const LinearProgressIndicator(minHeight: 2)
                        else ...[
                          ...workspaceStore.workspaces.map(
                            (workspace) => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(workspace.name)),
                                TextButton(
                                  onPressed: () => _inviteToWorkspace(context, workspaceStore, workspace.id),
                                  child: const Text('Invite'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: entitlement.isPro ? () => _createWorkspace(context, workspaceStore) : null,
                              child: const Text('Create team workspace'),
                            ),
                          ),
                          if (!entitlement.isPro) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Team workspaces are a Pro feature.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        if (SupabaseConfig.isConfigured) ...[
                          Text(
                            isAuthenticated
                                ? 'Manual backup keeps your local data safe.'
                                : 'Sign in to back up and restore your data.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                          ),
                          if (settings.lastBackupAt != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Last backup: ${formatDateTime(settings.lastBackupAt!)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isAuthenticated ? () => _backupNow(context, store, settings) : null,
                                  child: const Text('Backup to Supabase'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: isAuthenticated ? () => _restoreNow(context, store, workspaceStore) : null,
                                  child: const Text('Restore'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => _copyExport(store),
                            icon: const Icon(Icons.copy),
                            label: const Text('Copy data export'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmClear(context, store),
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('Clear all transactions'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _syncControllers(SettingsStore settings) {
    if (_lastCurrency != settings.defaultCurrency) {
      if (_currencyController.text.trim().isEmpty || _currencyController.text.trim() == _lastCurrency) {
        _currencyController.text = settings.defaultCurrency;
      }
      _lastCurrency = settings.defaultCurrency;
    }

    if (_budgetController.text.isEmpty && settings.monthlyBudget != null) {
      _budgetController.text = settings.monthlyBudget!.toStringAsFixed(0);
    }
  }

  Future<void> _saveDefaults(SettingsStore settings) async {
    final currency = _currencyController.text.trim();
    final budgetText = _budgetController.text.trim();
    final budget = budgetText.isEmpty ? null : double.tryParse(budgetText);

    if (currency.isEmpty) {
      _showMessage('Currency is required.');
      return;
    }

    if (budgetText.isNotEmpty && (budget == null || budget <= 0)) {
      _showMessage('Enter a valid budget.');
      return;
    }

    await settings.updateCurrency(currency);
    await settings.updateMonthlyBudget(budget);
    if (!mounted) return;
    _showMessage('Defaults saved.');
  }

  Future<void> _toggleSms(BuildContext context, SettingsStore settings, bool enabled) async {
    await settings.updateSmsAutomation(enabled);
    if (!mounted) return;
    if (enabled) {
      final automation = context.read<AutomationService>();
      final granted = await automation.ensureSmsPermission();
      if (!mounted) return;
      _showMessage(granted ? 'SMS automation enabled.' : 'SMS permission is required to read messages.');
    } else {
      _showMessage('SMS automation disabled.');
    }
  }

  Future<void> _toggleNotifications(BuildContext context, SettingsStore settings, bool enabled) async {
    await settings.updateNotificationAutomation(enabled);
    if (!mounted) return;
    if (enabled) {
      final automation = context.read<AutomationService>();
      final granted = await automation.ensureNotificationPermission();
      if (!mounted) return;
      _showMessage(granted ? 'Notification automation enabled.' : 'Notification access is required.');
    } else {
      _showMessage('Notification automation disabled.');
    }
  }

  Future<void> _copyExport(TransactionStore store) async {
    final payload = store.exportJson();
    await Clipboard.setData(ClipboardData(text: payload));
    if (!mounted) return;
    _showMessage('Export copied to clipboard.');
  }

  Future<void> _backupNow(BuildContext context, TransactionStore store, SettingsStore settings) async {
    final error = await store.backupToSupabase();
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    await settings.updateLastBackup(DateTime.now());
    if (!mounted) return;
    _showMessage('Backup complete.');
  }

  Future<void> _restoreNow(BuildContext context, TransactionStore store, WorkspaceStore workspaceStore) async {
    final workspaceIds = workspaceStore.workspaces.map((workspace) => workspace.id).toList();
    final error = await store.restoreFromSupabase(workspaceIds: workspaceIds);
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }
    _showMessage('Restore complete.');
  }

  Future<void> _confirmClear(BuildContext context, TransactionStore store) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text('This permanently removes all stored transactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await store.clearAll();
      if (!mounted) return;
      _showMessage('All transactions cleared.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _signOut(AuthStore? auth) async {
    await auth?.signOut();
    if (!mounted) return;
    _showMessage('Signed out.');
  }

  void _openSignIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  void _openPaywall(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallScreen()),
    );
  }

  Future<void> _addPackage(SettingsStore settings) async {
    final value = _packageController.text.trim();
    if (value.isEmpty) return;
    await settings.addAllowedPackage(value);
    if (!mounted) return;
    _packageController.clear();
  }

  Future<void> _createWorkspace(BuildContext context, WorkspaceStore workspaceStore) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create workspace'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Team name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Create')),
        ],
      ),
    );

    if (name == null || name.trim().isEmpty) return;
    final error = await workspaceStore.createWorkspace(name.trim());
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
    } else {
      _showMessage('Workspace created.');
    }
  }

  Future<void> _inviteToWorkspace(BuildContext context, WorkspaceStore workspaceStore, String workspaceId) async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite member'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'name@email.com'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Invite')),
        ],
      ),
    );
    if (email == null || email.trim().isEmpty) return;
    final error = await workspaceStore.inviteMember(workspaceId, email.trim());
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
    } else {
      _showMessage('Invite created.');
    }
  }
}
