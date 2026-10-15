import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../settings/app_settings.dart';
import '../services/app_services_scope.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    final services = AppServicesScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final errorMessage = AppLocalizations.of(context).logoutError;
    setState(() => _loggingOut = true);
    try {
      final auth = services.auth;
      if (auth == null) {
        services.session.signOut();
      } else {
        await auth.logout();
      }
    } catch (_) {
      if (messenger.mounted) {
        messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final settings = AppSettingsScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(text.settingsTitle)),
      body: SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  text.settingsTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text.languageTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        text.languageDescription,
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                      const SizedBox(height: 20),
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: text.languageTitle,
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            isDense: true,
                            value: settings.locale?.languageCode ?? 'system',
                            items: [
                              DropdownMenuItem(
                                value: 'system',
                                child: Text(text.systemLanguageLabel),
                              ),
                              const DropdownMenuItem(
                                value: 'nl',
                                child: Text('Nederlands'),
                              ),
                              const DropdownMenuItem(
                                value: 'en',
                                child: Text('English'),
                              ),
                            ],
                            onChanged: settings.loading || settings.saving
                                ? null
                                : (value) {
                                    if (value != null) {
                                      settings.setLanguage(value);
                                    }
                                  },
                          ),
                        ),
                      ),
                      if (settings.loading || settings.saving) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(minHeight: 2),
                        if (settings.saving)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Semantics(
                              liveRegion: true,
                              child: Text(text.languageSaving),
                            ),
                          ),
                      ],
                      if (settings.loadFailed) ...[
                        const SizedBox(height: 16),
                        Text(
                          text.settingsLoadError,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: settings.loading || settings.saving
                              ? null
                              : settings.load,
                          icon: const Icon(Icons.refresh),
                          label: Text(text.settingsRetry),
                        ),
                      ],
                      if (settings.saveFailed) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            text.settingsSaveError,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                OutlinedButton.icon(
                  onPressed: _loggingOut ? null : _logout,
                  icon: const Icon(Icons.logout),
                  label: Text(_loggingOut ? text.loggingOut : text.logout),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
