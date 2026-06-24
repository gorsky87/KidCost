# KidCost Beta Build 1

Data: 2026-06-24

## Konfiguracja

- Wersja Flutter: `1.0.0+2`
- Build name: `1.0.0`
- Build number / Android versionCode: `2`
- Release channel: `beta`
- Android application id: `pl.kidcost.app`
- iOS bundle id: `pl.kidcost.app`
- Analytics i crash reporting: wylaczone do czasu dodania projektu Firebase i plikow platformowych poza repo.

## Komendy

```sh
scripts/verify_beta_release_config.sh
scripts/build_beta_artifacts.sh --check-only
cd apps/mobile && flutter analyze && flutter test
```

Po dodaniu sekretow signing i kont sklepowych:

```sh
scripts/build_beta_artifacts.sh
```

## Status wysylki

- Android Internal Testing: zablokowane przez brak release keystore/signing config oraz brak potwierdzonego dostepu upload do Google Play Console.
- Apple TestFlight: zablokowane przez brak Apple distribution signing, `ExportOptions.plist` i potwierdzonego dostepu upload do App Store Connect.

Blokady sa operacyjne i nie wymagaja commitowania sekretow do repo. Skrypty release readiness maja zatrzymac wysylke dopoki signing/upload nie beda skonfigurowane lokalnie albo w CI secrets.
