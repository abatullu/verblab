// lib/presentation/pages/settings_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:verblab/domain/models/user_preferences.dart';
import '../../core/themes/app_theme.dart';
import '../../core/providers/user_preferences_provider.dart';
import '../../core/providers/monetization_providers.dart';
import '../widgets/common/error_view.dart';
import '../widgets/settings/settings_section.dart';
import '../widgets/settings/settings_switch_tile.dart';
import '../widgets/settings/settings_select_tile.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final preferencesAsync = ref.watch(userPreferencesNotifierProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text('Settings', style: theme.textTheme.titleLarge),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: preferencesAsync.when(
        data: (preferences) => _buildSettingsContent(context, preferences, ref),
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (error, stack) => ErrorView(
              error: 'Failed to load settings: $error',
              onRetry: () => ref.refresh(userPreferencesNotifierProvider),
            ),
      ),
    );
  }

  Widget _buildSettingsContent(
    BuildContext context,
    UserPreferences preferences,
    WidgetRef ref,
  ) {
    final theme = Theme.of(context);
    final notifier = ref.read(userPreferencesNotifierProvider.notifier);

    return ListView(
      padding: EdgeInsets.all(VerbLabTheme.spacing['md']!),
      children: [
        // Appearance section
        SettingsSection(
          title: 'Appearance',
          children: [
            SettingsSwitchTile(
              title: 'Dark Mode',
              subtitle: 'Use dark theme throughout the app',
              value: preferences.isDarkMode,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                notifier.setDarkMode(value);
              },
              icon: Icons.dark_mode_outlined,
            ),
          ],
        ),

        SizedBox(height: VerbLabTheme.spacing['md']),

        // Language section
        SettingsSection(
          title: 'Language',
          children: [
            SettingsSelectTile(
              title: 'Preferred Dialect',
              subtitle: 'Choose between UK and US English',
              value:
                  preferences.dialect == 'en-US' ? 'US English' : 'UK English',
              options: const ['UK English', 'US English'],
              onChanged: (value) {
                HapticFeedback.selectionClick();
                final dialect = value == 'US English' ? 'en-US' : 'en-UK';
                notifier.setDialect(dialect);
              },
              icon: Icons.language,
            ),
          ],
        ),

        SizedBox(height: VerbLabTheme.spacing['md']),

        // Premium section
        SettingsSection(
          title: 'Premium',
          children: [
            ListTile(
              title: Text(
                'Upgrade to Premium',
                style: theme.textTheme.bodyLarge,
              ),
              subtitle: Text(
                'Remove ads and support development',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              leading: Icon(
                Icons.workspace_premium,
                color: theme.colorScheme.primary,
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              onTap: () => context.pushNamed('premium'),
            ),
            // Opción para el modo de prueba (solo visible en modo debug)
            if (kDebugMode)
              SettingsSwitchTile(
                title: 'Purchase Test Mode',
                subtitle: 'Simulate purchases without real store',
                value: ref.watch(purchaseTestModeProvider),
                onChanged: (value) {
                  HapticFeedback.lightImpact();
                  ref.read(togglePurchaseTestModeProvider)(value);
                },
                icon: Icons.bug_report,
              ),
          ],
        ),

        SizedBox(height: VerbLabTheme.spacing['md']),

        // Reset section
        SettingsSection(
          title: 'Reset',
          children: [
            ListTile(
              title: Text(
                'Reset to Defaults',
                style: theme.textTheme.bodyLarge,
              ),
              subtitle: Text(
                'Reset all settings to default values',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              leading: Icon(Icons.restore, color: theme.colorScheme.error),
              onTap: () {
                HapticFeedback.mediumImpact();
                _showResetConfirmationDialog(context, notifier);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showResetConfirmationDialog(
    BuildContext context,
    UserPreferencesNotifier notifier,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Settings?'),
            content: const Text(
              'This will reset all settings to their default values. This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  notifier.resetToDefaults();
                  Navigator.of(context).pop();
                },
                child: const Text('Reset'),
              ),
            ],
          ),
    );
  }
}
