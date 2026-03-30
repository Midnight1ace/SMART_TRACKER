import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/entitlement_store.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key, this.onUnlocked});

  final VoidCallback? onUnlocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.pageGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlock Smart Tracker Pro',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 8),
              Text(
                'Automation Inbox, bank templates, and shared workspaces for teams.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pro includes', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('- Automation Inbox for review before saving'),
                    const Text('- Bank templates and higher parsing accuracy'),
                    const Text('- Team workspaces with shared ledgers'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () => _unlock(context),
                  child: const Text('Unlock Pro (Demo)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _unlock(BuildContext context) async {
    await context.read<EntitlementStore>().setPro(true);
    onUnlocked?.call();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
