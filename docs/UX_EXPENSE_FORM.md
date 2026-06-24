# KidCost UX - formularz kosztu i szybkie kategorie

## Cel

Rodzic ma dodac koszt w mniej niz minute. Formularz zaczyna sie od informacji,
ktore uzytkownik ma w glowie albo na paragonie: kwota, data, kategoria i dowod.

## Kolejnosc pol

1. `Kwota` - wymagane, pierwsze pole, klawiatura numeryczna z przecinkiem/kropka.
2. `Data kosztu` - wymagana, domyslnie dzisiejsza data w formacie `RRRR-MM-DD`.
3. `Dziecko` - widoczne jako pole kontekstowe; przy jednym dziecku bez decyzji.
4. `Kategoria` - szybkie chipy z ikonami; `Inne` zawsze na koncu.
5. `Kto zaplacil` - jedyna nieoczywista decyzja w formularzu.
6. `Opis lub nazwa kosztu` - opcjonalne.
7. `Paragon/faktura` - opcjonalne, nie blokuje zapisu kosztu.
8. `Zapisz koszt` - primary CTA.

## Warianty dziecka

| Wariant | Zachowanie |
| --- | --- |
| Bez dziecka | Pokazac stan `Dodaj dziecko w rodzinie, aby przypisac koszt.` i zablokowac zapis kosztu rodzinnego. |
| Jedno dziecko | Pokazac imie dziecka jako nieinteraktywne pole kontekstowe. |
| Wiele dzieci | Zamienic pole na wybor dziecka; domyslnie ostatnio wybrane dziecko. |

Obecny MVP ma jedno dziecko z onboardingu, wiec formularz pokazuje je bez
dodatkowej decyzji.

## Szybkie kategorie

Kategorie dzialaja bez OCR, dlatego nazwy musza byc zrozumiale po samym
przeczytaniu. Kolejnosc:

1. Jedzenie
2. Ubrania
3. Szkola/przedszkole
4. Lekarze i leki
5. Zajecia dodatkowe
6. Wakacje
7. Transport
8. Inne

`Inne` jest ostatnie, bo ma byc bezpiecznym wyjsciem, a nie domyslna sciezka.

## Zalacznik

CTA: `Dodaj paragon lub PDF`

Opcje w MVP:

- `Aparat` - zrob zdjecie paragonu.
- `Galeria` - wybierz zdjecie z telefonu.
- `PDF` - dodaj fakture lub rachunek.
- `Zapisz bez paragonu` - swiadomie kontynuuj bez dowodu.

Zalacznik jest opcjonalny. Blad uploadu nie blokuje kosztu; koszt zostaje
zapisany ze statusem zalacznika wymagajacym ponowienia.

### Receipt review tray

Po wybraniu pliku formularz pokazuje inline tray zamiast samej nazwy pliku.
Tray ma byc gotowy do implementacji Flutter bez dodatkowych decyzji UI:

- miniatura 72x72 z ikona obrazu albo PDF,
- nazwa pliku, typ MIME i rozmiar,
- status: `Gotowy do wyslania`, `Wysylanie`, `Upload zakonczony`,
  `Upload nieudany`, `Plik za duzy`, `Nieobslugiwany format`,
- neutralna wskazowka jakosci: `Sprawdz, czy widac caly paragon, czytelna kwote i date.`,
- akcje: `Podejrzyj`, `Zamien`, `Usun`, `Dodaj kolejny`, `Zapisz bez paragonu`.

MVP mobilny zapisuje jeden zalacznik do kosztu. Akcja `Dodaj kolejny` pozostaje
widoczna jako docelowy wzorzec UX, ale komunikuje, ze w tej wersji nalezy wybrac
jeden najlepiej czytelny dowod.

Teksty nie sugeruja winy drugiego rodzica. Mowimy o czytelnosci dowodu,
ponowieniu uploadu i zapisie kosztu, nie o `udowodnieniu` albo `oskarzeniu`.

## Walidacje

| Pole | Regula | Komunikat |
| --- | --- | --- |
| Kwota | wymagane, wieksze od 0, maks. 2 miejsca po przecinku | `Podaj kwote wieksza od 0.` |
| Data kosztu | wymagana, format `RRRR-MM-DD` | `Podaj date kosztu.` |
| Kto zaplacil | wymagane | `Wybierz kto zaplacil.` |
| Opis | opcjonalny | brak bledu |
| Zalacznik | opcjonalny, JPG/PNG/PDF, docelowo limit 8 MB | tray pokazuje status; snackbar po zapisie, jesli upload sie nie udal |

## Stany

### Empty

- Kwota pusta.
- Data ustawiona na dzisiaj.
- Dziecko wypelnione z onboardingu.
- Kategoria domyslnie `Jedzenie`.
- Placacy domyslnie aktualny uzytkownik.
- Opis pusty.
- Zalacznik pusty.

### Loading

- `Zapisz koszt` pokazuje loader.
- Pola wyboru i zalacznik sa zablokowane.
- Tray pokazuje status `Wysylanie`, jesli wybrano zalacznik.

### Error

- Bledy sa przy polach, nie w globalnym alertcie.
- Kwota i data maja najkrotsze mozliwe komunikaty.

### Upload error

- Koszt zostaje zapisany.
- Uzytkownik widzi snackbar: `Koszt zapisany, ale zalacznik wymaga ponowienia.`
- Formularz pokazuje informacyjny stan po zapisie, a lista i szczegoly pokazuja
  blad uploadu zalacznika.

### Success

- Snackbar: `Koszt zapisany.`
- Formularz czysci kwote, opis i zalacznik.
- Data wraca do dzisiejszej.
- Kategoria wraca do `Jedzenie`.
- Szczegoly kosztu pokazuja `Upload zakonczony`, sciezke lub neutralny opis
  zapisanego pliku.

## Decyzje

- Opis nie jest wymagany.
- Data domyslnie jest dzisiejsza.
- `Inne` zostaje na koncu listy kategorii.
- MVP pokazuje osobno `Aparat`, `Galeria` i `PDF`, ale implementacja moze uzyc
  demo-draftow do czasu podpiecia natywnych pickerow.
- OCR confirm screen jest poza zakresem tego zadania.
