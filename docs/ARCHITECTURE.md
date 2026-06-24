# KidCost - architecture

Data: 2026-06-23

## Status decyzji

Na pierwsze 30 dni KidCost jest budowany jako jedno repozytorium typu monorepo.

Ta decyzja jest swiadoma i tymczasowa. Priorytetem jest szybkie dowiezienie bety, latwe zmiany modelu danych oraz jeden wspolny backlog dla backendu, API/domeny, frontendu, UX i release.

## Dlaczego monorepo

- Jeden commit moze zmienic model danych, kontrakt domenowy i ekran aplikacji razem.
- Latwiej utrzymac spojna dokumentacje produktu, architektury i release.
- Mniej konfiguracji na poczatku: CI, sekrety, branche, uprawnienia i review.
- Mniej ryzyka, ze aplikacja mobilna i schema bazy rozjada sie przed beta.
- Automatyczne workery moga pracowac na jednym backlogu i jednym repo.

## Docelowa struktura repo

```text
KidCost/
  apps/
    mobile/              # Flutter app dla Android/iOS
    web/                 # landing, privacy policy, terms, support
  supabase/
    migrations/          # migracje PostgreSQL
    functions/           # Supabase Edge Functions
    seed.sql             # dane demo/testowe
  packages/
    domain/              # logika domenowa, np. saldo i reguly podzialu
    contracts/           # wspolne typy/kontrakty, jesli beda potrzebne
  docs/
    ARCHITECTURE.md
    PLAN.md
    PL_MONTHLY_REPORTS.md
    ROADMAP_30_DAYS.md
    SECURITY.md
    SUBSCRIPTIONS.md
    DATA_MODEL.md
    RELEASE.md
  AGENTS.md
```

## Kiedy tworzyc katalogi

Nie tworzymy pustych katalogow tylko po to, aby pasowaly do diagramu. Katalog powstaje, gdy pierwsze zadanie realnie potrzebuje kodu albo dokumentu w tym obszarze.

- `apps/mobile` powstaje przy inicjalizacji Fluttera.
- `apps/web` powstaje przy privacy/support/landing.
- `supabase/migrations` powstaje przy pierwszym schemacie bazy.
- `supabase/functions` powstaje przy pierwszej funkcji backendowej poza prostym CRUD przez Supabase SDK.
- `packages/domain` powstaje przy pierwszej implementacji logiki salda.
- `packages/contracts` powstaje dopiero, gdy kontrakty zaczna byc uzywane przez wiecej niz jeden modul.

## Strumienie pracy i odpowiedzialnosci

### Backend i dane

Miejsce pracy:

- `supabase/migrations`
- `supabase/functions`
- `supabase/seed.sql`
- dokumenty `docs/DATA_MODEL.md` i `docs/SECURITY.md`, jesli powstana

Odpowiedzialnosc:

- Supabase Auth,
- PostgreSQL schema,
- Row Level Security,
- Storage dla paragonow i faktur,
- migracje,
- seed danych demo,
- audit log,
- soft delete,
- podstawowe backupy i zabezpieczenia.

Backend nie powinien implementowac logiki UI ani copy produktowego.

### API i domena

Miejsce pracy:

- `packages/domain`
- `packages/contracts`
- `supabase/functions`, gdy logika musi byc wykonywana po stronie backendu

Odpowiedzialnosc:

- algorytm salda,
- reguly podzialu kosztow,
- walidacje domenowe,
- statusy kosztow,
- kontrakty danych,
- przyszle generowanie raportow,
- przyszly OCR pipeline.

Logika salda nie moze byc zaszyta wylacznie w widgetach UI. Minimalny day-3 wariant moze byc uruchamiany przez aplikacje, ale musi byc wydzielony tak, aby pozniej mozna bylo przeniesc lub wspoldzielic go z API bez przepisywania ekranu.

### Aplikacja mobilna i frontend

Miejsce pracy:

- `apps/mobile`
- `apps/web`

Odpowiedzialnosc:

- Flutter app dla Android/iOS,
- auth screens,
- onboarding,
- dashboard,
- formularze kosztow,
- lista kosztow,
- widok salda,
- kalendarz,
- raporty,
- strony privacy/support/terms.

Frontend moze korzystac z Supabase SDK w MVP, ale nie powinien duplikowac reguly salda w wielu ekranach.

### Release i operacje

Miejsce pracy:

- `docs/RELEASE.md`
- konfiguracja w `apps/mobile`
- konfiguracja CI/CD, gdy zostanie dodana

Odpowiedzialnosc:

- package name Android,
- bundle id iOS,
- signing,
- buildy,
- TestFlight,
- Google Play Internal Testing,
- Crashlytics,
- analytics,
- smoke test checklist.

## Decyzje produktowe przekrojowe

Tematy, ktore przecinaja backend, frontend, UX i release, zapisujemy jako osobne dokumenty decyzyjne w `docs/`.

Aktualnie dotyczy to szczegolnie:

- `docs/SUBSCRIPTIONS.md` dla entitlementow, downgrade, fee waiver i zasad dostepu po wygasnieciu Premium.
- `docs/PL_MONTHLY_REPORTS.md` dla miesiecznego kosztorysu dziecka, polskich zalozen raportowych oraz granicy miedzy ledgerem a kontekstem uzytkownika.

## Granice zaleznosci

Dozwolony przeplyw:

```text
apps/mobile -> packages/domain
apps/mobile -> packages/contracts
apps/mobile -> Supabase SDK
supabase/functions -> packages/domain, jesli runtime na to pozwala
supabase/functions -> packages/contracts
packages/domain -> brak zaleznosci od UI
packages/contracts -> brak zaleznosci od UI i Supabase runtime
```

Zasady:

- `packages/domain` ma byc testowalne bez aplikacji mobilnej.
- `packages/domain` nie moze importowac Fluttera ani komponentow UI.
- `apps/mobile` moze formatowac wynik dla ekranu, ale nie powinno byc jedynym miejscem prawdy dla obliczen.
- Kontrakty miedzy aplikacja i backendem powinny byc jawne, gdy tylko pojawia sie Edge Functions albo publiczniejsze API.
- Decyzje architektoniczne utrwalamy w `docs/ARCHITECTURE.md` albo osobnym ADR, jezeli temat jest duzy.

## Srodowiska

### Local

Do pracy deweloperskiej. Moze korzystac z lokalnej konfiguracji Supabase CLI albo z projektu dev, zaleznosci od aktualnego etapu.

### Dev

Wspolne srodowisko dla automatycznych workerow, testerow technicznych i integracji. Dane moga byc resetowane.

### Prod

Srodowisko dla TestFlight, Google Play Internal Testing i pozniejszych uzytkownikow. Nie uzywamy go do eksperymentow lokalnych.

## Konfiguracja i sekrety

- Sekretow nie commitujemy.
- Pliki `.env`, `.env.local`, klucze prywatne, tokeny i lokalne konfiguracje powinny byc ignorowane przez Git, gdy tylko pojawia sie aplikacja lub backend.
- Do repo mozna commitowac tylko przyklady bez sekretow, np. `.env.example`.
- Supabase anon key moze byc traktowany jako konfiguracja klienta, ale service role key nigdy nie moze trafic do aplikacji mobilnej ani repo.
- Sekrety release, signing i CI powinny byc trzymane w narzedziach platformy, nie w plikach projektu.

## Kontrakty danych

Na poczatku aplikacja moze pracowac bez osobnego pakietu kontraktow, bo schema jest mala.

`packages/contracts` tworzymy, gdy:

- Edge Functions zaczna zwracac struktury uzywane przez Fluttera,
- raporty beda mialy wspolny format,
- OCR bedzie mial wynik wymagajacy potwierdzenia w aplikacji,
- kilka modulow zacznie powielac typy statusow, kategorii albo konfiguracji splitu.

Kontrakty versionujemy w praktyce przez:

- migracje bazy,
- testy domenowe,
- notatke w `docs/DATA_MODEL.md`,
- changelog lub ADR, gdy zmiana lamie stary format.

## Workflow pracy

- Kazde zadanie robimy w osobnym Git worktree i branchu `codex/issue-<number>-<slug>`.
- Nie pracujemy bezposrednio na `master`, poza jawnym setupem repo.
- Zmiany w kodzie wymagaja sensownych testow.
- Bugfixy i zmiany zachowania wymagaja testow regresji.
- Merge do `master` nastepuje dopiero po przejsciu testow albo jawnej weryfikacji, jezeli zmiana jest tylko dokumentacyjna.
- Po merge'u pushujemy `master` i zamykamy albo komentujemy GitHub issue.

## Kiedy wydzielic osobne repozytoria

Wracamy do decyzji o podziale repo dopiero po becie albo przy wyraznym sygnale organizacyjnym.

Podzial ma sens, gdy wystapi co najmniej kilka z tych warunkow:

- backend ma osobny zespol i osobny rytm release,
- API staje sie publicznym produktem dla partnerow,
- aplikacja webowa staje sie pelnoprawnym produktem, nie tylko support/landing,
- backend wychodzi poza Supabase i wymaga osobnej infrastruktury,
- compliance/security wymaga rozdzielenia uprawnien i historii zmian,
- mobile, web i backend maja niezalezne wersjonowanie,
- liczba konfliktow w monorepo realnie spowalnia prace.

Nie dzielimy repo tylko dlatego, ze mamy oddzielne role w zespole. Role pracuja w oddzielnych katalogach i worktree, ale w ramach jednego backlogu.

## ADR-001: monorepo na pierwsze 30 dni

### Decyzja

KidCost startuje jako monorepo.

### Konsekwencje pozytywne

- szybszy start,
- mniej konfiguracji,
- latwiejsze zmiany przekrojowe,
- jedna dokumentacja i jeden backlog,
- prostsza praca automatycznych workerow.

### Konsekwencje negatywne

- trzeba pilnowac granic modulow,
- branch/worktree workflow jest obowiazkowy,
- wieksze zmiany moga konfliktowac, jesli role pracuja w tych samych dokumentach,
- w przyszlosci moze byc potrzebna migracja do kilku repo.

### Rewizja decyzji

Decyzje sprawdzamy ponownie po day-30 beta albo po pierwszym realnym problemie organizacyjnym, ktory monorepo utrudnia zamiast ulatwiac.
