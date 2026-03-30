import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_constants.dart';
import '../services/transaction_parser.dart';
import '../state/settings_store.dart';
import '../state/transaction_store.dart';
import '../state/workspace_store.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/label_pill.dart';
import '../widgets/section_card.dart';
import '../widgets/workspace_selector.dart';

enum AddMode { manual, paste }

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _merchantController = TextEditingController();
  final _currencyController = TextEditingController(text: defaultCurrency);
  final _rawTextController = TextEditingController();

  AddMode _mode = AddMode.manual;
  String _selectedCategory = transactionCategories.first;
  String _selectedCardType = cardTypes.first;
  DateTime _timestamp = DateTime.now();
  ParsedTransaction? _preview;
  String _lastCurrency = defaultCurrency;

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    _currencyController.dispose();
    _rawTextController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timestamp,
      firstDate: DateTime(2022),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timestamp),
    );
    if (time == null) return;

    setState(() {
      _timestamp = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submitManual(TransactionStore store, String workspaceId) async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showMessage('Enter a valid amount.');
      return;
    }

    final currencyInput = _currencyController.text.trim();
    final error = await store.addManual(
      amount: amount,
      workspaceId: workspaceId,
      currency: currencyInput.isEmpty ? _lastCurrency : currencyInput,
      merchant: _merchantController.text.trim(),
      category: _selectedCategory,
      cardType: _selectedCardType,
      timestamp: _timestamp,
    );

    if (!mounted) return;

    if (error != null) {
      _showMessage(error);
    } else {
      _amountController.clear();
      _merchantController.clear();
      setState(() {
        _selectedCategory = transactionCategories.first;
        _selectedCardType = cardTypes.first;
        _timestamp = DateTime.now();
      });
      _showMessage('Transaction added.');
    }
  }

  Future<void> _submitPaste(TransactionStore store, String workspaceId) async {
    final error = await store.addFromRawTextForWorkspace(
      _rawTextController.text,
      workspaceId: workspaceId,
      currencyFallback: _lastCurrency,
    );
    if (!mounted) return;
    if (error != null) {
      _showMessage(error);
      return;
    }

    _rawTextController.clear();
    setState(() {
      _preview = null;
    });
    _showMessage('Transaction added from message.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.pageGradient),
        child: SafeArea(
        child: Consumer3<TransactionStore, SettingsStore, WorkspaceStore>(
          builder: (context, store, settings, workspaceStore, _) {
            _syncDefaultCurrency(settings.defaultCurrency);
            final workspaceId = workspaceStore.selectedWorkspace?.id ?? 'personal';
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add transaction',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 30),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manual entry or paste a bank message.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 16),
                  const WorkspaceSelector(),
                  const SizedBox(height: 16),
                  SegmentedButton<AddMode>(
                    segments: const [
                      ButtonSegment(value: AddMode.manual, label: Text('Manual')),
                      ButtonSegment(value: AddMode.paste, label: Text('Paste message')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (value) {
                      setState(() {
                        _mode = value.first;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  if (_mode == AddMode.manual)
                    _buildManualForm(store, settings, workspaceId)
                  else
                    _buildPasteForm(store, settings, workspaceId),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildManualForm(TransactionStore store, SettingsStore settings, String workspaceId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Amount', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.muted)),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'e.g. 45.50'),
              ),
              const SizedBox(height: 16),
              Text('Currency', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.muted)),
              const SizedBox(height: 8),
              TextField(
                controller: _currencyController,
                decoration: const InputDecoration(hintText: 'QAR'),
              ),
              const SizedBox(height: 16),
              Text('Merchant', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.muted)),
              const SizedBox(height: 8),
              TextField(
                controller: _merchantController,
                decoration: const InputDecoration(hintText: 'Talabat'),
              ),
              const SizedBox(height: 16),
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
                      items: cardTypes
                          .map((type) => DropdownMenuItem(value: type, child: Text(_titleCase(type))))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedCardType = value ?? cardTypes.first),
                      decoration: const InputDecoration(labelText: 'Card type'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Timestamp', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.muted)),
                      const SizedBox(height: 6),
                      Text(formatDateTime(_timestamp), style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _pickDateTime,
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text('Edit'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
      child: FilledButton(
            onPressed: () => _submitManual(store, workspaceId),
            child: const Text('Add transaction'),
          ),
        ),
      ],
    );
  }

  Widget _buildPasteForm(TransactionStore store, SettingsStore settings, String workspaceId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Paste message', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.muted)),
              const SizedBox(height: 8),
              TextField(
                controller: _rawTextController,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'QNB: QAR 45.50 spent at TALABAT DOHA'),
                onChanged: (value) {
                  setState(() {
                        _preview = value.trim().isEmpty
                            ? null
                            : TransactionParser(defaultTemplateId: settings.bankTemplateId).parse(value);
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_preview != null) _buildPreviewCard(_preview!, settings.defaultCurrency),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () => _submitPaste(store, workspaceId),
            child: const Text('Add from message'),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard(ParsedTransaction preview, String fallbackCurrency) {
    return SectionCard(
      color: Colors.white.withOpacity(0.95),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Parsed preview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (preview.amount != null)
                LabelPill(
                  label: formatAmount(preview.amount!, preview.currency ?? fallbackCurrency),
                  color: AppTheme.primary,
                ),
              LabelPill(
                label: preview.cardType.toUpperCase(),
                color: AppTheme.accent,
                textColor: const Color(0xFF1B1B1B),
              ),
              if (preview.category != null)
                LabelPill(
                  label: _titleCase(preview.category!),
                  color: const Color(0xFF6BC4B8),
                  textColor: const Color(0xFF0B1C1C),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            preview.merchant ?? 'Merchant not detected',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            preview.normalizedText.isEmpty ? 'No normalized text' : preview.normalizedText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
          ),
        ],
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  void _syncDefaultCurrency(String currency) {
    if (currency == _lastCurrency) return;
    if (_currencyController.text.trim().isEmpty || _currencyController.text == _lastCurrency) {
      _currencyController.text = currency;
    }
    _lastCurrency = currency;
  }
}
