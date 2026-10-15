import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'form_widgets.dart';

class DeviceColorSection extends StatelessWidget {
  const DeviceColorSection({
    super.key,
    required this.color,
    required this.enabled,
    required this.text,
    required this.onChanged,
  });

  final int? color;
  final bool enabled;
  final AppLocalizations text;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final labels = [
      text.copperColor,
      text.blueColor,
      text.lavenderColor,
      text.sageColor,
      text.sandColor,
      text.pinkColor,
      text.silverColor,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        DeviceFormSectionTitle(number: '03', title: text.colorSection),
        Text(
          text.colorDescription,
          style: const TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(text.noColor),
              selected: color == null,
              onSelected: enabled ? (_) => onChanged(null) : null,
            ),
            for (var i = 0; i < AppTheme.deviceColors.length; i++)
              DeviceFormColorOption(
                color: AppTheme.deviceColors[i],
                label: labels[i],
                selected:
                    color == (AppTheme.deviceColors[i].toARGB32() & 0xFFFFFF),
                onTap: enabled
                    ? () => onChanged(
                        AppTheme.deviceColors[i].toARGB32() & 0xFFFFFF,
                      )
                    : null,
              ),
            if (color != null &&
                !AppTheme.deviceColors.any(
                  (item) => (item.toARGB32() & 0xFFFFFF) == color,
                ))
              DeviceFormColorOption(
                color: Color(0xFF000000 | color!),
                label: text.currentColor,
                selected: true,
                onTap: null,
              ),
          ],
        ),
      ],
    );
  }
}
