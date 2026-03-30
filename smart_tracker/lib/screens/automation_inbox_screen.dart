import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/automation_inbox_item.dart';
import '../models/transaction_constants.dart';
import '../services/transaction_parser.dart';
import '../state/automation_inbox_store.dart';
import '../state/entitlement_store.dart';
import '../state/settings_store.dart';
import '../state/transaction_store.dart';
import '../state/workspace_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/section_card.dart';
import 'paywall_screen.dart';

class AutomationInboxScreen extends StatelessWidget {
  const AutomationInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.pageGradient),
      child: SafeArea(
        child: Consumer4<AutomationInboxStore, EntitlementStore, WorkspaceStore, SettingsStore>(
          builder: (context, inbox, entitlement, workspaceStore, settings, _) {
            if (!entitlement.isPro) {
              return PaywallScreen(onUnlocked: () => _refresh(context));
            }
            if (!inbox.isLoaded || !workspaceStore.isLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = inbox.items;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Automation inbox',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Review detected transactions before saving.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    SectionCard(
                      child: Text(
                        'No new items yet.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                      ),
                    )
                  else
                    ...items.map((item) => _InboxCard(item: item, settings: settings)),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => inbox.clearAll(),
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Clear inbox'),
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

  void _refresh(BuildContext context) {
    context.read<EntitlementStore>().load();
  }
}

class _InboxCard extends StatelessWidget {
  const _InboxCard({required this.item, required this.settings});

  final AutomationInboxItem item;
  final SettingsStore settings;

  @override
  Widget build(BuildContext context) {
    final parser = TransactionParser(defaultTemplateId: settings.bankTemplateId);
    final preview = parser.parse(item.rawText);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.rawText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Detected: ${preview.amount == null ? 'Unclear amount' : formatAmount(preview.amount!, preview.currency ?? settings.defaultCurrency)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 6),
            Text(
              'Merchant: ${preview.merchant ?? 'Unknown'} • ${_titleCase(preview.category ?? 'other')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => _approve(context, item, preview),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _edit(context, item),
                    child: const Text('Edit'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, AutomationInboxItem item, ParsedTransaction preview) async {
    final store = context.read<TransactionStore>();
    final workspace = context.read<WorkspaceStore>().selectedWorkspace?.id ?? 'personal';
    if (preview.amount == null) {
      _showMessage(context, 'Amount not detected. Please edit.');
      return;
    }

    final error = await store.addParsedForWorkspace(
      parsed: preview,
      rawText: item.rawText,
      workspaceId: workspace,
      currencyFallback: settings.defaultCurrency,
    );

    if (error != null) {
      _showMessage(context, error);
      return;
    }

    await context.read<AutomationInboxStore>().remove(item.id);
    _showMessage(context, 'Transaction saved.');
  }

  Future<void> _edit(BuildContext context, AutomationInboxItem item) async {
    final result = await showModalBottomSheet<_EditResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => _EditSheet(rawText: item.rawText, settings: settings),
    );

    if (result == null) return;

    final store = context.read<TransactionStore>();
    final workspace = context.read<WorkspaceStore>().selectedWorkspace?.id ?? 'personal';
    final error = await store.addManual(
      amount: result.amount,
      workspaceId: workspace,
      currency: result.currency,
      merchant: result.merchant,
      category: result.category,
      cardType: result.cardType,
      timestamp: result.timestamp,
    );

    if (error != null) {
      _showMessage(context, error);
      return;
    }

    await context.read<AutomationInboxStore>().remove(item.id);
    _showMessage(context, 'Transaction saved.');
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}

class _EditResult {
  const _EditResult({
    required this.amount,
    required this.currency,
    required this.merchant,
    required this.category,
    required this.cardType,
    required this.timestamp,
  });

  final double amount;
  final String currency;
  final String merchant;
  final String category;
  final String cardType;
  final DateTime timestamp;
}

class _EditSheet extends StatefulWidget {
  const _EditSheet({required this.rawText, required this.settings});

  final String rawText;
  final SettingsStore settings;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _amountController;
  late final TextEditingController _merchantController;
  late final TextEditingController _currencyController;
  String _selectedCategory = transactionCategories.first;
  String _selectedCardType = cardTypes.first;
  DateTime _timestamp = DateTime.now();

  @override
  void initState() {
    super.initState();
    final parser = TransactionParser(defaultTemplateId: widget.settings.bankTemplateId);
    final parsed = parser.parse(widget.rawText);
    _amountController = TextEditingController(text: parsed.amount?.toStringAsFixed(2) ?? '');
    _merchantController = TextEditingController(text: parsed.merchant ?? '');
    _currencyController = TextEditingController(text: parsed.currency ?? widget.settings.defaultCurrency);
    _selectedCategory = parsed.category ?? transactionCategories.first;
    _selectedCardType = parsed.cardType;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review transaction',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _currencyController,
            decoration: const InputDecoration(labelText: 'Currency'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _merchantController,
            decoration: const InputDecoration(labelText: 'Merchant'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: transactionCategories
                      .map((category) => DropdownMenuItem(value: category, child: Text(_titleCase(category))))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedCategory = value ?? transactionCategories.first),
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCardType,
                  items: cardTypes.map((type) => DropdownMenuItem(value: type, child: Text(_titleCase(type)))).toList(),
                  onChanged: (value) => setState(() => _selectedCardType = value ?? cardTypes.first),
                  decoration: const InputDecoration(labelText: 'Card type'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _submit,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      return;
    }
    Navigator.of(context).pop(
      _EditResult(
        amount: amount,
        currency: _currencyController.text.trim().isEmpty ? widget.settings.defaultCurrency : _currencyController.text.trim(),
        merchant: _merchantController.text.trim().isEmpty ? 'Unknown merchant' : _merchantController.text.trim(),
        category: _selectedCategory,
        cardType: _selectedCardType,
        timestamp: _timestamp,
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }
}
