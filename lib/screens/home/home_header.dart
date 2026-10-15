import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'device_list_heading.dart';
import 'home_toolbar.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.count,
    required this.loadFailed,
    required this.onSettings,
    required this.onReload,
    required this.onAdd,
  });
  final int count;
  final bool loadFailed;
  final VoidCallback onSettings;
  final VoidCallback? onReload;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomeToolbar(onSettings: onSettings, onReload: onReload),
            const SizedBox(height: 36),
            Text(
              text.homeTitle,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              text.homeSubtitle,
              style: const TextStyle(color: AppTheme.muted, fontSize: 15),
            ),
            const SizedBox(height: 32),
            DeviceListHeading(count: count, onAdd: onAdd),
            const SizedBox(height: 16),
            const Divider(height: 1),
            if (loadFailed)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          text.loadError,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: onReload,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: Text(text.retry),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
