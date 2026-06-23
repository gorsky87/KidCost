# KidCost - plan produktu i architektury

## Decyzja na start

Na pierwsze 30 dni robimy **jedno repozytorium typu monorepo**.

Powody:

- demo po 3 dniach wymaga maksymalnie prostego przeplywu pracy,
- latwiej trzymac aplikacje, migracje bazy, funkcje backendowe i dokumentacje w jednym miejscu,
- mniej konfiguracji CI/CD, sekretow, branchy i synchronizacji,
- szybciej zmieniamy model danych razem z ekranami aplikacji,
- latwiej utrzymac jeden wspolny backlog.

Nie robimy teraz 3 osobnych repozytoriow. Podzial na kilka repo ma sens dopiero wtedy, gdy:

- beda oddzielne zespoly,
- API bedzie publicznym produktem dla partnerow,
- backend urosnie poza Supabase,
- aplikacja webowa i mobile beda mialy niezalezne cykle wydan,
- wymagania security/compliance wymusza osobne uprawnienia.

## Docelowy podzial obszarow

Uzytkowo mamy 4 obszary, ale organizacyjnie na start spinamy je w 3 strumienie pracy.

### 1. Backend i dane

Odpowiada za:

- Supabase Auth,
- PostgreSQL,
- Row Level Security,
- Storage na zdjecia paragonow,
- migracje bazy,
- audit log,
- soft delete,
- backupy i podstawowe zabezpieczenia.

Na MVP backendiem jest Supabase. Nie piszemy osobnego serwera, dopoki nie bedzie realnej potrzeby.

### 2. API i logika domenowa

Odpowiada za:

- kontrakty danych,
- funkcje wyliczania salda,
- walidacje,
- Edge Functions, jesli logika nie powinna siedziec w aplikacji,
- przyszle PDF, OCR, powiadomienia i integracje.

Na MVP aplikacja moze czytac i zapisywac dane przez Supabase SDK, ale logike salda trzymamy jako wydzielony modul, zeby pozniej latwo przeniesc ja do API.

### 3. Aplikacja mobilna i frontend

Priorytetem jest aplikacja mobilna:

- Flutter,
- Android,
- iOS,
- jeden kod dla obu platform,
- szybkie demo przez Google Play Internal Testing i TestFlight.

Frontend webowy na start ograniczamy do minimum:

- landing page,
- privacy policy,
- terms,
- ewentualnie prosta strona supportu.

Nie budujemy pelnego panelu webowego w pierwszych 3 dniach.

## Proponowana struktura repo

```text
KidCost/
  apps/
    mobile/              # Flutter app
    web/                 # landing/support later
  supabase/
    migrations/          # schema DB
    functions/           # Edge Functions
    seed.sql             # dane testowe
  packages/
    domain/              # kalkulacje salda, modele domenowe
    contracts/           # typy/kontrakty API, jesli beda potrzebne
  docs/
    PLAN.md
    PRODUCT.md
    DATA_MODEL.md
    RELEASE.md
  AGENTS.md
```

Na dzis repo moze zawierac tylko `docs/` i potem dokladamy `apps/mobile` oraz `supabase`.

## MVP po 3 dniach

Cel: dzialajace demo, ktore pokazuje realna wartosc, nawet jesli jeszcze nie ma OCR, PDF, kalendarza i zaawansowanych regul.

### Zakres MUST HAVE

- logowanie email/password,
- proste konto rodzica,
- jedno dziecko lub rodzina testowa,
- dodawanie kosztu:
  - kwota,
  - data,
  - kategoria,
  - opis,
  - kto zaplacil,
  - opcjonalne zdjecie paragonu,
- lista kosztow,
- podstawowe saldo 50/50:
  - kto ile wydal,
  - kto komu powinien oddac,
- build Android,
- build iOS,
- publikacja testowa:
  - Google Play Internal Testing,
  - Apple TestFlight.

### Zakres WON'T HAVE w 3 dni

- OCR,
- raporty PDF,
- kalendarz opieki,
- rozbudowane alimenty,
- integracje bankowe,
- AI chat,
- automatyczne przelewy,
- publiczne API,
- skomplikowane spory i workflow akceptacji.

## Plan pierwszych 3 dni

### Dzien 1 - fundament

Produkt:

- potwierdzamy nazwe aplikacji,
- ustalamy 6-8 kategorii kosztow,
- ustalamy podstawowy algorytm 50/50,
- przygotowujemy minimalny tekst privacy policy.

Technicznie:

- inicjalizacja Flutter,
- inicjalizacja Supabase,
- tabele MVP:
  - profiles,
  - families,
  - family_members,
  - children,
  - expenses,
  - expense_attachments,
- podstawowe RLS,
- ekran logowania,
- ekran startowy po zalogowaniu.

Efekt dnia:

- uzytkownik moze sie zalogowac i wejsc do aplikacji.

### Dzien 2 - wartosc produktu

Funkcje:

- formularz dodania kosztu,
- upload zdjecia do Supabase Storage,
- lista kosztow,
- dashboard z suma miesiaca,
- podstawowe saldo 50/50.

Efekt dnia:

- da sie dodac koszty i zobaczyc, kto komu powinien oddac pieniadze.

### Dzien 3 - demo i publikacja testowa

Funkcje:

- poprawki UX,
- empty states,
- obsluga bledow,
- ikona,
- splash screen,
- test danych na czystym koncie.

Release:

- Android package name,
- iOS bundle id,
- screenshoty,
- opis aplikacji,
- privacy policy URL,
- build Android AAB,
- build iOS,
- wysylka do Internal Testing i TestFlight.

Efekt dnia:

- aplikacja jest gotowa do testowania przez link.

## Plan 30 dni

### Dni 1-3 - demo

- logowanie,
- koszty,
- saldo,
- upload zdjecia,
- testowe wydanie mobile.

### Dni 4-7 - stabilizacja MVP

- zapraszanie drugiego rodzica,
- wiele dzieci,
- filtry kosztow,
- status kosztu: oczekuje / zaakceptowany / sporny,
- lepsze RLS,
- Crashlytics,
- podstawowe analytics,
- pierwsze testy automatyczne logiki salda.

### Dni 8-14 - pierwsza wartosc premium

- raport miesieczny,
- eksport CSV,
- prosty PDF,
- historia rozliczen,
- oznaczanie przelewow/wyrownan,
- komentarze do kosztow,
- przypomnienia o zaleglosciach.

### Dni 15-21 - opieka i reguly podzialu

- konfiguracja podzialu 50/50, 70/30 itd.,
- liczba dni opieki,
- podstawowy kalendarz,
- wakacje i dni specjalne,
- algorytm uwzgledniajacy indywidualne proporcje.

### Dni 22-30 - automatyzacja i przygotowanie do platnosci

- OCR paragonow,
- sugestie kategorii,
- raporty roczne,
- audit log widoczny dla uzytkownika,
- model subskrypcji,
- paywall,
- przygotowanie publicznego launchu.

## Priorytet implementacji

1. Model danych i RLS.
2. Flutter shell aplikacji.
3. Auth.
4. Dodawanie kosztu.
5. Lista kosztow.
6. Saldo.
7. Upload zdjecia.
8. Build i publikacja testowa.

To jest kolejnosc krytyczna. Bez niej nie ma demo.

## Minimalny model danych MVP

```text
profiles
  id
  email
  display_name
  created_at

families
  id
  name
  created_by
  created_at

family_members
  id
  family_id
  user_id
  role
  created_at

children
  id
  family_id
  name
  birth_date
  created_at

expenses
  id
  family_id
  child_id
  paid_by
  amount
  currency
  category
  description
  expense_date
  status
  created_at
  updated_at

expense_attachments
  id
  expense_id
  storage_path
  file_type
  created_at
```

## Algorytm salda MVP

Na start tylko 50/50:

```text
suma_wydatkow = suma wszystkich kosztow
udzial_rodzica = suma_wydatkow / 2

saldo_rodzica = ile_zaplacil - udzial_rodzica

jesli tata ma +300, a mama -300:
  mama oddaje tacie 300
```

Pozniej rozszerzamy to do:

- 70/30,
- alimentow,
- dni opieki,
- kosztow indywidualnych,
- kosztow wymagajacych akceptacji.

## Ryzyka

- App Store moze nie zaakceptowac produkcyjnej publikacji w 3 dni. Realny cel to TestFlight.
- Google Play Internal Testing jest bardziej realistyczne niz pelna publiczna publikacja.
- Apple wymaga konta developerskiego i poprawnych danych prawnych.
- OCR i PDF nie powinny wejsc do 3-dniowego demo.
- Dane rodzinne i finansowe sa wrazliwe, wiec RLS i privacy policy musza byc od poczatku.

## Co robimy teraz

Najblizszy praktyczny krok:

1. Utworzyc `apps/mobile` jako Flutter app.
2. Utworzyc projekt Supabase.
3. Spisac migracje bazy MVP.
4. Podlaczyc auth.
5. Zrobic pierwszy ekran logowania i pusty dashboard.

Po tym mozemy isc ekran po ekranie do dzialajacego demo.
