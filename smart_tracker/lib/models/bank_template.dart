class BankTemplate {
  const BankTemplate({
    required this.id,
    required this.name,
    required this.amountPattern,
    required this.merchantPattern,
  });

  final String id;
  final String name;
  final RegExp amountPattern;
  final RegExp merchantPattern;
}

class BankTemplates {
  static const defaultId = 'auto';

  static final templates = <BankTemplate>[
    BankTemplate(
      id: 'qnb',
      name: 'QNB',
      amountPattern: RegExp(r'(?:QAR|QR)\s*([0-9.,]+)', caseSensitive: false),
      merchantPattern: RegExp(r"(?:at|merchant)\s+([a-z0-9][a-z0-9 &*'-.]{2,})", caseSensitive: false),
    ),
    BankTemplate(
      id: 'qib',
      name: 'QIB',
      amountPattern: RegExp(r'(?:QAR|QR)\s*([0-9.,]+)', caseSensitive: false),
      merchantPattern: RegExp(r"(?:pos|purchase)\s+([a-z0-9][a-z0-9 &*'-.]{2,})", caseSensitive: false),
    ),
    BankTemplate(
      id: 'cbq',
      name: 'CBQ',
      amountPattern: RegExp(r'(?:QAR|QR)\s*([0-9.,]+)', caseSensitive: false),
      merchantPattern: RegExp(r"(?:at|from)\s+([a-z0-9][a-z0-9 &*'-.]{2,})", caseSensitive: false),
    ),
    BankTemplate(
      id: 'hsbc',
      name: 'HSBC',
      amountPattern: RegExp(r'(?:USD|EUR|GBP|QAR|AED|SAR)\s*([0-9.,]+)', caseSensitive: false),
      merchantPattern: RegExp(r"(?:merchant|at)\s+([a-z0-9][a-z0-9 &*'-.]{2,})", caseSensitive: false),
    ),
  ];

  static BankTemplate? byId(String? id) {
    if (id == null || id.isEmpty || id == defaultId) return null;
    for (final template in templates) {
      if (template.id == id) return template;
    }
    return null;
  }
}
