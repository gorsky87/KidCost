# KidCost - MVP data model i kontrakty domenowe

Data: 2026-06-23
Zakres: issue #3

## Cel

Ten dokument zamyka minimalny model danych dla day-3 demo KidCost.

Model ma obsluzyc:

- jedna rodzine w MVP, ale bez blokowania wielu rodzin per system,
- dwoch rodzicow we wspolnej rodzinie,
- wiele dzieci w rodzinie,
- dodawanie kosztu bez OCR,
- dolaczanie zdjecia albo PDF do kosztu,
- obliczanie salda 50/50 bez osobnej tabeli rozliczen salda.

## Zasady projektowe

1. Kazdy rekord finansowy nalezy do `family_id`, bo to jest granica dostepu i RLS.
2. Koszt moze byc przypisany do jednego dziecka albo do calej rodziny, dlatego `child_id` pozostaje opcjonalne.
3. Saldo day-3 liczymy z tabeli `expenses`, a nie z materializowanej tabeli bilansu.
4. Zalacznik jest osobnym rekordem, aby koszt mogl istniec bez paragonu oraz miec wiecej niz jeden plik w przyszlosci.
5. Kontrakty domenowe maja byc przenoszalne do `packages/domain` i ewentualnie `packages/contracts`, ale na tym etapie wystarcza decyzje w dokumentacji.

## Encje MVP

### `profiles`

Mapuje konto Supabase Auth na profil produktu.

| Pole | Typ | Wymagane | Uwagi |
| --- | --- | --- | --- |
| `id` | `uuid` | tak | PK. To samo `uuid`, co `auth.users.id`. |
| `display_name` | `text` | tak | Widoczne imie/nazwa rodzica w aplikacji. |
| `email` | `text` | tak | Kopia do wyswietlania i wyszukiwania zaproszen. |
| `avatar_url` | `text` | nie | Opcjonalne. Nie blokuje MVP. |
| `created_at` | `timestamptz` | tak | Domyslnie `now()`. |
| `updated_at` | `timestamptz` | tak | Aktualizowane przy zmianach profilu. |

### `families`

Logiczny kontener na dzieci, koszty i czlonkow wspolnej rodziny.

| Pole | Typ | Wymagane | Uwagi |
| --- | --- | --- | --- |
| `id` | `uuid` | tak | PK. |
| `name` | `text` | tak | Nazwa robocza rodziny, np. `Rodzina Kowalskich`. |
| `created_by` | `uuid` | tak | FK -> `profiles.id`. Autor zalozenia rodziny. |
| `default_currency` | `text` | tak | Domyslnie `PLN`. |
| `created_at` | `timestamptz` | tak | Domyslnie `now()`. |
| `updated_at` | `timestamptz` | tak | Aktualizowane przy zmianach rodziny. |

### `family_members`

Laczy profile z rodzina i ustala role w rodzinie.

| Pole | Typ | Wymagane | Uwagi |
| --- | --- | --- | --- |
| `id` | `uuid` | tak | PK. |
| `family_id` | `uuid` | tak | FK -> `families.id`. |
| `profile_id` | `uuid` | tak | FK -> `profiles.id`. |
| `role` | `family_member_role` | tak | MVP: `parent`. Pole zostaje jako enum pod przyszle role. |
| `status` | `membership_status` | tak | `active`, `invited`, `revoked`. MVP pozwala zaczac od `active`. |
| `joined_at` | `timestamptz` | nie | Ustawiane po dolaczeniu do rodziny. |
| `created_at` | `timestamptz` | tak | Domyslnie `now()`. |
| `updated_at` | `timestamptz` | tak | Aktualizowane przy zmianach czlonkostwa. |

Ograniczenia:

- unikalnosc `family_id + profile_id`,
- w MVP jedna rodzina powinna miec maksymalnie 2 aktywnych rodzicow jako regula aplikacyjna lub follow-up constraint,
- tylko `active` czlonek rodziny widzi dane finansowe tej rodziny.

### `children`

Dzieci nalezace do rodziny.

| Pole | Typ | Wymagane | Uwagi |
| --- | --- | --- | --- |
| `id` | `uuid` | tak | PK. |
| `family_id` | `uuid` | tak | FK -> `families.id`. |
| `first_name` | `text` | tak | Imie dziecka. |
| `birth_date` | `date` | nie | Opcjonalne w MVP. |
| `is_active` | `boolean` | tak | Domyslnie `true`. Bez twardego kasowania historii kosztow. |
| `created_at` | `timestamptz` | tak | Domyslnie `now()`. |
| `updated_at` | `timestamptz` | tak | Aktualizowane przy zmianach dziecka. |

### `expenses`

Centralna tabela kosztow dziecka lub calej rodziny.

| Pole | Typ | Wymagane | Uwagi |
| --- | --- | --- | --- |
| `id` | `uuid` | tak | PK. |
| `family_id` | `uuid` | tak | FK -> `families.id`. |
| `child_id` | `uuid` | nie | FK -> `children.id`. `NULL` oznacza koszt rodzinny lub jeszcze nieprzypisany do dziecka. |
| `paid_by` | `uuid` | tak | FK -> `profiles.id`. Rodzic, ktory zaplacil. |
| `payer_kind` | `expense_payer_kind` | tak | `profile` dla konta uzytkownika albo `manual_label` dla trybu solo. |
| `manual_payer_label` | `text` | nie | Reczna etykieta drugiego rodzica, gdy nie ma jeszcze konta. |
| `amount` | `numeric(12,2)` | tak | Constraint `amount > 0`. |
| `currency` | `text` | tak | Domyslnie `PLN`. |
| `category` | `expense_category` | tak | Enum MVP. |
| `description` | `text` | nie | Opcjonalny opis kosztu. |
| `expense_date` | `date` | tak | Data kosztu. |
| `status` | `expense_status` | tak | Domyslnie `pending`. |
| `visibility` | `expense_visibility` | tak | `private_author` dla kosztu solo albo `shared_family` dla kosztu wspolnego. |
| `created_by` | `uuid` | tak | FK -> `profiles.id`. Autor rekordu. |
| `updated_by` | `uuid` | nie | Ostatni edytujacy. |
| `shared_at` | `timestamptz` | nie | Ustawiane przy jawnym udostepnieniu kosztu solo rodzinie. |
| `shared_by` | `uuid` | nie | FK -> `profiles.id`. Uzytkownik, ktory udostepnil koszt solo. |
| `created_at` | `timestamptz` | tak | Domyslnie `now()`. |
| `updated_at` | `timestamptz` | tak | Aktualizowane przy zmianach kosztu. |

Ograniczenia:

- `family_id` musi nalezec do rodziny, ktorej czlonkiem jest `paid_by`,
- jesli `child_id` nie jest `NULL`, dziecko musi nalezec do tej samej rodziny co koszt,
- `paid_by` i `created_by` musza byc czlonkami tej samej rodziny,
- dla `payer_kind = manual_label` pole `paid_by` jest puste, a `manual_payer_label` jest niepuste,
- `private_author` widzi tylko autor kosztu, nawet jezeli drugi rodzic dolaczy pozniej do rodziny,
- `status` steruje tym, czy rekord mozna jeszcze edytowac bez tworzenia korekty lub audit eventu.

## Tryb solo i mapowanie platnika

Tryb solo pozwala jednemu rodzicowi zaczac dokumentowac koszty przed akceptacja
zaproszenia przez drugiego rodzica. To nie tworzy technicznego konta dla
drugiego rodzica i nie nadaje mu automatycznie dostepu do prywatnych wpisow.

Zasady:

1. Rodzina moze miec koszty `private_author`, ktore sa widoczne tylko dla
   `created_by`.
2. Jezeli koszt wpisuje platnosc drugiego rodzica bez konta, uzywa
   `payer_kind = manual_label` oraz `manual_payer_label`, a `paid_by` pozostaje
   puste.
3. Po akceptacji zaproszenia nie mapujemy automatycznie wszystkich kosztow
   `manual_label` na nowy profil. Aplikacja pokazuje uzytkownikowi liste
   kosztow solo i wymaga jawnego potwierdzenia udostepnienia.
4. Udostepnienie kosztu zmienia `visibility` na `shared_family`, ustawia
   `shared_at` i `shared_by`, ale prywatne notatki autora pozostaja poza
   zakresem udostepnienia, dopoki nie powstanie osobna zgoda i model notatek.
5. RLS dla `private_author` musi sprawdzac `created_by = auth.uid()`, a nie
   samo aktywne czlonkostwo w rodzinie.

### `expense_attachments`

Metadane plikow dolaczonych do kosztu.

| Pole | Typ | Wymagane | Uwagi |
| --- | --- | --- | --- |
| `id` | `uuid` | tak | PK. |
| `expense_id` | `uuid` | tak | FK -> `expenses.id`. |
| `storage_path` | `text` | tak | Np. `family_id/expense_id/file_id.ext`. |
| `file_type` | `attachment_file_type` | tak | MVP: `jpg`, `jpeg`, `png`, `pdf`. |
| `original_filename` | `text` | nie | Do wygodniejszego preview i supportu. |
| `uploaded_by` | `uuid` | tak | FK -> `profiles.id`. |
| `created_at` | `timestamptz` | tak | Domyslnie `now()`. |

Ograniczenia:

- rekord nie istnieje bez kosztu,
- dostep do pliku wynika z czlonkostwa w rodzinie powiazanej z kosztem,
- MVP nie wymaga OCR ani ekstrakcji danych z pliku.

## Relacje

```text
profiles 1 --- * family_members * --- 1 families
families 1 --- * children
families 1 --- * expenses
children 1 --- * expenses
profiles 1 --- * expenses (paid_by)
profiles 1 --- * expenses (created_by / updated_by)
expenses 1 --- * expense_attachments
profiles 1 --- * expense_attachments (uploaded_by)
```

Zasady spojnosci:

- `children.family_id` musi byc rowne `expenses.family_id`, jezeli `expenses.child_id` jest ustawione,
- zalacznik dziedziczy granice dostepu z kosztu i rodziny,
- user moze nalezec do wielu rodzin w systemie, ale day-3 demo nie musi jeszcze eksponowac przechodzenia miedzy nimi w UI.

## Enumy MVP

### `family_member_role`

- `parent`

Uwagi:

- enum od razu pozwala na przyszle role typu `guardian`, `viewer`, `professional`, ale nie dodajemy ich do MVP.

### `membership_status`

- `invited`
- `active`
- `revoked`

Uwagi:

- dla day-3 demo mozna zaczac od `active` i dopiero potem rozbudowac flow zaproszen.

### `expense_status`

- `pending`
- `accepted`
- `disputed`
- `settled`

Znaczenie:

- `pending`: koszt dodany, czeka na reakcje drugiego rodzica,
- `accepted`: koszt zostal zaakceptowany,
- `disputed`: koszt jest zakwestionowany, ale rekord i dowody pozostaja widoczne,
- `settled`: koszt albo grupa kosztow zostala wyrownana poza systemem lub przez osobny workflow.

### `expense_payer_kind`

- `profile`
- `manual_label`

### `expense_visibility`

- `private_author`
- `shared_family`

### `expense_category`

- `food`
- `clothing`
- `school`
- `health`
- `activities`
- `vacation`
- `transport`
- `other`

### `attachment_file_type`

- `jpg`
- `jpeg`
- `png`
- `pdf`

## Minimalne kontrakty domenowe

To nie jest jeszcze osobny pakiet, ale kontrakty sa juz jawne.

### Contract: `ExpenseInput`

```text
ExpenseInput {
  family_id: uuid
  child_id: uuid | null
  paid_by: uuid | null
  payer_kind: "profile" | "manual_label"
  manual_payer_label: string | null
  amount: decimal(12,2)
  currency: "PLN" | future currency code
  category: expense_category
  description: string | null
  expense_date: date
  visibility: "private_author" | "shared_family"
}
```

### Contract: `ExpenseAttachmentInput`

```text
ExpenseAttachmentInput {
  expense_id: uuid
  storage_path: string
  file_type: attachment_file_type
  original_filename: string | null
}
```

### Contract: `BalanceComputationInput`

```text
BalanceComputationInput {
  family_id: uuid
  expenses: Expense[]
  split_rule: "equal_50_50"   # MVP
}
```

### Contract: `BalanceComputationResult`

```text
BalanceComputationResult {
  total_amount: decimal
  spend_per_parent: Record<profile_id, decimal>
  target_share_per_parent: Record<profile_id, decimal>
  transfer_direction: {
    from_profile_id: uuid
    to_profile_id: uuid
    amount: decimal
  } | null
}
```

MVP day-3:

- saldo 50/50 liczymy z kosztow o statusie jawnie wlaczonym do rozliczen,
- nie tworzymy osobnej tabeli `balances`,
- nie tworzymy jeszcze tabeli `settlements`, dopoki nie pojawi sie osobny flow wyrownan.

## Jak saldo 50/50 dziala bez dodatkowych tabel

1. Pobieramy koszty z jednej rodziny.
2. Filtrujemy statusy zgodnie z regula domenowa. MVP moze zaczac od `pending`, `accepted` i `settled`, a temat `disputed` doprecyzowac w issue statusowym.
3. Sumujemy wydatki per `paid_by` albo per `manual_payer_label`, jezeli koszt
   jest jeszcze kosztem solo bez konta drugiego rodzica.
4. Dzielimy sume kosztow przez liczbe rodzicow objetych splitem.
5. Porownujemy realny wydatek z docelowym udzialem.
6. Zwracamy jedna kwote wyrownania i kierunek transferu.

To wystarcza dla demo:

- jedna rodzina,
- dwoch rodzicow,
- wiele dzieci,
- brak potrzeby przechowywania zdenormalizowanego bilansu.

## Decyzje odlozone poza MVP

Tych elementow swiadomie nie modelujemy teraz:

- `ocr_results` lub tabela ekstrakcji danych z paragonow,
- `payment_provider_transactions`,
- konta lub role dla mediatorow, prawnikow i innych profesjonalistow,
- `messages`, `chat_threads` albo komentarze ogolne niezwiazane ze sporem,
- automatyczne rozliczenia bankowe,
- wielowalutowosc poza techniczna mozliwoscia pola `currency`,
- osobna tabela `balance_snapshots`,
- osobna tabela `reports`.

Powod:

- kazdy z tych tematow zwieksza model i ryzyko bez poprawy day-3 demo,
- obecny zakres wystarcza do auth, rodziny, dziecka, kosztu, zalacznika i salda 50/50.

## Otwarte decyzje follow-up

1. Czy `disputed` koszt liczy sie do salda natychmiast, czy dopiero po rozstrzygnieciu.
2. Czy `family_members.status` ma byc juz w pierwszej migracji, czy dopiero razem z issue o zaproszeniach.
3. Czy ograniczenie do 2 aktywnych rodzicow egzekwujemy w bazie, czy na poziomie backendu.
4. Czy `description` ma byc calkowicie opcjonalne, czy wymagane dla kategorii `other`.
5. Czy `settled` dotyczy pojedynczego kosztu, czy przyszlej grupy kosztow i wtedy wymaga dodatkowej tabeli.
