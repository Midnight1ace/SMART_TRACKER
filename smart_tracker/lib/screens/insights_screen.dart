import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/insight.dart';
import '../models/transaction_item.dart';
import '../services/insight_service.dart';
import '../state/settings_store.dart';
import '../state/transaction_store.dart';
import '../state/workspace_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';
import '../widgets/workspace_selector.dart';
import 'add_transaction_screen.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.pageGradient),
      child: SafeArea(
        child: Consumer3<TransactionStore, SettingsStore, WorkspaceStore>(
          builder: (context, store, settings, workspaceStore, _) {
            if (!store.isLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final workspaceId = workspaceStore.selectedWorkspace?.id ?? 'personal';
            final transactions = store.transactionsForWorkspace(workspaceId).toList();
            final insights = InsightService().buildInsights(
              transactions,
              monthlyBudget: settings.monthlyBudget,
              currencyOverride: settings.defaultCurrency,
            );
            final categoryTotals = _categoryTotals(transactions);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Insights',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Signals about your spending behavior.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 16),
                  const WorkspaceSelector(),
                  const SizedBox(height: 16),
                  if (transactions.isEmpty)
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No insights yet',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add your first transaction to unlock insights.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: FilledButton(
                              onPressed: () => _openAdd(context),
                              child: const Text('Add transaction'),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    ...insights.map((insight) => _InsightCard(insight: insight)),
                    const SizedBox(height: 4),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category totals',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 12),
                          ...categoryTotals.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_titleCase(entry.key), style: Theme.of(context).textTheme.bodyMedium),
                                  Text(
                                    formatAmount(entry.value, settings.defaultCurrency),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

List<MapEntry<String, double>> _categoryTotals(List<TransactionItem> transactions) {
  final totals = <String, double>{};
  for (final item in transactions) {
    final category = item.category as String;
    final amount = item.amount as double;
    totals[category] = (totals[category] ?? 0) + amount;
  }
  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries;
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

void _openAdd(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
  );
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final Insight insight;

  @override
  Widget build(BuildContext context) {
    final toneColor = _toneColor(insight.tone);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(
                color: toneColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    insight.detail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _toneColor(InsightTone tone) {
    switch (tone) {
      case InsightTone.positive:
        return const Color(0xFF1B8F6B);
      case InsightTone.caution:
        return const Color(0xFFE07A1A);
      case InsightTone.neutral:
        return const Color(0xFF6B7A8F);
    }
  }
}
