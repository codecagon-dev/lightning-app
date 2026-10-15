import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../models/device.dart';
import 'device_card_details.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    required this.index,
    required this.deleting,
    required this.onEdit,
    this.onModify,
    required this.onDelete,
    required this.onPowerOn,
    required this.onPowerOff,
    required this.powering,
    this.checking = false,
    this.showSshCheck = false,
    this.onCheckSsh,
  });
  final Device device;
  final int index;
  final bool deleting;
  final bool powering;
  final bool checking, showSshCheck;
  final VoidCallback? onCheckSsh;
  final VoidCallback? onPowerOn, onPowerOff;
  final VoidCallback? onEdit, onDelete, onModify;

  @override
  Widget build(BuildContext context) => Material(
    color: AppTheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppTheme.line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 10, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: device.color == null
                        ? AppTheme.muted
                        : Color(0xFF000000 | device.color!),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    device.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  index.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 4),
                if (onModify != null)
                  IconButton(
                    tooltip: AppLocalizations.of(context).editDevice,
                    onPressed: onModify,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: AppTheme.muted,
                      size: 20,
                    ),
                  ),
                if (deleting)
                  const SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else
                  IconButton(
                    tooltip: AppLocalizations.of(context)
                        .deleteDeviceTooltip(device.name),
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppTheme.muted,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  DeviceNetworkLabel(label: 'IP', value: device.ipAddress),
                  DeviceNetworkLabel(label: 'MAC', value: device.macAddress),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DeviceConfigTag(
                    icon: Icons.bolt,
                    text: 'WOL · ${device.wolPort}',
                  ),
                  DeviceConfigTag(
                    icon: Icons.terminal,
                    text: 'SSH · ${device.sshPort}',
                  ),
                  DeviceConfigTag(
                    icon: device.os == DeviceOs.linux
                        ? Icons.computer
                        : Icons.desktop_windows,
                    text: device.os.name,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tooltip(
                    message: AppLocalizations.of(context).statusDescription,
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: switch (device.status) {
                            DeviceStatus.online => const Color(0xFF97AA9B),
                            DeviceStatus.offline => AppTheme.muted,
                            DeviceStatus.unknown => AppTheme.copper,
                          },
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context)
                                .deviceStatus(device.status),
                          ),
                        ),
                        if (powering) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: AppLocalizations.of(context)
                              .sshStatusDescription,
                          child: Text(
                            device.sshStatus == SshStatus.ready
                                ? '${AppLocalizations.of(context).sshLastChecked}: ${device.sshCheckedAt?.toLocal().toString() ?? AppLocalizations.of(context).neverChecked}'
                                : AppLocalizations.of(context)
                                      .sshStatus(device.sshStatus),
                            style: TextStyle(
                              color: switch (device.sshStatus) {
                                SshStatus.ready => AppTheme.muted,
                                SshStatus.authFailed ||
                                SshStatus.hostKeyMismatch ||
                                SshStatus.error => Theme.of(
                                  context,
                                ).colorScheme.error,
                                _ => AppTheme.muted,
                              },
                            ),
                          ),
                        ),
                      ),
                      if (showSshCheck)
                        IconButton(
                          tooltip: AppLocalizations.of(context).checkSsh,
                          onPressed: checking ? null : onCheckSsh,
                          icon: checking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 20),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  if (device.sshStatus != SshStatus.ready)
                    Text(
                      '${AppLocalizations.of(context).sshLastChecked}: ${device.sshCheckedAt?.toLocal().toString() ?? AppLocalizations.of(context).neverChecked}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onPowerOn,
                          icon: const Icon(Icons.bolt, size: 18),
                          label: Text(AppLocalizations.of(context).powerOn),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onPowerOff,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.copper,
                          ),
                          icon: const Icon(Icons.power_settings_new, size: 18),
                          label: Text(AppLocalizations.of(context).powerOff),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
