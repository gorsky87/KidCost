# KidCost - kierunek marki MVP

## Kierunek

Wybrany kierunek: `Calm Ledger`.

KidCost ma wygladac jak spokojny, rodzinny rejestr faktow: jasny, nowoczesny,
wiarygodny przy kwotach, ale bez bankowego chlodu i bez prawniczego ciezaru.
Marka nie uzywa infantylnych ilustracji dzieci ani agresywnych komunikatow o
sporze.

## Logo

Koncepcja znaku: `K` zbudowane z dwoch uporzadkowanych kart/rejestru.

- Mala ikona: zaokraglony kwadrat z monogramem `K`, pionowym rytmem ledger i
  malym akcentem saldo.
- Wordmark: tekst `KidCost` z tym samym znakiem po lewej.
- Forma jest geometryczna, prosta i czytelna w rozmiarach nawigacji i ikony
  aplikacji.

Pliki robocze:

- `docs/brand/kidcost-mark.svg`
- `docs/brand/kidcost-wordmark.svg`

## Paleta

| Rola | Nazwa | HEX | Uzycie |
| --- | --- | --- | --- |
| Primary | Ledger Teal | `#0F766E` | glowne CTA, aktywna nawigacja, saldo neutralne |
| Secondary | Warm Copper | `#C76F3D` | rodzinny akcent, onboarding, elementy drugoplanowe |
| Tertiary | Document Blue | `#375E97` | raporty, eksporty, dokumenty |
| Success | Settled Green | `#2F855A` | zaakceptowane i rozliczone stany |
| Warning | Soft Amber | `#B7791F` | do akceptacji, uwaga bez alarmu |
| Danger | Calm Red | `#B42318` | blad, ryzyko, akcje destrukcyjne |
| Surface | Quiet Paper | `#FAFAF7` | tlo aplikacji |
| Surface variant | Ledger Line | `#E7ECE7` | obramowania, delikatne panele |
| Text | Ink Charcoal | `#172326` | podstawowy tekst |

Zastosowanie:

- CTA: `Ledger Teal`.
- Saldo: tekst kierunkowy w `Ink Charcoal`, ikona lub akcent w `Ledger Teal`.
- Status `Do akceptacji`: `Soft Amber`.
- Status `Wymaga wyjasnienia`: `Document Blue` albo indygo statusowe.
- Status `Rozliczone`: `Settled Green`.
- Bledy formularza: `Calm Red`.

## Typografia

MVP uzywa systemowej typografii Material 3 bez dodatkowej zaleznosci fontowej.

Hierarchia:

- Display: nazwa produktu i najwazniejsze naglowki.
- Title: karty salda, sekcje raportu, naglowki ustawien.
- Body: opisy, empty states i wyjasnienia.
- Label: przyciski, chipy statusow, filtry.

Zasady:

- Bez waskiego, technicznego kroju kojarzonego z bankowoscia.
- Bez ozdobnych fontow dzieciecych.
- Kwoty maja byc czytelne w standardowym kroju systemowym.

## Styl ikon

Ikony kategorii i statusow:

- outline, 24 px,
- zaokraglone koncowki,
- bez wypelnionych ilustracji,
- kategorie maja uzywac jednego koloru akcentu i tekstu, nie wielokolorowych
  obrazkow,
- status zawsze ma tekst + ikone + kolor, nigdy sam kolor.

## Mini brand board

```text
KidCost
Calm Ledger

[ K mark ]  KidCost

Primary       #0F766E  CTA, aktywna nawigacja
Secondary     #C76F3D  onboarding, cieply akcent
Tertiary      #375E97  raporty, eksporty
Success       #2F855A  rozliczone
Warning       #B7791F  do akceptacji
Danger        #B42318  blad
Surface       #FAFAF7  tlo
Text          #172326  tekst

Ton: spokojny, uporzadkowany, rodzinny, neutralny.
Nie: bank, kancelaria, dzieciece rysunki, konfliktowy jezyk.
```

## Implementacja Flutter

Tokeny MVP sa podlaczone w `apps/mobile/lib/src/theme/kidcost_theme.dart`.

Nastepne kroki:

1. Issue #26: przeniesc styl outline do ikon kategorii i statusow.
2. Issue #27: przygotowac finalna ikone aplikacji i splash screen na podstawie
   `kidcost-mark.svg`.
3. Issue #29: zamknac komponenty design systemu, uzywajac tej palety jako
   zrodla.
