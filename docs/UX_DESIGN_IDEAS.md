# UX Design Ideas

## 2026-06-23 - Mobile co-parenting and expense UX patterns

## 2026-06-23 - Pakiet kopi zaufania: onboarding + settings

Gotowe teksty do użycia w pierwszym flow onboardingowym i ustawieniach, aby budować zaufanie bez tonu prawnego i bez obiecywania porad.

### Onboarding step 1/4 - Bezpieczenstwo danych

- **Nagłówek:** "Twoje dane pozostają bezpieczne"
- **Podtytuł:** "Dane widzi tylko Twoja rodzina i zaproszeni przez Ciebie współrodzice."
- **Treść:** "Twój email, profil, dane dzieci i wydatki są używane tylko do działania aplikacji KidCost. Nie sprzedajemy danych i nie pokazujemy ich innym użytkownikom."
- **Akcja:** Przycisk `Dalej`

### Onboarding step 2/4 - Co rejestrujemy

- **Nagłówek:** "Co zapisujemy, żeby było bezsporne"
- **Treść wypunktowana:**
  - "Wydatki: kwota, data, kategoria, opis, autor wpisu."
  - "Status wydatku: oczekuje / zaakceptowane / sporne / rozliczone."
  - "Załączniki: zdjęcia paragonów, faktur, potwierdzeń."
  - "Historia zmian: kto co dodał, zmienił lub zaakceptował."
- **Dodatkowy opis:** "Dzięki temu łatwiej odtworzyć rozmowę o rozliczeniach, nawet po czasie."

### Onboarding step 3/4 - Dostępność danych

- **Nagłówek:** "Kto może zobaczyć dane rodziny"
- **Treść:** "Gdy zaprosisz współrodzica, dane kosztów i historii widzi on/ona wraz z Tobą. Brak zaproszenia = brak dostępu. Raporty możesz udostępnić tylko wtedy, gdy wyraźnie to zrobisz."

### Ustawienia - sekcja "Prywatność i dane"

- **Etykieta sekcji:** `Prywatność i dane`
- **Elementy:**
  - `Privacy policy` -> link do strony polityki prywatności
  - `Terms of service` -> link do regulaminu
  - `Eksport danych` -> tworzy plik z wydatkami, statusami, historią i załącznikami
  - `Kontakt support` -> mail lub formularz pomocowy
  - `Usuń konto` -> opis: "Usunięcie konta usuwa Twój dostęp i przerywa dalsze przetwarzanie danych."

### Copy gotowy do ustawienia komunikatów o ryzyku prawno-finansowym

- "KidCost porządkuje dane do rozmów o kosztach. Nie jest to porada prawna ani pomoc prawna."
- "Aplikacja nie ocenia uprawnień opieki ani alimentów i nie zastępuje porady prawnika."
- "Jeśli sprawa ma charakter sporny, dane z KidCost mogą pomóc w rozmowie i dokumentacji."

### Sources reviewed

- AppClose product site: reimbursement requests support receipts, request statuses, comments, history, exports, secure payments, non-connected co-parent flows, and trust messaging around timestamps/privacy. Source: https://appclose.com/
- AppClose App Store reviews: users value the feature set but complain about glitches, missed taps, typing friction, and confusing/slow calendar entries. Source: https://apps.apple.com/nz/app/appclose/id1019290876
- OurFamilyWizard product site and App Store listing: expense tracking emphasizes receipt files, custom responsibility splits, real-time balance, time trades, and secure records. Sources: https://www.ourfamilywizard.com/ and https://apps.apple.com/us/app/ourfamilywizard-co-parent-app/id497405393
- Custody X Change: custody calendar setup uses guided templates, clearly shows who has parenting time, and calculates scheduled/actual time. Source: https://www.custodyxchange.com/topics/software/tech/co-parenting-app.php
- Reddit co-parenting app thread: users mention calendar, receipts, payment sections, attorney visibility, and confusion around calendar setup. Source: https://www.reddit.com/r/coparenting/comments/1dums37/coparenting_apps/
- Receipt scanner app roundups: common patterns are mobile capture, immediate upload, OCR later, searchable receipt storage, duplicate/anomaly detection, and audit-friendly retrieval. Sources: https://peoplemanagingpeople.com/tools/pmp-best-receipt-scanner-app/ and https://www.bill.com/blog/best-receipt-scanning-app
- NerdWallet budget app roundup: partner finance apps need controlled sharing, simple manual entry, custom categories, spending alerts, and lightweight communication around transactions. Source: https://www.nerdwallet.com/finance/learn/best-budget-apps

### Useful patterns and pain points

- Receipt capture should feel like a small review tray, not a file upload chore: add photo, retake, add another, show upload/failed state, and let users save the expense even if OCR is unavailable.
- Co-parenting apps create trust with immutable records, timestamps, exportability, and privacy explanations, but KidCost should express this calmly and avoid legal-heavy language in the main flow.
- Calendar setup is a known friction point. Guided presets for common custody schedules can reduce blank-calendar anxiety before advanced scheduling exists.
- Balance language should stay directional and human: who pays whom, why, and what period/statuses are included.
- Statuses must be visible beyond color. Use icon/shape plus short labels for pending, accepted, disputed, and settled.
- Premium discovery should be contextual and quiet: exports, OCR, advanced reports, and evidence bundles can appear where the need naturally arises, without blocking the core expense flow.
- App store review complaints point to practical quality requirements: large tap targets, fast screen transitions, forgiving typing, visible loading, and no hidden delay after actions.

### Original opportunities for KidCost

- Design a receipt evidence tray for the add-expense flow: thumbnail, quality hint, retake, remove, add another, upload progress, and "save without receipt" escape hatch.
- Add calendar setup presets for beta: alternating weeks, 2-2-3, weekdays/weekends, custom later. Show a preview before applying so parents understand the result.
- Add restrained premium teasers only after value moments: after exporting a report, viewing many receipts, or wanting OCR. Use "not needed for basic tracking" language to preserve trust.

### Potential GitHub tasks

- Design and implement a receipt capture review tray for the add-expense flow.
- Design custody calendar setup presets with preview before applying.
- Design contextual premium discovery for OCR, exports, and advanced reports.
