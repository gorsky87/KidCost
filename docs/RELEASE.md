# KidCost - przygotowanie release dla sklepów

Data: 2026-06-23

Ten dokument zbiera minimalne aktywa publikacyjne potrzebne do uruchomienia TestFlight i Google Play Internal Testing.

## Aktywy web (wersja testowa)

- Privacy policy URL: `docs/web/privacy-policy.md`
- Support/contact URL: `docs/web/support.md`
- Terms of service URL: `docs/web/terms-of-service.md`
- Krótki opis aplikacji: `docs/web/app-description.md`

## Minimalny zestaw treści wymaganych przez sklepy

1. Polityka prywatnosci i data policy:
   - Zakres danych: konto, rodzina, dzieci, wydatki, statusy, załączniki, telemetry.
   - Przejrzysty opis widoczności danych.
   - Wersja bez obietnic szyfrowania end-to-end i bez porady prawnej.
2. Strona support/contact:
   - Kontakt e-mailowy.
   - Krótkie FAQ (co to jest i jak uzyskać pomoc).
   - Czas reakcji supportu.
3. Opis aplikacji:
   - 1 akapit celu produktu.
   - 6-8 punktów korzyści.
   - Krótki fragment do store listingów.

## Weryfikacja przed wysłaniem do sklepów

- [ ] pliki `docs/web/privacy-policy.md`, `docs/web/support.md`, `docs/web/terms-of-service.md`, `docs/web/app-description.md` istnieją i są kompletne
- [ ] linki w opisach metadanych wskazują poprawne lokalizacje
- [ ] treść jasno wyjaśnia, że KidCost pomaga dokumentować koszty i statusy, ale nie udziela porad prawnych
- [ ] treść jasno wyjaśnia, kto widzi dane rodziny i jakie dane są zbierane
- [ ] treść nie obiecuje pełnego end-to-end encryption, jeżeli nie jest wdrożone
