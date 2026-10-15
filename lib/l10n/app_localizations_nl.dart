import 'app_localizations.dart';
import '../validation/device_validators.dart';
import '../models/device.dart';
import '../validation/auth_validators.dart';

class AppLocalizationsNl extends AppLocalizations {
  @override
  String get replaceSshCredentials => 'SSH-inloggegevens vervangen';
  @override
  String get keepSshCredentials =>
      'Laat dit uit om de opgeslagen inloggegevens te behouden.';
  @override
  String get editDevice => 'Apparaat bewerken';
  @override
  String sshStatus(SshStatus status) => switch (status) {
    SshStatus.unknown => 'SSH nog niet gecontroleerd',
    SshStatus.ready => 'SSH gereed',
    SshStatus.authFailed => 'SSH-login geweigerd',
    SshStatus.hostKeyMismatch => 'SSH-hostkey wijkt af',
    SshStatus.unreachable => 'SSH onbereikbaar',
    SshStatus.error => 'SSH-controle mislukt',
  };
  @override
  String get checkSsh => 'SSH controleren';
  @override
  String get sshLastChecked => 'Laatste SSH-controle';
  @override
  String get sshCheckError =>
      'SSH controleren is niet gelukt. Probeer het opnieuw.';
  @override
  String get sshStatusDescription =>
      'SSH gereed bevestigt een vertrouwde hostkey en succesvolle login; afsluitrechten worden niet gecontroleerd.';
  const AppLocalizationsNl();

  @override
  String get authWorking => 'Aanmelden…';
  @override
  String get apiNotConfigured => 'Het API-adres is nog niet ingesteld.';
  @override
  String authValidationError(AuthValidationError error) => switch (error) {
    AuthValidationError.invalidEmail =>
      'Vul een geldig e-mailadres in (maximaal 254 tekens).',
    AuthValidationError.invalidPassword =>
      'Gebruik 12 tot en met 128 tekens voor je wachtwoord.',
  };
  @override
  String authError(int? statusCode) => switch (statusCode) {
    400 => 'Controleer je e-mailadres en wachtwoord.',
    401 => 'Ongeldig e-mailadres of wachtwoord.',
    409 => 'Dit e-mailadres is al geregistreerd.',
    415 => 'De server kan dit verzoek niet verwerken. Controleer de appconfiguratie.',
    429 => 'Te veel pogingen. Wacht een minuut en probeer het opnieuw.',
    null => 'Verbinden of aanmelden is niet gelukt. Probeer het opnieuw.',
    >= 200 && < 300 => 'De server gaf geen geldige gebruikerssessie terug.',
    _ => 'De server kan je verzoek niet afronden. Probeer het later opnieuw.',
  };

  @override
  String get loginTitle => 'Inloggen';
  @override
  String get loginSubtitle =>
      'Je computers wekken en afsluiten, allemaal op één plek.';
  @override
  String get emailLabel => 'E-mail';
  @override
  @override
  String get osLabel => 'Besturingssysteem';
  @override
  String get broadcastAddressLabel => 'Broadcastadres';
  @override
  String get fingerprintLabel => 'SSH-hostfingerprint';
  @override
  String get fingerprintHelper =>
      'Neem de SHA256-fingerprint over van een vertrouwde console op de doelcomputer.';
  @override
  String get passphraseLabel => 'Passphrase private key (optioneel)';
  @override
  String get sshRequiredDescription =>
      'SSH-instellingen zijn nodig om bereikbaarheid te controleren en de computer af te sluiten.';
  @override
  String get noColor => 'Geen kleur';
  @override
  String get powerOn => 'Aanzetten';
  @override
  String get powerOff => 'Afsluiten';
  @override
  String get powerOnAccepted =>
      'Wake-on-LAN-pakket verzonden. De bereikbaarheid wordt apart bijgewerkt.';
  @override
  String get powerOffAccepted =>
      'Afsluitopdracht uitgevoerd. De bereikbaarheid wordt apart bijgewerkt.';
  @override
  String get powerError =>
      'De actie is mislukt. Controleer de computer, het netwerk en de SSH-instellingen.';
  @override
  String get shutdownTitle => 'Computer afsluiten?';
  @override
  String get detailsTitle => 'Apparaatgegevens';
  @override
  String get close => 'Sluiten';
  @override
  String get liveDisconnected => 'Live updates verbroken. Opnieuw verbinden…';
  @override
  String get statusDescription =>
      'Status toont of de SSH-poort bereikbaar is, geen geslaagde SSH-login of volledige opstart.';
  @override
  String get lastChecked => 'Laatst gecontroleerd';
  @override
  String get neverChecked => 'Nog niet gecontroleerd';
  @override
  String deviceStatus(DeviceStatus status) => switch (status) {
    DeviceStatus.unknown => 'Onbekend',
    DeviceStatus.online => 'Online',
    DeviceStatus.offline => 'Offline',
  };
  @override
  String shutdownDescription(String name) =>
      '“$name” via SSH afsluiten? Hiermee wordt de computer uitgezet.';

  @override
  String get homeTitle => 'Je apparaten.';
  @override
  String get homeSubtitle => 'Een overzicht. Alles binnen bereik.';
  @override
  String get devicesLabel => 'APPARATEN';
  @override
  String get reloadDevices => 'Apparaten herladen';
  @override
  String get addDevice => 'Apparaat toevoegen';
  @override
  String get loadError => 'Je apparaten konden niet worden opgehaald.';
  @override
  String get deleteTitle => 'Apparaat verwijderen?';
  @override
  String get cancel => 'Annuleren';
  @override
  String get deleteAction => 'Verwijderen';
  @override
  String get deleteError => 'Verwijderen is niet gelukt. Probeer het opnieuw.';
  @override
  String get retry => 'Opnieuw proberen';
  @override
  String get emptyTitle => 'Het begint met één.';
  @override
  String get emptyDescription =>
      'Voeg je eerste apparaat toe. Geef het een naam, stel het netwerk in en maak het overzicht van jou.';
  @override
  String get addFirstDevice => 'Eerste apparaat toevoegen';
  @override
  String get privateKeyLabel => 'Private key';
  @override
  String get passwordLabel => 'Wachtwoord';
  @override
  String get logout => 'Uitloggen';
  @override
  String get loggingOut => 'Uitloggen…';
  @override
  String get logoutError =>
      'Je bent lokaal uitgelogd. Afmelden bij de server kon niet worden bevestigd.';
  @override
  String get settingsTitle => 'Instellingen';
  @override
  String get languageTitle => 'Taal';
  @override
  String get languageDescription => 'Kies de taal voor Lightning.';
  @override
  String get systemLanguageLabel => 'Systeem';
  @override
  String get settingsLoadError => 'Instellingen konden niet worden geladen.';
  @override
  String get settingsSaveError =>
      'Je taalkeuze kon niet worden opgeslagen. Probeer het opnieuw.';
  @override
  String get settingsRetry => 'Opnieuw laden';
  @override
  String get languageSaving => 'Taal opslaan…';
  @override
  String deleteDescription(String name) =>
      '“$name” wordt uit je apparaten verwijderd.';
  @override
  String deleteDeviceTooltip(String name) => '$name verwijderen';
  @override
  String get addDeviceTitle => 'Apparaat toevoegen';
  @override
  String get editDeviceTitle => 'Apparaat bewerken';
  @override
  String get editIntro => 'Alles op zijn plek.';
  @override
  String get addIntro => 'Een plek voor je apparaat.';
  @override
  String get formSubtitle => 'Stel het netwerk en de toegang in.';
  @override
  String get deviceSection => 'Apparaat';
  @override
  String get networkSection => 'Netwerk';
  @override
  String get colorSection => 'Kleur';
  @override
  String get sshSection => 'SSH';
  @override
  String get nameLabel => 'Naam';
  @override
  String get nameHint => 'Bijvoorbeeld: Werkstation';
  @override
  String get macAddressLabel => 'MAC-adres';
  @override
  String get ipAddressLabel => 'IP-adres';
  @override
  String get wolPortLabel => 'WOL-poort';
  @override
  String get wolPortHelper => 'UDP-poort voor Wake-on-LAN, meestal 9.';
  @override
  String get subnetMaskLabel => 'Subnetmasker';
  @override
  String get colorDescription =>
      'Een kleine markering om je apparaat te herkennen.';
  @override
  String get sshEnabledLabel => 'SSH configureren';
  @override
  String get sshEnabledDescription => 'Toegang op afstand';
  @override
  String get sshPortLabel => 'SSH-poort';
  @override
  String get usernameLabel => 'Gebruikersnaam';
  @override
  String get usernameHint => 'Bijvoorbeeld: jelte';
  @override
  String get authMethodLabel => 'Aanmelden met';
  @override
  String get privateKeyHint =>
      '-----BEGIN OPENSSH PRIVATE KEY-----\n…\n-----END OPENSSH PRIVATE KEY-----';
  @override
  String get privateKeyHelper =>
      'Plak de volledige private key. Vul bij een versleutelde key hieronder de passphrase in.';
  @override
  String get showPassword => 'Wachtwoord tonen';
  @override
  String get hidePassword => 'Wachtwoord verbergen';
  @override
  String get saveDevice => 'Apparaat opslaan';
  @override
  String get saving => 'Opslaan…';
  @override
  String get formCancel => 'Annuleren';
  @override
  String get formSaveError =>
      'Opslaan is niet gelukt. Je invoer is bewaard. Probeer het opnieuw.';
  @override
  String get currentColor => 'Huidige kleur';
  @override
  String get copperColor => 'Koper';
  @override
  String get blueColor => 'Blauw';
  @override
  String get lavenderColor => 'Lavendel';
  @override
  String get sageColor => 'Salie';
  @override
  String get sandColor => 'Zand';
  @override
  String get pinkColor => 'Roze';
  @override
  String get silverColor => 'Zilver';
  @override
  String get passwordAuthLabel => 'Wachtwoord';
  @override
  String get privateKeyAuthLabel => 'Private key';

  @override
  String validationError(DeviceValidationError error) => switch (error) {
    DeviceValidationError.invalidFingerprint =>
      'Vul een canonieke SHA256-fingerprint in (43 base64tekens na SHA256:).',
    DeviceValidationError.textTooLong => 'Gebruik maximaal 128 tekens.',
    DeviceValidationError.credentialsTooLarge =>
      'SSH-inloggegevens mogen samen maximaal 32 KiB gecodeerde JSON zijn.',
    DeviceValidationError.nameRequired => 'Vul een naam in.',
    DeviceValidationError.nameTooLong => 'Gebruik maximaal 100 tekens.',
    DeviceValidationError.invalidMac => 'Vul een geldig MAC-adres in.',
    DeviceValidationError.invalidIp => 'Vul een geldig IPv4-apparaatadres in.',
    DeviceValidationError.invalidPort =>
      'Vul een poortnummer van 1 t/m 65535 in.',
    DeviceValidationError.invalidSubnet => 'Vul een geldig subnetmasker in.',
    DeviceValidationError.nonContiguousSubnet =>
      'Gebruik een aaneengesloten subnetmasker van /1 t/m /32.',
    DeviceValidationError.requiredText => 'Dit veld is verplicht.',
    DeviceValidationError.privateKeyRequired => 'Vul een private key in.',
    DeviceValidationError.encryptedPrivateKey =>
      'Gebruik voor nu een private key zonder passphrase.',
    DeviceValidationError.invalidPrivateKey => 'Plak de volledige private key met bijbehorende BEGIN- en END-markeringen.',
  };
}
