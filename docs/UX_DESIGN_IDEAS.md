# UX Design Ideas

## 2026-06-24 - Searchable proof library and report selection

### Sources reviewed

- QuickReceipts App Store listing and release notes: modern receipt tools combine paper scans, email receipt import, tags, folders, search, multi-select bulk edit, PDF/CSV/ZIP export, and a review tab for possible imported receipts. Source: https://apps.apple.com/us/app/quickreceipts-smart-scanner/id1484095338
- QuickReceipts App Store reviews: users value simple receipt capture plus categorization/export, but ask for multi-photo support for long receipts and archive/cloud workflows so old proofs do not clutter local storage. Source: https://apps.apple.com/us/app/quickreceipts-smart-scanner/id1484095338
- Finny receipt scanner guide: receipt capture is valuable only when the receipt can later be found, organized, and connected to spending context. Source: https://getfinny.app/blog/best-receipt-scanner-iphone-2026
- NerdWallet 2026 budget app roundup: shared finance tools are judged on categorization, alerts, reports, shared views, and search once history accumulates. Source: https://www.nerdwallet.com/finance/learn/best-budget-apps
- OurFamilyWizard App Store listing and reviews: co-parenting expense records need receipts, categories, custom splits, reimbursements, and enough notes/detail to explain third-party payments or school lunch-style costs. Source: https://apps.apple.com/us/app/ourfamilywizard-co-parent-app/id497405393
- Family Budget Together App Store listing: family finance apps commonly combine member-level spending, shared/personal distinction, calendar view, category budgets, and monthly trend summaries. Source: https://apps.apple.com/in/app/family-budget-together/id6749153961

### Screenshot notes in words

- Receipt scanner screenshots generally separate capture from later organization: a receipt list, tags/folders, search, and export/report actions. KidCost should translate this into child-first proof retrieval rather than a generic business receipt archive.
- Family budget screenshots tend to expose calendar and chart summaries early. KidCost should keep the dashboard calmer, but reports can borrow the idea of visible filters before export.

### Insight summaries

- Capture-heavy UX creates a retrieval problem. Once parents have months of receipts, they need to find proof by child, category, merchant/provider, month, status, attachment type, and whether it was already included in a report.
- Report creation should not force users to export everything for a month. A small "included proofs" review step can make PDFs feel intentional and reduce accidental sharing of private or irrelevant attachments.
- Bulk selection is useful for report assembly and archiving, but high-stakes actions should stay explicit: include/exclude in report, mark reviewed, or open detail. Gestures should not notify a co-parent or change reimbursement state.
- Email receipt import is promising but privacy-heavy. Treat it as later research; the MVP opportunity is to make already-attached receipts searchable and selectable for reports.
- Storage trust can be expressed with simple proof states: attached, missing, included in report, excluded from report, archived locally/cloud-backed later.

### Deduplication against existing backlog

- Already covered: basic expense list filters, monthly reports/export, receipt tray, OCR, quick capture, draft inbox, proof types, itemized bills, service period, and attachment metadata cleanup.
- New enough for one GitHub issue: searchable proof library and report-selection UX, because existing report/list issues do not specify proof retrieval, inclusion review, bulk proof selection, or "already used in report" states.

### Potential GitHub tasks

- Add searchable proof library and report-selection controls for receipts and attachments.

## 2026-06-23 - Low-friction requests and activation clarity

### Sources reviewed

- Appcues mobile onboarding guide: modern onboarding should move users to a first concrete value moment quickly, using progressive disclosure instead of explaining every feature up front. Source: https://www.appcues.com/blog/essential-guide-mobile-onboarding-ui-ux
- UXCam onboarding examples: common 2026 patterns include picker-style setup, demo content, lightweight progress, and asking only for context needed to personalize the first screen. Source: https://uxcam.com/blog/10-apps-with-great-user-onboarding/
- NN/g mobile onboarding analysis: onboarding can promote features, customize the product, or teach interactions, but should be used only where it improves first use. Source: https://www.nngroup.com/articles/mobile-app-onboarding/
- UserOnboard empty-state patterns: empty states are a good place to teach and prompt first action, not just say there is no data. Source: https://www.useronboard.com/onboarding-ux-patterns/empty-states/
- SupportPay App Store listing and reviews: users value replacing spreadsheets/texts with shared expense records, receipt uploads, payment proof, and smooth onboarding. Source: https://apps.apple.com/us/app/supportpay-split-expenses/id808332758
- DComply App Store listing and reviews: useful patterns include saved receipts, multi-item bills, balance summaries, disputes, reminders, and PDF reports; negative reviews warn against revealing subscription/payment constraints too late. Source: https://apps.apple.com/us/app/dcomply-co-parenting-expenses/id1451089998
- Blended App Store listing and screenshots/reviews: notable pattern is sending itemized reimbursement invoices with splits, notes, receipts, and payment links to a co-parent who does not need the app installed. Source: https://apps.apple.com/us/app/blended-money-after-divorce/id6739967832
- Alimentor 2 App Store listing: solo-first custody and expense documentation can distinguish planned vs actual events, attach evidence, and export structured reports from private records. Source: https://apps.apple.com/us/app/alimentor-2-custody-tracker/id1428802675
- Emburse mobile expense guide: mobile expense apps benefit from receipt capture, reimbursement status, and offline capture with later sync. Source: https://www.emburse.com/resources/top-5-expense-tracker-apps-for-small-businesses-in-2025

### Screenshot notes in words

- Blended App Store screenshots appear to position the request as an itemized invoice rather than a generic chat message: amount, split, receipts, notes, and payment path are grouped into one reviewable object.
- Alimentor screenshots/listing language emphasize factual timelines and planned-vs-actual custody documentation, which suggests KidCost reports should clearly label what is logged fact versus calculated summary.

### Insight summaries

- Onboarding should start with one useful record, not a tour: create family, add child, add first expense, then show the first balance/receipt proof state.
- Empty dashboards can be productive: offer three first actions such as add expense, attach receipt, or invite/share with co-parent, with one recommended action based on whether the user is solo.
- Payment and subscription expectations must appear before sensitive setup such as bank/payment details. DComply reviews show trust damage when trial or payment constraints appear late.
- Competitors increasingly support reimbursement requests even when the other parent has not joined. KidCost can keep this simpler: email/share an itemized request packet with receipt thumbnails and a secure view link, without chat or in-app payments.
- Planned-vs-actual is useful beyond calendars: reports should distinguish original expense request, edits, acceptance/dispute, settlement proof, and exported summary.
- Offline or poor-network receipt capture should preserve user momentum: save the draft and show sync status rather than failing the whole expense flow.

### Deduplication against existing backlog

- Already covered: receipt review tray, receipt storage, custody calendar presets, contextual premium discovery, solo mode, mediator/professional report access, payment proof, partial reimbursements, category rules, fee-waiver policy, and privacy/trust onboarding copy.
- New enough for a GitHub issue: itemized reimbursement request packet for a non-connected co-parent, because existing solo mode/invite/report issues do not specify a lightweight outbound request object.

### Potential GitHub tasks

- Design and implement itemized reimbursement request packets for non-connected co-parents.

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

## 2026-06-24 - Calmer notifications, structured disagreements, and attachment privacy

### Sources reviewed

- OurFamilyWizard 2026 co-parenting app guide: highlights centralized expenses, records, reimbursement requests, PDF reports, daily digest notifications, and tone support for high-conflict communication. Source: https://www.ourfamilywizard.com/blog/best-app-co-parents
- AppClose product site: expense requests include receipt/document scanning, approval/decline/paid states, comments, detailed history, exports, secure storage, and private messaging with time stamps. Source: https://appclose.com/
- AppClose App Store and Google Play listings: app store positioning stresses court-trusted records, secure unalterable storage, child details, receipts, reimbursements, and category organization. Sources: https://apps.apple.com/us/app/appclose/id1019290876 and https://play.google.com/store/apps/details?id=com.appclose.androidapp
- Smart Receipts 2026 scanner guide: modern receipt tools are judged by workflow fit, fast capture, export format, OCR, report output, and whether they support the person who needs the receipt next. Source: https://smartreceipts.co/blog/best-app-to-scan-receipts/
- Fuselab fintech UX guide 2026: trust in finance UX depends on visible security, predictable transaction state, plain-language privacy, and explaining delays/statuses rather than leaving ambiguity. Source: https://fuselabcreative.com/fintech-ux-design-guide-2026-user-experience/
- IxDF progressive disclosure guide: advanced controls should stay available without cluttering the primary path, especially for novice users and infrequent tasks. Source: https://ixdf.org/literature/topics/progressive-disclosure
- Custody X Change co-parenting app guide: calendar tools use quick templates, visible parenting time, activity alerts, and scheduled-vs-actual reporting. Source: https://www.custodyxchange.com/topics/software/tech/co-parenting-app.php

### Screenshot notes in words

- AppClose listing screenshots and copy emphasize many family roles and many record types in one app. KidCost should avoid copying that broad layout and instead keep the first screen focused on current balance, next required action, and recent proof.
- Co-parenting marketing pages often frame requests as form-based tasks rather than open-ended chat. KidCost can use this pattern for expense disagreements: a short reason, a requested correction, and a time-stamped outcome.

### Insight summaries

- High-conflict users do not just need more notifications; they need fewer surprise interruptions. A daily digest or quiet-hours preference can make KidCost feel calmer while still preserving urgent overdue/payment states.
- A generic dispute comment box can invite emotional text. Structured reason chips such as "wrong amount", "missing receipt", "not agreed", or "already paid" keep the record useful and make next steps clearer.
- Receipt uploads can accidentally reveal more than a purchase, especially when photos contain location metadata. A visible privacy confirmation around attachment cleanup can build trust without making onboarding longer.
- Progressive disclosure fits KidCost: keep the add-expense path short, but reveal advanced notification, dispute, and privacy controls at the relevant screen.
- Trust-building should be attached to system behavior: "receipt saved", "metadata removed", "co-parent notified in digest", "reason recorded", not generic security claims.

### Deduplication against existing backlog

- Already covered: core notifications for new costs and overdue balances, status/dispute model, receipt tray, storage, security/privacy model, child info vault, deadlines, report exports, and calendar presets.
- New enough for GitHub issues: notification digest/quiet controls, structured dispute reasons with requested correction, and privacy-safe attachment metadata handling are not currently represented as small implementable tasks.

### Potential GitHub tasks

- Add notification digest and quiet-hours preferences for expense/calendar updates.
- Add structured dispute reason chips and requested-correction flow.
- Add privacy-safe attachment upload copy and metadata stripping for receipt photos.

## 2026-06-23 - Duplicate-aware bill verification and calmer shared ledgers

### Sources reviewed

- Reddit co-parenting app thread: parents ask for expense/payment tracking that preserves child, provider, service date, categories, PDF reports, and duplicate bill context because medical statements and receipts can be resent or confused. Source: https://www.reddit.com/r/coparenting/comments/wuleo4/coparenting_appprogram_what_do_you_use/
- Splitwise Google Play listing: simple shared-expense apps foreground "who owes who", quick add, and settlement, but this language can feel too social or generic for co-parenting. Source: https://play.google.com/store/apps/details?hl=en_US&id=com.Splitwise.SplitwiseMobile
- Cino shared-expense article: shared finance tools often fail because users must remember to log, split, check balances, settle later, and chase reminders manually. Source: https://www.getcino.com/post/app-to-track-shared-expenses
- ExpenseBot shared expense tracker: receipt-proof workflows can reduce manual admin by routing receipts into a shared ledger and producing monthly category settle-up summaries. Source: https://www.expensebot.ai/shared-expense-tracker
- Smart Receipts 2026 roundup: receipt tracking expectations now include OCR, categorization, exportable reports, and searchable storage rather than standalone scanning. Source: https://smartreceipts.co/blog/best-app-for-tracking-receipts/
- Shareroo App Store listing: family finance tools use shared dashboards, spending summaries, reminders, receipts, tasks, and category planning for non-technical households. Source: https://apps.apple.com/us/app/home-budget-tracker-planner/id1475406336
- Appcues mobile onboarding guide: modern onboarding should get users to a first value moment quickly and use contextual prompts after the user reaches a relevant screen. Source: https://www.appcues.com/blog/essential-guide-mobile-user-onboarding-ui-ux
- Kidtime co-parenting calendar article: formalized requests can reduce emotional load by turning calendar swaps or reimbursement asks into logged logistical tasks. Source: https://kidtime.app/blog/best-co-parenting-calendar-app

### Screenshot notes in words

- App store shared-finance screenshots tend to show a dashboard first: balance, monthly total, and a visible add action. KidCost should make the dashboard useful without forcing "settle up" language into every family situation.
- Receipt scanner product screenshots commonly show document thumbnails, extracted fields, and export/report affordances. KidCost can borrow the pattern of "review fields before filing" without copying visual composition.

### Insight summaries

- Medical and recurring child expenses need more than amount/date/category. Provider, service date, statement date, child, and proof type are key to catching duplicate statements or mistaken reimbursement requests.
- "Who owes who" is clear, but can be too blunt for high-conflict co-parenting. KidCost should pair balance language with included period, included statuses, and why the amount changed.
- A calm verification checklist can prevent disputes before they start: "same provider/date/amount already exists" is less accusatory than a fraud warning.
- Shared ledger users may be non-technical. Fast entry should avoid forcing full accounting language, while still capturing enough structure for reports.
- Contextual onboarding can introduce verification only when a user enters a medical bill or similar repeatable expense, instead of making onboarding longer.

### Deduplication against existing backlog

- Already covered: receipt review tray, evidence types, payment proof, partial reimbursements, recurring cost templates, dashboard/saldo basics, status/dispute language, cost-to-calendar links, and non-connected reimbursement packets.
- New enough for a GitHub issue: duplicate-aware bill verification for medical/recurring expenses, because current issues cover proof types and settlements but not UI/data cues that help users spot a repeated statement before paying twice.

### Potential GitHub tasks

- Design and implement duplicate-aware bill verification cues for medical and recurring expenses.

## 2026-06-24 - Accessibility baseline and quick capture entry points

### Sources reviewed

- Apple Human Interface Guidelines accessibility: iOS apps should support Dynamic Type, clear hierarchy, accessible controls, and assistive technologies rather than relying on fixed visual layouts. Source: https://developer.apple.com/design/Human-Interface-Guidelines/accessibility
- Google Android accessibility touch target guidance: touch targets should be at least 48 x 48 dp with spacing that reduces accidental taps. Source: https://support.google.com/accessibility/android/answer/7101858
- W3C WCAG 2.2 target-size guidance: pointer targets need sufficient size or spacing so users with motor limitations do not accidentally activate adjacent controls. Source: https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html
- University of Arizona mobile accessibility roadmap: mobile apps should support text scaling up to at least 200%, contrast for text and UI components, visible focus, and orientation resilience. Source: https://accessibility.arizona.edu/web-apps/mobile-app-accessibility-roadmap
- Fuselab fintech UX guide 2026: finance UX should reduce anxiety with clear transaction states, transparent security behavior, simple language, personalization, and accessibility. Source: https://fuselabcreative.com/fintech-ux-design-guide-2026-user-experience/
- WSA fintech UX best practices 2026: trust improves when payment/transaction flows show full timing, clear status labels, proactive delay messaging, and dispute entry points inside transaction details. Source: https://wsa.design/news/top-10-fintech-ux-design-best-practices-for-2026
- Apple App Intents App Shortcuts documentation and WWDC25 App Intents guidance: app actions can be exposed to Shortcuts, Siri, and Spotlight for faster task starts. Sources: https://developer.apple.com/documentation/appintents/app-shortcuts and https://developer.apple.com/videos/play/wwdc2025/260/
- Expenses App Store listing: modern lightweight expense apps emphasize no-learning-curve entry, adding expenses in seconds, and receipt scanning that reduces manual typing. Source: https://apps.apple.com/us/app/expenses-spending-tracker/id1492055171
- SnapKoin App Store listing/version notes: fast expense trackers market "3-second" tracking, Shortcuts, widgets, and native quick interactions as a core differentiator. Source: https://apps.apple.com/us/app/snapkoin-fast-expense-tracker/id6742044212
- Finny Apple Shortcuts expense-tracking guide: users quit expense tracking when the gap between spending and logging is too wide; shortcuts, widgets, NFC, or action-button flows can close that gap. Source: https://getfinny.app/blog/apple-shortcuts-expense-tracking-automations-2026

### Screenshot notes in words

- Lightweight expense tracker listings often make the primary first-viewport promise "add in seconds", with screenshots centered on a single add action, a short form, and compact spending feedback rather than a dense ledger.
- Shortcut/widget-oriented apps present capture as an operating-system habit: home screen, Siri, share sheet, or action button first; full app review second.

### Insight summaries

- Accessibility should not be a late polish item for KidCost because the core UI includes money, dates, status chips, proofs, and high-stakes actions that must remain understandable under larger text, screen readers, and reduced color perception.
- The current backlog mentions color-safe status/category design, but not a measurable accessibility acceptance baseline across onboarding, add expense, dashboard, expense detail, and reports.
- Fast expense entry can start outside the full app. A "quick add expense" or "scan receipt for KidCost" entry point can capture amount/photo/category intent first, then let the user finish details in a draft review flow.
- OS-level quick capture should stay bounded: no automatic reimbursement request, no bypass of review, no hidden co-parent notification. It should create a draft or open the add-expense flow with prefilled context.
- Quick capture pairs well with trust UX: users should see whether a shortcut-created item is only a private draft, not yet shared, and missing required fields.

### Deduplication against existing backlog

- Already covered: quick in-app expense form, receipt review tray, design system basics, dashboard balance language, privacy-safe attachments, notifications, and dispute reasons.
- New enough for GitHub issues: an explicit mobile accessibility baseline with acceptance checks, and OS-level quick capture entry points for expenses/receipts, because neither is represented as a small implementation-ready UX/frontend task.

### Potential GitHub tasks

- Define and implement a mobile accessibility acceptance baseline for KidCost MVP flows.
- Design OS-level quick capture entry points for adding a receipt or expense draft.

## 2026-06-24 - Receipt draft inbox and explainable balances

### Sources reviewed

- Easy Expense Google Play listing and reviews: receipt scanning, offline mode, cloud sync, reports, and a recent review asking for faster list review, bulk select, or swipe classification because reviewing items one by one is slow. Source: https://play.google.com/store/apps/details?hl=en_US&id=com.easyexpense
- Mobilexpense mobile expense article: mobile receipt capture reduces forgotten receipts, supports real-time categorization/submission, and uses immediate feedback for missing fields or unsubmitted receipts. Source: https://www.mobilexpense.com/en/blog/mobile-expense-tracker-app
- WSA fintech UX best practices 2026: trust improves when financial UX explains status, timing, fees, receipts, and recovery instead of hiding uncertainty behind generic states. Source: https://wsa.design/news/top-10-fintech-ux-design-best-practices-for-2026
- NerdWallet 2026 budget apps roundup: household finance tools benefit from controlled sharing, alerts, reports, tagging, and shared views, but users may skip apps that lack transaction search. Source: https://www.nerdwallet.com/finance/learn/best-budget-apps
- Custody X Change co-parenting app guide: calendar tools use guided templates, visible parenting-time context, alerts, and reporting to make schedule state legible. Source: https://www.custodyxchange.com/topics/software/tech/co-parenting-app.php
- AppClose product page: reimbursement requests and expenses support attachments, status updates, category/date filtering, exports, and non-connected co-parent responses. Source: https://appclose.com/

### Screenshot notes in words

- Receipt scanner app store screenshots commonly show a scan-first promise, then a list/report surface where captured receipts become categorized records. KidCost should avoid a generic business-expense look and instead make the queue child/family-specific: missing child, category, split, proof quality, and share status.
- Co-parenting product pages show request state as a formal object with status history. KidCost can use that idea in a quieter dashboard explanation: what changed, which records are included, and which drafts do not affect the balance yet.

### Insight summaries

- Quick capture creates a follow-up problem: if receipts can enter KidCost as private drafts, parents need a small inbox to finish them later instead of losing them inside the expense list.
- The draft inbox should prioritize the next missing field over accounting language. A receipt card can say "needs child", "needs category", "amount not checked", or "not shared yet".
- Bulk or swipe triage is useful only after the model is safe: approve/save draft, assign category, archive, or open full edit. It should never submit a reimbursement request or notify a co-parent from a gesture alone.
- Balance clarity can improve without a new full report screen by adding "what changed" microcopy: new accepted costs, disputed items excluded/included, settlements, and private drafts excluded.
- Search matters once receipts and reports accumulate. Even if advanced search waits, the UX spec should define searchable fields such as child, category, provider/merchant, status, month, and attachment presence.

### Deduplication against existing backlog

- Already covered: receipt review tray, OS-level quick capture, dashboard balance language, reports/export, duplicate-aware bill verification, status/dispute model, privacy-safe attachments, calendar presets, and non-connected reimbursement packets.
- New enough for a GitHub issue: a receipt/expense draft inbox for unfinished quick-captured items. Existing quick-capture and receipt-tray tasks mention drafts and indicators, but not a dedicated review queue, missing-field prioritization, or safe triage actions.
- Covered by existing issues for now: broader explainable balance language and report search/filtering, because issues #23, #30, #17, #18, and #58 already cover the core surfaces.

### Potential GitHub tasks

- Add a receipt and expense draft inbox for unfinished quick-captured items.

## 2026-06-24 - Corrections, refunds, and visible activity history

### Sources reviewed

- 2houses App Store listing and reviews: co-parenting finance users ask for expense tracking, reimbursements, category split percentages, and the ability to handle refunds or canceled transactions without confusing the shared record. Source: https://apps.apple.com/us/app/2houses-better-co-parenting/id545552070
- OurFamilyWizard expense and payment pages: expense records emphasize receipts, categories, custom splits, reimbursements, histories, and exportable records. Sources: https://www.ourfamilywizard.com/product-features/expenses and https://www.ourfamilywizard.com/product-features/payments
- AppClose product site: reimbursement requests show status, comments, history, exports, and non-connected co-parent responses as formal records rather than chat-only messages. Source: https://appclose.com/
- Splitwise help and app listing: shared ledgers need clear settle-up history, deleted/edited expense handling, and non-destructive adjustments so balances remain explainable later. Sources: https://feedback.splitwise.com/knowledgebase and https://play.google.com/store/apps/details?id=com.Splitwise.SplitwiseMobile
- Fintech UX best-practice guides: trust improves when transaction state changes, delays, reversals, and recovery actions are visible in plain language. Sources: https://fuselabcreative.com/fintech-ux-design-guide-2026-user-experience/ and https://wsa.design/news/top-10-fintech-ux-design-best-practices-for-2026

### Screenshot notes in words

- Co-parenting app screenshots often show expense records as request cards with amount, split, status, and history. KidCost should keep the visual language calmer and smaller: the important pattern is not the card layout, but the persistent record of what changed and why.
- Shared-expense tools usually make settle-up history easy to find. KidCost needs a more family-safe version: corrections and reversals should look like transparent adjustments, not like hidden edits to a sensitive balance.

### Insight summaries

- Real family costs change after entry: a provider cancels, a refund arrives, insurance later covers part of a bill, or a parent entered the wrong amount. Editing the original expense silently can damage trust.
- A correction flow should preserve the original amount, show the adjustment amount, require a short reason, and explain whether the balance changed immediately or waits for co-parent review.
- Refunds and cancellations are different from partial reimbursements. A reimbursement records money paid between parents; a refund/cancellation changes the underlying child expense.
- Parents who mute notifications or return after a few days need a "what happened" surface. A user-facing activity history can translate audit-log events into readable entries: expense added, receipt attached, amount corrected, refund recorded, dispute opened, dispute resolved, report exported.
- Activity history should be filterable by child, expense, and date, but MVP can start with a simple family activity list and an expense-detail timeline.

### Deduplication against existing backlog

- Already covered: partial reimbursements and arrears (#47), settlements and backend audit log (#31), dispute reasons (#64), balance language (#23), report exports (#18/#30), attachment audit/soft delete (#83), duplicate-bill checks (#58), and child context reports (#76).
- New enough for GitHub issues: refund/cancellation/correction UX for the underlying expense, because existing reimbursement tasks do not model provider refunds or non-destructive amount corrections; user-facing activity history, because the backend audit-log task does not define the mobile timeline/list that parents will use to understand changes.

### Potential GitHub tasks

- Add non-destructive correction, refund, and cancellation flow for expenses.
- Design and implement a user-facing family activity history and expense timeline.

## 2026-06-24 - Single-currency guardrails before multi-currency support

### Sources reviewed

- Receipto App Store listing: modern receipt tools increasingly expose flexible per-receipt currencies and exports that total by currency. Source: https://apps.apple.com/us/app/receipt-scanner-receipto/id6745450337
- Smart Receipts App Store listing and reviews: users value simple receipt capture and report export, but readability, subscription expectations, and report output shape trust. Source: https://apps.apple.com/us/app/smart-receipts-expenses-tax/id905698613
- WSA fintech UX best practices 2026: confirmation screens, receipts, visible fees, transaction timelines, and clear status updates are part of modern financial UX expectations. Source: https://wsa.design/news/top-10-fintech-ux-design-best-practices-for-2026
- Fuselab fintech UX guide 2026: finance UX should build trust with transparent states, plain language, accessibility, and calibrated friction for high-stakes money actions. Source: https://fuselabcreative.com/fintech-ux-design-guide-2026-user-experience/
- OurFamilyWizard 2026 co-parenting app guide: co-parenting apps combine receipts, expenses, reimbursements, reports, and calm notification patterns for family documentation. Source: https://www.ourfamilywizard.com/blog/best-app-co-parents
- NerdWallet 2026 budget app roundup: shared finance products are evaluated on categorization, shared views, alerts, reports, and search once household history accumulates. Source: https://www.nerdwallet.com/finance/learn/best-budget-apps

### Screenshot notes in words

- Receipt scanner listings now commonly show currency-aware reports and export controls. KidCost should not copy business-expense layouts, but it should prevent the more dangerous outcome: a foreign-currency receipt being visually treated as a normal PLN child expense.
- Fintech confirmation examples emphasize that money-state ambiguity is a trust problem. For KidCost, "this family tracks costs in PLN" is a clearer MVP promise than implying exchange-rate support that does not exist.

### Insight summaries

- The current data model has `families.default_currency` and `expenses.currency`, but `docs/DATA_MODEL.md` states that real multi-currency is outside scope beyond the technical field.
- A parent may receive a foreign receipt from travel, online services, medical care abroad, or a school trip. If the form accepts `EUR` or `USD` without explanation, the dashboard and reimbursement language can become misleading.
- MVP should make the family currency visible in settings/onboarding and on the add-expense form. If a receipt appears to be in another currency, the UI should ask the user to enter the converted family-currency amount and optionally keep the original receipt amount as a note.
- Reports should state the report currency and avoid mixed-currency totals until conversion rules exist.
- This is a guardrail, not a full exchange-rate feature: no live FX rates, no automatic conversion, and no multi-currency balance math for MVP.

### Deduplication against existing backlog

- Already covered: PLN rounding precision, reports, dashboard balance language, import history, settlements/audit, and subscription pricing localization.
- New enough for one GitHub issue: single-currency guardrail UX, because existing issues do not define how the app prevents accidental mixed-currency balances or explains unsupported foreign-currency receipts.

### Potential GitHub tasks

- Add single-currency guardrails for expense entry, balances, and reports before multi-currency support.

## 2026-06-24 - Privacy-redacted notifications and app previews

### Sources reviewed

- Apple Human Interface Guidelines notifications: notification content can appear when people are away from the app, so sensitive personal or confidential details should not be included by default. Source: https://developer.apple.com/design/human-interface-guidelines/notifications
- Apple Human Interface Guidelines privacy: privacy UX should protect data people allow into the app and explain privacy-related behavior clearly. Source: https://developer.apple.com/design/human-interface-guidelines/privacy
- Android Developers secure sensitive activities: `FLAG_SECURE` can prevent screenshots and non-secure display of sensitive windows, which is relevant for family finance screens with child names, amounts, and receipts. Source: https://developer.android.com/security/fraud-prevention/activities
- EFF push notification privacy article: notification previews can expose sensitive content outside the app, and developers/platform settings should support hiding sensitive notification content. Source: https://www.eff.org/deeplinks/2026/04/how-push-notifications-can-betray-your-privacy-and-what-do-about-it
- Fuselab fintech UX guide 2026: financial apps build trust through visible security signals, clear state, calibrated friction, and plain-language privacy behavior. Source: https://fuselabcreative.com/fintech-ux-design-guide-2026-user-experience/
- WSA fintech UX best practices 2026: modern finance UX must manage sensitive financial data with clarity, confidence, and reduced anxiety. Source: https://wsa.design/news/top-10-fintech-ux-design-best-practices-for-2026

### Screenshot notes in words

- Banking and finance apps commonly avoid showing full account details in notifications or app-switcher previews. KidCost should adapt the pattern for family expense context: hide child names, exact amounts, receipt thumbnails, and dispute text unless the user is inside the authenticated app.
- Co-parenting expense notifications should be recognizable without being revealing. A lock-screen message can say that an expense needs review, while the in-app detail shows the amount, child, receipt, and history.

### Insight summaries

- KidCost handles unusually sensitive combinations: child identity, family relationship, money owed, receipts, locations/providers, and dispute state. Lock-screen notifications and app previews can leak that context to people near the device.
- Notification digest and quiet-hours settings are already planned, but the privacy mode is a separate UX decision: what information is safe to show before authentication.
- A simple setting can offer "private previews" by default for MVP: notification title/body avoid child names, exact amounts, merchant/provider names, and dispute reasons; tapping opens the relevant detail after the OS/app unlock state.
- App-switcher protection should be screen-aware. Dashboard and expense detail can blur or replace sensitive content when backgrounded; generic marketing/support screens do not need the same treatment.
- Trust copy should be behavior-specific: "Private previews hide names and amounts on the lock screen" is more useful than broad security claims.

### Deduplication against existing backlog

- Already covered: push notifications (#32), daily digest and quiet hours (#63), privacy-safe attachment metadata (#65), trust onboarding (#24), audit/soft delete for attachments (#83), and accessibility baseline (#73).
- New enough for one GitHub issue: privacy-redacted notification previews and app-switcher protection, because existing notification/privacy tasks do not define lock-screen redaction rules or background snapshot behavior.

### Potential GitHub tasks

- Add private notification previews and app-switcher protection for sensitive family finance screens.

## 2026-06-24 - Calendar exceptions, handoffs, and cost context

### Sources reviewed

- OurFamilyWizard Schedule Change Request support: schedule changes are posted on the calendar, notify the co-parent, can be accepted/countered/refused, and update the calendar only after acceptance. Source: https://www.ourfamilywizard.com/knowledge-center/tips-tricks/parents-website/trade-swap
- OurFamilyWizard mobile Schedule Change Requests: requests need a response date and expire without changing the schedule if no response arrives. Source: https://www.ourfamilywizard.com/knowledge-center/tips-tricks/parents-mobile/trade-swap
- OurFamilyWizard calendar exceptions and holiday scheduling: exceptions should be documented without altering the repeating parenting plan; holiday schedules override the normal schedule visibly. Sources: https://support.ourfamilywizard.com/hc/en-us/articles/39824961955597-What-s-the-easiest-way-to-document-exceptions-to-our-regularly-scheduled-parenting-time and https://www.ourfamilywizard.com/knowledge-center/tips-tricks/parents-mobile/calendar
- Custody X Change calendar guide: custody calendars are valuable when they show parenting time, school breaks/holidays, reminders, planned-vs-actual differences, and reports for a selected period. Source: https://www.custodyxchange.com/topics/software/cxc/calendar.php
- AppClose support and features: co-parents can request swap days, pick-up/drop-off time or location changes, notify connected or non-connected co-parents, and keep request records with supporting documentation. Sources: https://support.appclose.com/hc/en-us/articles/27282580816027-How-do-I-create-a-parenting-schedule and https://appclose.com/pro/features/
- Kidtime free co-parenting calendar article: users compare co-parenting calendars on schedule templates, shared calendar basics, and whether pricing changes make continued use practical. Source: https://kidtime.app/blog/free-co-parenting-calendar-app

### Screenshot notes in words

- Calendar-focused co-parenting apps commonly separate the repeating schedule from exceptions. The visual opportunity for KidCost is a calm exception layer: a base custody rhythm, overlaid holidays/school breaks/swaps, and a small explanation of why a day changed.
- Handoff-related screens often become form-heavy. KidCost should use a compact request object with date/time, pickup/drop-off location, child, response deadline, and optional note/proof, instead of a chat-like negotiation surface.

### Insight summaries

- Calendar usability breaks down when one-off changes overwrite the base schedule. Parents need to know whether a day is normal, holiday override, school break, agreed swap, pending request, refused request, or expired request.
- Expense context improves when cost records can reference the custody state for that date. A school-trip or medical pickup cost may need "during holiday override" or "after accepted swap" context in reports without turning the expense form into a legal diary.
- Handoff requests need deadlines and neutral outcomes. "Accepted", "countered", "declined", and "expired" are clearer and calmer than open-ended comment threads.
- Non-connected co-parent support matters for beta adoption, but should be constrained: send a view/respond link for the handoff request, then keep KidCost's record of response state.
- Exceptions should be reportable but not overbearing. MVP can start with a visible exception badge on calendar days and an optional link from expense detail/report line items.

### Deduplication against existing backlog

- Already covered: base custody calendar (#19), calendar setup presets (#39), linking costs to calendar events (#54), parenting-time context in reports (#69), calendar sync/export (#85), and cost markers on calendar (#88).
- New enough for one GitHub issue: a calendar exception and handoff request layer, because existing issues do not specify holiday/school-break overrides, swap/pickup/drop-off request states, response deadlines, or how those exceptions affect expense context.

### Potential GitHub tasks

- Add calendar exceptions and handoff request states for custody swaps, holidays, school breaks, pickup/drop-off changes, and expense context.

## 2026-06-24 - Interrupted capture and repeated micro-cost entry

### Sources reviewed

- WSA fintech UX best practices 2026: finance products should auto-save progress, support re-entry after abandonment, explain pending/failed states, and keep core flows fast on mid-tier mobile connections. Source: https://wsa.design/news/top-10-fintech-ux-design-best-practices-for-2026
- Easy Expense Google Play listing: receipt tools increasingly promise offline use with automatic cloud sync so users can keep capturing expenses when connectivity is unreliable. Source: https://play.google.com/store/apps/details?hl=en_US&id=com.easyexpense
- Microsoft Dynamics 365 mobile expense app overview: mobile expense flows separate receipt capture, attachment management, save/submit/recall actions, and later report submission. Source: https://learn.microsoft.com/en-us/dynamics365/project-operations/expense/new-expense-mobile-app-overview
- Mobilexpense mobile expense article: mobile capture reduces forgotten receipts when users can record and categorize expenses in the moment instead of reconstructing them later. Source: https://www.mobilexpense.com/en/blog/mobile-expense-tracker-app
- Masraff mobile expense UX article: mobile expense workflows should be optimized for one-handed, interruption-friendly use rather than desktop-style forms squeezed onto a phone. Source: https://www.masraff.co/en/blog/expense-app-your-team-will-actually-use/
- OurFamilyWizard App Store listing/reviews: a user specifically complains that expense records are too limited for school-lunch-style costs where dates, details, and third-party payments matter. Source: https://apps.apple.com/us/app/ourfamilywizard-co-parent-app/id497405393
- AppClose product site: co-parenting expense tools commonly include receipts, reimbursement status, comments, history, exports, and child-related expense categories. Source: https://appclose.com/

### Screenshot notes in words

- Expense apps tend to make capture and submission separate steps: scan or save now, then review, categorize, and submit later. KidCost should apply that pattern with stronger privacy language: interrupted items stay private and do not affect balances.
- Co-parenting screenshots often show one reimbursement request per cost. For repeated small child costs, KidCost can avoid a long list of near-duplicate entries by offering a compact date-batch pattern instead.

### Insight summaries

- KidCost's quick capture and draft inbox backlog covers the happy path, but not the visible behavior when the phone is offline, the upload stalls, or the user backgrounds the app halfway through receipt capture.
- A resilient capture state should tell the parent exactly what is local, what is synced, what failed, and what is still private. This is trust UX, not just technical sync.
- Repeated micro-costs such as school lunches, transport tickets, daycare extras, paid activities, or small pharmacy purchases are too detailed for one generic total but too repetitive for separate full forms.
- A date-batch entry pattern can let a parent select multiple service dates, add one provider/category/split, attach one statement or proof set, and show a per-day or total amount without creating confusing duplicate requests.
- Micro-cost batching should stay distinct from recurring templates and line-item bills: it is for several past dates in one submission, not future automation or itemizing a shop receipt.

### Deduplication against existing backlog

- Already covered: quick add entry points (#74), draft inbox (#79), receipt tray (#37), expense line items (#77), service period/range (#81), recurring templates (#38), back-to-school activation (#100), and reimbursement delivery/read states (#102).
- New enough for GitHub issues: offline/interrupted capture state UX because current draft work mentions failed upload retry but not local/synced/private state rules; repeated micro-cost batch entry because existing line-item/service-period/recurring tasks do not specify selecting multiple service dates for small repeated child costs.

### Potential GitHub tasks

- Add offline/interrupted capture states for local receipts, pending sync, failed upload, and private drafts.
- Add repeated micro-cost batch entry for school lunches, transport, childcare extras, and similar small dated costs.

## 2026-06-24 - Dashboard attention queue for parent tasks

### Sources reviewed

- AppClose product site: co-parenting requests and expenses expose approved, declined, paid, pending, canceled, history, comments, attachments, and non-connected responses. Source: https://appclose.com/
- Microsoft Dynamics 365 expense mobile overview: expense apps commonly separate expenses, receipts, reports, and approvals, with pending approvals grouped in one tab. Source: https://learn.microsoft.com/en-us/dynamics365/project-operations/expense/mobile-app-manage-expenses-overview
- ServiceNow Now Mobile approvals: mobile task UX groups approvals under "My Tasks", shows due dates, details, comments, attachments, and requires a reason for rejection. Source: https://www.servicenow.com/docs/r/zurich/employee-service-management/now-mobile-employee-experience/approvals-mesp-ec.html
- Setproduct empty-state guide: useful empty states should provide one clear next step instead of leaving a dead end. Source: https://www.setproduct.com/blog/empty-state-ui-design
- Formbricks onboarding best practices: blank dashboards can stall activation; guided empty states and sample context help users understand the working product. Source: https://formbricks.com/blog/user-onboarding-best-practices
- Stash couple budgeting app comparison: shared finance users value shared visibility, bill reminders, partner notes, privacy controls, and clear reimbursement tracking. Source: https://www.stash.com/learn/best-budget-app-for-couples/

### Screenshot notes in words

- Approval/task apps tend to use a compact list of pending items with due dates, status, reason/comment access, and one primary action per item. KidCost should adapt this as a calm family "needs attention" queue, not an enterprise approval inbox.
- Empty dashboard examples often place one obvious CTA in the empty state. For KidCost, the same area can become a next-action queue once the family has expenses: review cost, add missing receipt, respond to dispute, record payment, or finish draft.

### Insight summaries

- A dashboard that only shows balance can still leave parents uncertain about what to do next. The more KidCost adds statuses, receipts, reports, disputes, notifications, and calendar requests, the more users need one calm triage surface.
- The attention queue should summarize user-actionable items, not every event. Activity history explains what happened; the queue answers what needs a decision now.
- Parent-safe priority should favor deadlines, blocked reimbursement, missing proof, and direct requests over chronological noise.
- Empty and zero-state behavior matters: if there is nothing pending, the queue can show one useful next action such as add first cost, attach receipt, or export this month, depending on context.
- Actions should be explicit and reversible where possible. No swipe should accept a disputed cost, notify a co-parent, or mark paid without a confirmation path.

### Deduplication against existing backlog

- Already covered: status actions (#116), push/digest notifications (#32/#63), missing proof request (#106), draft inbox (#79), activity history (#90), reimbursement request packets (#51/#115), calendar exceptions (#104), and dashboard/balance basics (#20/#23).
- New enough for one GitHub issue: a dashboard attention queue that aggregates pending user tasks across these surfaces, because existing issues define individual flows but not a single mobile triage area for "what needs my attention".

### Potential GitHub tasks

- Add a dashboard attention queue for pending parent tasks and next best actions.

## 2026-06-24 - Reusable provider defaults for repeated child costs

### Sources reviewed

- Finny 2026 automatic receipt tracking guide: receipt tools increasingly extract merchant/date/amount/category, learn categorization patterns, support batch review, and keep privacy/offline constraints visible. Source: https://getfinny.app/blog/best-apps-track-receipts-automatically-2026
- Mobilexpense 2026 expense trends: modern expense UX is moving toward fewer screens, fewer decisions, native interactions, and zero-learning-curve completion rather than broad feature density. Source: https://www.mobilexpense.com/en/blog/expense-management-trends-2026
- Purrweb 2026 banking UX guide: financial transaction lists need readable merchant labels, category icons, filtering, clear pending states, and contextual detail without overloading dashboards. Source: https://www.purrweb.com/blog/banking-app-design/
- OurFamilyWizard App Store listing: co-parenting expenses commonly need receipts, categories, custom responsibility splits, and reimbursement records tied to a child/family context. Source: https://apps.apple.com/us/app/ourfamilywizard-co-parent-app/id497405393

### Screenshot notes in words

- Receipt automation screenshots commonly show extracted merchant/category fields before saving. KidCost should avoid a generic AI-forward look and instead make the repeated family provider feel familiar: school, pharmacy, dentist, daycare, transport, activity club.
- Expense and banking lists often become easier to scan when merchant/provider labels are cleaned up and paired with category/status cues. KidCost can apply this to child-cost providers without adding bank sync.

### Insight summaries

- Many KidCost expenses will repeat by provider but are not true recurring templates: the same school, pharmacy, clinic, club, or transport provider may reuse the same child, category, split, and proof expectations while amount/date vary.
- Custom categories and recurring templates are already planned, but they do not remove enough friction for "same provider, new one-off cost" entry.
- A small "save as default for this provider" or "use last settings" pattern could prefill child, category, split, proof type, and optional payer while keeping amount/date/manual review explicit.
- Defaults must be transparent and reversible. The form should show what was filled from history and let parents change it before sharing or requesting reimbursement.
- This is a safer MVP than full AI categorization or bank/email import because it keeps user confirmation in the loop and avoids sensitive third-party account connections.

### Deduplication against existing backlog

- Already covered: quick expense form (#21), recurring templates (#38), custom family categories (#87), duplicate bill verification (#58), batch micro-cost entry (#114), draft inbox (#79), and proof library (#82).
- New enough for one GitHub issue: provider-level entry defaults, because existing tasks do not specify saving or reusing child/category/split/proof choices from past provider entries for faster one-off costs.

### Potential GitHub tasks

- Add reusable provider defaults for faster one-off expense entry.

## 2026-06-24 - Status clarity, empty states, and backlog saturation check

### Sources reviewed

- Forbes Advisor 2026 budgeting app roundup: budgeting tools are evaluated on usability, app ratings, cost clarity, security/encryption, reports, and whether users can actually stick with the product. Source: https://www.forbes.com/advisor/banking/best-budgeting-apps/
- Intuit empty-state content guidance: empty states should orient users in unfamiliar spaces, build trust, and offer a useful next step rather than becoming decorative filler. Source: https://contentdesign.intuit.com/product-and-ui/empty-states/
- Justworks mobile expenses help: reimbursement status should remain visible after submit, with review/approved/returned states and detail review before submission. Source: https://help.justworks.com/hc/en-us/articles/17076907141403-Expenses-Mobile
- Microsoft Dynamics 365 mobile expense overview: expense mobile flows separate receipt capture, attachment management, save/submit/recall actions, and later report submission. Source: https://learn.microsoft.com/en-us/dynamics365/project-operations/expense/new-expense-mobile-app-overview
- Fuselab fintech UX guide 2026: financial UX trust depends on transparent states, visible security behavior, simple language, accessibility, and calibrated friction for high-stakes actions. Source: https://fuselabcreative.com/fintech-ux-design-guide-2026-user-experience/
- WSA fintech UX best practices 2026: finance products should reduce anxiety by clarifying risky moments, pending/failed states, accessibility expectations, and recovery paths. Source: https://wsa.design/news/top-10-fintech-ux-design-best-practices-for-2026
- DComply App Store listing/reviews: co-parenting expense users value easy reimbursement, disputes, payments, balance summaries, and PDF exports, but onboarding/payment surprises create trust problems. Source: https://apps.apple.com/us/app/dcomply-co-parenting-expenses/id1451089998
- OurFamilyWizard 2026 co-parenting app guide: users need centralized calendars, expenses, reimbursement records, documentation, daily digests, and fewer upsetting interruptions. Source: https://www.ourfamilywizard.com/blog/best-app-co-parents

### Screenshot notes in words

- Expense approval screenshots and help pages often separate "capture now" from "submit/review later." KidCost already has matching backlog coverage through receipt tray, draft inbox, interrupted capture, grouped requests, and status actions.
- Budget app and empty-state examples show first screens that combine a clear current state with one action. KidCost's dashboard attention queue should use that pattern without turning the family finance home screen into a generic budgeting dashboard.

### Insight summaries

- The most useful new-source reinforcement is not another feature, but consistency: every sensitive object should show whether it is draft, submitted, pending review, returned/disputed, accepted, settled, or excluded from reports.
- Empty states should be specific to the surface: no expenses means add first cost; no receipts means attach proof; no pending tasks means export/report or review month; no calendar events means choose a schedule preset.
- Co-parenting finance UX needs predictable "what happens next" language after every submit action, especially before any co-parent notification, balance change, or report inclusion.
- Trust-building should be expressed as behavior attached to the current task: private draft, receipt saved, metadata removed, notification digest scheduled, report excluded, or status returned for correction.
- Current GitHub backlog already covers the actionable pieces from this pass; creating another broad "clarity/status/empty state" issue would duplicate existing UX, frontend, and backend tasks.

### Deduplication against existing backlog

- Already covered by open issues: accessibility baseline (#73), quick capture (#74), draft inbox (#79), proof library (#82), report proof checklist (#91), co-parent preview (#94), private previews (#96), missing proof request (#106), interrupted capture states (#113), grouped reimbursement requests (#115), status rules/actions (#116), dashboard attention queue (#118), and provider defaults (#120).
- No new GitHub issue created in this run because the strongest sources reinforced existing backlog items rather than exposing a distinct, small, implementable UX/design/frontend task.

### Potential GitHub tasks

- None for this run; revisit after the first mobile screens exist and compare rendered empty/status states against these notes.

## 2026-06-24 - Contextual support from high-stress mobile screens

### Sources reviewed

- WSA fintech UX best practices 2026: financial products should explain pending, failed, or stuck states with next steps, timestamps, and visible escalation paths instead of hiding disputes/support in generic menus. Source: https://wsa.design/news/top-10-fintech-ux-design-best-practices-for-2026
- UXCam finance support article: support quality is tightly linked to trust and retention when users are handling sensitive money/data workflows. Source: https://uxcam.com/blog/finance-apps-customer-support-problems-and-solutions/
- AppClose App Store listing/reviews: developer responses repeatedly ask frustrated users to contact support because app store reviews cannot provide enough context for resolution. Source: https://apps.apple.com/us/app/appclose/id1019290876
- AppClose product site: support and co-parenting guidance are positioned as part of trust, not only a separate help page. Source: https://appclose.com/
- Chameleon contextual help UX guide: contextual help works best when it appears in the user's current task via inline guidance, help menus, checklists, or reactive help entry points. Source: https://www.chameleon.io/blog/contextual-help-ux

### Screenshot notes in words

- Co-parenting app store pages and reviews surface support as an after-the-fact channel. KidCost should bring a small support/help affordance into sensitive mobile screens before frustration turns into an app-store complaint.
- Fintech UX examples frame escalation as part of transaction state handling. KidCost can adapt this for stuck uploads, unclear balances, failed report export, rejected/disputed costs, and invite problems.

### Insight summaries

- Parents in a reimbursement dispute may not know whether the problem is product behavior, missing proof, co-parent action, or a sync/upload issue. A generic settings support link is too far away at that moment.
- Contextual support should be narrow and privacy-preserving: include screen name, object IDs/statuses, app version, and user-entered optional message, but avoid attaching receipts, child details, or co-parent text by default.
- Support entry points should not bypass product flows. For example, a disputed cost detail can show "Need help with this record?" while still encouraging structured dispute reasons and requested corrections first.
- This can double as trust UX: show what context will be sent, let the parent remove optional details, and confirm no co-parent is notified by a support request.
- The smallest useful MVP is a consistent help entry pattern plus a generated context summary that can open email/support form; full in-app ticketing can wait.

### Deduplication against existing backlog

- Already covered: public support/privacy pages (#35), beta feedback backlog (#72), structured disputes (#64), missing proof requests (#106), delivery/read receipts (#102), activity timeline (#90), and status actions (#116).
- New enough for one GitHub issue: contextual mobile help/escalation for high-stress screens, because existing support work is web/release oriented and existing product flows do not define privacy-safe support context from the screen where the user is stuck.

### Potential GitHub tasks

- Add contextual help and privacy-safe support context from high-stress mobile screens.

## 2026-06-24 - Multi-page proof capture for long receipts and document bundles

### Sources reviewed

- SAP Concur ExpenseIt multi-page receipt help: mobile capture supports a multi-page mode, page ordering, retake/delete for a single page, add-page loops, and a final Done step before extraction/review. Source: https://community.concur.com/t5/Support-and-FAQs/How-Do-I-Expense-Multi-Page-Receipts-Using-ExpenseIt/ba-p/16891
- AppClose product site: co-parenting expense and request flows combine reimbursement requests, receipt/document scans, request comments, detailed history, approvals/declines/paid states, and exports. Source: https://appclose.com/
- OurFamilyWizard ToneMeter page: calm co-parenting communication tools keep suggestions optional, private until send, and controlled by the user. Source: https://www.ourfamilywizard.com/product-features/tonemeter
- Shared family organizer App Store listing: custody tools expose school-holiday schedules, one-click custody swaps, and real-time custody distribution; useful context for documents tied to time periods. Source: https://apps.apple.com/cz/app/shared-the-family-organizer/id1345299534
- WSA 2026 fintech UX guide: trust-focused financial UX should reduce anxiety, clarify risky moments, and provide clear status updates instead of silent failures. Source: https://wsa.design/news/top-10-fintech-ux-design-best-practices-for-2026
- Lollypop 2026 banking UI guide: financial histories need scan-friendly labels, status indicators, progressive disclosure, confirmation summaries, and clear system feedback. Source: https://lollypop.design/blog/2026/june/banking-app-ui-design/

### Screenshot notes in words

- Multi-page receipt capture patterns usually keep the camera active while collecting ordered pages, then move to review. KidCost should adapt this for family proof sets rather than generic corporate expense reports.
- Co-parenting request screenshots/pages emphasize documents attached to a request, not just a receipt thumbnail. KidCost can show one proof bundle with page count, type labels, and per-page retry without copying competitor layouts.

### Insight summaries

- One child cost can require several pages: a long pharmacy receipt, a daycare statement, a school invoice plus payment confirmation, or a medical bill plus EOB. Treating each page as a separate attachment makes review and reports harder.
- The existing receipt tray should have a bundle variant: page order, page count, retake/remove page, add page, preview bundle, and save as one proof object attached to one expense.
- Page-level upload states matter. A failed second page should not make the parent wonder whether page one or the whole expense was lost.
- Multi-page capture should stay private until the user submits or shares the expense/request. This aligns with calm communication patterns: drafts and suggested actions remain user-controlled.
- This is a narrower MVP than OCR or document intelligence. The first value is reliable capture, readable preview, and coherent export/report inclusion.

### Deduplication against existing backlog

- Already covered: receipt capture tray (#37), proof types (#40), medical/EOB packet (#80), proof library/report selection (#82), proof completeness checklist (#91), attachment redaction (#103), interrupted capture states (#113), and grouped reimbursement requests (#115).
- New enough for one GitHub issue: multi-page proof bundle capture, because existing tasks mention adding multiple attachments but do not define ordered pages, per-page retry/remove, bundle preview, page count, or report inclusion as one proof object.

### Potential GitHub tasks

- Add multi-page proof bundle capture for long receipts, statements, invoices, and EOB packets.

## 2026-06-24 - OCR field review without accidental sharing

### Sources reviewed

- Smart Receipts 2026 guide: receipt apps are workflow tools, not just cameras; OCR can miss merchant names, dates, tax, or totals, so manual correction remains part of reliable reimbursement records. Source: https://smartreceipts.co/blog/best-app-to-scan-receipts/
- BILL 2026 receipt scanner roundup: receipt scanning is commonly bundled into broader expense workflows where capture, categorization, export, and audit-ready organization matter together. Source: https://www.bill.com/blog/best-receipt-scanning-app
- Simular 2026 receipt organizer comparison: scanning and extracting vendor/date/amount solves only part of the job; users still need to verify, reconcile, and turn the record into something usable. Source: https://www.simular.ai/alternatives/receipt-scanner-and-organizer
- Fuselab fintech UX guide 2026: finance UX should build trust through transparent transaction states, simple language, accessibility, and calibrated friction around high-stakes actions. Source: https://fuselabcreative.com/fintech-ux-design-guide-2026-user-experience/
- AppClose App Store listing/reviews: co-parenting users value receipts, category organization, exportable records, and an extra review step before sending files or uncertain records. Source: https://apps.apple.com/us/app/appclose/id1019290876

### Screenshot notes in words

- Receipt scanner screenshots generally show extracted fields next to the captured document. KidCost should adapt this as a small confirmation surface: amount, date, provider, category, child, split, and proof state, with uncertain fields visibly asking for review.
- Co-parenting screenshots/reviews show that users worry about what the other parent can see. OCR-created drafts should be clearly private until the parent taps an explicit share/request action.

### Insight summaries

- OCR is only trustworthy if the parent can see what was extracted, what is uncertain, and what still needs manual confirmation before the expense affects balances or gets shared.
- The review state should use calm labels such as "check amount" or "date not found" rather than implying the parent made a mistake.
- Confidence should not be exposed as technical percentages in the main UI. Use plain uncertainty markers and focus the parent on the next correction.
- This complements the receipt tray and draft inbox: the tray handles proof attachment; the inbox handles unfinished private items; OCR review handles extracted fields and "safe to submit" confidence.
- The MVP can define the UX/frontend pattern before OCR exists by using mocked extracted fields or future API contracts.

### Deduplication against existing backlog

- Already covered: receipt review tray (#37), OCR/report usage credits (#52), quick capture (#74), draft inbox (#79), proof library (#82), interrupted capture states (#113), and multi-page proof bundles (#126).
- New enough for one GitHub issue: OCR extracted-field review and uncertainty states, because the existing receipt/draft tasks explicitly exclude OCR and do not define how extracted amount/date/provider/category data is reviewed before sharing.

### Potential GitHub tasks

- Add OCR extracted-field review states for private receipt drafts before submission.
