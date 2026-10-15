import 'package:flutter/material.dart';

import '../../models/device.dart';
import 'device_card.dart';

class DeviceList extends StatelessWidget {
  const DeviceList({
    super.key,
    required this.devices,
    required this.busy,
    required this.deletingId,
    required this.onEdit,
    this.onModify,
    required this.onDelete,
    required this.onPowerOn,
    required this.onPowerOff,
    required this.poweringId,
    this.checkingId,
    this.onCheckSsh,
  });

  final List<Device> devices;
  final bool busy;
  final String? deletingId;
  final String? poweringId;
  final String? checkingId;
  final ValueChanged<Device>? onCheckSsh;
  final ValueChanged<Device> onPowerOn, onPowerOff;
  final ValueChanged<Device> onEdit;
  final ValueChanged<Device>? onModify;
  final ValueChanged<Device> onDelete;

  Widget _card(int index) => DeviceCard(
    key: ValueKey(devices[index].id),
    device: devices[index],
    index: index + 1,
    deleting: deletingId == devices[index].id,
    onEdit: busy ? null : () => onEdit(devices[index]),
    onModify: busy || onModify == null ? null : () => onModify!(devices[index]),
    onDelete: busy ? null : () => onDelete(devices[index]),
    onPowerOn: busy ? null : () => onPowerOn(devices[index]),
    onPowerOff: busy ? null : () => onPowerOff(devices[index]),
    powering: poweringId == devices[index].id,
    checking: checkingId == devices[index].id,
    showSshCheck: onCheckSsh != null,
    onCheckSsh: busy || onCheckSsh == null
        ? null
        : () => onCheckSsh!(devices[index]),
  );

  @override
  Widget build(BuildContext context) => SliverLayoutBuilder(
    builder: (context, constraints) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final width =
          (constraints.crossAxisExtent - 48) / textScale.clamp(1.0, 2.0);
      final columns = width >= 1080
          ? 3
          : width >= 700
          ? 2
          : 1;
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        sliver: SliverList.separated(
          itemCount: (devices.length / columns).ceil(),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, row) {
            if (columns == 1) return _card(row);
            // Intrinsic height lets cards wrap without a fixed grid height.
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: 12),
                    Expanded(
                      child: row * columns + column < devices.length
                          ? _card(row * columns + column)
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
