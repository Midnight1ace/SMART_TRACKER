import '../models/bank_template.dart';

class ParsedTransaction {
  ParsedTransaction({
    required this.amount,
    required this.currency,
    required this.merchant,
    required this.category,
    required this.cardType,
    required this.normalizedText,
    required this.isRefund,
  });

  final double? amount;
  final String? currency;
  final String? merchant;
  final String? category;
  final String cardType;
  final String normalizedText;
  final bool isRefund;
}

class TransactionParser {
  TransactionParser({this.defaultTemplateId});

  final String? defaultTemplateId;

  static const Map<String, String> _currencyMap = {
    r'$': 'USD',
    'qar': 'QAR',
    'qr': 'QAR',
    'sar': 'SAR',
    'aed': 'AED',
    'usd': 'USD',
    'eur': 'EUR',
    'gbp': 'GBP',
    'inr': 'INR',
    'rs': 'INR',
  };

  static const List<String> _debitKeywords = ['debit', 'mada'];
  static const List<String> _creditKeywords = ['credit', 'visa', 'mastercard', 'master card', 'amex'];
  static const List<String> _refundKeywords = [
    'refund',
    'reversal',
    'reversed',
    'chargeback',
    'credited',
    'credit back',
    'returned',
  ];

  static final List<_CategoryRule> _categoryRules = [
    _CategoryRule(RegExp(r'talabat|ubereats|deliveroo|noon food|rafiq|kfc|mcdonald|burger|pizza|starbucks', caseSensitive: false), 'food'),
    _CategoryRule(RegExp(r'uber|careem|taxi|metro|bus', caseSensitive: false), 'transport'),
    _CategoryRule(RegExp(r'amazon|noon|carrefour|lulu|mall|store|shop|market', caseSensitive: false), 'shopping'),
    _CategoryRule(RegExp(r'netflix|spotify|anghami|cinema|movie|steam', caseSensitive: false), 'entertainment'),
    _CategoryRule(RegExp(r'clinic|pharmacy|hospital|medical|dental', caseSensitive: false), 'health'),
    _CategoryRule(RegExp(r'hotel|air|flight|airways|booking|trip', caseSensitive: false), 'travel'),
    _CategoryRule(RegExp(r'electric|water|internet|telecom|vodafone|ooredoo|du|utility', caseSensitive: false), 'bills'),
  ];

  ParsedTransaction parse(String rawText) {
    final template = BankTemplates.byId(defaultTemplateId);
    if (template != null) {
      final templated = parseWithTemplate(rawText, template);
      if (templated.amount != null || templated.merchant != null) {
        return templated;
      }
    }
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return ParsedTransaction(
        amount: null,
        currency: null,
        merchant: null,
        category: null,
        cardType: 'unknown',
        normalizedText: '',
        isRefund: false,
      );
    }

    final normalizedText = _normalizeText(trimmed);
    final isRefund = _isRefund(trimmed);
    final amountAndCurrency = _extractAmountAndCurrency(trimmed);
    final merchant = _extractMerchant(trimmed);
    final cardType = _detectCardType(trimmed);
    final category = _categorize(merchant, trimmed);

    return ParsedTransaction(
      amount: isRefund ? null : amountAndCurrency.amount,
      currency: amountAndCurrency.currency,
      merchant: merchant,
      category: category,
      cardType: cardType,
      normalizedText: normalizedText,
      isRefund: isRefund,
    );
  }

  ParsedTransaction parseWithTemplate(String rawText, BankTemplate template) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return ParsedTransaction(
        amount: null,
        currency: null,
        merchant: null,
        category: null,
        cardType: 'unknown',
        normalizedText: '',
        isRefund: false,
      );
    }

    final normalizedText = _normalizeText(trimmed);
    final isRefund = _isRefund(trimmed);
    final amountMatch = template.amountPattern.firstMatch(trimmed);
    final merchantMatch = template.merchantPattern.firstMatch(trimmed);

    final amount = amountMatch != null ? _parseAmount(amountMatch.group(1) ?? '') : null;
    final merchant = merchantMatch != null ? _cleanMerchant(merchantMatch.group(1) ?? '') : null;
    final currency = _extractAmountAndCurrency(trimmed).currency;
    final cardType = _detectCardType(trimmed);
    final category = _categorize(merchant, trimmed);

    return ParsedTransaction(
      amount: isRefund ? null : amount,
      currency: currency,
      merchant: merchant,
      category: category,
      cardType: cardType,
      normalizedText: normalizedText,
      isRefund: isRefund,
    );
  }

  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9.\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  _AmountResult _extractAmountAndCurrency(String rawText) {
    final text = rawText.toLowerCase();
    const numberPattern = r'([0-9]{1,3}(?:[.,][0-9]{3})*(?:[.,][0-9]{1,2})?|[0-9]+(?:[.,][0-9]{1,2})?)';
    final patterns = [
      RegExp(r'(\$|qar|sar|aed|usd|eur|gbp|inr|rs|qr)\s*' + numberPattern, caseSensitive: false),
      RegExp(numberPattern + r'\s*(\$|qar|sar|aed|usd|eur|gbp|inr|rs|qr)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final token = match.group(1) != null && RegExp(r'[a-z$]', caseSensitive: false).hasMatch(match.group(1)!)
            ? match.group(1)!.toLowerCase()
            : match.group(2)!.toLowerCase();
        final amountString = match.group(1) != null && RegExp(r'[0-9]').hasMatch(match.group(1)!)
            ? match.group(1)!
            : match.group(2)!;
        final amount = _parseAmount(amountString);
        if (amount != null) {
          return _AmountResult(amount: amount, currency: _currencyMap[token]);
        }
      }
    }

    final looseMatch = RegExp(numberPattern).firstMatch(text);
    if (looseMatch != null) {
      final amount = _parseAmount(looseMatch.group(1)!);
      if (amount != null) {
        return _AmountResult(amount: amount, currency: null);
      }
    }

    return _AmountResult(amount: null, currency: null);
  }

  double? _parseAmount(String value) {
    var normalized = value.trim();
    if (normalized.contains(',') && normalized.contains('.')) {
      if (normalized.lastIndexOf('.') > normalized.lastIndexOf(',')) {
        normalized = normalized.replaceAll(',', '');
      } else {
        normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (normalized.contains(',') && !normalized.contains('.')) {
      if (RegExp(r',\\d{1,2}$').hasMatch(normalized)) {
        normalized = normalized.replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
    }
    normalized = normalized.replaceAll(' ', '');
    final amount = double.tryParse(normalized);
    if (amount == null || amount <= 0) return null;
    return amount;
  }

  String _detectCardType(String rawText) {
    final text = rawText.toLowerCase();
    if (_debitKeywords.any(text.contains)) return 'debit';
    if (_creditKeywords.any(text.contains)) return 'credit';
    return 'unknown';
  }

  String? _extractMerchant(String rawText) {
    final withoutPrefix = rawText.replaceFirst(RegExp(r'^[A-Z\\s]{2,}:\\s*'), '');
    final candidates = [rawText, withoutPrefix];
    final patterns = [
      RegExp(r"(?:at|from|in)\s+([a-z0-9][a-z0-9 &*'-.]{2,})", caseSensitive: false),
      RegExp(r"(?:pos|purchase)\s+([a-z0-9][a-z0-9 &*'-.]{2,})", caseSensitive: false),
      RegExp(r"(?:pos purchase|pos)\s*(?:at)?\s+([a-z0-9][a-z0-9 &*'-.]{2,})", caseSensitive: false),
    ];

    for (final candidate in candidates) {
      for (final pattern in patterns) {
        final match = pattern.firstMatch(candidate);
        if (match != null && match.group(1) != null) {
          final cleaned = _cleanMerchant(match.group(1)!);
          if (cleaned != null) return cleaned;
        }
      }
    }

    return null;
  }

  bool _isRefund(String rawText) {
    final text = rawText.toLowerCase();
    return _refundKeywords.any(text.contains);
  }

  String? _cleanMerchant(String value) {
    var cleaned = value.replaceAll(RegExp(r"[^a-z0-9 &*'\-.]", caseSensitive: false), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(qar|sar|aed|usd|eur|gbp|inr|rs|qr|\$)\b\s*[0-9.,\s]+$', caseSensitive: false),
      '',
    ).trim();
    cleaned = cleaned.replaceAll(RegExp(r'\b(qa|qatar|doha)\b', caseSensitive: false), '').trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  String? _categorize(String? merchant, String rawText) {
    final haystack = '${merchant ?? ''} $rawText'.toLowerCase();
    for (final rule in _categoryRules) {
      if (rule.pattern.hasMatch(haystack)) return rule.category;
    }
    return null;
  }
}

class _AmountResult {
  _AmountResult({required this.amount, required this.currency});

  final double? amount;
  final String? currency;
}

class _CategoryRule {
  _CategoryRule(this.pattern, this.category);

  final RegExp pattern;
  final String category;
}
