# KidCost UX - statusy, akceptacja i spor kosztu

## Cel

Status kosztu ma pokazac fakty bez podgrzewania konfliktu. Uzytkownik powinien
wiedziec, co juz sie stalo, kto moze wykonac nastepna akcje i czy koszt liczy
sie jeszcze do rozliczen.

## Statusy

| Status techniczny | Nazwa w aplikacji | Opis dla uzytkownika | Kolor | Ikona |
| --- | --- | --- | --- | --- |
| `pending` | Do akceptacji | Czeka na spokojna reakcje drugiego rodzica. | Pomaranczowy | Klepsydra |
| `accepted` | Zaakceptowany | Drugi rodzic potwierdzil koszt. | Zielony | Check |
| `disputed` | Wymaga wyjasnienia | Koszt zostal oznaczony do wyjasnienia z komentarzem. | Indygo | Uwaga |
| `settled` | Rozliczony | Koszt zostal juz wyrownany lub ujety w rozliczeniu. | Grafitowy | Check w kregu |

Kolor nie jest jedynym sygnalem. Kazdy status ma tekst i ikone, zeby byl
czytelny dla osob, ktore gorzej rozrozniaja kolory.

## Ton komunikacji

- Uzywamy neutralnych czasownikow: `Oznacz jako sporne`, `Wymaga wyjasnienia`,
  `Potwierdz po wyjasnieniu`.
- Unikamy slow: `odrzuc`, `wina`, `nieuczciwy`, `atak`, `kara`.
- Komentarz przy sporze ma byc krotkim powodem, nie czatem.
- UI pokazuje rekord zdarzen, ale nie zacheca do rozmowy w aplikacji.

## Akcje wedlug roli

| Status | Autor kosztu | Drugi rodzic | System |
| --- | --- | --- | --- |
| Do akceptacji | Moze edytowac koszt do pierwszej reakcji. | Moze zaakceptowac albo oznaczyc jako sporne. | Tworzy status po dodaniu kosztu. |
| Zaakceptowany | Moze oznaczyc jako rozliczone. | Moze oznaczyc jako rozliczone. | Moze rozliczyc przy przyszlym batch settlement. |
| Wymaga wyjasnienia | Moze dodac korekte po wyjasnieniu. | Moze potwierdzic po wyjasnieniu. | Nie rozstrzyga automatycznie sporu w MVP. |
| Rozliczony | Brak akcji na rekordzie kosztu. | Brak akcji na rekordzie kosztu. | Pokazuje powiazane wyrownanie w przyszlosci. |

`Nie zgadzam sie` i `juz rozliczone` sa osobnymi intencjami:

- `Oznacz jako sporne` oznacza, ze koszt wymaga komentarza i nie powinien byc
  traktowany jak zwykle potwierdzenie.
- `Oznacz jako rozliczone` oznacza, ze zaakceptowany koszt zostal wyrownany albo
  ujety w rozliczeniu.

## Szczegoly kosztu

Ekran szczegolow pokazuje:

1. Status badge na gorze ekranu.
2. Jednozdaniowy opis statusu.
3. Dane kosztu: nazwa, kwota, kategoria, dziecko, placacy, data.
4. Zalacznik lub pusty stan zalacznika.
5. Sekcje akcji oddzielone wedlug wykonawcy: `Autor kosztu`, `Drugi rodzic`.
6. `Historia statusu` jako placeholder pod przyszly audit trail.

## Komentarz przy sporze

Komentarz jest wymagany przy zmianie `pending -> disputed`.

Placeholder: `Np. brakuje paragonu albo kwota wymaga sprawdzenia.`

Komunikat bledu: `Dodaj krotki powod, zeby drugi rodzic wiedzial co wyjasnic.`

Komentarz nie jest chatem. Nie ma watkow, reakcji ani odpowiedzi w MVP.

## Empty i error states

| Stan | Tekst |
| --- | --- |
| Brak kosztow | `Lista bedzie pokazywac koszty, statusy i zalaczniki.` |
| Brak kosztow po filtrach | `Zmien kryteria albo wyczysc wszystkie filtry.` |
| Brak historii statusu | `Dodano koszt. Historia reakcji pojawi sie po pierwszej akcji.` |
| Blad pobierania kosztow | `Nie udalo sie pobrac kosztow` + techniczny szczegol bledu. |
| Brak akcji w statusie | `Brak dostepnych akcji w tym statusie.` |

## Beta 1

Wymagane:

- Cztery statusy: `pending`, `accepted`, `disputed`, `settled`.
- Badge z nazwa, ikona i kolorem.
- Filtr statusu na liscie kosztow.
- Szczegoly kosztu ze statusem, opisem i miejscem na historie.
- Neutralne nazwy akcji oraz rozroznienie akcji autora i drugiego rodzica.
- Komentarz wymagany przy `Oznacz jako sporne`.

Pozniej:

- Pelny audit trail z data, aktorem i komentarzem.
- Grupowe rozliczenia wielu kosztow.
- Powiadomienia push o zmianach statusu.
- Rozbudowane powody sporu i propozycja korekty.
- Dostep mediatora lub prawnika do rekordu statusow.

## Decyzje

- `disputed` w UI nie nazywa sie domyslnie `Spor`, tylko `Wymaga wyjasnienia`.
- Edycja podstawowych pol kosztu jest mozliwa tylko przed pierwsza reakcja.
- `settled` jest stanem terminalnym w MVP.
- Historia statusu jest widoczna jako sekcja juz teraz, ale dane audytowe sa
  poza zakresem tej iteracji UI.
