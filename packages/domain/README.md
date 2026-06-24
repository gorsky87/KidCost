# KidCost domain

Pure Dart domain logic shared by future Flutter UI and backend-facing code.

## Balance calculation

`calculateBalance` computes the child-cost settlement for a family:

- accepts expenses with `amountCents`, `paidBy`, `status`, and optional `childId`
- includes `pending`, `accepted`, and `settled` expenses by default
- ignores `disputed`, `deleted`, `cancelled`, `removed`, and `void` unless callers pass a different included-status set
- supports equal split and custom weighted split, such as 70/30
- accepts manual settlements so an offline transfer can reduce or close the open balance
- keeps all money as integer cents for deterministic rounding

Rounding rule: target shares are floored to cents, then leftover cents are assigned by largest remainder, with participant id as the tie-breaker. This keeps target shares summing exactly to the total amount.

Run tests:

```sh
cd packages/domain
dart test/balance_test.dart
```

## Expense status workflow

`ExpenseStatus` defines the MVP workflow for shared expense reactions:

- `pending` starts after an expense is submitted.
- `accepted` means the counterparty accepted the expense.
- `disputed` means the counterparty questioned the expense and must leave a short comment.
- `settled` means an accepted expense has been paid back or included in a settlement.

Allowed transitions:

| From | To | Actor | Notes |
| --- | --- | --- | --- |
| `pending` | `accepted` | counterparty | Author cannot accept their own expense. |
| `pending` | `disputed` | counterparty | Requires a non-empty comment. |
| `disputed` | `accepted` | counterparty | Use after the dispute is clarified or corrected. |
| `accepted` | `settled` | author, counterparty, or system | Settlement history should be recorded separately. |

`settled` is terminal in the MVP workflow. Core financial fields are editable
only while an expense is `pending`; later changes should be represented as a
correction plus an `ExpenseStatusEvent`, not as a silent overwrite.

Run workflow tests:

```sh
cd packages/domain
dart test/expense_status_test.dart
```

## Usage credits

`usage_credits.dart` defines the MVP credit contract for cost-bearing
Premium conveniences:

- credit types are limited to receipt OCR and Premium report generation
- grant sources cover free monthly allowance, Premium bundles, referral
  rewards, hardship/support grants, admin adjustments, and future add-ons
- ledger entries are signed deltas with scope, audit actor, expiry, and
  related feature event fields
- failed OCR/report jobs do not spend credits; credits are consumed only after
  successful output
- manual expense creation, existing record access, receipt storage, and basic
  CSV export are explicitly outside the credit gate
- analytics allowlists exclude child, receipt, expense, attachment, note, and
  amount properties

Run usage credit tests:

```sh
cd packages/domain
dart test test/usage_credits_test.dart
```
