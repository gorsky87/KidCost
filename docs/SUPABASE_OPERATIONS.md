# Supabase Operations MVP

Data: 2026-06-24

Zakres: issue #70, czyli minimalna gotowosc Supabase przed beta.

## Decyzja srodowiskowa

Pierwsze buildy testowe KidCost uzywaja dwoch klas srodowisk:

| Srodowisko | Projekt Supabase | Cel | Reset danych |
| --- | --- | --- | --- |
| `dev` | lokalny Supabase CLI albo chmurowy `kidcost-dev` | migracje, RLS, seed demo, praca developerska | dozwolony przez `supabase db reset` |
| `beta-prod` | osobny chmurowy projekt `kidcost-beta-prod` | TestFlight / Google Play Internal Testing z prawdziwymi testerami | niedozwolony bez pisemnej decyzji ownera |

Nie wysylamy buildow beta na lokalny Supabase ani na wspolny projekt `dev`. Dane rodzinne, finansowe i zalaczniki moga byc prawdziwe juz w internal testing, wiec beta musi miec stabilny projekt, prywatny Storage, RLS i kopie zapasowe.

`prod` powstaje dopiero przy publicznym release. Do tego czasu `beta-prod` jest izolowanym projektem dla testerow.

## Seed demo/testowy

Lokalny seed jest w `supabase/seed.sql` i jest wlaczony w `supabase/config.toml`:

```sh
supabase db reset
```

Seed tworzy fikcyjna rodzine demo:

- `demo.parent.one@example.test`
- `demo.parent.two@example.test`
- haslo lokalne: `KidCostDemo123!`

Dane obejmuja profile, rodzine, dziecko, koszty o roznych statusach, settlement oraz pending invitation. Adresy `example.test` i stale UUID nie sa danymi produkcyjnymi.

Seed wolno uruchamiac tylko na lokalnym `dev` albo chmurowym projekcie dev. Nie uruchamiamy seeda na `beta-prod`, bo moglby nadpisac albo pomieszac dane testerow.

## Backup bazy

Skrypt:

```sh
DATABASE_URL="$DATABASE_URL" KIDCOST_BACKUP_ENV=beta scripts/supabase_backup.sh
```

Tworzy:

- custom dump Postgres do `pg_restore`,
- schema-only SQL dump do przegladu,
- CSV manifest obiektow Storage z `storage.objects`.

Domyslny katalog to `./backups/supabase/<env>/<timestamp>`. Katalog `backups/` nie powinien byc commitowany; dumpy moga zawierac dane rodzinne i finansowe.

Minimalny rytm przed beta:

- backup przed pierwszym zaproszeniem prawdziwego testera,
- backup przed kazda migracja na `beta-prod`,
- backup przed kazda zmiana polityk RLS albo Storage,
- backup po zamknieciu cyklu testow, zanim dane zostana zarchiwizowane lub usuniete.

## Backup Storage

`scripts/supabase_backup.sh` zapisuje manifest Storage, ale nie kopiuje bajtow prywatnych plikow. Przed prawdziwymi testerami owner projektu musi pobrac obiekty bucketow przez Supabase Storage/provider dashboard lub osobny zatwierdzony job i trzymac je razem z manifestem.

Minimalne buckety MVP:

- `expense-attachments` dla paragonow, PDF i dowodow platnosci settlementow.

Storage backup musi zachowac sciezki obiektow, bo metadane w bazie odnosza sie do `storage_path`.

## Sekrety i dostep

W repo nie trzymamy:

- `DATABASE_URL` do chmury,
- Supabase service role key,
- anon key dla projektu beta/prod, jesli build nie jest jeszcze publikowany,
- dumpow bazy ani plikow Storage,
- plikow `.env`.

Sekrety ida do:

- lokalnego menedzera sekretow developera dla dev,
- App Store Connect / Google Play / CI secrets dla buildow,
- Supabase dashboard dla rotacji kluczy.

Dostep do `beta-prod`:

- owner/admin: founder albo osoba odpowiedzialna za release,
- developer: ograniczony dostep tylko na czas migracji lub incidentu,
- service role: tylko w sekretach serwerowych/CI, nigdy w aplikacji mobilnej.

## Checklist przed TestFlight/Internal Testing

- [ ] `beta-prod` istnieje jako osobny projekt Supabase.
- [ ] Migracje przechodza na czystej bazie.
- [ ] RLS manual checks przechodza na lokalnej bazie po `supabase db reset`.
- [ ] Prywatny bucket `expense-attachments` dziala z RLS.
- [ ] `scripts/supabase_backup.sh` zostal uruchomiony na `beta-prod`.
- [ ] Obiekty Storage zostaly pobrane lub backup Storage ma wlasciciela i termin.
- [ ] Aplikacja mobilna wskazuje na `beta-prod`, nie na lokalny ani dev Supabase.
- [ ] Service role key nie jest w aplikacji, repo ani logach.
