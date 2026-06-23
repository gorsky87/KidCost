# KidCost - dziennik testera

## Cel

Ten plik jest miejscem na scenariusze testowe, notatki z myslenia testerskiego i dzienne wyniki testow.

Rytm pracy:

- co 1 godzine dopisujemy nowe scenariusze, ryzyka i edge case'y,
- raz dziennie wybieramy najwazniejsze scenariusze i wykonujemy sesje testowa,
- kazdy scenariusz ma status, zeby bylo widac, co jest gotowe do testu, co przeszlo, a co wymaga poprawki.

## Statusy

- `todo` - scenariusz czeka na test.
- `blocked` - scenariusza nie da sie jeszcze wykonac, bo brakuje funkcji/srodowiska.
- `testing` - scenariusz jest w dziennej sesji testowej.
- `pass` - scenariusz przeszedl.
- `fail` - scenariusz wykryl blad.
- `needs-update` - scenariusz trzeba poprawic, bo zmienil sie produkt.

## Dzienne minimum testowe

Przed koncem dnia sprawdzamy przynajmniej:

- czy aplikacja sie uruchamia,
- czy logowanie/rejestracja dzialaja dla podstawowego przypadku,
- czy mozna dodac koszt,
- czy lista kosztow pokazuje dodane dane,
- czy saldo 50/50 liczy sie poprawnie dla prostych danych,
- czy nie widac danych innej rodziny/uzytkownika,
- czy aplikacja pokazuje zrozumiale stany bledu i puste stany.

## Backlog scenariuszy

| ID | Obszar | Priorytet | Status | Scenariusz | Oczekiwany wynik | Notatki |
| --- | --- | --- | --- | --- | --- | --- |
| TC-001 | Auth | P1 | blocked | Nowy rodzic zaklada konto przez email i haslo. | Konto powstaje, uzytkownik trafia do startowego widoku aplikacji. | Do wykonania po dodaniu auth. |
| TC-002 | Auth | P1 | blocked | Rodzic wpisuje bledne haslo przy logowaniu. | Aplikacja pokazuje jasny blad i nie loguje uzytkownika. | Sprawdzic tekst bledu i brak wycieku informacji. |
| TC-003 | Koszty | P1 | blocked | Rodzic dodaje koszt z kwota, data, kategoria, opisem i osoba placaca. | Koszt zapisuje sie i jest widoczny na liscie. | Podstawowy happy path MVP. |
| TC-004 | Koszty | P1 | blocked | Rodzic probuje zapisac koszt bez kwoty. | Formularz blokuje zapis i pokazuje blad przy polu kwoty. | Walidacja graniczna. |
| TC-005 | Paragony | P2 | blocked | Rodzic dodaje zdjecie paragonu do kosztu. | Zdjecie przesyla sie, widac miniaturke i mozna wrocic do kosztu. | Do wykonania po Storage. |
| TC-006 | Paragony | P2 | blocked | Upload paragonu nie udaje sie, ale uzytkownik chce zapisac koszt. | Aplikacja pozwala zapisac koszt bez paragonu albo jasno pokazuje opcje ponowienia. | Wazne dla slabej sieci. |
| TC-007 | Saldo | P1 | blocked | Jeden rodzic placi 100, drugi 40 przy podziale 50/50. | Saldo pokazuje, ze drugi rodzic powinien oddac 30. | Sprawdzic zaokraglenia. |
| TC-008 | Saldo | P1 | blocked | Lista kosztow zawiera kilka kategorii i rozne daty. | Suma miesiaca i saldo obejmuja wlasciwy zakres. | Wazne przy filtrach. |
| TC-009 | Rodzina | P1 | blocked | Uzytkownik z rodziny A probuje zobaczyc dane rodziny B. | Dane sa odizolowane przez RLS/API i nie sa widoczne. | Test security/privacy. |
| TC-010 | Statusy | P2 | blocked | Koszt zmienia status z oczekujacego na zaakceptowany. | Status aktualizuje sie w szczegolach, na liscie i w saldzie zgodnie z regule. | Do doprecyzowania reguly salda. |
| TC-011 | UX | P2 | blocked | Uzytkownik otwiera pusta liste kosztow. | Widzi pusty stan z jasna akcja dodania pierwszego kosztu. | Pierwsze wrazenie w MVP. |
| TC-012 | Release | P1 | blocked | Aplikacja startuje na czystej instalacji Android/iOS. | Nie ma crasha, pierwszy ekran jest poprawny, sesja nie jest stara. | Test przed kazdym wydaniem. |

## Log godzinowy

Nowe wpisy dopisujemy od najnowszego do najstarszego.

### 2026-06-23

- Start dziennika testera.
- Ustalony rytm: co 1 godzine nowe scenariusze, raz dziennie sesja testowa.
- Pierwszy backlog zawiera obszary: auth, koszty, paragony, saldo, prywatnosc, statusy, UX i release.

## Wyniki dziennych sesji testowych

Nowe sesje dopisujemy od najnowszej do najstarszej.

### Szablon sesji

```text
Data:
Zakres:
Srodowisko:
Wykonane scenariusze:
Wynik:
Bledy:
Decyzje:
Nastepne testy:
```
