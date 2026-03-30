import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class MissingConfigScreen extends StatelessWidget {
  const MissingConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.pageGradient),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Supabase setup required',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your Supabase URL and anon key using --dart-define to continue.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.muted),
              ),
              const SizedBox(height: 20),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Example run command',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      'flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}