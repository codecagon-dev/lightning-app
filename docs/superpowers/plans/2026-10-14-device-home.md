# Lightning apparaatbeheer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Een donker grafiet homescreen met lege apparaatlijst, gevalideerde invoer en vervangbare API-opslag.

**Architecture:** Immutable JSON-modellen en een geïnjecteerde asynchrone repository ondersteunen de Flutter-schermen. De standaardrepository bewaart apparaten alleen tijdens de sessie. De hoofdagent bouwt de UI; een goedkopere agent implementeert de afgebakende datalaag.

**Tech Stack:** Bestaande Flutter, Dart en Material; geen nieuwe dependencies.

**Spec:** `docs/superpowers/specs/2026-10-14-device-home-design.md`

## Global Constraints

- Nederlandse interface; warm grafiet #18191B, oppervlakken #222326, tekst #ECE8E1, secundair #ABA7A0, gedempt koper #C49A80; geen lime accenten.
- Geen voorbeeldapparaten, fictieve online-status, WOL-uitvoering of SSH-verbindingen.
- SSH ondersteunt wachtwoord of private key; geen passphrase in deze versie.
- Geen credentials op schijf of in logs; geheugenopslag is tijdelijk.
- Geen tests toevoegen of uitvoeren tenzij de gebruiker daarom vraagt. Controle via formattering, statische analyse en code-inspectie.

## Review Focus

- Lange inhoud, smalle schermen en zichtbaar toetsenbord: het formulier blijft scrollbaar.
- Repositoryfouten bij laden, opslaan en verwijderen: gegevens blijven behouden en opnieuw proberen is mogelijk.
- Dubbele acties en verlaten schermen tijdens een request: geen dubbele mutaties of updates na dispose.
- Wisselen van SSH-authenticatie of uitschakelen van SSH: alleen de actieve configuratie wordt opgeslagen.
- Ongeldige adressen, subnetmaskers en poorten: veldfouten voorkomen opslaan.

## Task 1: Datamodel, repository en validatie

**Files:** Create `lib/models/device.dart`, `lib/services/device_repository.dart`, `lib/validation/device_validators.dart`.

**Interfaces:**
- `enum SshAuthType { password, privateKey }`.
- `SshConfig({required int port, required String username, required SshAuthType authType, String? password, String? privateKey})`, met `fromJson`/`toJson`.
- `Device({required String id, required String name, required String macAddress, required String ipAddress, required int wolPort, required String subnetMask, required int color, SshConfig? ssh})`, met `fromJson`/`toJson`.
- `DeviceRepository`: `Future<List<Device>> list()`, `Future<Device> create(Device device)`, `Future<Device> update(Device device)`, `Future<void> delete(String id)`.
- `MemoryDeviceRepository` begint leeg, kent bij create een unieke id toe, en meldt ontbrekende ids bij update/delete.
- `DeviceValidators`: static `String? name(String? value)`, `macAddress`, `ipAddress`, `port`, `subnetMask`, `requiredText`, `privateKey`; static `String normalizeMac(String value)`.
- JSON gebruikt id, name, macAddress, ipAddress, wolPort, subnetMask, color (hex #RRGGBB), ssh (null of object met port, username, authType en uitsluitend actief credential).

- [ ] Implementeer modellen en JSON-contract; bewaak geldige credential-combinaties en kleurwaarden.
- [ ] Implementeer lege geheugenrepository met stabiele ids en defensieve lijstkopieën.
- [ ] Implementeer de exacte validatieregels uit de spec, inclusief aaneengesloten subnetbits en matching private-key-markeringen.
- [ ] Inspecteer grenswaarden en inactieve SSH-credentials in de code; formatteer de bestanden.

## Task 2: Thema en apparaatformulier

**Files:** Modify `lib/theme/app_theme.dart`; create `lib/screens/device_form_screen.dart`.

**Interfaces:** `DeviceFormScreen({super.key, required DeviceRepository repository, Device? device})`; retourneert na succesvol opslaan een `Device` via Navigator.pop.

- [ ] Bouw het gedeelde donkere thema met duidelijke focus-, fout- en uitgeschakelde staten.
- [ ] Bouw een scrollbaar formulier met alle velden, kleurselectie, optionele SSH en authentieke technische labels.
- [ ] Gebruik validators uit taak 1; normaliseer MAC en trim uitsluitend tekstvelden waarvoor dat zinvol is. Bewaar credential-inhoud zonder onbedoelde wijzigingen.
- [ ] Valideer vóór create/update; blokkeer herhaalde submits, houd invoer bij fouten en controleer mounted na awaits.
- [ ] Inspecteer smalle layout, toetsenbordruimte, SSH-wisselingen en foutpaden; formatteer.

## Task 3: Homescreen, injectie en documentatie

**Files:** Modify `lib/screens/home_screen.dart`, `lib/app.dart`, `README.md`.

**Interfaces:** `LightningApp({super.key, DeviceRepository? repository})`; `HomeScreen({super.key, required DeviceRepository repository})`. De standaardrepository heeft een levensduur gelijk aan de appinstantie.

- [ ] Bouw home met titel, teller, plusknop, herladen, lege staat, laden en herhaalbare foutstaat.
- [ ] Bouw cards met naam, netwerkgegevens, kleurmarkering en SSH-configuratie; tik opent het formulier.
- [ ] Verwerk create/update-resultaten zonder extra request; verwijderen vraagt bevestiging en verwijdert uitsluitend na repositorysucces.
- [ ] Blokkeer conflicterende laad- en mutatieacties en bewaak mounted na async werk.
- [ ] Documenteer repository-injectie, JSON-contract, sessieopslag en API-verantwoordelijkheid voor credentials in README.
- [ ] Run formattering en `flutter analyze`; corrigeer gevonden fouten. Inspecteer de integratie tegen alle specvelden. Meld dat de bestaande placeholdertest verouderd is als deze niet is aangepast.

## Execution

De gebruiker heeft agentinzet gevraagd, met goedkopere agents voor eenvoudige onderdelen. Task 1 gaat naar de beschikbare goedkopere agent; de hoofdagent voert tasks 2 en 3 uit. Delegatie naar een duurder model is niet nodig. Er is geen Git-repository beschikbaar, dus er worden geen worktrees, commits of PRs gemaakt.

## Uitvoeringsresultaat

Tasks 1–3 zijn geïmplementeerd. De goedkopere agent bouwde de modellen, repository en validators en inspecteerde daarna de integratie. De hoofdagent bouwde thema, formulier en home, inspecteerde de datalaag en verbeterde MAC-trimmen, decimale poortvalidatie en private-key-markeringen/CRLF.

Ruling: kleur is intern 24-bit RGB, net als het JSON-contract; Flutter voegt expliciet een ondoorzichtige alpha toe bij weergave. Dit voorkomt twee opslagrepresentaties. Een API-adapter die ARGB aanlevert moet de alpha verwijderen.

Verificatie: directe Dart SDK formattering (8 bestanden) en `dart analyze` met resultaat `No issues found!`. De Flutter wrapper probeert een cache buiten de toegestane schrijfmap bij te werken; daarom is de aanwezige Dart SDK rechtstreeks gebruikt. Geen tests uitgevoerd. De bestaande placeholdertest is verouderd en blijft ongewijzigd; dit staat in README.
