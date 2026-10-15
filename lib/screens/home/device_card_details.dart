import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class DeviceNetworkLabel extends StatelessWidget {
  const DeviceNetworkLabel({
    super.key,
    required this.label,
    required this.value,
  });
  final String label, value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.2,
          color: AppTheme.muted,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
      ),
    ],
  );
}

class DeviceConfigTag extends StatelessWidget {
  const DeviceConfigTag({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      border: Border.all(color: AppTheme.line),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.muted),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.muted)),
      ],
    ),
  );
}
