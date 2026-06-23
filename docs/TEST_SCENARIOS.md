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
| TC-013 | Rodzina | P1 | blocked | Rodzic zaczyna w trybie solo, dodaje koszty, a pozniej zaprasza drugiego rodzica do rodziny. | Dotychczasowe koszty pozostaja przypisane do tej samej rodziny, drugi rodzic widzi tylko dane po zaakceptowaniu zaproszenia. | Ryzyko migracji danych solo do wspolnej rodziny. |
| TC-014 | Saldo | P1 | blocked | Rodzic edytuje zaakceptowany koszt 100 zl na 120 zl po tym, jak saldo zostalo juz pokazane na dashboardzie. | Saldo, suma miesiaca i historia kosztu odswiezaja sie spojnie, a zmiana jest widoczna jako audit event. | Wymaga decyzji, czy edycja zaakceptowanego kosztu jest dozwolona. |
| TC-015 | Koszty | P1 | blocked | Rodzic wpisuje kwote z przecinkiem, zerem, wartoscia ujemna i bardzo duza kwota. | Formularz akceptuje poprawny format lokalny, blokuje zero/ujemne wartosci i pokazuje zrozumialy blad bez utraty reszty formularza. | Walidacja PL/EU i UX formularza. |
| TC-016 | Paragony | P2 | blocked | OCR lub podpowiedz z paragonu rozpoznaje kwote inna niz wpisana recznie przez rodzica. | Aplikacja nie nadpisuje danych automatycznie, pokazuje roznice i wymaga swiadomego wyboru uzytkownika. | Scenariusz premium/later, ale wazny dla sporow finansowych. |
| TC-017 | Release | P1 | blocked | Tester aktualizuje aplikacje z poprzedniej wersji testowej Android/iOS z aktywna sesja i lokalnymi danymi formularza. | Aplikacja startuje bez crasha, sesja jest nadal poprawna albo bezpiecznie wygaszona, a niedokonczony formularz nie wysyla duplikatu kosztu. | Test regresyjny przed TestFlight/Internal Testing. |
| TC-018 | Subskrypcja | P1 | blocked | Premium wygasa po zakonczeniu okresu rozliczeniowego dla rodziny z istniejacymi kosztami, paragonami i raportami. | Historia kosztow, salda, komentarze i stare zalaczniki pozostaja czytelne, a zablokowane sa tylko nowe funkcje Premium. | Regresja dla issue #42 i #46. |
| TC-019 | Subskrypcja | P1 | blocked | Rodzina po downgrade ma zajete 400 MB storage i probuje dodac nowy paragon. | Aplikacja nie usuwa starych plikow, pokazuje komunikat o przekroczonym limicie Free i blokuje tylko nowe uploady. | Weryfikuje polityke storage po lapse. |
| TC-020 | Subskrypcja | P1 | blocked | Jeden rodzic oplaca Premium Family, a drugi rodzic loguje sie i przeglada te same rekordy. | Status platnika nie daje dodatkowej wladzy nad danymi; obie strony maja dostep zgodny z rolami rodziny. | Chroni przed traktowaniem subskrypcji jako narzedzia kontroli. |
| TC-021 | Support | P2 | blocked | Uzytkownik sklada wniosek o fee waiver bez dolaczania dokumentow wrazliwych. | Formularz wymaga tylko kategorii powodu, krotkiego opisu i zgody na kontakt, a decyzja trafia do recznego review. | Minimalizacja danych wrazliwych. |

## Log godzinowy

Nowe wpisy dopisujemy od najnowszego do najstarszego.

### 2026-06-23

- 22:05 CEST: Dodane scenariusze TC-018 - TC-021 dla wygasniecia Premium, limitu storage po downgrade, neutralnosci platnika rodzinnego i recznego fee waiver MVP.
- Zapisano polityke entitlementow i fee waiver w `docs/SUBSCRIPTIONS.md`; nowe scenariusze maja chronic dostep do historii kosztow po lapse oraz ograniczenie zbierania danych wrazliwych.
- 21:22 CEST: Po przegladzie planu, roadmapy, researchu i UX najwieksze ryzyka testowe na tym etapie to przejscie z trybu solo do rodziny, spojnosc salda po edycjach, lokalne formaty kwot, prywatnosc/audit trail oraz aktualizacje buildow mobile.
- Dodane scenariusze TC-013 - TC-017 dla solo mode, salda po korekcie, walidacji kwot, konfliktu OCR z danymi recznymi i aktualizacji aplikacji testowej.
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
