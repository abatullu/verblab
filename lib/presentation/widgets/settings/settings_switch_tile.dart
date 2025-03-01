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
    final isDarkMode = theme.brightness == Brightness.dark;

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
          icon != null
              ? Icon(
                icon,
                color:
                    value
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withOpacity(0.7),
              )
              : null,
      activeColor: theme.colorScheme.primary,
      activeTrackColor:
          isDarkMode
              ? theme.colorScheme.primaryContainer.withOpacity(0.7)
              : theme.colorScheme.primaryContainer,
      inactiveThumbColor:
          isDarkMode ? Colors.white.withOpacity(0.9) : Colors.white,
      inactiveTrackColor:
          isDarkMode
              ? theme.colorScheme.onSurfaceVariant.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
      trackOutlineColor: MaterialStateProperty.resolveWith<Color?>((
        Set<MaterialState> states,
      ) {
        if (states.contains(MaterialState.selected)) {
          return Colors.transparent;
        }
        return theme.colorScheme.outline.withOpacity(0.3);
      }),
      thumbIcon: MaterialStateProperty.resolveWith<Icon?>((
        Set<MaterialState> states,
      ) {
        if (states.contains(MaterialState.selected)) {
          return Icon(
            Icons.check,
            size: 12.0,
            color: theme.colorScheme.onPrimary,
          );
        }
        return null;
      }),
    );
  }
}
