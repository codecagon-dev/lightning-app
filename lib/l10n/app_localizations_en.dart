import 'app_localizations.dart';
import '../validation/device_validators.dart';
import '../models/device.dart';
import '../validation/auth_validators.dart';

class AppLocalizationsEn extends AppLocalizations {
  @override
  String get replaceSshCredentials => 'Replace SSH credentials';
  @override
  String get keepSshCredentials =>
      'Leave this off to keep the stored login details.';
  @override
  String get editDevice => 'Edit device';
  @override
  String sshStatus(SshStatus status) => switch (status) {
    SshStatus.unknown => 'SSH not checked',
    SshStatus.ready => 'SSH ready',
    SshStatus.authFailed => 'SSH login refused',
    SshStatus.hostKeyMismatch => 'SSH host key mismatch',
    SshStatus.unreachable => 'SSH unreachable',
    SshStatus.error => 'SSH check failed',
  };
  @override
  String get checkSsh => 'Check SSH';
  @override
  String get sshLastChecked => 'Last SSH check';
  @override
  String get sshCheckError => 'Could not check SSH. Please try again.';
  @override
  String get sshStatusDescription =>
      'SSH ready confirms a trusted host key and successful login; shutdown permissions are not checked.';
  const AppLocalizationsEn();

  @override
  String get authWorking => 'Signing in…';
  @override
  String get apiNotConfigured => 'The API address has not been configured.';
  @override
  String authValidationError(AuthValidationError error) => switch (error) {
    AuthValidationError.invalidEmail =>
      'Enter a valid email address (up to 254 characters).',
    AuthValidationError.invalidPassword =>
      'Use 12 to 128 characters for your password.',
  };
  @override
  String authError(int? statusCode) => switch (statusCode) {
    400 => 'Check your email address and password.',
    401 => 'Invalid email or password.',
    415 =>
      'The server could not process this request. Check the app configuration.',
    429 => 'Too many attempts. Wait a minute and try again.',
    null => 'Could not connect or sign in. Please try again.',
    >= 200 && < 300 => 'The server did not return a valid user session.',
    _ => 'The server could not complete your request. Try again later.',
  };

  @override
  String get loginTitle => 'Sign in';
  @override
  String get loginSubtitle =>
      'Wake up and shut down your computers, all in one place.';
  @override
  String get emailLabel => 'Email';
  @override
  String get osLabel => 'Operating system';
  @override
  String get broadcastAddressLabel => 'Broadcast address';
  @override
  String get fingerprintLabel => 'SSH host fingerprint';
  @override
  String get fingerprintHelper =>
      'Copy the SHA256 fingerprint from a trusted console on the target computer.';
  @override
  String get passphraseLabel => 'Private key passphrase (optional)';
  @override
  String get sshRequiredDescription =>
      'SSH settings are required to check reachability and shut down the computer.';
  @override
  String get noColor => 'No color';
  @override
  String get powerOn => 'Wake up';
  @override
  String get powerOff => 'Shut down';
  @override
  String get powerOnAccepted =>
      'Wake-on-LAN packet sent. Reachability will update separately.';
  @override
  String get powerOffAccepted =>
      'Shutdown command completed. Reachability will update separately.';
  @override
  String get powerError =>
      'The action failed. Check the computer, network and SSH settings.';
  @override
  String get shutdownTitle => 'Shut down computer?';
  @override
  String get detailsTitle => 'Computer details';
  @override
  String get close => 'Close';
  @override
  String get liveDisconnected => 'Live updates disconnected. Reconnecting…';
  @override
  String get statusDescription =>
      'Status indicates SSH port reachability, not a successful SSH login or full startup.';
  @override
  String get lastChecked => 'Last checked';
  @override
  String get neverChecked => 'Not checked yet';
  @override
  String deviceStatus(DeviceStatus status) => switch (status) {
    DeviceStatus.unknown => 'Unknown',
    DeviceStatus.online => 'Online',
    DeviceStatus.offline => 'Offline',
  };
  @override
  String shutdownDescription(String name) =>
      'Shut down “$name” via SSH? This stops the computer.';

  @override
  String get homeTitle => 'Your devices.';
  @override
  String get homeSubtitle => 'An overview. Everything within reach.';
  @override
  String get devicesLabel => 'DEVICES';
  @override
  String get reloadDevices => 'Reload devices';
  @override
  String get addDevice => 'Add device';
  @override
  String get loadError => 'Your devices could not be loaded.';
  @override
  String get deleteTitle => 'Delete device?';
  @override
  String get cancel => 'Cancel';
  @override
  String get deleteAction => 'Delete';
  @override
  String get deleteError => 'Could not delete the device. Try again.';
  @override
  String get retry => 'Try again';
  @override
  String get emptyTitle => 'Start with one.';
  @override
  String get emptyDescription =>
      'Add your first device. Give it a name, set up the network, and make the overview yours.';
  @override
  String get addFirstDevice => 'Add your first device';
  @override
  String get privateKeyLabel => 'Private key';
  @override
  String get passwordLabel => 'Password';
  @override
  String get logout => 'Log out';
  @override
  String get loggingOut => 'Logging out…';
  @override
  String get logoutError =>
      'You are logged out locally. Server sign-out could not be confirmed.';
  @override
  String get settingsTitle => 'Settings';
  @override
  String get languageTitle => 'Language';
  @override
  String get languageDescription => 'Choose the language used in Lightning.';
  @override
  String get systemLanguageLabel => 'System';
  @override
  String get settingsLoadError => 'Settings could not be loaded.';
  @override
  String get settingsSaveError =>
      'Your language preference could not be saved. Please try again.';
  @override
  String get settingsRetry => 'Reload';
  @override
  String get languageSaving => 'Saving language…';
  @override
  String deleteDescription(String name) =>
      '“$name” will be removed from your devices.';
  @override
  String deleteDeviceTooltip(String name) => 'Delete $name';
  @override
  String get addDeviceTitle => 'Add device';
  @override
  String get editDeviceTitle => 'Edit device';
  @override
  String get editIntro => 'Everything in its place.';
  @override
  String get addIntro => 'Make room for your device.';
  @override
  String get formSubtitle => 'Set up the network and access.';
  @override
  String get deviceSection => 'Device';
  @override
  String get networkSection => 'Network';
  @override
  String get colorSection => 'Color';
  @override
  String get sshSection => 'SSH';
  @override
  String get nameLabel => 'Name';
  @override
  String get nameHint => 'For example: Workstation';
  @override
  String get macAddressLabel => 'MAC address';
  @override
  String get ipAddressLabel => 'IP address';
  @override
  String get wolPortLabel => 'WOL port';
  @override
  String get wolPortHelper => 'UDP port for Wake-on-LAN, usually 9.';
  @override
  String get subnetMaskLabel => 'Subnet mask';
  @override
  String get colorDescription => 'A small marker to recognize your device.';
  @override
  String get sshEnabledLabel => 'Configure SSH';
  @override
  String get sshEnabledDescription => 'Remote access';
  @override
  String get sshPortLabel => 'SSH port';
  @override
  String get usernameLabel => 'Username';
  @override
  String get usernameHint => 'For example: jelte';
  @override
  String get authMethodLabel => 'Sign in with';
  @override
  String get privateKeyHint =>
      '-----BEGIN OPENSSH PRIVATE KEY-----\n…\n-----END OPENSSH PRIVATE KEY-----';
  @override
  String get privateKeyHelper =>
      'Paste the complete private key. For an encrypted key, enter its passphrase below.';
  @override
  String get showPassword => 'Show password';
  @override
  String get hidePassword => 'Hide password';
  @override
  String get saveDevice => 'Save device';
  @override
  String get saving => 'Saving…';
  @override
  String get formCancel => 'Cancel';
  @override
  String get formSaveError =>
      'Could not save. Your input is preserved. Please try again.';
  @override
  String get currentColor => 'Current color';
  @override
  String get copperColor => 'Copper';
  @override
  String get blueColor => 'Blue';
  @override
  String get lavenderColor => 'Lavender';
  @override
  String get sageColor => 'Sage';
  @override
  String get sandColor => 'Sand';
  @override
  String get pinkColor => 'Pink';
  @override
  String get silverColor => 'Silver';
  @override
  String get passwordAuthLabel => 'Password';
  @override
  String get privateKeyAuthLabel => 'Private key';

  @override
  String validationError(DeviceValidationError error) => switch (error) {
    DeviceValidationError.invalidFingerprint => 'Enter a canonical SHA256 fingerprint (43 base64 characters after SHA256:).',
    DeviceValidationError.textTooLong => 'Use no more than 128 characters.',
    DeviceValidationError.credentialsTooLarge =>
      'SSH credentials must fit within 32 KiB of encoded JSON.',
    DeviceValidationError.nameRequired => 'Enter a name.',
    DeviceValidationError.nameTooLong => 'Use no more than 100 characters.',
    DeviceValidationError.invalidMac => 'Enter a valid MAC address.',
    DeviceValidationError.invalidIp => 'Enter a valid IPv4 device address.',
    DeviceValidationError.invalidPort => 'Enter a port from 1 to 65535.',
    DeviceValidationError.invalidSubnet => 'Enter a valid subnet mask.',
    DeviceValidationError.nonContiguousSubnet =>
      'Use a contiguous subnet mask from /1 to /32.',
    DeviceValidationError.requiredText => 'This field is required.',
    DeviceValidationError.privateKeyRequired => 'Enter a private key.',
    DeviceValidationError.encryptedPrivateKey =>
      'For now, use a private key without a passphrase.',
    DeviceValidationError.invalidPrivateKey =>
      'Paste the complete private key with matching BEGIN and END markers.',
  };
}
