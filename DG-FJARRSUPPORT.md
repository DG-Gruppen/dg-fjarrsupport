# DG Fjärrsupport

Det här är DG Gruppens version av [RustDesk](https://github.com/rustdesk/rustdesk). Den heter
DG Fjärrsupport och används när DG:s tekniker hjälper kunder via fjärrstyrning. Kunden laddar ner
`DG-Fjarrsupport.exe` från kundportalen (`https://helpdesk.dggruppen.se/portal/fjarrsupport`),
startar den och läser upp ID och lösenord för teknikern. Ingenting installeras.

Grenen `dg-fjarrsupport` utgår från RustDesk 1.5.0 (taggen `1.5.0`). Dokumentationen om
servern och helpdesken finns i helpdeskens repo under `docs/rustdesk/`.

## Ändringar mot RustDesk

| Fil | Ändring |
|---|---|
| `res/custom-client.json` | Inbyggd konfiguration: appnamn, server, relay, publik nyckel, API-server, bara inkommande anslutningar, ingen installation, inga inställningar, ingen adressbok eller inloggning, bara engångslösenord |
| `src/common.rs` | `load_builtin_custom_client()` läser konfigurationen ovan på samma sätt som RustDesk läser en signerad `custom.txt` |
| `flutter/assets/logo.png`, `logo_dark.png` | Loggan DG Fjärrsupport i appens fönster, för ljust och mörkt tema |
| `flutter/assets/icon.*`, `res/icon.ico`, `res/tray-icon.ico`, `flutter/windows/runner/resources/app_icon.ico` | DG-ikonen |
| `flutter/windows/runner/Runner.rc`, `libs/portable/Cargo.toml` | Namn och utgivare i Windows filinformation |
| `.github/workflows/dg-fjarrsupport.yml`, `res/dg-version` | Bygger `DG-Fjarrsupport.exe` för Windows x64 och publicerar den som release när versionen är ny |
| `.github/workflows/` | RustDesks egna byggen som startar automatiskt är borttagna i den här grenen |

Appnamnet är `DG-Fjarrsupport` utan mellanslag och å, ä, ö. RustDesk använder appnamnet i
filnamn, processnamn och mappar och kräver `[a-zA-Z0-9-]` vid installation. Kunden ser
namnet med ä i loggan och i filinformationen.

"Powered by RustDesk" visas i fönstret.

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
