# Lightning apparaatbeheer

## Doel en scope

Bouw de eerste apparaatbeheerflow in de bestaande Flutter-app: een donker grafiet homescreen met een aanvankelijk lege lijst, apparaatcards, toevoegen, bewerken en verwijderen. De gebruiker sluit later de echte API aan; de app levert daarvoor een vervangbare repository en JSON-modellen. SSH gebruikt een private key of een wachtwoord. Er wordt nog geen WOL-pakket verstuurd of SSH-verbinding gemaakt.

## Visueel ontwerp

Warm grafiet achtergrond (#18191B), iets lichtere oppervlakken (#222326), gebroken witte tekst (#ECE8E1) en gedempte secundaire tekst (#ABA7A0). Primaire knoppen zijn gebroken wit met donkere tekst. Gedempt koper (#C49A80) wordt spaarzaam gebruikt voor focus en selectie; er zijn geen lime accenten. Dunne lijnen, duidelijke typografische hiërarchie, compacte monospaced netwerklabels en een kleine gekleurde markering per apparaat geven het scherm het karakter van een apparatenconsole. Cards krijgen bescheiden hoekafronding (12 px) en geen zware schaduw. Geen gradients, glass-effecten of voorbeeldapparaten. Nederlandse interface.

Deze richting is een ontwerpkeuze op basis van actuele voorbeelden, geen claim dat er één universele trend is. Linear beschrijft in zijn refresh van maart 2026 een rustigere interface met nadruk op hiërarchie en consistentie (https://linear.app/now/behind-the-latest-design-refresh). Canva benoemt in zijn trendrapport voor 2026 meer eigenheid en expressief gebruik van alledaagse technische UI-elementen (https://www.canva.com/newsroom/news/design-trends-2026/). Lightning vertaalt dit naar een sobere console met karakter in typografie, ritme en details.

Het homescreen toont Lightning, een apparaatteller, een herlaadactie en een plusknop. De lege staat legt kort uit hoe je het eerste apparaat toevoegt. Cards tonen naam, IPv4, MAC en WOL/SSH-configuratie. Ze tonen geen verzonnen online-status. Tikken opent het bewerkformulier; een afzonderlijke verwijderactie vraagt bevestiging.

De layout past zich aan smalle en brede schermen aan, met begrensde inhoudsbreedte. Formulieren scrollen en houden rekening met toetsenbord en schermranden. Acties en kleurkeuzes hebben duidelijke labels en voldoende grote aanraakvlakken.

## Formulier

Een apart scherm voor toevoegen en bewerken, met secties Apparaat, Netwerk, Kleur en SSH. Velden: naam, MAC-adres, IPv4-adres, WOL-poort (standaard 9), subnetmasker (standaard 255.255.255.0), kleurkeuze. SSH is optioneel via een schakelaar. Bij inschakelen verschijnen SSH-poort (standaard 22), gebruikersnaam en een keuze tussen wachtwoord en private key. Alleen het gekozen credential wordt opgeslagen; het andere wordt verwijderd uit het model. Private key ondersteunt meerdere regels; wachtwoord is verborgen met een zichtbaarheidsschakelaar. De private key wordt als PEM/OpenSSH-inhoud ingevoerd; versleutelde keys met passphrase vallen buiten deze eerste versie.

Naam is verplicht na trimmen, maximaal 80 tekens. MAC accepteert zes hexadecimale bytes met dubbele punten of streepjes, of twaalf hexadecimale tekens; opslag normaliseert naar hoofdletters met dubbele punten. IPv4 bestaat uit vier decimale octetten van 0 tot 255; 0.0.0.0 en 255.255.255.255 zijn geen geldige apparaatadressen. Poorten zijn gehele getallen van 1 tot 65535. Subnetmasker gebruikt IPv4-notatie met aaneengesloten enen gevolgd door nullen; /1 tot /32 zijn toegestaan. SSH-gebruikersnaam en gekozen credential zijn verplicht wanneer SSH aan staat. Key-invoer krijgt een basale controle op herkenbare private-key BEGIN/END-markeringen; dit garandeert niet dat de sleutel cryptografisch geldig is.

## Model en API-grens

Een immutable Device bevat id, name, macAddress, ipAddress, wolPort, subnetMask, color en een optionele SshConfig. SshConfig bevat port, username, authType en alleen password of privateKey. Modellen bieden fromJson/toJson met gedocumenteerde veldnamen. Kleur is een hexwaarde in het JSON-contract.

DeviceRepository heeft Future<List<Device>> list(), Future<Device> create(Device device), Future<Device> update(Device device) en Future<void> delete(String id). Create levert het door de backend opgeslagen apparaat terug, inclusief id. De repository wordt geïnjecteerd via LightningApp naar HomeScreen; de gebruiker kan één implementatie vervangen om de API aan te sluiten.

De standaardimplementatie is een lege geheugenrepository. Toevoegingen blijven beschikbaar tijdens de appsessie en verdwijnen bij herstart. Dit gedrag staat in de README; de app beweert geen serveropslag. Er worden geen credentials gelogd of op schijf opgeslagen. De API-implementatie en beveiligde opslag worden later door de gebruiker geleverd.

## Gedrag bij asynchrone acties

Bij laden is een laadindicator zichtbaar; fouten tonen een bericht en een herhaalactie. Herladen vervangt de lijst door repositorydata. Tijdens opslaan en verwijderen zijn herhaalde acties geblokkeerd. Alleen na succesvolle repository-acties wordt het resultaat zichtbaar: opgeslagen apparaat keert terug naar home, verwijderde card verdwijnt. Fouten houden formuliergegevens of cards intact en laten opnieuw proberen toe. Na sluiten van een scherm mogen callbacks geen state op een disposed widget aanpassen.

## Implementatiegrenzen

Gebruik de aanwezige Flutter/Material-dependencies; geen extra packages of platformconfiguratie nodig. Verdeel model/repository, formulier en homescreen in afzonderlijke bestanden. Een goedkopere agent kan de modellen, repository en validators implementeren; de hoofdagent bewaakt de UI en integratie. Geen tests toevoegen of uitvoeren tenzij de gebruiker daarom vraagt; statische analyse en formattering kunnen de implementatie controleren.
