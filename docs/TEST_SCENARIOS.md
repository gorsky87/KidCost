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
| TC-018 | Release | P1 | blocked | Przegląd dokumentow sklepowych dla TestFlight i Play: privacy policy, support i terms. | Strony istnieja pod linkami wskazanymi w `docs/RELEASE.md` i zawieraja kompletne informacje wymagane do testowej publikacji. | Weryfikacja manualna: linki, treść i spójnosc. |
| TC-019 | UX | P1 | blocked | Ustawienia mają widoczne odnośniki: privacy policy, terms, support, eksport danych oraz jasny komunikat o braku porady prawnej. | Wchodzac do ustawien uzytkownik widzi 1) linki do stron i 2) jasny wpis o zakresie odpowiedzialności i przejrzystych zasadach. | Sprawdzenie gotowych tekstow onboardingowych dla zaufania. |
| TC-020 | Subskrypcja | P1 | blocked | Premium wygasa po zakonczeniu okresu rozliczeniowego dla rodziny z istniejacymi kosztami, paragonami i raportami. | Historia kosztow, salda, komentarze i stare zalaczniki pozostaja czytelne, a zablokowane sa tylko nowe funkcje Premium. | Regresja dla issue #42 i #46. |
| TC-021 | Subskrypcja | P1 | blocked | Rodzina po downgrade ma zajete 400 MB storage i probuje dodac nowy paragon. | Aplikacja nie usuwa starych plikow, pokazuje komunikat o przekroczonym limicie Free i blokuje tylko nowe uploady. | Weryfikuje polityke storage po lapse. |
| TC-022 | Subskrypcja | P1 | blocked | Jeden rodzic oplaca Premium Family, a drugi rodzic loguje sie i przeglada te same rekordy. | Status platnika nie daje dodatkowej wladzy nad danymi; obie strony maja dostep zgodny z rolami rodziny. | Chroni przed traktowaniem subskrypcji jako narzedzia kontroli. |
| TC-023 | Support | P2 | blocked | Uzytkownik sklada wniosek o fee waiver bez dolaczania dokumentow wrazliwych. | Formularz wymaga tylko kategorii powodu, krotkiego opisu i zgody na kontakt, a decyzja trafia do recznego review. | Minimalizacja danych wrazliwych. |
| TC-024 | Rodzina | P1 | blocked | Drugi rodzic otwiera zaproszenie do rodziny po jego wygasnieciu albo po wykorzystaniu tego samego linku na innym koncie. | Aplikacja nie dolacza uzytkownika drugi raz, pokazuje jasny status zaproszenia i nie ujawnia danych rodziny przed akceptacja waznego zaproszenia. | Ryzyko duplikatow czlonkow rodziny i wycieku metadanych przez invite link. |
| TC-025 | Prywatnosc | P1 | blocked | Uzytkownik z rodziny A probuje pobrac plik paragonu rodziny B przez bezposredni URL lub znany identyfikator zalacznika. | Storage/API zwraca brak dostepu, aplikacja nie pokazuje miniatury ani metadanych paragonu, a zdarzenie mozna wykryc w logach bez zapisu danych wrazliwych. | Doprecyzowanie RLS/Storage dla zalacznikow, nie tylko rekordow kosztow. |
| TC-026 | Koszty | P1 | blocked | Rodzic wypelnia formularz kosztu z paragonem przy slabej sieci, zapis konczy sie timeoutem, a potem naciska ponowienie. | Draft pozostaje w aplikacji, koszt zapisuje sie maksymalnie raz, a zalacznik ma czytelny status: wyslany, do ponowienia albo zapisany bez paragonu. | Edge case dla offline/poor-network UX i ochrony przed duplikatami salda. |
| TC-027 | Saldo | P1 | blocked | Rodzina uzywala splitu 70/30 w Premium, Premium wygasa, a rodzic przeglada stare saldo i dodaje nowy zwykly koszt 50/50. | Historyczne saldo 70/30 pozostaje zgodne z pierwotna regula, nowy koszt liczy sie wedlug dostepnych zasad, a edycja niestandardowego splitu jest zablokowana z jasnym komunikatem. | Laczy entitlementy z poprawnoscia rozliczen po lapse. |
| TC-028 | Release | P2 | blocked | Tester uruchamia build TestFlight/Internal Testing z wlaczonym crash reportingiem i wykonuje rejestracje, dodanie kosztu oraz upload paragonu. | Crash/analytics nie zawieraja kwot, danych dziecka, opisow kosztow ani tresci paragonu; zdarzenia techniczne pozwalaja diagnozowac blad bez danych rodzinnych. | Kontrola prywatnosci telemetryki przed release mobile. |
| TC-029 | Raporty | P1 | blocked | Rodzic generuje miesieczny eksport CSV i prosty wydruk dla zakresu z kosztami oczekujacymi, zaakceptowanymi, spornymi i rozliczonymi. | Eksport jasno pokazuje zakres dat, status kazdego kosztu, autora wpisu i saldo zgodne z widokiem w aplikacji, bez ukrytych kosztow ani podwojnych sum. | Weryfikuje minimum Free i spojność raportu z ledgerem. |
| TC-030 | Koszty | P1 | blocked | Rodzic dodaje rachunek medyczny o tej samej kwocie, dostawcy i dacie uslugi jak juz istniejacy koszt, ale z inna data wystawienia dokumentu. | Aplikacja pokazuje nieoskarzajaca sugestie mozliwego duplikatu i pozwala swiadomie kontynuowac albo otworzyc istniejacy wpis. | Ryzyko podwojnego rozliczenia powtarzanych rachunkow. |
| TC-031 | Subskrypcja | P1 | blocked | Rodzic rozpoczyna anulowanie Premium po wygenerowaniu raportu i z istniejacymi paragonami ponad limitem Free. | Flow jasno pokazuje, co pozostanie dostepne, oferuje eksport danych i fee waiver bez utrudniania anulowania ani ukrywania historii. | Etyczny downgrade/cancellation i ochrona zaufania. |
| TC-032 | Offline | P1 | blocked | Uzytkownik offline dodaje dwa koszty, edytuje jeden draft, zamyka aplikacje i wraca online po ponownym uruchomieniu. | Kolejka synchronizacji zachowuje kolejnosc operacji, nie duplikuje kosztow, pokazuje konflikty czytelnie i nie gubi paragonow oczekujacych na upload. | Krytyczne dla mobile i slabej sieci. |
| TC-033 | Prywatnosc | P2 | blocked | Rodzic usuwa konto albo traci czlonkostwo w rodzinie, gdy jego historyczne koszty sa czescia salda drugiego rodzica. | Aplikacja nie ujawnia danych ponad uprawnienia, zachowuje integralnosc historii finansowej rodziny i pokazuje jasny komunikat o skutkach usuniecia dostepu. | Wymaga decyzji produktowo-prawnej przed implementacja usuwania konta. |
| TC-034 | Powiadomienia | P1 | blocked | Rodzina ma wlaczony dzienny digest i quiet hours, a drugi rodzic dodaje koszt, komentarz oraz oznacza zalegle wyrownanie jako pilne. | Zwykle zdarzenia trafiaja do digestu bez pushy w quiet hours, pilne zdarzenie ma jasna regule wyjatku, a ekran powiadomien pokazuje co i kiedy zostalo wyslane. | Ryzyko eskalacji konfliktu przez nadmiar alertow i niejasne opoznienia. |
| TC-035 | Spory | P1 | blocked | Rodzic kwestionuje koszt przez wybor powodu "zla kwota", dopisuje proponowana korekte i zalacza dowod bez wolnego, emocjonalnego komentarza. | Koszt zmienia status na sporny, historia zapisuje powod, proponowana korekte, autora i czas, a saldo pokazuje czy sporny koszt jest wliczony czy pominiety. | Strukturyzacja sporu musi wspierac ledger i neutralny jezyk UI. |
| TC-036 | Prywatnosc | P1 | blocked | Rodzic dodaje zdjecie paragonu z metadanymi lokalizacji/urzadzenia i pozniej udostepnia raport drugiemu rodzicowi lub mediatorowi. | Aplikacja usuwa albo neutralizuje metadane przed zapisem/udostepnieniem, informuje o tym zrozumiale i nie przenosi EXIF do raportu ani miniatur. | Prywatnosc zalacznikow: paragony moga ujawniac lokalizacje i dane urzadzenia. |
| TC-037 | Raporty | P2 | blocked | Raport miesieczny zawiera koszty zaakceptowane, sporne i rozliczone oraz strukturyzowane powody sporow. | Raport rozdziela statusy, pokazuje powody sporow faktograficznie, nie sugeruje winy i zachowuje zgodnosc sum z widokiem salda w aplikacji. | Kontrola jezyka i integralnosci danych przed eksportem PDF/CSV. |
| TC-038 | Raporty | P1 | blocked | Rodzic otwiera miesieczny kosztorys dziecka dla jednego miesiaca, wpisuje plan per kategoria i porownuje go z rzeczywistymi kosztami z KidCost. | Raport pokazuje plan, rzeczywiste koszty i roznice per kategoria bez zmiany salda ani zwrotow. | Regresja dla issue #56 i granicy miedzy report view a ledgerem. |
| TC-039 | Raporty | P1 | blocked | Rodzic dopisuje w sekcji `Zalozenia i swiadczenia` informacje o `800+`, `Dobry Start`, uldze PIT i opiece naprzemiennej, a nastepnie eksportuje raport. | Eksport oddziela zalozenia od faktycznych kosztow, zachowuje disclaimer o braku porady prawnej/podatkowej i nie miesza notatek z obliczeniami. | Regresja dla issue #62 i neutralnego jezyka PL. |
| TC-040 | Analytics | P1 | blocked | Rodzic wpisuje krotka notatke w polu zalozen i generuje eksport kosztorysu. | Analytics zapisuje tylko flagi uzycia funkcji, bez tresci notatek, PIT contextu ani nazw dziecka. | Ochrona prywatnosci dla raportu PL i danych wrazliwych kontekstowych. |
| TC-041 | Raporty | P1 | blocked | Rodzina ma dwoje dzieci, a rodzic generuje `Miesieczny kosztorys dziecka` tylko dla jednego dziecka. | Raport, eksport i analytics obejmuja wylacznie wybrane dziecko; koszty drugiego dziecka nie trafiaja do sum, podgladu ani payloadow telemetrycznych. | Prywatnosc i poprawne filtrowanie danych dziecka w raporcie PL. |
| TC-042 | Saldo | P1 | blocked | Rodzic zmienia plan miesieczny i pole `800+` w raporcie PL po tym, jak dashboard pokazal saldo 50/50. | Saldo, zwroty i statusy kosztow pozostaja bez zmian, a raport pokazuje tylko nowy kontekst planu/zalozen z jasnym help textem. | Regresja granicy `display/export only` kontra ledger. |
| TC-043 | Support | P2 | blocked | Wniosek fee waiver wygasa, a uzytkownik prosi o usuniecie danych wniosku i opcjonalnego zalacznika doslanego do recznej eskalacji. | System usuwa zalacznik zgodnie z retencja, zachowuje minimalny audyt decyzji bez danych wrazliwych i nie ukrywa historii kosztow rodziny. | Prywatnosc i retencja danych supportowych po waiver. |
| TC-044 | Release | P1 | blocked | Build wysylany do TestFlight/Google Play Internal Testing ma konfiguracje produkcyjna, ale przypadkowo wskazuje na dev Supabase albo debug analytics. | Smoke test release blokuje wysylke, pokazuje niespojna konfiguracje srodowiska i nie pozwala testowac na danych produkcyjnych z debug telemetryka. | Krytyczne przed mobile release: srodowiska, sekrety i privacy telemetryki. |
| TC-045 | Accessibility | P1 | blocked | Uzytkownik ustawia duzy tekst systemowy i otwiera add expense, dashboard, expense detail oraz podglad raportu. | Krytyczne kwoty, statusy i glowna akcja pozostaja czytelne, bez clippingu i bez poziomego scrolla. | Regresja dla issue #73 i baseline 200% font scaling. |
| TC-046 | Accessibility | P1 | blocked | Uzytkownik korzysta z VoiceOver albo TalkBack na dashboardzie, liscie kosztow i formularzu z zalacznikiem. | Czytnik odczytuje kwote, platnika, status, attachment state i skutki glownych akcji bez pustych ikon ani mylacej kolejnosci fokusu. | Sprawdza semantics labels dla flow MVP. |
| TC-047 | Accessibility | P1 | blocked | Uzytkownik z ograniczonym rozroznianiem kolorow przeglada statusy `draft`, `pending`, `accepted`, `disputed` i kategorie kosztow. | Statusy i kategorie sa rozroznialne przez tekst i dodatkowy sygnal, nie tylko kolor. | Chroni przed nieczytelnymi chipsami finansowymi. |
| TC-048 | Accessibility | P1 | blocked | Uzytkownik probuje trafic w ikony zalacznika, menu statusu i glowny przycisk zapisu na malym telefonie. | Interaktywne elementy maja bezpieczny target size, sensowny odstep i logiczny focus order. | Weryfikuje 44 pt / 48 dp oraz akcje bez ukrytych gestow. |
| TC-049 | Support | P1 | blocked | Tester bety zglasza blad przez `support@kidcost.app` wedlug szablonu feedbacku. | Zgloszenie zawiera kontekst, kroki, oczekiwane i rzeczywiste zachowanie oraz wplyw, ale nie wymaga danych wrazliwych dziecka, pelnych kwot ani pelnych paragonow. | Regresja dla issue #72 i procesu privacy-safe supportu. |
| TC-050 | Release | P1 | blocked | Zespol przygotowuje build beta i publikuje instrukcje dla testerow. | Razem z buildem istnieje lista znanych ograniczen, kanal feedbacku i jasny triage rozdzielajacy blocker, bug, privacy/security, V1 feature i later. | Chroni przed chaotycznym backlogiem po rundzie bety. |

## Log godzinowy

Nowe wpisy dopisujemy od najnowszego do najstarszego.

### 2026-06-24

- 12:05 CEST: Dla issue #72 i #73 doprecyzowano baseline accessibility dla flow MVP oraz proces feedbacku z bety, w tym privacy-safe szablon zgloszen i liste znanych ograniczen.
- Dodane scenariusze TC-045 - TC-050 dla duzego tekstu, czytnikow ekranu, target size, feedbacku beta i triage backlogu V1.
- 09:10 CEST: Dla issue #56 i #62 doprecyzowano miesieczny kosztorys dziecka dla rynku PL, rozdzielenie `plan vs actual` od ledgera oraz sekcje `Zalozenia i swiadczenia` bez wplywu na saldo.
- Dodane scenariusze TC-038 - TC-040 dla kosztorysu miesiecznego, PL benefit/tax context w eksporcie oraz analityki bez tresci notatek.
- 01:30 CEST: Po przegladzie planu, architektury, subskrypcji, release i raportu PL nowe ryzyka testerskie dotycza izolacji danych jednego dziecka w raporcie, braku wplywu planu na saldo, retencji fee waiver oraz konfiguracji buildow mobile.
- Dodane scenariusze TC-041 - TC-044 dla raportu per dziecko, niezmiennosci ledgera po edycji zalozen, usuwania danych waiver i blokady release przy zlym srodowisku.
- 00:29 CEST: Po przegladzie planu, release, subskrypcji i nowych notatek UX najwieksze ryzyka testerskie dotycza spokojnych powiadomien, strukturyzowanych sporow, prywatnosci metadanych paragonow oraz neutralnego jezyka w raportach.
- Dodane scenariusze TC-034 - TC-037 dla digestu/quiet hours, dispute reason flow, czyszczenia EXIF/metadanych zalacznikow i raportow obejmujacych koszty sporne.

### 2026-06-23

- 23:26 CEST: Po przegladzie roadmapy 30 dni, UX, release i subskrypcji nowe ryzyka testerskie dotycza eksportow zgodnych z ledgerem, wykrywania duplikatow rachunkow, etycznego anulowania Premium, kolejki offline oraz skutkow usuniecia konta dla historii salda.
- Dodane scenariusze TC-029 - TC-033 dla raportow CSV/wydrukow, duplicate-aware bill verification, cancellation/downgrade UX, synchronizacji offline i prywatnosci przy utracie dostepu do rodziny.
- 22:24 CEST: Po przegladzie roadmapy, architektury, release, UX i subskrypcji nowe ryzyka testerskie dotycza zaproszen do rodziny, izolacji paragonow w Storage, slabej sieci przy zapisie kosztu, splitow po wygasnieciu Premium oraz prywatnosci telemetryki w buildach testowych.
- Dodane scenariusze TC-024 - TC-028 dla wygaslych/ponownie uzytych zaproszen, bezposredniego dostepu do zalacznikow innej rodziny, idempotentnego zapisu kosztu z draftem, historycznych splitow po lapse i release telemetryki bez danych rodzinnych.
- 22:05 CEST: Dodane scenariusze TC-020 - TC-023 dla wygasniecia Premium, limitu storage po downgrade, neutralnosci platnika rodzinnego i recznego fee waiver MVP.
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
