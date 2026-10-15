import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/device.dart';
import '../../theme/app_theme.dart';
import '../../validation/device_validators.dart';
import 'form_data.dart';
import 'form_widgets.dart';

class DeviceSshSection extends StatelessWidget {
  const DeviceSshSection({
    super.key,
    required this.data,
    required this.enabled,
    required this.saving,
    required this.showPassword,
    required this.text,
    required this.onAuthTypeChanged,
    required this.onPasswordVisibilityChanged,
  });

  final DeviceFormData data;
  final bool enabled;
  final bool saving;
  final bool showPassword;
  final AppLocalizations text;
  final ValueChanged<SshAuthType> onAuthTypeChanged;
  final ValueChanged<bool> onPasswordVisibilityChanged;

  String? _validation(DeviceValidationError? error) =>
      error == null ? null : text.validationError(error);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 32),
      DeviceFormSectionTitle(number: '04', title: text.sshSection),
      Text(
        text.sshRequiredDescription,
        style: const TextStyle(color: AppTheme.muted),
      ),
      const SizedBox(height: 20),
      DeviceFormField(
        controller: data.sshPort,
        label: text.sshPortLabel,
        enabled: enabled,
        validator: (value) => _validation(DeviceValidators.port(value)),
        keyboard: TextInputType.number,
        digits: true,
      ),
      DeviceFormField(
        controller: data.username,
        label: text.usernameLabel,
        hint: text.usernameHint,
        enabled: enabled,
        validator: (value) => _validation(DeviceValidators.username(value)),
      ),
      DeviceFormField(
        controller: data.fingerprint,
        label: text.fingerprintLabel,
        helper: text.fingerprintHelper,
        hint: 'SHA256:…',
        enabled: enabled,
        mono: true,
        validator: (value) => _validation(DeviceValidators.fingerprint(value)),
      ),
      if (data.needsCredentials) ...[
        Text(
          text.authMethodLabel,
          style: const TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(text.passwordAuthLabel),
              selected: data.authType == SshAuthType.password,
              onSelected: saving
                  ? null
                  : (_) => onAuthTypeChanged(SshAuthType.password),
            ),
            ChoiceChip(
              label: Text(text.privateKeyAuthLabel),
              selected: data.authType == SshAuthType.privateKey,
              onSelected: saving
                  ? null
                  : (_) => onAuthTypeChanged(SshAuthType.privateKey),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (data.authType == SshAuthType.password)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextFormField(
              controller: data.password,
              enabled: enabled,
              obscureText: !showPassword,
              autocorrect: false,
              enableSuggestions: false,
              validator: (value) =>
                  _validation(DeviceValidators.credential(value)),
              decoration: InputDecoration(
                labelText: text.passwordLabel,
                suffixIcon: IconButton(
                  tooltip: showPassword ? text.hidePassword : text.showPassword,
                  onPressed: saving
                      ? null
                      : () => onPasswordVisibilityChanged(!showPassword),
                  icon: Icon(
                    showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
          )
        else ...[
          TextFormField(
            controller: data.privateKey,
            enabled: enabled,
            minLines: 5,
            maxLines: 10,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            validator: (value) =>
                _validation(DeviceValidators.privateKey(value)),
            decoration: InputDecoration(
              labelText: text.privateKeyLabel,
              hintText: text.privateKeyHint,
              helperText: text.privateKeyHelper,
              helperMaxLines: 3,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: data.passphrase,
            enabled: enabled,
            obscureText: !showPassword,
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(labelText: text.passphraseLabel),
          ),
        ],
      ],
    ],
  );
}
