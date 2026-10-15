import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class EmptyDeviceState extends StatelessWidget {
  const EmptyDeviceState({super.key, required this.onAdd});
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 124,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -0.10,
                child: Container(
                  width: 96,
                  height: 70,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              Transform.rotate(
                angle: 0.08,
                child: Container(
                  width: 96,
                  height: 70,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    border: Border.all(color: AppTheme.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.dns_outlined,
                    color: AppTheme.muted,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          AppLocalizations.of(context).emptyTitle,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            AppLocalizations.of(context).emptyDescription,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.muted, height: 1.6),
          ),
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 20),
          label: Text(AppLocalizations.of(context).addFirstDevice),
        ),
      ],
    ),
  );
}
