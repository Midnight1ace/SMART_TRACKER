enum InsightTone {
  positive,
  neutral,
  caution,
}

class Insight {
  Insight({
    required this.title,
    required this.detail,
    required this.tone,
  });

  final String title;
  final String detail;
  final InsightTone tone;
}