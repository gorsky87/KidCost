# KidCost UX - onboarding bezpieczenstwa i zaufania

## Cel

KidCost ma budowac zaufanie bez ciezkiego tonu prawnego. Uzytkownik powinien
wiedziec, kto widzi dane rodziny, ze koszty maja historie zmian, gdzie znajdzie
privacy/terms/support oraz ze aplikacja porzadkuje fakty, ale nie daje porad
prawnych.

## Zasady

- Nie dodajemy osobnego, blokujacego kroku przed pierwszym kosztem.
- Komunikaty zaufania pojawiaja sie w ostatnim kroku onboardingu, gdy uzytkownik
  decyduje o zaproszeniu drugiego rodzica.
- Ustawienia sa miejscem na pelniejsze linki i akcje: eksport danych, privacy,
  terms, support.
- Nie obiecujemy porad prawnych, wyniku mediacji ani pelnego szyfrowania E2E,
  jezeli nie jest formalnie wdrozone.

## Onboarding

Miejsce: krok `Zapros rodzica`.

Gotowe teksty:

| Element | Tekst |
| --- | --- |
| Tytul sekcji | `Prywatnosc i zaufanie` |
| Kto widzi dane | `Dane rodziny widza tylko osoby z aktywnym dostepem do tej rodziny.` |
| Historia zmian | `Koszty i statusy beda mialy historie, zeby bylo widac kto i kiedy zmienil wpis.` |
| Zakres aplikacji | `KidCost pomaga dokumentowac koszty, ale nie zastepuje porady prawnej.` |
| Zaproszenie | `Kod nie ujawnia kosztow ani danych dziecka.` |

Low-fi:

```text
Zapros rodzica
Zaproszenie nie pokazuje danych rodzinnych przed akceptacja.

[ Email drugiego rodzica ]
[ Wygeneruj kod ]

Prywatnosc i zaufanie
Prywatnosc danych rodzinnych
Dane rodziny widza tylko osoby z aktywnym dostepem do tej rodziny.

Historia zmian
Koszty i statusy beda mialy historie...

Porzadkujemy fakty
KidCost pomaga dokumentowac koszty, ale nie zastepuje porady prawnej.

[ Zakoncz ]
[ Pomin zaproszenie ]
```

## Ustawienia

Sekcja ustawien ma byc konkretna, bez marketingowego tonu.

Gotowe pozycje:

| Pozycja | Tekst |
| --- | --- |
| Prywatnosc danych rodzinnych | `Dane rodziny widza tylko osoby z aktywnym dostepem do tej rodziny.` |
| Historia zmian | `Koszty i statusy beda zapisywac kto i kiedy zmienil wpis.` |
| Eksport danych | `Przygotujemy plik z kosztami, statusami i historia rodziny.` |
| Polityka prywatnosci | `https://kidcost.app/privacy` |
| Regulamin | `https://kidcost.app/terms` |
| Kontakt support | `support@kidcost.app` |
| Brak porad prawnych | `KidCost pomaga porzadkowac fakty i dokumenty, ale nie zastepuje porady prawnej.` |

## Kto widzi dane rodziny

Tekst bazowy:

`Dane rodziny widza tylko osoby z aktywnym dostepem do tej rodziny. Zespol KidCost moze miec ograniczony dostep techniczny tylko wtedy, gdy jest to potrzebne do wsparcia, bezpieczenstwa albo rozwiazania zgloszonego problemu.`

Krotka wersja do UI:

`Dane rodziny widza tylko osoby z aktywnym dostepem do tej rodziny.`

## Eksport danych

MVP copy:

`Przygotujemy plik z kosztami, statusami i historia rodziny. Eksport nie zmienia salda ani statusow.`

Pozniej eksport powinien obejmowac:

- koszty,
- statusy,
- historie statusow,
- miesiac i zakres dat,
- informacje o zalacznikach,
- disclaimer: brak porad prawnych.

## Support

CTA:

`Kontakt support`

Pomocniczy tekst:

`Napisz na support@kidcost.app. Nie wysylaj pelnych danych dziecka, pelnych kwot ani calych paragonow, jezeli nie sa potrzebne do pokazania problemu.`

## Decyzje

- Zaufanie pojawia sie w onboardingu jako krotka sekcja, nie jako dodatkowy
  formularz.
- Privacy, terms i support maja stale docelowe URL zgodne z `docs/web`.
- Eksport danych jest widoczny jako intencja w ustawieniach, ale implementacja
  pliku pozostaje poza zakresem tego issue.
- Aplikacja mowi o dokumentowaniu faktow, nie o poradach prawnych.
