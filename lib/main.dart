import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnv(
    await rootBundle.loadString('.env'),
    android: Platform.isAndroid,
  );
  runApp(
    LightningApp(
      apiBaseUrl: config.apiBaseUrl,
      apiDebugLogs: config.apiDebugLogs,
      apiDebugSensitive: config.apiDebugSensitive,
    ),
  );
}
