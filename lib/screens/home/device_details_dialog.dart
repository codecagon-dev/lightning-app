import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/device.dart';

Future<void> showDeviceDetails(BuildContext context, Device device) {
  final text = AppLocalizations.of(context);
  final fields = <String, String>{
    text.nameLabel: device.name,
    'SSH': text.sshStatus(device.sshStatus),
    text.sshLastChecked:
        device.sshCheckedAt?.toLocal().toString() ?? text.neverChecked,
    text.osLabel: device.os.name,
    'IP': device.ipAddress,
    'MAC': device.macAddress,
    text.broadcastAddressLabel: device.broadcastAddress,
    text.wolPortLabel: '${device.wolPort}',
    text.sshPortLabel: '${device.sshPort}',
    text.usernameLabel: device.sshUsername,
    text.fingerprintLabel: device.sshHostKeyFingerprint,
    text.lastChecked:
        device.checkedAt?.toLocal().toString() ?? text.neverChecked,
  };
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(text.detailsTitle),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text.deviceStatus(device.status)),
              const SizedBox(height: 8),
              Text(text.statusDescription),
              const SizedBox(height: 8),
              Text(text.sshStatusDescription),
              const SizedBox(height: 20),
              for (final field in fields.entries) ...[
                Text(field.key, style: Theme.of(context).textTheme.labelLarge),
                SelectableText(field.value),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(text.close),
        ),
      ],
    ),
  );
}
