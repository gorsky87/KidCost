# KidCost - przygotowanie release dla sklepów

Data: 2026-06-23

Ten dokument zbiera minimalne aktywa publikacyjne potrzebne do uruchomienia TestFlight i Google Play Internal Testing.

## Decyzja dla issue #35

Na obecnym etapie nie budujemy jeszcze osobnej aplikacji `apps/web`. Zrodlem tresci pozostaja pliki `docs/web/*.md`, a docelowe linki do store metadata sa gotowe do publikacji pod domena `kidcost.app`.

## Aktywy web i docelowe URL

| Aktyw | Docelowy URL do sklepu | Plik z trescia |
| --- | --- | --- |
| Privacy policy | `https://kidcost.app/privacy` | `docs/web/privacy-policy.md` |
| Support/contact | `https://kidcost.app/support` | `docs/web/support.md` |
| Terms of service | `https://kidcost.app/terms` | `docs/web/terms-of-service.md` |
| App description source | `https://kidcost.app/app` | `docs/web/app-description.md` |

## Copy-paste do store listingow

- Privacy policy URL: `https://kidcost.app/privacy`
- Support URL: `https://kidcost.app/support`
- Support e-mail: `support@kidcost.app`
- Privacy e-mail: `privacy@kidcost.app`
- Krótki opis aplikacji: `Wspolna historia kosztow dziecka, dowodow i rozliczen w jednym miejscu.`

## Minimalny zestaw treści wymaganych przez sklepy

1. Polityka prywatnosci i data policy:
   - Zakres danych: konto, rodzina, dzieci, wydatki, statusy, zalaczniki, analytics i crash reports.
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

## Publikacja tresci

Przed pierwszym wyslaniem do TestFlight i Google Play Internal Testing tresci z `docs/web/*.md` nalezy opublikowac pod wskazanymi URL albo skopiowac 1:1 do statycznych stron pod domena `kidcost.app`.

## Weryfikacja przed wysłaniem do sklepów

- [ ] pliki `docs/web/privacy-policy.md`, `docs/web/support.md`, `docs/web/terms-of-service.md`, `docs/web/app-description.md` istnieją i są kompletne
- [ ] linki w opisach metadanych wskazują docelowe URL `https://kidcost.app/privacy`, `https://kidcost.app/support`, `https://kidcost.app/terms`
- [ ] treść jasno wyjaśnia, że KidCost pomaga dokumentować koszty i statusy, ale nie udziela porad prawnych
- [ ] treść jasno wyjaśnia, kto widzi dane rodziny i jakie dane są zbierane
- [ ] treść nie obiecuje pełnego end-to-end encryption, jeżeli nie jest wdrożone
