import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

class DeviceFormField extends StatelessWidget {
  const DeviceFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.enabled,
    this.hint,
    this.helper,
    this.validator,
    this.keyboard,
    this.mono = false,
    this.digits = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? helper;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  final bool enabled;
  final bool mono;
  final bool digits;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: enabled,
      validator: validator,
      keyboardType: keyboard,
      textCapitalization: textCapitalization,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: digits ? [FilteringTextInputFormatter.digitsOnly] : null,
      style: mono
          ? const TextStyle(fontFamily: 'monospace', fontSize: 14)
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helper,
        helperMaxLines: 3,
      ),
    ),
  );
}

class DeviceFormSectionTitle extends StatelessWidget {
  const DeviceFormSectionTitle({
    super.key,
    required this.number,
    required this.title,
  });
  final String number;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: AppTheme.muted,
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(width: 16),
        const Expanded(child: Divider()),
      ],
    ),
  );
}

class DeviceFormColorOption extends StatelessWidget {
  const DeviceFormColorOption({
    super.key,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    selected: selected,
    button: true,
    child: Tooltip(
      message: label,
      child: SizedBox(
        width: 48,
        height: 48,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: color,
            side: BorderSide(
              color: selected ? AppTheme.ink : Colors.transparent,
              width: 2,
            ),
          ),
          child: selected
              ? const Icon(Icons.check, color: AppTheme.background, size: 22)
              : const SizedBox.shrink(),
        ),
      ),
    ),
  );
}
