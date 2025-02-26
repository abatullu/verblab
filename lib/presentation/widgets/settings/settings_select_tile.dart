// lib/presentation/widgets/settings/settings_select_tile.dart
import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';

class SettingsSelectTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final IconData? icon;

  const SettingsSelectTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.options,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null)
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          SizedBox(height: VerbLabTheme.spacing['xs']),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      leading:
          icon != null ? Icon(icon, color: theme.colorScheme.primary) : null,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () => _showOptionsDialog(context),
    );
  }

  void _showOptionsDialog(BuildContext context) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text(title),
            children:
                options
                    .map(
                      (option) => RadioListTile<String>(
                        title: Text(option),
                        value: option,
                        groupValue: value,
                        activeColor: theme.colorScheme.primary,
                        onChanged: (newValue) {
                          if (newValue != null) {
                            onChanged(newValue);
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    )
                    .toList(),
          ),
    );
  }
}
