# KidCost PL/EU Subscription Lifecycle

Data: 2026-06-24

Ten dokument opisuje pierwsze zalozenie pricing-ops dla Polski i UE. Zrodlem wykonywalnej prawdy dla aplikacji jest `packages/domain/lib/src/subscription_lifecycle.dart`.

## Pierwsze zalozenie cenowe

- Bazowy storefront: Polska (`PL`)
- Bazowa waluta: PLN
- Pierwszy wariant bety: `kidcost_premium_monthly_pl`, `24.99 PLN` miesiecznie
- Wariant roczny do testow po aktywacji: `kidcost_premium_annual_pl`, `199.99 PLN` rocznie
- Zakres: jedna rodzina/workspace, bez przenoszenia praw do danych na platnika
- Status: hipoteza do walidacji, nie finalna zgoda komercyjna ani podatkowa

## Matrix lifecycle

| Stan | Dostep KidCost | Zasada rekordow |
| --- | --- | --- |
| `free` | Core ledger i podstawowy CSV; nowe funkcje Premium zamkniete | istniejace koszty, saldo, dowody i podstawowy eksport zostaja czytelne |
| `trial` | Premium dla rodziny | platnik nie przejmuje danych wspolrodzica |
| `activePremium` | Premium dla rodziny | pelny dostep, wymagany zweryfikowany status sklepu |
| `gracePeriod` | Premium trwa podczas recovery | spokojny komunikat o platnosci, bez straszenia utrata danych |
| `billingRetry` | nowe Premium wstrzymane | core ledger i historyczne dowody zostaja |
| `accountHold` | nowe Premium wstrzymane | core ledger i eksport zostaja |
| `canceledActiveUntilPeriodEnd` | Premium do konca oplaconego okresu | pokazac date konca i stan po downgrade |
| `expired` | powrot do Free | brak kasowania historii i dowodow |
| `refunded` | powrot do Free | brak kasowania historii i dowodow |
| `feeWaiver` | Premium bez platnosci | wsparcie finansowe nie pogarsza praw do danych |

## Price-change i oferty

- Price-change dla PL/EU jest wymaganiem release-ops: komunikat sklepu, storefront, data wejscia, plan rollback i pomiar opt-in/cancel.
- Mechanizmy przyszlosciowo bezpieczne: App Store introductory offers, offer codes, promotional/win-back offers oraz Google Play base plans/offers, grace period i account hold.
- Annual-first nie jest domyslnym eksperymentem, bo w high-trust co-parenting latwiej zaczac od miesiecznego PLN i dopiero potem testowac annual.

## Analytics

Dozwolone pola sa ograniczone do technicznych wartosci: `store`, `lifecycle_state`, `entitlement_state`, `plan_id`, `storefront_country`, `surface`, `offer_type`, `recovery_outcome`.

Zakazane w payloadach lifecycle/pricing: imiona dzieci, identyfikatory dziecka, notatki kosztow, dane paragonow, kwoty rodzinne, identyfikatory wspolrodzica i opisowe powody sporow.

## Zrodla operacyjne

- Apple auto-renewable subscriptions: https://developer.apple.com/app-store/subscriptions/
- Google Play subscription lifecycle: https://developer.android.com/google/play/billing/lifecycle/subscriptions
- Google Play price changes: https://developer.android.com/google/play/billing/price-changes
