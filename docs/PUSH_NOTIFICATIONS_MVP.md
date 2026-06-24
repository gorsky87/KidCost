# KidCost - push notifications MVP

Data: 2026-06-24
Zakres: issue #32

## Cel

Powiadomienia maja pomagac rodzicom reagowac na nowe koszty i zmiany statusu bez ujawniania szczegolow finansowych na ekranie blokady.
Ten etap dodaje kontrakt bazy danych, ustawienia uzytkownika i bezpieczny outbox pod przyszla funkcje wysylajaca FCM.

## Tabele

### `public.push_device_tokens`

Przechowuje token urzadzenia przypisany do `profiles.id`.
Token widzi tylko wlasciciel przez RLS oraz backend z uprawnieniami serwisowymi.
Tabela ma `token_hash`, zeby deduplikowac tokeny bez porownywania ich jawnie w logice aplikacji.

### `public.notification_preferences`

Minimalne preferencje:

- `push_new_expense`,
- `push_status_changed`,
- `push_unsettled_balance_reminders`.

Brak rekordu preferencji oznacza domyslnie wlaczone powiadomienia dla nowego kosztu i zmiany statusu.

### `public.notification_outbox`

Outbox zapisuje tylko minimalny payload:

- typ zdarzenia,
- `entity_type` i `entity_id`,
- klucze tekstow `title_key` i `body_key`,
- metadane techniczne, np. `expenseId`, `fromStatus`, `toStatus`.

Payload nie zawiera opisu kosztu, kwoty, imienia dziecka ani notatki.
Docelowa Edge Function moze pobrac pending outbox, sprawdzic aktywne tokeny i wyslac neutralny tekst push.

## Zdarzenia MVP

- `expense_created`: koszt dodany przez drugiego rodzica.
- `expense_status_changed`: status kosztu zmieniony przez drugiego rodzica.
- `unsettled_balance_reminder`: kontrakt pod przyszly harmonogram, bez schedulera w tym etapie.

## Flutter

Ekran ustawien pokazuje przelaczniki dla:

- nowych kosztow,
- zmian statusu,
- przypomnien o saldzie.

Aplikacja nie prosi o zgode na push przy starcie. Pierwszy prompt powinien pojawic sie dopiero po kontekscie, np. po dodaniu lub zaakceptowaniu pierwszego kosztu.
