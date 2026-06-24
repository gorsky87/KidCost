# KidCost Safe Referral Invite

Data: 2026-06-24

Ten dokument opisuje UX/product contract dla bezpiecznego referral loop. Wykonywalny model znajduje sie w `packages/domain/lib/src/safe_referral_policy.dart`.

## Trigger i reward

| Trigger | Reward | Powod |
| --- | --- | --- |
| `coParentInviteAccepted` | 14 dni trial extension | nagradza realne dolaczenie bez presji platniczej |
| `firstSharedExpenseAcknowledged` | 5 tymczasowych kredytow OCR | nagradza pierwsza zdrowa wspolprace przy koszcie |
| `firstReportShared` | 1 kredyt raportu | nagradza udostepnienie uporzadkowanych danych |
| `trustedHelperInvited` | 250 MB czasowego storage boost | nagradza ostrozne zaproszenie pomocnika bez ustawien rodziny |

## Anti-coercion

- Odmowa lub ignorowanie zaproszenia nigdy nie blokuje ledgera, salda, dowodow ani podstawowego eksportu.
- Platnik albo osoba zapraszajaca nie staje sie jedynym administratorem danych drugiego rodzica.
- Brak leaderboardow, presji copy i kar za brak akceptacji.
- Akceptacja, spor, zaplata i udostepnienie raportu pozostaja w normalnych flow potwierdzenia.

## Limits

- Jedna nagroda per family/co-parent pair.
- Cooldown: 30 dni.
- Maksymalny trial extension per rodzina: 30 dni.
- Podejrzane duplikaty kont nie dostaja nagrody do czasu support review.
- Abuse moze cofnac nagrode, ale nie odbiera dostepu do istniejacych rekordow.

## Analytics

Dozwolone pola: `surface`, `trigger`, `reward_type`.

Zakazane pola: email, family id, child id, expense id, coparent id, receipt data, note text, amount i opisowy powod odmowy.
