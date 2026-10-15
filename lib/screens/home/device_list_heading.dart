import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class DeviceListHeading extends StatelessWidget {
  const DeviceListHeading({
    super.key,
    required this.count,
    required this.onAdd,
  });
  final int count;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Row(
      children: [
        Text(
          text.devicesLabel,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
            color: AppTheme.muted,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            '$count'.padLeft(2, '0'),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 48,
          height: 48,
          child: FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(padding: EdgeInsets.zero),
            child: Tooltip(
              message: text.addDevice,
              child: Semantics(
                label: text.addDevice,
                child: const Icon(Icons.add, size: 25),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
