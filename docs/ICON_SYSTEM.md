# KidCost Icon System

Issue: #26 `[GRAPHIC] Zaprojektowac ikony kategorii kosztow i statusow`

KidCost uses simple outline icons that stay legible at 20-24 px, match the Calm Ledger brand direction, and can be tinted in light or dark UI. The Flutter app uses Material Symbols equivalents through `expense_visuals.dart`, while the SVG files in `docs/icons/` are the portable source assets for design and future platform work.

## Style Rules

- Canvas: 24 x 24 px.
- Stroke: 1.8 px, rounded caps and joins.
- Fill: none, except tiny semantic dots when needed.
- Color: SVGs use `currentColor`; Flutter tints each icon with its helper color.
- Statuses must not rely on color alone. Each status has a distinct icon silhouette and Polish label.

## Category Icons

| Category | Flutter icon | SVG | Helper color |
| --- | --- | --- | --- |
| Jedzenie | `Icons.restaurant_outlined` | `docs/icons/expense-categories/food.svg` | `#C76F3D` |
| Ubrania | `Icons.checkroom_outlined` | `docs/icons/expense-categories/clothes.svg` | `#7C5CBA` |
| Szkola/przedszkole | `Icons.school_outlined` | `docs/icons/expense-categories/school.svg` | `#375E97` |
| Lekarze i leki | `Icons.medical_services_outlined` | `docs/icons/expense-categories/health.svg` | `#B42318` |
| Zajecia dodatkowe | `Icons.sports_soccer_outlined` | `docs/icons/expense-categories/activities.svg` | `#8A6F1E` |
| Wakacje | `Icons.beach_access_outlined` | `docs/icons/expense-categories/holiday.svg` | `#2F7C95` |
| Transport | `Icons.directions_car_outlined` | `docs/icons/expense-categories/transport.svg` | `#4F5D75` |
| Inne | `Icons.more_horiz` | `docs/icons/expense-categories/other.svg` | `#6F7D80` |

## Status Icons

| Status | Flutter icon | SVG | Helper color | Non-color cue |
| --- | --- | --- | --- | --- |
| Do akceptacji | `Icons.hourglass_top_outlined` | `docs/icons/expense-statuses/pending.svg` | `#B7791F` | Hourglass |
| Zaakceptowany | `Icons.check_circle_outline` | `docs/icons/expense-statuses/accepted.svg` | `#2F855A` | Check in circle |
| Wymaga wyjasnienia | `Icons.report_problem_outlined` | `docs/icons/expense-statuses/disputed.svg` | `#B42318` | Warning triangle |
| Rozliczony | `Icons.task_alt_outlined` | `docs/icons/expense-statuses/settled.svg` | `#0F766E` | Ledger line with check |

## Implementation Notes

- App mappings live in `apps/mobile/lib/src/features/expenses/expense_visuals.dart`.
- Category chips and the expense list both use the same category icon/color metadata.
- Status chips and the status detail panel both use the same status icon/color metadata.
