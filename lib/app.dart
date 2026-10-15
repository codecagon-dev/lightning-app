import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/api_service.dart';
import 'services/api_diagnostics.dart';
import 'services/auth_service.dart';
import 'services/app_services_scope.dart';
import 'services/user_session.dart';
import 'services/device_repository.dart';
import 'services/api_device_repository.dart';
import 'settings/app_settings.dart';
import 'theme/app_theme.dart';

class LightningApp extends StatefulWidget {
  const LightningApp({
    super.key,
    this.repository,
    this.api,
    this.apiBaseUrl,
    this.apiDebugLogs = true,
    this.apiDebugSensitive = false,
  });
  final ApiService? api;
  final String? apiBaseUrl;
  final bool apiDebugLogs;
  final bool apiDebugSensitive;
  final DeviceRepository? repository;

  @override
  State<LightningApp> createState() => _LightningAppState();
}

class _LightningAppState extends State<LightningApp> {
  final AppSettings _settings = AppSettings();
  final GlobalKey<NavigatorState> _navigator = GlobalKey<NavigatorState>();
  late final ApiService? _api;
  late final AuthService? _auth;
  late final UserSession _session;
  late DeviceRepository _defaultRepository;
  String? _repositoryUser;

  @override
  void initState() {
    super.initState();
    _api =
        widget.api ??
        (widget.apiBaseUrl == null
            ? null
            : ApiService(
                baseUrl: widget.apiBaseUrl!,
                diagnostics: ApiDiagnostics(
                  enabled: widget.apiDebugLogs,
                  includeSensitive: widget.apiDebugSensitive,
                ),
              ));
    _defaultRepository = _api == null
        ? MemoryDeviceRepository()
        : ApiDeviceRepository(_api);
    _session = _api?.session ?? UserSession();
    _auth = _api == null ? null : AuthService(_api);
    _repositoryUser = _session.user?.id;
    _session.addListener(_sessionChanged);
    _settings.load();
  }

  void _sessionChanged() {
    final id = _session.user?.id;
    if (id != _repositoryUser) {
      if (_api == null) _defaultRepository = MemoryDeviceRepository();
      _repositoryUser = id;
    }
    if (!_session.isAuthenticated) {
      _navigator.currentState?.popUntil((route) => route.isFirst);
    }
  }

  @override
  void dispose() {
    _session.removeListener(_sessionChanged);
    final repository = _defaultRepository;
    if (repository is ApiDeviceRepository) repository.dispose();
    if (widget.api == null) {
      _api?.close();
      if (_api == null) _session.dispose();
    }
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppServicesScope(
    session: _session,
    api: _api,
    auth: _auth,
    child: AppSettingsScope(
      settings: _settings,
      child: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) => MaterialApp(
          navigatorKey: _navigator,
          title: 'Lightning',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
          locale: _settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (locale, _) =>
              AppLocalizations.resolve(locale),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: ListenableBuilder(
            listenable: _session,
            builder: (context, _) => _session.isAuthenticated
                ? HomeScreen(
                    key: ValueKey(_session.user!.id),
                    repository: widget.repository ?? _defaultRepository,
                  )
                : LoginScreen(authService: _auth),
          ),
        ),
      ),
    ),
  );
}
