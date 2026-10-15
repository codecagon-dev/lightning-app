import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class HomeToolbar extends StatelessWidget {
  const HomeToolbar({
    super.key,
    required this.onSettings,
    required this.onReload,
  });
  final VoidCallback onSettings;
  final VoidCallback? onReload;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.line),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bolt, size: 22, color: AppTheme.ink),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'LIGHTNING',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.5,
            ),
          ),
        ),
        IconButton(
          tooltip: text.settingsTitle,
          onPressed: onSettings,
          icon: const Icon(Icons.tune, size: 21),
        ),
        IconButton(
          tooltip: text.reloadDevices,
          onPressed: onReload,
          icon: const Icon(Icons.refresh, size: 21),
        ),
      ],
    );
  }
}
