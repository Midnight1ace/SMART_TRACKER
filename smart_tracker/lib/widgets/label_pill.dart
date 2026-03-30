import 'package:flutter/material.dart';

class LabelPill extends StatelessWidget {
  const LabelPill({
    super.key,
    required this.label,
    required this.color,
    this.textColor,
  });

  final String label;
  final Color color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor ?? Colors.white,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}