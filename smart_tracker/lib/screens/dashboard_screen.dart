import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
            final transactions = store.transactionsForWorkspace(workspaceId);
            final total = transactions.fold<double>(0, (sum, item) => sum + item.amount);
            final currency = transactions.isNotEmpty ? transactions.first.currency : settings.defaultCurrency;
            final insights = InsightService()
                .buildInsights(transactions.toList(), monthlyBudget: settings.monthlyBudget, currencyOverride: currency)
                .take(3)
                .toList();
            final recent = transactions.take(3).toList();
            final budgetSummary = _budgetSummary(transactions.toList(), settings.monthlyBudget, currency);
            final monthSummary = _monthSummary(transactions.toList(), settings.monthlyBudget, currency);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smart Tracker',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 32),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Behavior-first spending intelligence.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 20),
                  const WorkspaceSelector(),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total spend',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.muted),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          formatAmount(total, currency),
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 30, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${transactions.length} transactions logged',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  if (transactions.isEmpty) ...[
                    const SizedBox(height: 16),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start tracking',
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
                    ),
                  ],
                  if (budgetSummary != null) ...[
                    const SizedBox(height: 16),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly budget',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            budgetSummary.label,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              value: budgetSummary.progress,
                              minHeight: 10,
                              backgroundColor: AppTheme.backgroundAlt,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                budgetSummary.progress >= 1 ? const Color(0xFFE07A1A) : AppTheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (monthSummary != null) ...[
                    const SizedBox(height: 16),
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'This month',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            monthSummary.headline,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                          ),
                          const SizedBox(height: 12),
                          ...monthSummary.topCategories.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_titleCase(entry.key), style: Theme.of(context).textTheme.bodyMedium),
                                  Text(
                                    formatAmount(entry.value, currency),
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
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top insights',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        if (insights.isEmpty)
                          Text(
                            'Add transactions to unlock insights.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                          )
                        else
                          ...insights.map(
                            (insight) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    insight.title,
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    insight.detail,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                                  ),
                                ],
                              ),
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
                          'Recent activity',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        if (recent.isEmpty)
                          Text(
                            'No transactions yet.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                          )
                        else
                          ...recent.map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.merchant,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          formatDateTime(item.timestamp),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    formatAmount(item.amount, item.currency),
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
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BudgetSummary {
  _BudgetSummary({required this.label, required this.progress});

  final String label;
  final double progress;
}

_BudgetSummary? _budgetSummary(List<TransactionItem> transactions, double? budget, String currency) {
  if (budget == null || budget <= 0) return null;
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthTotal = transactions
      .where((item) => item.timestamp.isAfter(monthStart.subtract(const Duration(seconds: 1))))
      .fold<double>(0, (sum, item) => sum + item.amount);
  final remaining = budget - monthTotal;
  final label = remaining <= 0
      ? 'Over budget by ${formatAmount(remaining.abs(), currency)}'
      : '${formatAmount(remaining, currency)} remaining';
  return _BudgetSummary(label: label, progress: (monthTotal / budget).clamp(0, 1));
}

class _MonthSummary {
  _MonthSummary({
    required this.headline,
    required this.topCategories,
  });

  final String headline;
  final List<MapEntry<String, double>> topCategories;
}

_MonthSummary? _monthSummary(List<TransactionItem> transactions, double? budget, String currency) {
  if (transactions.isEmpty) return null;
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthItems = transactions.where((item) => item.timestamp.isAfter(monthStart.subtract(const Duration(seconds: 1)))).toList();
  if (monthItems.isEmpty) return null;

  final monthTotal = monthItems.fold<double>(0, (sum, item) => sum + item.amount);
  final remaining = budget == null ? null : budget - monthTotal;
  final headline = remaining == null
      ? '${formatAmount(monthTotal, currency)} spent this month'
      : remaining <= 0
          ? 'Over budget by ${formatAmount(remaining.abs(), currency)}'
          : '${formatAmount(remaining, currency)} remaining';

  final categoryTotals = <String, double>{};
  for (final item in monthItems) {
    categoryTotals[item.category] = (categoryTotals[item.category] ?? 0) + item.amount;
  }
  final topCategories = categoryTotals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return _MonthSummary(
    headline: headline,
    topCategories: topCategories.take(3).toList(),
  );
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
