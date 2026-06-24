# KidCost - settlements and audit log MVP

Data: 2026-06-24
Zakres: issue #31

## Cel

MVP pozwala zapisac reczne wyrownanie poza aplikacja, np. `Mama przelala tacie 300 zl`, oraz zachowac minimalna historie zdarzen dla kosztow i settlementow.

## Tabele

### `public.settlements`

Minimalny rekord:

- `family_id`: granica RLS,
- `paid_by`: rodzic, ktory zaplacil wyrownanie,
- `paid_to`: rodzic, ktory otrzymal wyrownanie,
- `amount` i `currency`,
- `settlement_date`,
- `note`,
- `expense_id`: opcjonalne powiazanie z kosztem,
- `period_start` i `period_end`: opcjonalny okres rozliczenia,
- `created_by` i `created_at`.

`paid_by`, `paid_to` i `created_by` musza byc aktywnymi czlonkami tej samej rodziny.

### `public.audit_events`

Tabela jest append-only z perspektywy aplikacji. Uzytkownik ma tylko `select`, a wpisy tworza triggery.

Minimalne eventy w tym etapie:

- `created` dla nowego kosztu,
- `status_changed` dla zmiany statusu kosztu,
- `settlement_added` dla nowego settlementu.

## Saldo

`packages/domain` przyjmuje teraz `SettlementInput`.
Settlement zmniejsza otwarty transfer: jezeli `mom` placi `dad` 1000 gr, to `mom` ma net +1000 gr, a `dad` net -1000 gr.
Pelne wyrownanie zamyka transfer do zera.

## RLS

Aktywny czlonek rodziny widzi settlementy i audit log tylko swojej rodziny.
Aktywny `owner` albo `parent` moze dodac settlement dla swojej rodziny.
Uzytkownik spoza rodziny nie moze czytac ani dodawac settlementow do tej rodziny.
