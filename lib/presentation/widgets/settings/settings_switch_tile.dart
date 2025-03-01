// lib/presentation/widgets/settings/settings_switch_tile.dart
import 'package:flutter/material.dart';

class SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      title: Text(title, style: theme.textTheme.bodyLarge),
      subtitle:
          subtitle != null
              ? Text(
                subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
              : null,
      value: value,
      onChanged: onChanged,
      secondary:
          icon != null ? Icon(icon, color: theme.colorScheme.primary) : null,
      activeColor: theme.colorScheme.primary,
    );
  }
}
