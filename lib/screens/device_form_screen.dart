import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/device_repository.dart';
import '../models/device.dart';
import '../theme/app_theme.dart';
import '../validation/device_validators.dart';
import 'device_form/color_section.dart';
import 'device_form/form_data.dart';
import 'device_form/network_section.dart';
import 'device_form/ssh_section.dart';

class DeviceFormScreen extends StatefulWidget {
  const DeviceFormScreen({super.key, required this.repository, this.device});
  final DeviceRepository repository;
  final Device? device;

  @override
  State<DeviceFormScreen> createState() => _DeviceFormScreenState();
}

class _DeviceFormScreenState extends State<DeviceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final DeviceFormData _data;
  bool _saving = false;
  bool _showPassword = false;
  bool _hasError = false;
  DeviceValidationError? _inputError;

  @override
  void initState() {
    super.initState();
    _data = DeviceFormData(original: widget.device);
  }

  @override
  void dispose() {
    _data.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final fieldsValid = _formKey.currentState!.validate();
    final inputError = _data.validationError;
    if (!fieldsValid || inputError != null) {
      setState(() {
        _hasError = true;
        _inputError = inputError;
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _hasError = false;
      _inputError = null;
    });
    try {
      final Device saved;
      if (widget.device case final device?) {
        final patch = _data.toPatch();
        if (patch.isEmpty) {
          Navigator.of(context).pop();
          return;
        }
        saved = await (widget.repository as EditableDeviceRepository).update(
          device.id,
          patch,
        );
      } else {
        saved = await widget.repository.create(_data.toRegistration());
      }

      if (!mounted) return;
      setState(() => _saving = false);
      Navigator.of(context).pop(saved);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.device == null ? text.addDeviceTitle : text.editDeviceTitle,
          ),
          centerTitle: false,
          automaticallyImplyLeading: !_saving,
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  children: [
                    Text(
                      widget.device == null ? text.addIntro : text.editIntro,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      text.formSubtitle,
                      style: const TextStyle(color: AppTheme.muted),
                    ),
                    const SizedBox(height: 32),
                    DeviceNetworkSection(
                      data: _data,
                      enabled: !_saving,
                      text: text,
                      onOsChanged: (os) => setState(() => _data.os = os),
                    ),
                    DeviceColorSection(
                      color: _data.color,
                      enabled: !_saving,
                      text: text,
                      onChanged: (color) => setState(() => _data.color = color),
                    ),
                    if (widget.device != null)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(text.replaceSshCredentials),
                        subtitle: Text(text.keepSshCredentials),
                        value: _data.replaceCredentials,
                        onChanged: _saving
                            ? null
                            : (value) => setState(
                                () => _data.replaceCredentials = value,
                              ),
                      ),
                    DeviceSshSection(
                      data: _data,
                      enabled: !_saving,
                      saving: _saving,
                      showPassword: _showPassword,
                      text: text,
                      onAuthTypeChanged: (authType) =>
                          setState(() => _data.authType = authType),
                      onPasswordVisibilityChanged: (visible) =>
                          setState(() => _showPassword = visible),
                    ),
                    const SizedBox(height: 32),
                    if (_hasError) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          (_inputError == null
                              ? text.formSaveError
                              : text.validationError(_inputError!)),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check, size: 20),
                      label: Text(_saving ? text.saving : text.saveDevice),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        text.formCancel,
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
