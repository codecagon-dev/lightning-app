import 'package:flutter/widgets.dart';

import '../validation/device_validators.dart';
import '../models/device.dart';
import '../validation/auth_validators.dart';
import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

abstract class AppLocalizations {
  const AppLocalizations();

  static const supportedLocales = [Locale('en'), Locale('nl')];
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static Locale resolve(Locale? locale) =>
      locale?.languageCode.toLowerCase() == 'nl'
      ? const Locale('nl')
      : const Locale('en');

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      (resolve(Localizations.localeOf(context)).languageCode == 'nl'
          ? const AppLocalizationsNl()
          : const AppLocalizationsEn());

  String sshStatus(SshStatus status);
  String get checkSsh;
  String get sshLastChecked;
  String get sshCheckError;
  String get sshStatusDescription;
  String get replaceSshCredentials;
  String get keepSshCredentials;
  String get editDevice;
  String get osLabel;
  String get broadcastAddressLabel;
  String get fingerprintLabel;
  String get fingerprintHelper;
  String get passphraseLabel;
  String get sshRequiredDescription;
  String get noColor;
  String get powerOn;
  String get powerOff;
  String get powerOnAccepted;
  String get powerOffAccepted;
  String get powerError;
  String get shutdownTitle;
  String get detailsTitle;
  String get close;
  String get liveDisconnected;
  String get statusDescription;
  String get lastChecked;
  String get neverChecked;
  String deviceStatus(DeviceStatus status);
  String shutdownDescription(String name);
  String get homeTitle;
  String get authWorking;
  String get apiNotConfigured;
  String authValidationError(AuthValidationError error);
  String authError(int? statusCode);
  String get loginTitle;
  String get loginSubtitle;
  String get emailLabel;
  String get homeSubtitle;
  String get devicesLabel;
  String get reloadDevices;
  String get addDevice;
  String get loadError;
  String get deleteTitle;
  String get cancel;
  String get deleteAction;
  String get deleteError;
  String get retry;
  String get emptyTitle;
  String get emptyDescription;
  String get addFirstDevice;
  String get privateKeyLabel;
  String get passwordLabel;
  String get settingsTitle;
  String get logout;
  String get loggingOut;
  String get logoutError;
  String get languageTitle;
  String get languageDescription;
  String get systemLanguageLabel;
  String get settingsLoadError;
  String get settingsSaveError;
  String get settingsRetry;
  String get languageSaving;
  String deleteDescription(String name);
  String deleteDeviceTooltip(String name);

  String get addDeviceTitle;
  String get editDeviceTitle;
  String get editIntro;
  String get addIntro;
  String get formSubtitle;
  String get deviceSection;
  String get networkSection;
  String get colorSection;
  String get sshSection;
  String get nameLabel;
  String get nameHint;
  String get macAddressLabel;
  String get ipAddressLabel;
  String get wolPortLabel;
  String get wolPortHelper;
  String get subnetMaskLabel;
  String get colorDescription;
  String get sshEnabledLabel;
  String get sshEnabledDescription;
  String get sshPortLabel;
  String get usernameLabel;
  String get usernameHint;
  String get authMethodLabel;
  String get privateKeyHint;
  String get privateKeyHelper;
  String get showPassword;
  String get hidePassword;
  String get saveDevice;
  String get saving;
  String get formCancel;
  String get formSaveError;
  String get currentColor;
  String get copperColor;
  String get blueColor;
  String get lavenderColor;
  String get sageColor;
  String get sandColor;
  String get pinkColor;
  String get silverColor;
  String get passwordAuthLabel;
  String get privateKeyAuthLabel;

  String validationError(DeviceValidationError error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'nl';

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      locale.languageCode == 'nl'
      ? const AppLocalizationsNl()
      : const AppLocalizationsEn();

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
