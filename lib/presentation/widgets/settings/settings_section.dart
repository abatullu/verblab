// lib/presentation/widgets/settings/settings_section.dart
import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: VerbLabTheme.spacing['md']!,
            bottom: VerbLabTheme.spacing['xs']!,
          ),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VerbLabTheme.radius['md']!),
            side: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
          ),
          child: Column(children: [...children]),
        ),
      ],
    );
  }
}
