# KidCost domain

Pure Dart domain logic shared by future Flutter UI and backend-facing code.

## Balance calculation

`calculateBalance` computes the child-cost settlement for a family:

- accepts expenses with `amountCents`, `paidBy`, `status`, and optional `childId`
- includes `pending`, `accepted`, and `settled` expenses by default
- ignores `disputed`, `deleted`, `cancelled`, `removed`, and `void` unless callers pass a different included-status set
- supports equal split and custom weighted split, such as 70/30
- keeps all money as integer cents for deterministic rounding

Rounding rule: target shares are floored to cents, then leftover cents are assigned by largest remainder, with participant id as the tie-breaker. This keeps target shares summing exactly to the total amount.

Run tests:

```sh
cd packages/domain
dart test/balance_test.dart
```
