# KidCost - roadmapa 30 dni

## Cel po 30 dniach

Po 30 dniach chcemy miec dzialajaca bete aplikacji mobilnej, gotowa do testow z prawdziwymi uzytkownikami.

Zakres bety:

- logowanie,
- rodzina i dzieci,
- zapraszanie drugiego rodzica,
- dodawanie kosztow,
- zdjecia paragonow,
- lista i filtrowanie kosztow,
- saldo rodzicow,
- podstawowe rozliczenia,
- statusy kosztow,
- raport miesieczny,
- eksport PDF/CSV w wersji podstawowej,
- podstawowy kalendarz opieki,
- powiadomienia,
- analytics i crash reporting,
- publikacja testowa Android/iOS.

## Decyzja repozytoryjna

Przez pierwsze 30 dni uzywamy **jednego repozytorium**.

Proponowany podzial katalogow:

```text
apps/mobile       # Flutter
apps/web          # landing, privacy policy, support
supabase          # migracje, RLS, storage, edge functions
packages/domain   # kalkulacje salda i modele domenowe
packages/contracts # typy i kontrakty, jesli beda potrzebne
docs              # plan, decyzje, model danych, release notes
```

Trzech repozytoriow nie robimy teraz, bo spowolnia development, testy i wydania. Do podzialu wracamy po becie, jezeli pojawi sie osobny zespol backendowy, publiczne API albo duzy panel webowy.

## Strumienie pracy

### Backend

Odpowiada za baze, dane, bezpieczenstwo i storage.

Zakres:

- Supabase project,
- PostgreSQL schema,
- RLS policies,
- storage buckets,
- audit log,
- soft delete,
- backup,
- seed danych testowych.

### API i domena

Odpowiada za logike biznesowa.

Zakres:

- algorytm salda,
- statusy kosztow,
- walidacje,
- Edge Functions,
- generowanie raportow,
- OCR pozniej,
- testy logiki domenowej.

### Frontend i aplikacja

Odpowiada za uzytkownika.

Zakres:

- Flutter mobile app,
- onboarding,
- auth screens,
- dashboard,
- expenses,
- settlement view,
- calendar,
- reports,
- podstawowy web: privacy policy, terms, support.

### Release i operacje

Odpowiada za dostarczenie aplikacji do testerow.

Zakres:

- Android package name,
- iOS bundle id,
- signing,
- ikona,
- splash screen,
- TestFlight,
- Google Play Internal Testing,
- Crashlytics,
- analytics,
- monitoring.

## Kamienie milowe

### Dzien 3 - pierwsze demo

Cel:

- aplikacja uruchamia sie na Androidzie i iOS,
- uzytkownik moze sie zalogowac,
- moze dodac koszt,
- widzi liste kosztow,
- widzi podstawowe saldo 50/50.

To moze byc demo wewnetrzne, jeszcze nie pelna beta.

### Dzien 7 - stabilny MVP

Cel:

- dziala rodzina,
- dziala dziecko,
- drugi rodzic moze byc zaproszony lub zasymulowany,
- upload zdjecia dziala stabilnie,
- RLS zabezpiecza dane rodziny,
- aplikacja ma podstawowy wyglad produktu.

### Dzien 14 - wersja beta 1

Cel:

- statusy kosztow,
- filtrowanie,
- historia rozliczen,
- podstawowy raport miesieczny,
- crash reporting,
- pierwsze testy automatyczne.

### Dzien 21 - wersja beta 2

Cel:

- podzial kosztow inny niz 50/50,
- podstawowy kalendarz opieki,
- powiadomienia,
- eksport CSV/PDF w wersji podstawowej,
- miesieczny kosztorys dziecka dla PL jako view `plan vs actual` bez zmiany salda.

### Dzien 30 - beta gotowa do testow

Cel:

- beta na TestFlight i Google Play Internal Testing,
- onboarding nadaje sie dla nowych osob,
- aplikacja ma minimum funkcji potrzebnych do rozmow z pierwszymi uzytkownikami,
- backlog V1 jest przygotowany na podstawie brakow i feedbacku,
- raport miesieczny dla PL moze opcjonalnie pokazywac `Zalozenia i swiadczenia` jako kontekst export-only bez porad prawnych ani podatkowych.

## Plan dzien po dniu

### Dzien 1

Backend:

- zalozyc projekt Supabase,
- przygotowac srodowiska `dev` i `prod` albo minimum `dev`,
- przygotowac wstepny model danych.

API/domena:

- opisac algorytm salda 50/50,
- zdefiniowac statusy kosztow.

Frontend/mobile:

- utworzyc Flutter app,
- ustawic podstawowa nawigacje,
- dodac ekran splash/login placeholder.

Release:

- potwierdzic nazwe aplikacji,
- wybrac bundle id i package name.

### Dzien 2

Backend:

- tabele: profiles, families, family_members, children, expenses,
- podstawowe RLS.

API/domena:

- modul kalkulacji salda,
- testy prostych przypadkow.

Frontend/mobile:

- auth email/password,
- dashboard,
- formularz dodania kosztu.

Release:

- przygotowac ikone robocza i splash.

### Dzien 3

Backend:

- storage bucket na paragony,
- expense_attachments.

API/domena:

- saldo po danych z bazy.

Frontend/mobile:

- lista kosztow,
- upload zdjecia,
- widok salda.

Release:

- pierwszy build Android,
- pierwszy build iOS,
- wewnetrzne demo.

### Dzien 4

Backend:

- poprawki RLS po testach,
- seed danych demo.

API/domena:

- walidacje kosztow.

Frontend/mobile:

- empty states,
- error states,
- loading states.

Release:

- konfiguracja Firebase/Crashlytics.

### Dzien 5

Backend:

- zapraszanie drugiego rodzica: model invitation.

API/domena:

- logika dolaczania do rodziny.

Frontend/mobile:

- ekran rodziny,
- dodawanie dziecka,
- zaproszenie drugiego rodzica.

Release:

- przygotowanie kont developerskich i metadanych store.

### Dzien 6

Backend:

- status kosztu w bazie.

API/domena:

- reguly statusow: pending, accepted, disputed.

Frontend/mobile:

- status kosztu na liscie,
- akcje zaakceptuj / oznacz jako sporne.

Release:

- pierwsze screenshoty testowe.

### Dzien 7

Backend:

- przeglad security MVP.

API/domena:

- testy salda i statusow.

Frontend/mobile:

- polishing UI,
- poprawki flow onboardingowego.

Release:

- build tygodniowy dla testerow.

### Dni 8-10

Backend:

- tabela settlements,
- historia wyrownan,
- audit log MVP.

API/domena:

- rozliczenia miedzy rodzicami,
- oznaczanie kosztow jako rozliczone.

Frontend/mobile:

- ekran historii,
- ekran szczegolow kosztu,
- edycja kosztu.

Release:

- analytics eventow: signup, add_expense, view_balance.

### Dni 11-14

Backend:

- dane do raportow miesiecznych,
- podstawowe agregacje.

API/domena:

- raport miesieczny,
- eksport CSV,
- przygotowanie prostego PDF.

Frontend/mobile:

- filtry,
- podsumowanie miesiaca,
- ekran raportu.

Release:

- beta 1 do wewnetrznych testerow.

### Dni 15-17

Backend:

- konfiguracja proporcji podzialu per rodzina.

API/domena:

- algorytm 50/50, 70/30, custom split.

Frontend/mobile:

- ekran ustawien rozliczen,
- pokazanie zasad podzialu na dashboardzie.

Release:

- testy regresji salda.

### Dni 18-21

Backend:

- tabele calendar_events / custody_days.

API/domena:

- podstawowy kalendarz opieki,
- przypomnienia.

Frontend/mobile:

- widok kalendarza,
- dodawanie dnia opieki,
- widok najblizszych wydarzen.

Release:

- beta 2.

### Dni 22-24

Backend:

- przygotowanie OCR pipeline, jeszcze bez perfekcji.

API/domena:

- parser wyniku OCR,
- sugestia kategorii.

Frontend/mobile:

- ekran potwierdzenia danych z OCR,
- reczna korekta kwoty/daty/sklepu.

Release:

- testy na realnych paragonach demo.

### Dni 25-27

Backend:

- dopracowanie audit log,
- eksport danych rodziny.

API/domena:

- raport roczny MVP,
- PDF z podstawowymi tabelami.

Frontend/mobile:

- eksport raportu,
- historia zmian widoczna przy koszcie.

Release:

- store metadata, privacy, terms, support.

### Dni 28-30

Backend:

- porzadkowanie migracji i polityk RLS.

API/domena:

- poprawki po testach,
- blokada krytycznych edge case'ow.

Frontend/mobile:

- finalny polish,
- poprawki responsywnosci,
- onboarding dla nowych testerow.

Release:

- TestFlight,
- Google Play Internal Testing,
- lista znanych ograniczen,
- backlog V1.

## Backlog po 30 dniach

Po becie zostawiamy na pozniej:

- pelny OCR produkcyjny,
- integracje bankowe,
- automatyczne przelewy,
- AI chat,
- mediatorzy/kancelarie/sady jako osobne role,
- publiczne API,
- rozbudowany panel webowy,
- subskrypcje i platnosci, jesli nie beda konieczne do testow.

## Pierwszy task do wykonania

Najpierw tworzymy szkielet repo:

1. `apps/mobile` jako Flutter project.
2. `supabase/migrations` z pierwszym schematem.
3. `packages/domain` z algorytmem salda.
4. `apps/web` dopiero gdy bedzie potrzebny privacy/support.

To daje nam fundament pod cale 30 dni bez przepinania architektury w polowie pracy.
