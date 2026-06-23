# KidCost - subskrypcje, entitlements i dostep po wygasnieciu

Data: 2026-06-23
Zakres: decyzje produktowe dla issue #42 i #46

## Cel

KidCost ma monetyzowac wygode i automatyzacje, ale nie moze zamieniac dostepu do historii kosztow w narzedzie nacisku miedzy rodzicami.

Zasada nadrzedna:

- rekordy finansowe juz utworzone przez rodzine pozostaja czytelne po wygasnieciu Premium,
- subskrypcja daje dodatkowe mozliwosci, a nie wlascicielstwo nad danymi drugiego rodzica,
- platnik rodzinny nie staje sie przez to jedynym administratorem danych,
- fee waiver ma chronic dostep do istotnych funkcji bez zbierania nadmiernie wrazliwych danych.

## Model planow

### Free

Plan zaufania i codziennego rejestrowania kosztow.

Zakres:

- 1 rodzina,
- do 2 aktywnych opiekunow we wspolnej rodzinie,
- do 6 dzieci,
- nielimitowane reczne koszty, komentarze i wpisy wyrownan,
- nielimitowany odczyt historii kosztow, sald, komentarzy i historii wyrownan,
- podstawowy upload paragonow do lacznego limitu 250 MB na rodzine,
- podstawowy eksport CSV i prosty widok do wydruku miesiecznego zestawienia,
- podstawowe powiadomienia systemowe i e-mail, gdy pojawia sie nowy koszt lub komentarz.

### Premium Family

Plan wygody, automatyzacji i formalnych raportow dla calej rodziny.

Zakres:

- wszystko z Free,
- wiekszy limit storage: 5 GB na rodzine,
- formalne raporty PDF do mediacji, prawnika lub ksiegowania domowego,
- zaawansowane filtry i eksport raportow za wiele okresow,
- niestandardowe reguly podzialu kosztow, np. 70/30 lub kategorie z innym splitem,
- powiazanie kosztow z kalendarzem opieki,
- szablony kosztow cyklicznych i automatyzacje przypomnien,
- priorytetowa obsluga supportu,
- przyszle funkcje OCR jako Premium beta,
- przyszle udostepnianie raportu profesjonaliscie w trybie read-only.

## Matryca entitlementow

| Obszar | Free | Premium Family | Po wygasnieciu Premium |
| --- | --- | --- | --- |
| Rodzina i wspolrodzic | 1 rodzina, 2 opiekunow | To samo | To samo |
| Dzieci | do 6 | do 6 | To samo |
| Reczne koszty | bez limitu | bez limitu | bez limitu |
| Historia kosztow i sald | pelny odczyt | pelny odczyt | pelny odczyt |
| Paragony juz zapisane | odczyt w limicie storage | odczyt | odczyt wszystkich istniejacych plikow |
| Nowe uploady paragonow | do 250 MB/rodzina | do 5 GB/rodzina | zablokowane, jesli rodzina jest ponad limitem Free |
| Eksport CSV | tak | tak | tak |
| Prosty wydruk miesieczny | tak | tak | tak |
| Formalny raport PDF | nie | tak | tylko dla raportow juz wyeksportowanych; nowe eksporty zablokowane |
| Zaawansowane filtry wielookresowe | nie | tak | zablokowane |
| Zaawansowane splity | nie | tak | istniejace dane dalej licza sie poprawnie, ale edycja reguly zablokowana |
| Kalendarz opieki w rozliczeniach | nie | tak | dane historyczne czytelne, nowe powiazania zablokowane |
| OCR / automatyzacje AI | nie | tak, beta/later | zablokowane |
| Udostepnianie profesjonaliscie | nie | tak, later | odczyt juz wygenerowanych raportow pozostaje |
| Priorytetowy support | nie | tak | nie |

## Reguly zaufania i wlasnosci danych

1. Subskrypcja jest przypisana do rodziny, nie do jednostronnej kontroli jednego rodzica.
2. Rodzic placacy za Premium nie moze usunac drugiemu rodzicowi dostepu do danych tylko dlatego, ze oplaca plan.
3. Role administracyjne, uprawnienia do zapraszania i widocznosc danych sa kontrolowane przez model rodziny, nie przez status platnika.
4. Zmiana platnika, wycofanie karty albo wygasniecie subskrypcji nie zmienia autora kosztow, historii auditowej ani wlasciciela zalacznikow.
5. Zadna blokada platnosci nie moze ukrywac juz utworzonych kosztow, wyrownan, komentarzy ani paragonow.

## Downgrade i wygasniecie

### Stany uproszczone dla MVP

- `free`
- `trial`
- `premium_active`
- `premium_canceled_period_end`
- `premium_lapsed`
- `fee_waiver_active`

Pelniejszy lifecycle App Store / Google Play pozostaje osobnym tematem dla issue #49.

### Zachowanie po wygasnieciu

- Rodzina wraca do bazowych entitlementow Free.
- Wszystkie istniejace rekordy pozostaja czytelne.
- CSV i prosty wydruk miesieczny pozostaja dostepne.
- Wygenerowane wczesniej pliki PDF pozostaja do odczytu i ponownego pobrania, ale nie tworzymy nowych formalnych raportow bez aktywnego Premium lub fee waiver.
- Jesli rodzina przekracza limit storage Free, nie usuwamy plikow automatycznie. Blokujemy tylko nowe uploady do czasu zejscia ponizej limitu albo wznowienia Premium.
- Jesli rodzina korzystala z zaawansowanego splitu, stare obliczenia pozostaja spojne. Edycja lub tworzenie nowych niestandardowych splitow wymaga aktywnego Premium.
- Funkcje o zmiennym koszcie operacyjnym, jak OCR, sa natychmiast pauzowane po zakonczeniu okresu aktywnego.

## Fee waiver

### Cel

Fee waiver chroni rodziny, dla ktorych platnosc jest chwilowo nierealna, ale dostep do dokumentacji kosztow pozostaje wazny dla codziennej opieki, mediacji albo bezpieczenstwa.

### Kto moze sie kwalifikowac

- osoba w przejsciowej trudnosci finansowej,
- osoba kierowana przez mediatora, organizacje pomocowa albo program court-adjacent,
- osoba w sytuacji przemocy ekonomicznej lub ryzyka wykorzystania subskrypcji jako narzedzia nacisku,
- osoba, ktora utracila prace lub ma udokumentowana czasowa przerwe w dochodzie,
- osoba objeta lokalnym programem pomocy publicznej lub stypendialnej.

### Zakres fee waiver

KidCost przyjmuje wariant `Premium Essential`, a nie pelne Premium:

- pelny odczyt historii, paragonow, sald i komentarzy,
- nowe formalne raporty PDF,
- eksport CSV i podstawowy wydruk,
- utrzymanie dostepu do juz zapisanych zalacznikow,
- zaawansowane splity, jesli rodzina juz ich uzywa,
- udostepnianie raportu profesjonaliscie, gdy ta funkcja powstanie,
- brak nieograniczonego OCR i innych kosztownych automatyzacji AI; te funkcje pozostaja poza fee waiver albo wymagaja osobnej decyzji supportu.

To daje dostep do funkcji krytycznych dla zaufania i dokumentacji, ale nie otwiera bez limitu funkcji o stale rosnacym koszcie jednostkowym.

### Czas trwania i odnowienie

- standardowa decyzja: 90 dni,
- jedno uproszczone odnowienie na kolejne 90 dni,
- dalsze przedluzenie tylko po recznej eskalacji do wlasciciela produktu/supportu,
- przeglad wniosku w ciagu 3 dni roboczych,
- aktywna decyzja jest zapisywana jako osobny stan entitlementu, bez nadpisywania historii subskrypcji.

### Minimalne dane do zebrania

W MVP prosimy tylko o:

- wybranie kategorii powodu z listy,
- krotki opis tekstowy do 500 znakow,
- zgode na kontakt zwrotny e-mail.

Domyslnie nie wymagamy:

- skanow dochodow,
- dokumentow sadowych,
- danych dzieci,
- szczegolow konfliktu rodzinnego.

Opcjonalny dokument mozna poprosic dopiero przy recznej eskalacji i tylko wtedy, gdy bez niego nie da sie podjac decyzji.

### Retencja danych fee waiver

- formularz wniosku i decyzja: 12 miesiecy od zakonczenia waiver,
- zalaczniki doslane do recznej eskalacji: usuwane po 30 dniach od decyzji, chyba ze uzytkownik prosi o wczesniejsze usuniecie,
- notatki supportu: bez danych wrazliwych o dziecku i bez kopiowania tresci paragonow.

### Wlasciciel procesu

- pierwsza decyzja: support owner lub founder dyzurujacy,
- eskalacja: founder lub product owner przy sytuacjach abuse-risk albo sporze o zakres dostepu,
- MVP pozostaje reczny: bez automatycznej odmowy i bez scoringu dochodowego.

## Copy UX dla MVP

### Payment failed

`Nie udalo sie odnowic Premium. Twoje dotychczasowe koszty i paragony nadal sa dostepne. Funkcje Premium beda wznowione po udanej platnosci.`

### Premium expired

`Premium wygaslo. Historia kosztow, salda i dotychczasowe zalaczniki pozostaja dostepne w trybie odczytu. Formalne raporty PDF i nowe funkcje Premium sa chwilowo pauzowane.`

### Over free storage after downgrade

`Przekroczono limit storage planu Free. Nic nie usuwamy automatycznie, ale nowe zdjecia paragonow beda zablokowane do czasu zwolnienia miejsca albo wznowienia Premium.`

### Fee waiver request

`Potrzebujesz utrzymac dostep do raportow lub dokumentacji mimo problemu z oplata? Zloz krotki wniosek o fee waiver. Poprosimy tylko o minimum informacji potrzebnych do decyzji.`

## Wymagania implementacyjne dla kolejnych issue

### Backend / entitlement service

- model stanu entitlementu rodziny, nie pojedynczego platnika,
- osobny znacznik `fee_waiver_active`,
- storage quota liczona na rodzine,
- blokady write-only dla funkcji Premium po lapse, bez ukrywania danych historycznych,
- audyt decyzji fee waiver bez trzymania wrazliwych dokumentow dluzej niz potrzeba.

### Frontend / mobile

- osobne komunikaty dla `payment_failed`, `premium_lapsed`, `over_free_storage`, `fee_waiver_active`,
- feature gates oparte o matryce entitlementow, nie o sam fakt "ma subskrypcje / nie ma",
- widoczny status, ze dane historyczne pozostaja dostepne,
- ekran ustawien z informacja, kto oplaca plan, ale bez nadawania tej osobie specjalnej wladzy nad rekordami.

### Support / operations

- prosty inbox lub admin checklist dla wnioskow fee waiver,
- SLA 3 dni robocze,
- szablony odpowiedzi akceptacja / prosba o doprecyzowanie / odmowa,
- raportowanie powodow churn i wnioskow o fee waiver bez danych wrazliwych.

## Decyzje otwarte, ale odlozone

- pelny lifecycle App Store / Google Play: issue #49,
- finalny publiczny cennik,
- czy OCR bedzie czescia Premium, dodatkiem kredytowym czy funkcja beta z limitem,
- czy mediator/prawnik access bedzie w Premium Family czy osobnym add-onie.
