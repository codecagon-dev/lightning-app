# Lightning

A computer management app built with Flutter.

## Project structure

```text
lib/
├── main.dart              # App entry point
├── app.dart               # MaterialApp and app configuration
├── theme/
│   └── app_theme.dart     # Shared colors and theme
├── screens/
│   ├── home_screen.dart   # Device list and actions
│   ├── home/              # Controller, header, cards, list and dialog
│   ├── device_form_screen.dart # Register devices
│   ├── device_form/       # Field state, network, SSH and color sections
│   └── settings_screen.dart # Language preferences
├── l10n/                  # English/Dutch translation catalogs
├── settings/              # Persisted language preference
├── models/
│   └── device.dart        # Device and SSH JSON models
├── validation/
│   └── device_validators.dart # Network and form validation
└── services/
    └── device_repository.dart # API interface and session storage
```

Keep screen-specific widgets close to their screen. Move widgets into
`widgets/` when multiple screens use them. Add models and services when
needed. Keep screen composition, input state and individual UI sections in
focused files. Localization and preferences use `flutter_localizations` and
`shared_preferences`.

## Development

```sh
flutter pub get
flutter run
```

## Checks

```sh
flutter analyze
flutter test
```

## Apparaatbeheer en de backend

De geconfigureerde app gebruikt `ApiDeviceRepository` met de ingelogde sessie.
`GET /computers` laadt de door de server opgeslagen computers. Met de plusknop
registreer je er één via `POST /computers`; herladen en opnieuw inloggen halen
dezelfde backendgegevens op. Alleen `MemoryDeviceRepository`, bedoeld voor
previews en tests, bewaart apparaten in het geheugen.

Het formulier vraagt naam, OS (Linux/Windows), IPv4, MAC-adres, broadcastadres,
WOL/SSH-poorten, SSH-gebruiker, de vertrouwd gecontroleerde SHA256-hostfingerprint
en precies één van SSH-wachtwoord of private key. Een key kan een passphrase
hebben. Kleur is optioneel; `Geen kleur` verstuurt `null`. Het broadcastadres
vervangt het oude subnetmaskerveld. Fingerprints worden canoniek gecontroleerd;
SSH-credentials mogen samen maximaal 32 KiB UTF-8 JSON zijn. Wachtwoorden en
passphrases worden niet getrimd. Key-inhoud wordt bij registratie niet
cryptografisch gevalideerd; de backend voert de SSH-authenticatie later uit.

`DeviceRegistration` bevat eenmalige invoer en maakt de strikt toegestane,
platte API-velden. `Device` bevat uitsluitend de publieke serverresponse:
geen wachtwoord, key, passphrase of SSH-authenticatiemethode. Deze geheimen
worden niet in de apparatenlijst of lokale opslag bewaard.

Een kaart opent een dialoog met de publieke details. Het potlood opent het
bewerkformulier en slaat wijzigingen op via `PATCH /computers/:id`.
De verwijderknop vraagt bevestiging en voert `DELETE /computers/:id` uit. Dit verwijdert alleen de registratie.

`Aanzetten` stuurt `POST /computers/:id/on`. Dit bevestigt verzending van het
WOL-pakket, niet dat de computer al gestart is. `Afsluiten` vraagt bevestiging
vóór `POST /computers/:id/off`; deze actie schakelt de fysieke computer uit.
Fouten behouden het apparaat en tonen een melding. Acties worden niet
automatisch opnieuw geprobeerd.

### Live status

`ComputerEvents` opent `/ws/computers` met dezelfde cookiejar als HTTP. HTTP/HTTPS
wordt WS/WSS, zonder token in de URL, queryparameters of Origin-header voor de
native client. De eigenaargebonden snapshots verversen de lijst; statusberichten
werken de bijbehorende kaart bij. Er staat expliciet `SSH bereikbaar`,
`SSH onbereikbaar` of `Onbekend`: dit bewijst geen succesvolle SSH-login of
volledige opstart.

Bij verbindingsverlies verschijnt een melding en volgt na drie seconden een
nieuwe verbinding met een vers snapshot. Uitloggen sluit de verbinding;
een HTTP 401 met de actuele sessie toont weer het loginformulier. Oudere
HTTP-responses overschrijven geen later ontvangen snapshots/status. Een
succesvol lokaal verwijderd ID wordt niet door een oud snapshot teruggezet.

### Repository gebruiken

`DeviceRepository` biedt `list`, `create(DeviceRegistration)`, `delete`,
`powerOn` en `powerOff`. `ApiDeviceRepository` implementeert deze routes;
`LiveDeviceRepository` levert daarnaast de updatesstream. Voor een eigen
implementatie of tests kun je een repository aan `LightningApp(repository: ...)`
meegeven. Een extern aangemaakte `ApiDeviceRepository` blijft eigendom van de
aanroeper; roep bij afsluiten `dispose()` aan om de live verbinding te sluiten.

## Talen en instellingen

Via het instellingenicoon op home kies je **Systeem**, **Nederlands** of
**English**. De keuze wordt lokaal opgeslagen met `shared_preferences` en blijft
na herstart behouden. Alleen deze taalvoorkeur wordt opgeslagen; apparaatdata
blijft afhankelijk van de geïnjecteerde repository.

De app volgt standaard de systeemtaal, met Engels als fallback voor andere
talen. Flutter-localisatie vertaalt ook de ingebouwde Material/Cupertino-acties.
Alle appteksten, inclusief foutmeldingen, toegankelijkheidslabels en validatie,
staan in `lib/l10n/`. Om een taal toe te voegen, voeg je een vertaalimplementatie
toe en werk je `supportedLocales`, `resolve`, de delegate en de taalkeuze in
instellingen bij. API-veldnamen en
gebruikersinvoer worden niet vertaald.

Na deze dependencywijziging: `flutter pub get` en de app opnieuw starten
(hot reload registreert nieuwe plugins niet).

## Telefoon en desktop

Home schakelt op basis van beschikbare breedte tussen één, twee en drie
cardkolommen; bij grotere tekst worden minder kolommen gebruikt. Cards hebben
variabele hoogte, zodat namen en labels kunnen doorlopen. Formulier en
instellingen blijven scrollbaar en hebben maximaal 680 px inhoudsbreedte.
Het Linux-venster is expliciet resizeable, met minimaal 320 × 360 px.

## API, inloggen en registreren

De login- en registreerknoppen gebruiken het ingevulde e-mailadres en wachtwoord.
`AuthService` verstuurt JSON naar `POST /auth/login` (HTTP 200) en
`POST /auth/register` (HTTP 201). Beide verwachten een gebruiker in de response
(`{"user":{"id":"…","email":"…"}}`) én een sessiecookie via `Set-Cookie`.
Registreren logt direct in. Bij succes opent het apparaatoverzicht.
Apparaatbeheer gebruikt dezelfde sessie voor `/computers` en `/ws/computers`.

Kopieer bij een nieuwe checkout `.env.example` naar `.env`. De app bundelt dit
bestand als asset en leest het bij het opstarten:

```dotenv
API_BASE_URL=http://localhost:3000
ANDROID_API_BASE_URL=http://10.0.2.2:3000
```

Linux gebruikt `API_BASE_URL`. Android gebruikt `ANDROID_API_BASE_URL` als die
is ingesteld, anders dezelfde basis-URL. `10.0.2.2` verwijst in de standaard
Android-emulator naar je ontwikkelcomputer. Voor een fysieke Android-telefoon
via USB kun je `adb reverse tcp:3000 tcp:3000` gebruiken en de Android-URL op
`http://localhost:3000` zetten. Het basispad is hier `/`, zonder `/api`-prefix.
Start de app opnieuw na wijzigingen aan `.env`. Dit bestand bevat publieke
appconfiguratie en wordt meegebundeld; zet er geen geheime sleutels in.

Android heeft internettoegang in de hoofdmanifest. HTTP is toegestaan voor
`localhost`, `127.0.0.1` en `10.0.2.2`; voor andere hosts gebruik je HTTPS.

Het formulier controleert e-mail en wachtwoord vóór een request. E-mail wordt
getrimd en naar kleine letters omgezet (maximaal 254 tekens). Wachtwoorden
blijven exact behouden, inclusief spaties, en moeten 12–128 tekens bevatten.
Beide knoppen zijn geblokkeerd tijdens een request. Fouten behouden de invoer
met een Nederlandse/Engelse melding, waaronder onjuiste login (401), bestaand
e-mailadres (409) en te veel pogingen (429). De server deelt een limiet van tien
login-/registreerpogingen per minuut per direct client-IP; requests worden niet
automatisch opnieuw geprobeerd. Achter een proxy kunnen gebruikers dezelfde
limiet delen. De wachtwoordmanager krijgt pas na bevestigde authenticatie een
verzoek om credentials op te slaan.

### Developmentlogs

`.env` bevat `API_DEBUG_LOGS=true`. Zet dit op `false` om de logs uit te zetten.
Logs verschijnen alleen in debugbuilds in de `flutter run`-terminal of IDE-console,
met prefix `[api]`. Release- en profilebuilds loggen ook met deze instelling niets.
Start de app opnieuw na een `.env`-wijziging.

De logs tonen request-id, methode, origin, de vaste auth-route, status, duur,
aantal Set-Cookie-headers, bruikbare cookies en de uitkomst van authenticatie.
Andere requestpaden worden als `[redacted]` getoond; cookiepaden alleen als
rootpad of beperkt pad.
Standaard worden request-/responsebodies, e-mailadressen, gebruikers-id's,
wachtwoorden, headerwaarden en cookiewaarden niet gelogd.

Met `API_DEBUG_SENSITIVE=true` in `.env` verschijnt daarnaast `response.sensitive`
met de volledige responsebody, responseheaders (inclusief Set-Cookie) en URL.
Dit staat lokaal aan; `.env.example` houdt het standaard uit. Requestbodies
met bijvoorbeeld het loginwachtwoord worden niet gelogd.
Ook deze modus wordt vóór het uitlezen van gevoelige gegevens met `kDebugMode`
afgeschermd: in release- en profilebuilds produceert hij geen logs, ongeacht
beide `.env`-instellingen.

Bij `The server did not return a valid user session` kun je bijvoorbeeld zien:

```text
[api] {"event":"response.received","requestId":1,"status":200,"elapsedMs":25,"setCookieCount":1,"bodyBytes":100}
[api] {"event":"cookie.rejected","reason":"secure_requires_https","scheme":"http","secure":true}
[api] {"event":"auth.rejected","reason":"missing_usable_cookie","expectedStatus":200,"status":200}
```

Dit voorbeeld betekent dat de server een Secure-cookie via HTTP aanbiedt.
Andere redenen zijn `unexpected_status`, `domain_mismatch`, verlopen/verwijderde
cookies, ongeldige cookie-attributen of ongeldige gebruikersdata. De controles
op cookies blijven actief; logging verandert de authenticatie niet.

### Gedeelde services en sessie

De app maakt één `ApiService`, `AuthService` en `UserSession` aan. Vanuit een
scherm heb je via de scope toegang tot dezelfde instanties:

```dart
import 'package:lightning/services/app_services_scope.dart';

final services = AppServicesScope.of(context);
final user = services.session.user;
final loggedIn = services.session.isAuthenticated;
final result = await services.api!.get('/computers');

await services.auth!.logout(); // Meldt af bij de server, wist de sessie en toont het loginformulier.
```

De sessie bewaart de gebruiker; `ApiService` bewaart en verstuurt de cookies.
Beide leven uitsluitend in het geheugen en verdwijnen bij afsluiten. Gebruik
`AuthService.login`/`register` om aan te melden; een token handmatig opslaan is
niet nodig. De uitlogknop in instellingen roept `POST /auth/logout` aan met de huidige
sessiecookie en wist daarna gebruiker en cookies. Bij een mislukte serveraanroep
logt de app lokaal alsnog uit en toont hij dat afmelden op de server niet kon
worden bevestigd. De knop is tijdens de aanroep geblokkeerd. Een rechtstreekse
`session.signOut()` wist alleen de lokale sessie.

Je kunt de services ook los gebruiken en in repositories injecteren:

```dart
import 'package:lightning/services/api_service.dart';
import 'package:lightning/services/auth_service.dart';

final api = ApiService(
  baseUrl: 'http://localhost:3000',
  headers: {'X-App': 'lightning'},
  timeout: const Duration(seconds: 30),
);
final auth = AuthService(api);
await auth.login(email: 'operator@example.com', password: 'voorbeeld-wachtwoord-123');
final user = api.session.user;

final result = await api.get('/computers');
// Registratie verloopt via ApiDeviceRepository.create(DeviceRegistration).
// De backend ondersteunt geen PUT/PATCH-updates van computers.
await auth.logout();
api.close();
```

### HTTP-gedrag

Endpointpaden blijven onder het ingestelde basispad, ook met een beginnende `/`.
Queryparameters en optionele `headers` kun je per aanroep meegeven; de service
beheert de `Cookie`-header zelf. Cookies worden per origin geïsoleerd en houden
rekening met domein, pad, Secure, vervaldatum en Max-Age. Nieuwe cookieheaders
vernieuwen de opgeslagen waarden. Er wordt uitsluitend `naam=waarde`
meegestuurd; de service volgt geen redirects. Cookies uit nog lopende requests
worden na uitloggen genegeerd.

Succesvolle antwoorden worden als JSON (`Object?`: map, lijst of scalar)
teruggegeven; een lege response, zoals HTTP 204, geeft `null`. Zet de JSON in je
repository om naar het gewenste model. Alleen 2xx-statuscodes gelden als succes.
Gebruik `api.request(method, path, ...)` als je ook de `statusCode` nodig hebt;
die geeft een `ApiResponse` met `statusCode` en `data`.
HTTP-fouten geven `ApiException` met `statusCode` en `data` (JSON of tekst).
Netwerkfouten en time-outs geven `ApiException` zonder statuscode; ongeldige JSON
in een succesvol antwoord geeft een exception met de ontvangen statuscode.
De timeout geldt voor headers én de volledige responsebody.

```dart
try {
  await api.get('/computers');
} on ApiException catch (error) {
  if (error.statusCode == 401) api.session.signOut();
  // Toon een passende melding; log geen cookies of ruwe serverdata.
}
```

Een optioneel geïnjecteerde `http.Client` blijft eigendom van de aanroeper;
`close()` sluit alleen een client die de service zelf heeft gemaakt. Hetzelfde
geldt voor een geïnjecteerde `UserSession`. Tests kunnen via
`LightningApp(api: api)` een service met gecontroleerde HTTP-responses injecteren.

SSH-diagnose wordt apart van TCP-bereikbaarheid weergegeven, inclusief de laatste
SSH-controletijd. **SSH controleren** roept `POST /computers/:id/check-ssh` zonder
body aan; het resultaat en WebSocket-updates werken de kaart bij. Een geweigerde
login of afwijkende hostkey is een diagnoseresultaat. `ready` bevestigt een
vertrouwde hostkey en succesvolle login, maar geen afsluitrechten.

Apparaten bewerken kan via het potlood op de kaart. Het formulier stuurt alleen
gewijzigde velden met `PATCH /computers/:id` en verwacht `200 {"computer": ...}`.
**Geen kleur** verstuurt `color: null`. SSH-inloggegevens blijven behouden tenzij
**SSH-inloggegevens vervangen** aanstaat en nieuwe gegevens worden ingevuld.
