# DG Fjärrsupport

Det här är DG Gruppens version av [RustDesk](https://github.com/rustdesk/rustdesk). Den heter
DG Fjärrsupport och används när DG:s tekniker hjälper kunder via fjärrstyrning. Den byggs i tre
varianter:

| Variant | Fil | Vem | Beskrivning |
|---|---|---|---|
| Kundklient | `DG-Fjarrsupport.exe` | Kunden | Laddas ner från kundportalen (`https://helpdesk.dggruppen.se/portal/fjarrsupport`). Kunden startar den och läser upp ID och lösenord för teknikern. Ingenting installeras |
| Server | `DG-Fjarrsupport-Server.exe` | Servrar och värdade datorer | Obevakad åtkomst. Installeras som tjänst och tar emot anslutningar med ett fast lösenord, utan att någon behöver godkänna. Registrerar sig i helpdesken som server och syns för alla inloggade tekniker i adressboken "Servrar". Bara Windows |
| Teknikerklient | `DG-Fjarrsupport-Tekniker.exe` | DG:s tekniker | Installeras med knappen i appen. Teknikern loggar in med sitt helpdeskkonto och kan inte ansluta utan att vara inloggad. Knappen Fjärrstyr i helpdesken öppnar den via URL-schemat `dg-fjarrsupport-tekniker://` |

Grenen `dg-fjarrsupport` utgår från RustDesk 1.5.0 (taggen `1.5.0`). Dokumentationen om
servern och helpdesken finns i helpdeskens repo under `docs/rustdesk/`.

## Ändringar mot RustDesk

| Fil | Ändring |
|---|---|
| `res/custom-client.json` | Kundklientens inbyggda konfiguration: appnamn, server, relay, publik nyckel, API-server, bara inkommande anslutningar, ingen installation, inga inställningar, ingen adressbok eller inloggning, bara engångslösenord, ingen "Powered by RustDesk" |
| `res/custom-client-tekniker.json` | Teknikerklientens konfiguration: appnamnet `DG-Fjarrsupport-Tekniker`, samma server, nyckel och API-server, bara utgående anslutningar, dolda serverinställningar och `dg-require-login`. Bygget kopierar den över `res/custom-client.json` |
| `res/custom-client-server.json` | Serverversionens konfiguration: appnamnet `DG-Fjarrsupport-Server`, bara inkommande anslutningar, bara fast lösenord utan godkännande, låsta inställningar (men lösenord via kommandoraden), fast ID och enhetsgruppen `Servrar`, som helpdesken känner igen |
| `src/common.rs` | `load_builtin_custom_client()` läser konfigurationen ovan på samma sätt som RustDesk läser en signerad `custom.txt` |
| `src/common.rs`, `src/ui_session_interface.rs` | `rendezvous_token()`: från `v1.5.0-dg4` skickas teknikerns inloggningstoken inte till ID-servern. Den officiella hbbs saknar nyckelutbytet som en token får klienten att vänta på, så en inloggad tekniker fick "Failed to secure tcp: deadline has elapsed" vid varje anslutning. hbbs läser aldrig token; API-servern får den som förut |
| `src/common.rs`, `src/hbbs_http/sync.rs` | `dg_version()`: sysinfo skickar också `dg-version` (till exempel `1.5.0-dg4`) från `res/dg-version`, så att helpdesken ser vilken DG-version datorn kör. `version` är fortfarande RustDesks version, som datorerna jämför sinsemellan |
| `src/hbbs_http/sync.rs` | Från `1.5.0-dg5`: heartbeat skickar `dg-password` (om datorn har ett fast lösenord), och på svaret `dg-password: true` hämtar `fetch_dg_password` serverns lösenord från helpdesken (`POST /api/dg/server-password` med `id` och `uuid`) och sätter det i tjänsten. Se Serverversionen nedan |
| `flutter/lib/common/widgets/dg_login_gate.dart`, `flutter/lib/utils/multi_window_manager.dart` | När `dg-require-login` är satt öppnar varje ny anslutning (från appen eller via URL-schemat) först inloggningen, och anslutningen avbryts om teknikern inte loggar in |
| `flutter/assets/logo.png`, `logo_dark.png` | Loggan DG Fjärrsupport i appens fönster, för ljust och mörkt tema |
| `flutter/assets/icon.*`, `res/icon.ico`, `res/tray-icon.ico`, `flutter/windows/runner/resources/app_icon.ico` | DG-ikonen |
| `flutter/windows/runner/Runner.rc`, `libs/portable/Cargo.toml` | Namn och utgivare i Windows filinformation |
| `flutter/macos/Runner/AppIcon.icns` | DG-ikonen för Mac |
| `.github/workflows/dg-fjarrsupport.yml`, `res/dg-version` | Bygger båda varianterna. Windows x64 blir `DG-Fjarrsupport.exe` och `DG-Fjarrsupport-Tekniker.exe`, som publiceras som release när versionen är ny. Mac blir dmg-filer för Apple Silicon och Intel, osignerade (ad hoc), som också ingår i releasen från `v1.5.0-dg3`. Releasen kräver bara Windows-bygget. Saknas en Mac-fil, till exempel för att GitHub inte hade någon ledig Apple Silicon-maskin, tas den från förra releasen. Mac-appen får eget bundle-id och URL-schema per variant |
| `.github/workflows/` | RustDesks egna byggen som startar automatiskt är borttagna i den här grenen |

Appnamnen är `DG-Fjarrsupport` och `DG-Fjarrsupport-Tekniker` utan mellanslag och å, ä, ö. RustDesk använder appnamnet i
filnamn, processnamn, mappar och URL-schemat och kräver `[a-zA-Z0-9-]` vid installation.
Namnet med ä syns i loggan och i filinformationen.

"Powered by RustDesk" visas i fönstret i `v1.5.0-dg1` och i den första Mac-testversionen. Från
`v1.5.0-dg2` döljs den med `hide-powered-by-me` under `override-settings`. Inställningen måste
ligga där och inte på översta nivån, eftersom fönstret läser den bland de inbyggda
inställningarna.

## Serverversionen

Installera som administratör:

```
DG-Fjarrsupport-Server.exe --silent-install
"C:\Program Files\DG-Fjarrsupport-Server\DG-Fjarrsupport-Server.exe" --get-id
```

Servern dyker upp i helpdesken. När en administratör kopplar den till en organisation skapar
helpdesken ett fast lösenord, sparar det bland organisationens hemliga uppgifter och skickar
det till de inloggade teknikernas adressbok "Servrar". Servern hämtar lösenordet själv (från
`1.5.0-dg5`): heartbeat skickar `dg-password` (om ett fast lösenord finns), helpdesken svarar
`dg-password: true` när servern ska hämta, och servern anropar `POST /api/dg/server-password`
med `id` och `uuid` och sätter lösenordet i tjänsten (`fetch_dg_password` i
`src/hbbs_http/sync.rs`). Samma sak händer när lösenordet byts i helpdesken och när en
ominstallerad server saknar lösenord. Helpdesken lämnar bara ut lösenordet till en kopplad
server med den uuid som registrerades i sysinfo. Teknikern ansluter via adressboken utan att se
det. Lösenordet byggs aldrig in i programmet, eftersom det här repot är publikt, och utan
lösenord kan ingen ansluta.

Lösenordet kan fortfarande sättas för hand, till exempel på en äldre version:

```
"C:\Program Files\DG-Fjarrsupport-Server\DG-Fjarrsupport-Server.exe" --password <lösenord>
```

## Bygga

Flödet **DG Fjärrsupport** under Actions bygger vid varje push till grenen och kan också köras
med Run workflow. Resultatet blir en artefakt. Versionen står i `res/dg-version`, till exempel
`1.5.0-dg1`. Finns ingen release med taggen `v1.5.0-dg1` än publiceras bygget som en release med
filen `DG-Fjarrsupport.exe`. Höj alltså versionen när en ny version ska ut till kunderna.
Den senaste releasen kan alltid laddas ner från:

```
https://github.com/DG-Gruppen/dg-fjarrsupport/releases/latest/download/DG-Fjarrsupport.exe
```

Bygget tar ungefär en timme första gången och går fortare när cachen finns.

Filen är inte signerad ännu. Windows visar då "Windows skyddade datorn", och kunden får klicka
på Mer information → Kör ändå. Signeringen läggs till i flödet när certifikatet finns.

## Ny version av RustDesk

1. Hämta taggen från RustDesk: `git fetch https://github.com/rustdesk/rustdesk tag <version>`.
2. Slå ihop den med grenen `dg-fjarrsupport` och lös eventuella konflikter. Ändringarna ovan
   är gjorda för att ge så få konflikter som möjligt.
3. Jämför `.github/workflows/flutter-build.yml` (jobbet `build-for-windows-flutter`) med
   `dg-fjarrsupport.yml` och för över ändrade versioner av Flutter, Rust och vcpkg.
4. Prova API-protokollet mot helpdesken innan releasen går ut.

## Licens

RustDesk är licensierat under AGPL-3.0, och det gäller även den här versionen. Källkoden till
varje release finns i den tagg som releasen pekar på.
