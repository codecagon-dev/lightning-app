import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/device.dart';
import '../../validation/device_validators.dart';
import 'form_data.dart';
import 'form_widgets.dart';

class DeviceNetworkSection extends StatelessWidget {
  const DeviceNetworkSection({
    super.key,
    required this.data,
    required this.enabled,
    required this.text,
    required this.onOsChanged,
  });

  final DeviceFormData data;
  final bool enabled;
  final AppLocalizations text;
  final ValueChanged<DeviceOs> onOsChanged;

  String? _validation(DeviceValidationError? error) =>
      error == null ? null : text.validationError(error);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DeviceFormSectionTitle(number: '01', title: text.deviceSection),
      DeviceFormField(
        controller: data.name,
        label: text.nameLabel,
        hint: text.nameHint,
        enabled: enabled,
        validator: (value) => _validation(DeviceValidators.name(value)),
        textCapitalization: TextCapitalization.sentences,
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: DropdownButtonFormField<DeviceOs>(
          initialValue: data.os,
          decoration: InputDecoration(labelText: text.osLabel),
          items: const [
            DropdownMenuItem(value: DeviceOs.linux, child: Text('Linux')),
            DropdownMenuItem(value: DeviceOs.windows, child: Text('Windows')),
          ],
          onChanged: enabled
              ? (value) {
                  if (value != null) onOsChanged(value);
                }
              : null,
        ),
      ),
      const SizedBox(height: 24),
      DeviceFormSectionTitle(number: '02', title: text.networkSection),
      DeviceFormField(
        controller: data.mac,
        label: text.macAddressLabel,
        hint: 'AA:BB:CC:DD:EE:FF',
        enabled: enabled,
        validator: (value) => _validation(DeviceValidators.macAddress(value)),
        mono: true,
      ),
      DeviceFormField(
        controller: data.ip,
        label: text.ipAddressLabel,
        hint: '192.168.1.10',
        enabled: enabled,
        validator: (value) => _validation(DeviceValidators.ipv4(value)),
        keyboard: const TextInputType.numberWithOptions(decimal: true),
        mono: true,
      ),
      DeviceFormField(
        controller: data.wolPort,
        label: text.wolPortLabel,
        enabled: enabled,
        validator: (value) => _validation(DeviceValidators.port(value)),
        keyboard: TextInputType.number,
        digits: true,
        helper: text.wolPortHelper,
      ),
      DeviceFormField(
        controller: data.broadcast,
        label: text.broadcastAddressLabel,
        hint: '192.168.1.255',
        enabled: enabled,
        validator: (value) => _validation(DeviceValidators.ipv4(value)),
        keyboard: const TextInputType.numberWithOptions(decimal: true),
        mono: true,
      ),
    ],
  );
}
