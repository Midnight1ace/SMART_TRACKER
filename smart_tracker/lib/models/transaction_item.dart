class TransactionItem {
  TransactionItem({
    required this.id,
    required this.clientId,
    required this.workspaceId,
    required this.amount,
    required this.currency,
    required this.merchant,
    required this.category,
    required this.cardType,
    required this.timestamp,
    required this.rawText,
    required this.createdAt,
  });

  final String id;
  final String clientId;
  final String workspaceId;
  final double amount;
  final String currency;
  final String merchant;
  final String category;
  final String cardType;
  final DateTime timestamp;
  final String rawText;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'workspaceId': workspaceId,
      'amount': amount,
      'currency': currency,
      'merchant': merchant,
      'category': category,
      'cardType': cardType,
      'timestamp': timestamp.toIso8601String(),
      'rawText': rawText,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String? ?? '',
      clientId: json['clientId'] as String? ?? json['client_id'] as String? ?? json['id'] as String? ?? '',
      workspaceId: json['workspaceId'] as String? ?? json['workspace_id'] as String? ?? 'personal',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'QAR',
      merchant: json['merchant'] as String? ?? 'Unknown',
      category: json['category'] as String? ?? 'other',
      cardType: json['cardType'] as String? ?? 'unknown',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      rawText: json['rawText'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  factory TransactionItem.fromSupabase(Map<String, dynamic> json) {
    return TransactionItem(
      id: (json['id'] ?? '').toString(),
      clientId: (json['client_id'] ?? json['clientId'] ?? json['id'] ?? '').toString(),
      workspaceId: (json['workspace_id'] ?? json['workspaceId'] ?? 'personal').toString(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'QAR',
      merchant: json['merchant'] as String? ?? 'Unknown',
      category: json['category'] as String? ?? 'other',
      cardType: (json['card_type'] as String?) ?? (json['cardType'] as String?) ?? 'unknown',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      rawText: (json['raw_text'] as String?) ?? (json['rawText'] as String?) ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
