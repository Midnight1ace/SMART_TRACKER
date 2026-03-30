class AutomationInboxItem {
  AutomationInboxItem({
    required this.id,
    required this.rawText,
    required this.source,
    required this.packageName,
    required this.receivedAt,
  });

  final String id;
  final String rawText;
  final String source;
  final String? packageName;
  final DateTime receivedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rawText': rawText,
      'source': source,
      'packageName': packageName,
      'receivedAt': receivedAt.toIso8601String(),
    };
  }

  factory AutomationInboxItem.fromJson(Map<String, dynamic> json) {
    return AutomationInboxItem(
      id: json['id'] as String? ?? '',
      rawText: json['rawText'] as String? ?? '',
      source: json['source'] as String? ?? 'unknown',
      packageName: json['packageName'] as String?,
      receivedAt: DateTime.tryParse(json['receivedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
