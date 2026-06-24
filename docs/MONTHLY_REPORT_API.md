# KidCost - monthly report API

Data: 2026-06-24
Zakres: issue #30

## Cel

Backend udostepnia jeden miesieczny raport kosztow rodziny oraz eksport CSV dla aplikacji Flutter.
Raport jest liczony z tabeli `expenses` i zachowuje granice dostepu rodziny przez `public.is_family_member(target_family_id)`.

## RPC

### `public.monthly_expense_report(target_family_id uuid, report_month date)`

Zwraca `jsonb` dla miesiaca wskazanego dowolna data z tego miesiaca.
Przyklad: `report_month = '2026-06-10'` zwraca zakres `2026-06-01` do `2026-07-01` bez konca.

Minimalny payload:

```json
{
  "familyId": "uuid",
  "month": "2026-06",
  "range": {
    "from": "2026-06-01",
    "toExclusive": "2026-07-01"
  },
  "currency": "PLN",
  "totalCents": 20550,
  "expenseCount": 3,
  "byParent": [],
  "byChild": [],
  "byCategory": [],
  "byStatus": [],
  "openExpenses": [],
  "expenses": [],
  "exports": {
    "csv": {
      "rpc": "monthly_expense_report_csv",
      "columns": ["data", "dziecko", "kategoria", "opis", "płacący", "kwota", "status"]
    },
    "pdf": {
      "status": "planned",
      "source": "monthly_expense_report"
    }
  }
}
```

Pola `byParent`, `byChild`, `byCategory` i `byStatus` zawieraja `totalCents`, `expenseCount` i `currency`.
Pole `openExpenses` zawiera koszty o statusie innym niz `settled`, czyli rzeczy sporne albo jeszcze nierozliczone.
Pole `expenses` zawiera wszystkie koszty miesiaca w kolejnosci daty.

Miesiac bez kosztow zwraca `totalCents = 0`, `expenseCount = 0` i puste listy.

### `public.monthly_expense_report_csv(target_family_id uuid, report_month date)`

Zwraca tekst CSV w kolejnosci:

```text
data,dziecko,kategoria,opis,płacący,kwota,status
```

Kazda wartosc w wierszach danych jest cytowana, a cudzyslowy w opisach sa escapowane przez podwojenie.
Miesiac bez kosztow zwraca tylko naglowek.

## RLS i uprawnienia

Oba RPC sa `security definer`, ale przed odczytem jawnie sprawdzaja:

```sql
public.is_family_member(target_family_id)
```

Uzytkownik spoza rodziny dostaje blad `42501`.
Funkcje maja `grant execute` dla roli `authenticated`; dane tabel nadal pozostaja ograniczone politykami rodziny.

## PDF MVP

PDF nie jest generowany w bazie danych.
Pierwszy PDF MVP powinien renderowac te same dane co `monthly_expense_report`: podsumowanie, agregacje i liste kosztow.
Kontrakt zawiera `exports.pdf.status = "planned"`, zeby Flutter mogl pokazywac stan funkcji bez zgadywania.
