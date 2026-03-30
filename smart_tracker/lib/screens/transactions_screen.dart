import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_constants.dart';
import '../models/transaction_item.dart';
import '../state/transaction_store.dart';
import '../state/workspace_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/label_pill.dart';
import '../widgets/section_card.dart';
import '../widgets/workspace_selector.dart';
import 'add_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.pageGradient),
      child: SafeArea(
        child: Consumer2<TransactionStore, WorkspaceStore>(
          builder: (context, store, workspaceStore, _) {
            if (!store.isLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final categories = ['all', ...transactionCategories];
            final workspaceId = workspaceStore.selectedWorkspace?.id ?? 'personal';
            final items = store.transactionsForWorkspace(workspaceId);
            final filteredByCategory = _selectedCategory == 'all'
                ? items
                : items.where((item) => item.category == _selectedCategory).toList();
            final filtered = _searchQuery.trim().isEmpty
                ? filteredByCategory
                : filteredByCategory
                    .where((item) =>
                        item.merchant.toLowerCase().contains(_searchQuery.trim().toLowerCase()) ||
                        item.rawText.toLowerCase().contains(_searchQuery.trim().toLowerCase()))
                    .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transactions',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 30),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Filter by category and review details.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search merchant or message',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) => setState(() => _searchQuery = value),
                      ),
                      const SizedBox(height: 12),
                      const WorkspaceSelector(),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final category = categories[index];
                            final selected = _selectedCategory == category;
                            return ChoiceChip(
                              label: Text(_titleCase(category)),
                              selected: selected,
                              onSelected: (_) => setState(() => _selectedCategory = category),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemCount: categories.length,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? _EmptyState(
                          hasAny: items.isNotEmpty,
                          onAdd: () => _openAdd(context),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return Dismissible(
                              key: ValueKey(item.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete transaction?'),
                                    content: const Text('This action cannot be undone.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                return confirm ?? false;
                              },
                              onDismissed: (_) => store.deleteById(item.id),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE07A1A),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: InkWell(
                                onTap: () => _showDetails(context, item),
                                child: SectionCard(
                                  child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.account_balance_wallet, color: AppTheme.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.merchant,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatDateTime(item.timestamp),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                                        ),
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: [
                                            LabelPill(
                                              label: _titleCase(item.category),
                                              color: AppTheme.accent,
                                              textColor: const Color(0xFF1B1B1B),
                                            ),
                                            LabelPill(
                                              label: item.cardType.toUpperCase(),
                                              color: AppTheme.primary,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    formatAmount(item.amount, item.currency),
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ],
                                  ),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemCount: filtered.length,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  void _showDetails(BuildContext context, TransactionItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.merchant,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                formatDateTime(item.timestamp),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Amount', style: Theme.of(context).textTheme.labelLarge),
                  Text(
                    formatAmount(item.amount, item.currency),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Category', style: Theme.of(context).textTheme.labelLarge),
                  Text(_titleCase(item.category), style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Card type', style: Theme.of(context).textTheme.labelLarge),
                  Text(item.cardType.toUpperCase(), style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              if (item.rawText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Original message', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Text(
                  item.rawText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasAny, required this.onAdd});

  final bool hasAny;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              hasAny ? 'No matches found.' : 'No transactions yet.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              textAlign: TextAlign.center,
            ),
            if (!hasAny) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: onAdd,
                  child: const Text('Add your first transaction'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void _openAdd(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
  );
}
