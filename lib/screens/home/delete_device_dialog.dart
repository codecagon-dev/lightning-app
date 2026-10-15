import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/device.dart';

Future<bool?> confirmDeviceDeletion(BuildContext context, Device device) =>
    showDialog<bool>(
      context: context,
      builder: (context) {
        final text = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(text.deleteTitle),
          content: Text(text.deleteDescription(device.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(text.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                text.deleteAction,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
