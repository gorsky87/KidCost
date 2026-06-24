# KidCost - security model

Data: 2026-06-24

## Cel

Ten dokument opisuje minimalny model bezpieczenstwa i prywatnosci dla MVP KidCost.

KidCost przechowuje dane rodzinne, finansowe, zalaczniki i historie decyzji miedzy rodzicami albo opiekunami. Dane nie powinny byc publiczne, latwe do przypadkowego usuniecia ani widoczne dla osob spoza rodziny.

## Zasada podstawowa

Dostep do danych rodziny wynika z aktywnego czlonkostwa w `family_members`.

Uzytkownik moze widziec albo zmieniac dane powiazane z `family_id` tylko wtedy, gdy istnieje aktywny rekord:

```sql
exists (
  select 1
  from family_members fm
  where fm.family_id = <table>.family_id
    and fm.user_id = auth.uid()
    and fm.status = 'active'
)
```

Wyjatkiem sa dane wlasnego profilu, zaproszenia oczekujace na przyjecie oraz administracyjne operacje wykonywane przez backend z service role key.

## Role i granice dostepu

### User

Zalogowany uzytkownik Supabase Auth. Moze czytac i aktualizowac swoj `profiles` rekord oraz dane rodzin, w ktorych ma aktywne czlonkostwo.

### Family member

Aktywny czlonek rodziny. Moze widziec dzieci, koszty, zalaczniki, rozliczenia i audit log tej rodziny zgodnie z rola.

Minimalne role MVP:

- `owner` - zalozyciel rodziny, zarzadza zaproszeniami i czlonkami.
- `parent` - rodzic albo opiekun, dodaje koszty, zalaczniki i rozliczenia.
- `viewer` - ograniczony dostep do odczytu, przyszlosciowo dla mediatora, prawnika albo eksportu.

### Service role

Klucz backendowy do migracji, zadan administracyjnych, edge functions i supportu technicznego. Nigdy nie trafia do aplikacji mobilnej, webowej ani repozytorium.

## Tabele MVP i RLS

Nazwy tabel odpowiadaja planowanemu modelowi MVP. Jezeli schema zmieni nazwy kolumn, zasady ponizej nalezy zaktualizowac razem z migracja.

### profiles

Cel: dane konta aplikacyjnego powiazane z `auth.users`.

Zasady:

- `select`: uzytkownik widzi swoj profil oraz profile aktywnych czlonkow swoich rodzin.
- `insert`: uzytkownik moze utworzyc tylko profil z `id = auth.uid()`.
- `update`: uzytkownik moze aktualizowac tylko swoj profil.
- `delete`: brak fizycznego delete w MVP; uzywamy statusu albo procedury usuniecia konta.

Przykladowe policy:

```sql
create policy "profiles_read_self_or_family"
on profiles for select
using (
  id = auth.uid()
  or exists (
    select 1
    from family_members me
    join family_members other on other.family_id = me.family_id
    where me.user_id = auth.uid()
      and me.status = 'active'
      and other.user_id = profiles.id
      and other.status = 'active'
  )
);

create policy "profiles_update_self"
on profiles for update
using (id = auth.uid())
with check (id = auth.uid());
```

### families

Cel: kontener danych wspolnej rodziny.

Zasady:

- `select`: tylko aktywni czlonkowie rodziny.
- `insert`: zalogowany uzytkownik moze utworzyc rodzine, a backend musi utworzyc dla niego `family_members` jako `owner`.
- `update`: tylko aktywny `owner` albo przyszla funkcja backendowa z kontrola uprawnien.
- `delete`: brak fizycznego delete w MVP; rodzina moze miec status `archived`.

Przykladowe policy:

```sql
create policy "families_read_members"
on families for select
using (
  exists (
    select 1
    from family_members fm
    where fm.family_id = families.id
      and fm.user_id = auth.uid()
      and fm.status = 'active'
  )
);

create policy "families_update_owner"
on families for update
using (
  exists (
    select 1
    from family_members fm
    where fm.family_id = families.id
      and fm.user_id = auth.uid()
      and fm.role = 'owner'
      and fm.status = 'active'
  )
);
```

### family_members

Cel: laczy uzytkownikow z rodzina i jest glownym zrodlem autoryzacji.

Zasady:

- `select`: aktywni czlonkowie widza liste czlonkow swojej rodziny.
- `insert`: tylko owner albo kontrolowana funkcja zaproszenia.
- `update`: owner moze zmienic role/status innych czlonkow; uzytkownik moze opuscic rodzine przez status `inactive`.
- `delete`: brak fizycznego delete w MVP; status zostaje do audytu.

Przykladowe policy:

```sql
create policy "family_members_read_same_family"
on family_members for select
using (
  exists (
    select 1
    from family_members me
    where me.family_id = family_members.family_id
      and me.user_id = auth.uid()
      and me.status = 'active'
  )
);
```

### children

Cel: profile dzieci w rodzinie.

Zasady:

- `select`: tylko aktywni czlonkowie rodziny.
- `insert`: aktywny `owner` albo `parent`.
- `update`: aktywny `owner` albo `parent`; zmiany istotnych danych powinny generowac audit event.
- `delete`: soft delete przez `deleted_at`; rekordy historyczne pozostaja powiazane z kosztami.

Przykladowe policy:

```sql
create policy "children_read_family"
on children for select
using (
  exists (
    select 1
    from family_members fm
    where fm.family_id = children.family_id
      and fm.user_id = auth.uid()
      and fm.status = 'active'
  )
);

create policy "children_write_parent"
on children for all
using (
  exists (
    select 1
    from family_members fm
    where fm.family_id = children.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'parent')
      and fm.status = 'active'
  )
)
with check (
  exists (
    select 1
    from family_members fm
    where fm.family_id = children.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'parent')
      and fm.status = 'active'
  )
);
```

### expenses

Cel: koszty dziecka, statusy i zasady podzialu.

Zasady:

- `select`: tylko aktywni czlonkowie rodziny.
- `insert`: aktywny `owner` albo `parent`; `created_by` musi byc `auth.uid()`.
- `update`: aktywny `owner` albo `parent`, ale po statusie `accepted` albo `disputed` nie wolno nadpisywac kwoty, waluty, daty, platnika, dziecka ani splitu bez sladu.
- `delete`: soft delete przez `deleted_at`, tylko dla kosztow roboczych albo blednych duplikatow; zaakceptowany lub sporny koszt nie znika bez audit eventu i wpisu korygujacego.

Przykladowe policy:

```sql
create policy "expenses_read_family"
on expenses for select
using (
  exists (
    select 1
    from family_members fm
    where fm.family_id = expenses.family_id
      and fm.user_id = auth.uid()
      and fm.status = 'active'
  )
);

create policy "expenses_insert_parent"
on expenses for insert
with check (
  created_by = auth.uid()
  and exists (
    select 1
    from family_members fm
    where fm.family_id = expenses.family_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'parent')
      and fm.status = 'active'
  )
);
```

Ograniczenie niezmiennosci zaakceptowanych i spornych kosztow powinno byc dodatkowo egzekwowane triggerem albo funkcja RPC, bo sama policy RLS nie porownuje wygodnie wartosci `old` i `new`.

Minimalny trigger logiczny:

- koszt `draft` albo `pending` mozna poprawic,
- koszt `accepted` albo `disputed` moze dostac komentarz, zalacznik, status rozliczenia albo korekte przez nowy rekord,
- pola finansowe i dowodowe kosztu zaakceptowanego/spornego wymagaja `audit_events` oraz rekordu korekty, nie cichego nadpisania.

### expense_attachments

Cel: metadane zalacznikow powiazanych z kosztem.

Zasady:

- `select`: tylko aktywni czlonkowie rodziny kosztu.
- `insert`: aktywny `owner` albo `parent`, tylko dla kosztu z tej samej rodziny.
- `update`: ograniczone do opisu, statusu skanowania albo soft delete.
- `delete`: soft delete; fizyczne usuniecie pliku tylko przez kontrolowana funkcje backendowa po sprawdzeniu retencji i audit logu.

Przykladowe policy:

```sql
create policy "attachments_read_family"
on expense_attachments for select
using (
  exists (
    select 1
    from expenses e
    join family_members fm on fm.family_id = e.family_id
    where e.id = expense_attachments.expense_id
      and fm.user_id = auth.uid()
      and fm.status = 'active'
  )
);

create policy "attachments_insert_parent"
on expense_attachments for insert
with check (
  uploaded_by = auth.uid()
  and exists (
    select 1
    from expenses e
    join family_members fm on fm.family_id = e.family_id
    where e.id = expense_attachments.expense_id
      and fm.user_id = auth.uid()
      and fm.role in ('owner', 'parent')
      and fm.status = 'active'
  )
);
```

## Supabase Storage

Zalaczniki kosztow powinny byc trzymane w prywatnym bucketcie, np. `expense-attachments`.

Rekomendowana sciezka:

```text
families/<family_id>/expenses/<expense_id>/<attachment_id>.<ext>
```

Minimalne ograniczenia uploadu:

- bucket prywatny, bez publicznych URL-i,
- typy plikow: `image/jpeg`, `image/png`, `application/pdf`,
- maksymalny rozmiar pojedynczego pliku: 10 MB w MVP,
- maksymalnie 5 zalacznikow na koszt w MVP,
- upload tylko przez aktywnego `owner` albo `parent` rodziny,
- odczyt tylko dla aktywnych czlonkow rodziny,
- metadane pliku musza miec rekord w `expense_attachments`,
- aplikacja powinna usuwac albo ignorowac metadane lokalizacji EXIF przed uploadem, gdy platforma na to pozwala.

Przykladowa zasada odczytu dla storage powinna sprawdzac, czy `family_id` ze sciezki nalezy do aktywnej rodziny uzytkownika. Jezeli RLS na `storage.objects` robi sie zbyt zlozony, upload i podpisane URL-e powinny isc przez Edge Function z jedna wspolna walidacja.

## Soft delete

W MVP nie usuwamy fizycznie danych rodzinnych, kosztow i zalacznikow z poziomu aplikacji.

Minimalny wzorzec:

- `deleted_at timestamptz null`,
- `deleted_by uuid null`,
- `delete_reason text null`,
- domyslne widoki i zapytania ukrywaja rekordy z `deleted_at`,
- audit event zapisuje kto, kiedy i dlaczego ukryl rekord.

Koszt w statusie `accepted`, `disputed` albo powiazany z rozliczeniem nie moze zniknac z historii bez sladu. Poprawka powinna powstac jako nowy wpis korygujacy albo status zmieniony w kontrolowanym workflow.

## Audit log MVP

Minimalna tabela `audit_events` powinna byc append-only dla aplikacji.

Minimalne pola:

- `id`,
- `family_id`,
- `actor_user_id`,
- `event_type`,
- `entity_type`,
- `entity_id`,
- `created_at`,
- `metadata jsonb`.

Minimalne typy zdarzen:

- `created`,
- `updated`,
- `status_changed`,
- `attachment_added`,
- `settlement_added`.

Dodatkowe zdarzenia rekomendowane po MVP:

- `soft_deleted`,
- `correction_added`,
- `member_invited`,
- `member_role_changed`,
- `export_generated`,
- `support_access_started`,
- `support_access_ended`.

Uzytkownik powinien widziec najwazniejsze zdarzenia zwiazane z kosztem albo rozliczeniem prostym jezykiem, bez wymagania znajomosci logow technicznych.

## Edycja po akceptacji kosztu

Koszt zaakceptowany albo sporny jest czescia wspolnej historii rodziny.

Mozna nadal dodac:

- komentarz,
- zalacznik uzupelniajacy,
- status rozliczenia,
- wpis wyrownania,
- nowy koszt korygujacy.

Nie wolno cicho nadpisac:

- kwoty,
- waluty,
- daty kosztu,
- platnika,
- dziecka,
- podzialu kosztu,
- pierwotnego dowodu.

Zmiana tych pol wymaga jawnej korekty, audit eventu i UI, ktore pokazuje, ze historia zostala poprawiona, a nie ukryta.

## Wymagania do privacy policy

Polityka prywatnosci musi jasno mowic:

- jakie dane konta, rodziny, dzieci, kosztow, rozliczen i zalacznikow sa przetwarzane,
- ze dane rodzinne nie sa publiczne i domyslnie widza je tylko aktywni czlonkowie rodziny,
- ze zalaczniki moga zawierac dane wrazliwe uzytkowo, np. informacje medyczne, szkolne albo lokalizacyjne na paragonach,
- ze KidCost nie sprzedaje danych rodzinnych do reklam behawioralnych,
- czy i kiedy zespol techniczny moze uzyskac ograniczony dostep supportowy,
- jakie sa zasady eksportu, poprawiania i usuwania danych,
- ze usuniecie konta moze nie oznaczac cichego usuniecia zaakceptowanej historii rozliczen drugiego rodzica,
- ze pelne end-to-end encryption nie jest obiecywane, dopoki nie zostanie wdrozone dla danych i zalacznikow.

## Minimalna lista przed wdrozeniem

Przed pierwsza beta:

- RLS wlaczone na wszystkich tabelach rodzinnych.
- Brak service role key w aplikacji, repo i logach klienta.
- Prywatny bucket zalacznikow.
- Limity typu i rozmiaru uploadu.
- Soft delete dla kosztow i zalacznikow.
- Audit eventy dla zmian statusu, zalacznikow i rozliczen.
- Trigger albo RPC blokujace ciche nadpisanie zaakceptowanych i spornych kosztow.
- Privacy policy zgodna z realnym zachowaniem aplikacji.
