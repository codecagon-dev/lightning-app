import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../services/api_exception.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../validation/auth_validators.dart';
import '../widgets/lightning_wordmark.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authService});
  final AuthService? authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _missingConfiguration = false;
  ApiException? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    if (!_form.currentState!.validate()) return;
    final auth = widget.authService;
    if (auth == null) {
      setState(() => _missingConfiguration = true);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _missingConfiguration = false;
    });
    try {
      await auth.login(email: _email.text, password: _password.text);
      if (!mounted) return;
      TextInput.finishAutofillContext(shouldSave: true);
      _password.clear();
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error);
    } catch (_) {
      if (mounted) {
        setState(() => _error = const ApiException('Authentication failed.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    String? validate(
      String? value,
      AuthValidationError? Function(String) check,
    ) {
      final error = check(value ?? '');
      return error == null ? null : strings.authValidationError(error);
    }

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: AutofillGroup(
                    // Save credentials explicitly only after confirmed success.
                    onDisposeAction: AutofillContextAction.cancel,
                    child: Form(
                      key: _form,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const LightningWordmark(),
                          const SizedBox(height: 40),
                          Text(
                            strings.loginTitle,
                            style: textTheme.headlineLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            strings.loginSubtitle,
                            style: textTheme.bodyMedium?.copyWith(
                              color: AppTheme.muted,
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _email,
                            readOnly: _busy,
                            decoration: InputDecoration(
                              labelText: strings.emailLabel,
                              errorMaxLines: 3,
                            ),
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [
                              AutofillHints.username,
                              AutofillHints.email,
                            ],
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            validator: (value) =>
                                validate(value, AuthValidators.email),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            readOnly: _busy,
                            decoration: InputDecoration(
                              labelText: strings.passwordLabel,
                              errorMaxLines: 3,
                            ),
                            obscureText: true,
                            keyboardType: TextInputType.visiblePassword,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            autocorrect: false,
                            enableSuggestions: false,
                            validator: (value) =>
                                validate(value, AuthValidators.password),
                            onFieldSubmitted: (_) => _submit(),
                          ),
                          if (_error != null || _missingConfiguration) ...[
                            const SizedBox(height: 16),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _missingConfiguration
                                    ? strings.apiNotConfigured
                                    : strings.authError(_error!.statusCode),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: _busy ? null : () => _submit(),
                            child: _busy
                                ? _progress(strings)
                                : Text(strings.loginTitle),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _progress(AppLocalizations strings) => SizedBox(
    width: 20,
    height: 20,
    child: CircularProgressIndicator(
      strokeWidth: 2,
      semanticsLabel: strings.authWorking,
    ),
  );
}
