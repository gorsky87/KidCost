# KidCost Store Screenshots

Issue: #28 `[GRAPHIC] Przygotowac screenshoty i grafiki do TestFlight/Google Play`

The first store screenshot pack uses safe demo data and the Calm Ledger visual direction. The exports are intended for TestFlight review, Google Play Internal Testing, and early tester invitations.

## Exports

Generated PNG files:

- `docs/store-screenshots/ios/01-dashboard.png`
- `docs/store-screenshots/ios/02-add-expense.png`
- `docs/store-screenshots/ios/03-expenses.png`
- `docs/store-screenshots/ios/04-reports.png`
- `docs/store-screenshots/android/01-dashboard.png`
- `docs/store-screenshots/android/02-add-expense.png`
- `docs/store-screenshots/android/03-expenses.png`
- `docs/store-screenshots/android/04-reports.png`

Source SVG files live under `docs/store-screenshots/source/`.

## Sizes

- iOS export: `1290 x 2796`, matching a modern 6.7-inch portrait screenshot size for TestFlight/App Store Connect.
- Android export: `1080 x 1920`, suitable as a portrait phone screenshot for Google Play Internal Testing.

## Demo Data Safety

The screenshots use generic demo labels only:

- `Dziecko`
- `Rodzic A`
- `Rodzic B`
- `demo@kidcost.app`
- synthetic amounts and dates

They do not include real names, real emails, real receipts, or real financial data.

## Screenshot Copy

- `Dodaj koszt w minute`
- `Widzisz, kto komu ile oddaje`
- `Paragony i historia w jednym miejscu`
- `Spokojne rozliczenia rodzicow`

## Regeneration

Run from the repository root:

```sh
python3 docs/store-screenshots/generate_store_screenshots.py
```

The generator uses only Python standard library plus macOS Quick Look (`qlmanage`) and `sips` for SVG-to-PNG rendering. If those tools are unavailable, the SVG sources remain editable and can be exported from any vector tool.
