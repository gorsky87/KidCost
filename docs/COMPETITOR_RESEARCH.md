# KidCost - competitor research

Data: 2026-06-23

## Cel dokumentu

Ten dokument zbiera praktyczne wnioski z aplikacji i materialow o co-parentingu, rozliczaniu kosztow dzieci, custody calendar, reimbursement requests i raportach. Celem nie jest kopiowanie konkurencji, tylko ustalenie, ktore wzorce warto przeniesc do KidCost jako wlasne, prostsze i bardziej skoncentrowane na rozliczeniach.

## Glowne pozycjonowanie KidCost

KidCost pomaga rodzicom szybko zapisac koszt dziecka, dodac dowod, zobaczyc kto komu ile oddaje i zachowac spokojna historie rozliczen.

## Krotkie wnioski strategiczne

- Rynek nie sprzedaje samego "expense trackera"; sprzedaje mniej konfliktu, mniej chaosu i lepsza dokumentacje.
- Najsilniejsze produkty lacza koszty, paragony, statusy, raporty i kalendarz, ale ich zakres bywa ciezki dla pierwszego kontaktu.
- KidCost powinien zaczac od finansow i salda, bo to jest najbardziej namacalna wartosc po 3 dniach.
- Kalendarz, raporty PDF, OCR i mediatorzy sa wazne, ale powinny wzmacniac finansowy core, a nie zastapic go.
- Najwieksza roznica KidCost na start: proste, mobile-first dodanie kosztu i zdanie wprost: "Mama oddaje tacie 300 zl".

## Zrodla

- OurFamilyWizard Expense Log: https://www.ourfamilywizard.com/product-features/expense-log
- OurFamilyWizard Expense Log mobile help: https://www.ourfamilywizard.com/knowledge-center/tips-tricks/parents-mobile/expense-log
- OurFamilyWizard Expenses help: https://support.ourfamilywizard.com/hc/en-us/articles/34522941780365-Expenses
- 2houses features: https://www.2houses.com/en/features
- 2houses App Store listing: https://apps.apple.com/de/app/2houses-better-co-parenting/id632536949?l=en-GB
- 2houses Google Play listing: https://play.google.com/store/apps/details?id=com.twohouses.app
- AppClose homepage: https://appclose.com/
- AppClose Pro features: https://appclose.com/pro/features/
- AppClose App Store listing: https://apps.apple.com/us/app/appclose/id1019290876
- DComply features: https://www.dcomply.com/features/
- DComply App Store listing: https://apps.apple.com/us/app/dcomply-co-parenting-expenses/id1451089998
- DComply FAQs: https://www.dcomply.com/faqs/
- Custody X Change co-parenting app overview: https://www.custodyxchange.com/topics/software/tech/co-parenting-app.php

## Porownanie funkcji

| Obszar | Wzorzec rynkowy | Decyzja dla KidCost |
| --- | --- | --- |
| Expenses | Wspolna lista kosztow, status, historia, kategorie | MVP day 3: dodawanie kosztu, lista, status bazowy |
| Receipts | Zalacznik paragonu/faktury jest dowodem kosztu | MVP day 3: upload zdjecia/PDF bez OCR |
| Reimbursements | Request o zwrot, platnosc, potwierdzenie offline/online | Day 14: settlements i historia wyrownan |
| Balance | Produkty pokazuja kto komu ile zalega | MVP day 3: jedno jasne zdanie o saldzie |
| Categories | Kategorie maja czasem wlasne proporcje podzialu | Day 3: stale kategorie; day 15+: custom split |
| Approvals | Drugi rodzic moze zaakceptowac lub zakwestionowac koszt | Day 14: pending / accepted / disputed / settled |
| Reports | CSV/PDF dla rozmow, mediacji i sadow | Day 14: raport miesieczny; day 30+: raport roczny |
| Calendar | Wspolny kalendarz opieki, wydarzen i wakacji | Day 21: podstawowy kalendarz opieki |
| Custody time | Liczenie planowanego i faktycznego czasu opieki | Later: gdy core finansowy jest stabilny |
| Payments | Niektore produkty integruja platnosci | Later: najpierw reczne oznaczenie wyrownania |
| Professionals | Dostep mediatora/prawnika do dokumentow | Later/premium: read-only access do raportow |
| Solo mode | Niektore aplikacje dzialaja bez podlaczonego co-parenta | Day 7/14: tryb solo jako wazny onboarding |
| Privacy | Bezpieczenstwo i trwale rekordy sa duza czescia wartosci | Day 7: RLS, audit log MVP, jasna polityka danych |

## Priorytety wg faz

### MVP day 3

- email/password auth,
- pierwsza rodzina lub tryb solo,
- jedno dziecko,
- dodanie kosztu,
- zdjecie/PDF paragonu,
- lista kosztow,
- saldo 50/50,
- jasny dashboard,
- build testowy.

### Day 7

- zaproszenie drugiego rodzica,
- wiele dzieci,
- podstawowe RLS,
- seed danych demo,
- ikony kategorii,
- stabilniejsze empty/error/loading states,
- pierwsze materialy store.

### Day 14

- statusy kosztow,
- filtrowanie,
- settlements,
- historia zmian MVP,
- raport miesieczny,
- CSV,
- Crashlytics i eventy analityczne.

### Day 30

- PDF lepszej jakosci,
- OCR jako funkcja beta/later,
- onboarding zaufania,
- model premium,
- eksport danych,
- przygotowanie do szerszych testow.

### Later

- integracje bankowe,
- automatyczne przelewy,
- pelne role mediator/prawnik,
- custody time actual vs planned,
- synchronizacja z Google/Apple Calendar,
- AI do sporow,
- publiczne API.

## 10 inspiracji przepisanych na funkcje KidCost

1. Szybki koszt z dowodem: formularz zaczyna sie od kwoty, kategorii i paragonu, bez wymuszania dlugiego opisu.
2. Saldo jako zdanie: zamiast samego plus/minus pokazujemy "Mama oddaje tacie 300 zl".
3. Kategorie z logika podzialu: na start stale kategorie, pozniej per-kategoria 50/50, 70/30 lub 100/0.
4. Tryb solo: rodzic moze zaczac sam i generowac raporty, nawet jesli drugi rodzic nie dolaczyl.
5. Status kosztu bez agresji: "sporne" zamiast ostrzejszego jezyka odrzucenia.
6. Offline settlement: mozna oznaczyc, ze przelew/wyrownanie nastapilo poza aplikacja.
7. Raport miesieczny jako produkt premium-ready: najpierw prosty raport, pozniej PDF do mediacji.
8. Receipt review tray: przed wyslaniem kosztu uzytkownik widzi mini podsumowanie paragonu i danych.
9. Historia bez kasowania sladow: zaakceptowane lub sporne koszty nie znikaja bez audit eventu.
10. Profesjonalny dostep read-only: mediator/prawnik dostaje w przyszlosci ograniczony dostep do raportow, nie do prywatnego chatu.
11. Koszty cykliczne: przedszkole, zajecia i alimentacyjne stale pozycje mozna odtworzyc jako szablony.
12. Dokumentacja PL/EU: koszt moze miec typ dowodu, np. paragon, faktura, potwierdzenie przelewu, decyzja/opis.

## Funkcje, ktore KidCost powinien miec od poczatku

1. Dodanie kosztu w mniej niz minute.
2. Zalacznik paragonu lub faktury.
3. Lista kosztow z podstawowymi kategoriami.
4. Saldo 50/50 wyjasnione prostym tekstem.
5. Tryb solo lub mozliwosc pominiecia zaproszenia drugiego rodzica.

## Funkcje, ktorych nie robimy teraz

1. Pelny chat miedzy rodzicami.
2. AI mediator albo AI do rozstrzygania sporow.
3. Integracje bankowe i automatyczne przelewy.
4. Pelny panel prawnik/mediator.
5. Zaawansowane raporty sadowe z gotowymi argumentami prawnymi.

## Persony

### Rodzic placacy

Chce szybko zapisac wydatek i nie tlumaczyc go kilka razy. Najwazniejsze potrzeby: szybki formularz, paragon, status, widocznosc czy drugi rodzic zareagowal.

### Rodzic rozliczajacy

Chce miec miesieczne podsumowanie, saldo i historie. Najwazniejsze potrzeby: filtry, raporty, kategorie, wyrownania.

### Rodzic w konflikcie

Chce dokumentowac fakty bez emocjonalnych dyskusji. Najwazniejsze potrzeby: trwala historia zmian, neutralny jezyk, spory z komentarzem, eksport.

### Mediator lub prawnik

To persona przyszlosciowa. Potrzebuje czytelnych raportow, eksportow i ograniczonego dostepu read-only, ale nie musi byc czescia MVP.

## Decyzje dla KidCost MVP

- Priorytetem jest prostota finansow przed rozbudowana komunikacja.
- Day-3 demo musi pokazac wartosc w jednym flow: login, dodaj koszt, zobacz saldo.
- Paragon jest wazniejszy niz OCR. OCR przychodzi dopiero wtedy, gdy reczny flow jest wygodny.
- Kalendarz jest wazny, ale nie moze opoznic finansowego core.
- Raport miesieczny powinien byc pierwsza funkcja premium-ready.
- Jezyk UI ma byc spokojny, faktograficzny i bez oskarzen.
- KidCost nie powinien obiecywac porad prawnych; ma porzadkowac dane i dokumenty.
- Tryb solo jest wazny, bo wielu rodzicow zacznie bez zgody lub udzialu drugiej strony.
- Dane rodzinne i finansowe wymagaja RLS, audit log i jasnej polityki prywatnosci od poczatku.
