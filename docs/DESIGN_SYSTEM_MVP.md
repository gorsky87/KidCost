# KidCost Mini Design System MVP

Issue: #29 `[GRAPHIC] Zbudowac mini design system dla Fluttera`

Ten dokument jest praktycznym mini design systemem dla pierwszych 30 dni KidCost. Ma pomagac szybko budowac mobile UI w Flutterze bez zmieniania aplikacji w landing page. System opiera sie na kierunku `Calm Ledger`, ikonach z `docs/ICON_SYSTEM.md` i tokenach juz podlaczonych w `apps/mobile/lib/src/theme/kidcost_theme.dart`.

## Principles

- Mobile first: komponenty projektujemy dla ekranu telefonu, gestu kciukiem i pionowego scrolla.
- Narzedziowy rytm: mniej ozdobnikow, wiecej czytelnych kart, list i akcji.
- Kwota, status i kierunek salda maja pierwszenstwo przed copy pomocniczym.
- Status i kategoria nigdy nie polegaja tylko na kolorze: zawsze `label + icon/shape + color`.
- Tekst ma sie zawijac, nie nachodzic; karty nie powinny miec sztywnej wysokosci, jesli zawieraja zmienne copy.

## Token Source

Przenosne tokeny sa zapisane w:

- `docs/design-system/kidcost_mvp_tokens.json`

Flutter source of truth na dzis:

- `apps/mobile/lib/src/theme/kidcost_theme.dart`

## Color Tokens

| Token | HEX | Flutter | Usage |
| --- | --- | --- | --- |
| `color.primary` | `#0F766E` | `KidCostTheme.primary` | Glowne CTA, aktywna nawigacja, saldo neutralne |
| `color.secondary` | `#C76F3D` | `KidCostTheme.secondary` | Cieply akcent rodzinny, onboarding |
| `color.tertiary` | `#375E97` | `KidCostTheme.tertiary` | Raporty, eksporty, dokumenty |
| `color.success` | `#2F855A` | `KidCostTheme.success` | Zaakceptowane stany |
| `color.warning` | `#B7791F` | `KidCostTheme.warning` | Do akceptacji, neutralna uwaga |
| `color.danger` | `#B42318` | `KidCostTheme.danger` | Sporne, blad, destrukcyjne akcje |
| `color.surface` | `#FAFAF7` | `KidCostTheme.surface` | Tlo aplikacji |
| `color.surfaceVariant` | `#E7ECE7` | `KidCostTheme.surfaceVariant` | Subtelne panele, ledger line |
| `color.text` | `#172326` | `KidCostTheme.text` | Tekst podstawowy |
| `color.outline` | `#6F7D80` | `ColorScheme.outline` | Drugoplanowe obramowania |
| `color.outlineVariant` | `#C7D0D2` | `ColorScheme.outlineVariant` | Delikatne obramowania kart |

## Spacing And Shape

| Token | Value | Usage |
| --- | --- | --- |
| `space.1` | `4` | Gesty drobne, odstep icon-label |
| `space.2` | `8` | Chip gaps, compact rows |
| `space.3` | `12` | Wnetrze malych kart, row gaps |
| `space.4` | `16` | Standardowy page padding |
| `space.5` | `24` | Odstep miedzy sekcjami |
| `space.6` | `32` | Duzy oddech w onboarding/empty state |
| `radius.sm` | `8` | Karty, panele, inputy |
| `radius.md` | `12` | Empty/error/loading state |
| `radius.pill` | `999` | Chipy statusow i kategorii |
| `stroke.hairline` | `1` | Card outline |
| `stroke.emphasis` | `2` | Active chip, selected segment |

## Typography

KidCost MVP uzywa systemowej typografii Material 3. Nie dodajemy zaleznosci fontowej.

| Role | Mobile size | Weight | Usage |
| --- | --- | --- | --- |
| `display.small` | 32 | 700 | Wyjatkowo: brand/startowe naglowki |
| `headline.small` | 24 | 700 | Tytul ekranu |
| `title.large` | 22 | 700 | Kwoty i glowne karty |
| `title.medium` | 16 | 700 | Naglowki sekcji, card title |
| `body.large` | 16 | 400 | Zwykly tekst i wartosci formularza |
| `body.medium` | 14 | 400 | Opisy pomocnicze |
| `label.large` | 14 | 700 | Przyciski, chipy, statusy |
| `label.small` | 12 | 600 | Meta, daty, captions |

Rules:

- Kwoty nie powinny spadac ponizej `title.medium`.
- Button labels max 2-3 slowa; dluzsze akcje przechodza do menu albo bottom sheet.
- Przy dynamicznym tekscie preferuj `Wrap`, `Expanded` i wieloliniowe copy.

## Components

### Buttons

| Variant | Flutter base | Visual | Usage |
| --- | --- | --- | --- |
| Primary | `FilledButton` | `primary` bg, `onPrimary` text, min height 48 | Zapisz koszt, Dalej, glowny CTA |
| Secondary | `OutlinedButton` | outline variant, text color `primary`, min height 48 | Dodaj paragon, Raport miesiaca |
| Destructive | `FilledButton` or `OutlinedButton` | `danger` bg/text, icon required | Usun zalacznik, anuluj dostep |
| Icon | `IconButton` | min tap target 48, tooltip/semantics label | Filtry, export, zamknij |

States:

- Loading: spinner 18-20 px plus disabled button.
- Disabled: keep label readable, opacity from Material state.
- Error/destructive: never icon-only for financial consequences.

### Form Fields

| Field | Base | Required affordance |
| --- | --- | --- |
| Amount | `TextField` with numeric keyboard | Prefix icon, large value text, inline error |
| Text | `TextField` | Sentence capitalization where useful |
| Date | `TextField` or picker trigger | `YYYY-MM-DD` helper, calendar icon |
| Select | `DropdownButtonFormField` | Label, selected value, not only placeholder |

Rules:

- Field height should survive text scale; avoid fixed-height parents.
- Inline error text must be visible, not only red border.
- Date and amount fields should stay above fold in add expense.

### Expense Card

An expense card is a tappable ledger row.

Required anatomy:

- category icon tinted with category accent,
- title,
- amount,
- category / child / date / payer metadata,
- status badge,
- attachment cue when present.

Mobile behavior:

- Amount may sit in trailing slot on normal text size.
- At larger text sizes, amount can wrap below title before metadata.
- Card outline uses `outlineVariant`, radius `8`, no shadow by default.

### Balance Widget

Purpose: explain "who owes whom" in one sentence.

Required anatomy:

- period label, e.g. `Czerwiec 2026`,
- directional sentence, e.g. `Rodzic B oddaje Rodzicowi A 86,50 zl`,
- total or included expense count as secondary text,
- neutral icon/accent in `primary`.

Empty state copy:

- Title: `Brak kosztow do wyrownania`
- Body: `Dodaj pierwszy koszt, a od razu zobaczysz kto ile zaplacil.`

### Status Badge

Use existing status mapping from `ExpenseStatusVisuals`.

| Status | Color | Icon cue | Shape |
| --- | --- | --- | --- |
| Do akceptacji | `warning` | Hourglass | pill outline |
| Zaakceptowany | `success` | Check in circle | pill outline |
| Wymaga wyjasnienia | `danger` | Warning triangle | pill outline |
| Rozliczony | `primary` | Ledger/check | pill outline |

Rules:

- Badge always includes label and icon.
- Never show status as color dot alone.
- Details panel may use tinted background at 8-10% opacity.

### Category Chip

Use existing category mapping from `ExpenseCategoryVisuals`.

Anatomy:

- outline icon,
- label,
- optional active border/fill.

Rules:

- Chips wrap; never horizontal-only scroll for MVP categories.
- Minimum height 40, target 48 when tappable.
- Category color is supportive; label remains required.

### Empty State

Anatomy:

- simple outline icon,
- short title,
- one sentence body,
- one primary action.

Examples:

- `Brak kosztow`
- `Brak raportu dla miesiaca`
- `Brak dni opieki`

Avoid: long onboarding explanation inside empty state.

### Error State

Anatomy:

- error icon in `danger`,
- title saying what failed,
- body saying what to do next,
- retry or alternative action if possible.

Copy pattern:

- `Nie udalo sie pobrac kosztow`
- `Sprawdz polaczenie i sprobuj ponownie.`

### Loading And Skeleton

Use:

- small `CircularProgressIndicator` in buttons,
- list/card skeleton for content that normally has multiple rows,
- short text label when loading blocks the whole screen.

Rules:

- Loading state should not shift navigation.
- Skeletons use `surfaceVariant` with 40-60% opacity.

## Screen Coverage For Day-14 Beta

| Screen | Components |
| --- | --- |
| Login | primary button, secondary text action, text fields, error state, loading button |
| Family onboarding | choice buttons, text fields, trust empty/info panels |
| Dashboard | balance widget, expense card preview, empty state, CTA buttons |
| Add expense | amount/date/text/select fields, category chips, attachment secondary action, loading button, inline errors |
| Expense list | filters, expense cards, status badges, empty/error/loading states |
| Expense detail | status panel, action groups, attachment preview, history placeholder |
| Custody calendar | date rows, day state chips, empty state, edit controls |
| Reports | summary cards, category rows, export secondary action, empty state |
| Settings | list tiles, destructive/logout action, legal/trust links |

## Flutter Implementation Notes

Already implemented:

- Core color tokens in `KidCostTheme`.
- Basic `InputDecorationTheme`.
- Card radius and outline.
- Button minimum height.
- Category/status visuals in `expense_visuals.dart`.

Next implementation candidates:

- Add named spacing/radius constants to `KidCostTheme` when components start repeating spacing logic.
- Extract shared `KidCostStatusBadge`, `KidCostCategoryChip`, `KidCostEmptyState`, and `KidCostErrorState` widgets once duplication appears in two or more screens.
- Keep components local until there is real duplication; do not add a large widget library prematurely.

## QA Checklist

- Small phone width: 360 dp or equivalent.
- Text scale: at least 200% for add expense, dashboard, expense list, reports.
- Status visible without color: icon and label still explain meaning.
- Tap targets: primary controls at least 48 dp high.
- Error messages visible in form and list states.
- Screenshot/store assets use the same token palette and safe demo data.
