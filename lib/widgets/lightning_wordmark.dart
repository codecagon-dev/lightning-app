import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Uses the wordmark font's lightning glyph for the first i.
class LightningWordmark extends StatelessWidget {
  const LightningWordmark({super.key});

  @override
  Widget build(BuildContext context) => Text.rich(
    const TextSpan(
      children: [
        TextSpan(text: 'L'),
        TextSpan(
          text: '\uE000',
          style: TextStyle(color: AppTheme.copper),
        ),
        TextSpan(text: 'ghtning'),
      ],
    ),
    semanticsLabel: 'Lightning',
    textDirection: TextDirection.ltr,
    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontFamily: 'LightningWordmark',
      fontSize: 30,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.35,
    ),
  );
}
