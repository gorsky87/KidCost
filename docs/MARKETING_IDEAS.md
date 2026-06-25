# KidCost marketing ideas

## 2026-06-24 - School notice intake for cost drafts

### Sources reviewed - school notice intake for cost drafts

- VarannanVecka Google Play listing updated 2026-06-23, positioning AI data entry from invitations, emails and school notices: https://play.google.com/store/apps/details?hl=en_US&id=app.varannanvecka
- Nuet 2026 school-schedule app guide describing school emails landing in one household and automatic school event capture: https://www.nuet.ai/blog/best-co-parenting-apps-school-schedules-uk-2026/
- AppClose product page covering child school details, non-connected requests/events/expenses and web access: https://appclose.com/
- AppClose Google Play listing covering school-related info, expenses, receipts, requests and third-party roles: https://play.google.com/store/apps/details?hl=en_US&id=com.appclose.androidapp
- Kidtime 2026 calendar-app roundup noting shared school supplies, groceries, packing lists and email agendas as family-organizer expectations: https://kidtime.app/blog/co-parenting-calendar-app-free

### Insights - school notice intake for cost drafts

- Some child costs begin as a school notice, flyer, PDF, email or activity announcement rather than a receipt. A finance-first product can reduce retyping by letting parents turn the notice into a reviewed planned purchase, calendar context or private expense draft.
- The safe KidCost version should be review-first and private by default. Avoid broad AI/email integrations for MVP; start with paste/upload/screenshot intake, explicit confirmation and no co-parent notification until the parent shares.
- This complements, but does not replace, planned purchases (#68), receipt drafts (#79), calendar event links (#54) and back-to-school activation (#100).
- This is a useful PL/EU positioning hook because school, activity and camp costs often need amount, due date, service period and source context, but KidCost should keep copy focused on organization rather than legal proof.

### Potential GitHub tasks

- Created issue #128: School notice intake for cost drafts. Rationale: convert school/activity notices into reviewed KidCost drafts or planned requests without direct school/email integrations or automatic legal claims. https://github.com/gorsky87/KidCost/issues/128
- Not created: automated school-email sync, direct Parentmail/Arbor/ClassDojo integrations, or AI-only extraction. Those are too broad and privacy-sensitive before a manual review-first intake flow exists.

## 2026-06-24 - Privacy-safe growth and proof access

### Sources reviewed - privacy-safe growth and proof access

- SupportPay Google Play listing updated 2026-06-04, covering receipt scanning, old-expense import, bill pay and a new credit-building angle: https://play.google.com/store/apps/details?hl=en_US&id=com.supportpay
- SupportPay App Store reviews emphasizing fast receipt capture, reduced conflict and web-first account creation friction: https://apps.apple.com/us/app/supportpay-split-expenses/id808332758?platform=iphone&see-all=reviews
- TalkingParents Google Play listing updated 2026-06-04, covering records, account deletion limits, paid PDF access windows and plan differences: https://play.google.com/store/apps/details?hl=en_US&id=com.talkingparents.tpandroid
- TalkingParents pricing page covering storage, records packages, writing assistance and payment speed packaging: https://legal.talkingparents.com/pricing
- OurFamilyWizard Trustpilot review surface showing price, payment and support-friction complaints: https://www.trustpilot.com/review/www.ourfamilywizard.com
- AppClose product page covering payments, receipt attachments, account verification, privacy and reminders: https://appclose.com/
- European Commission GDPR guidance on children's personal data safeguards: https://commission.europa.eu/law/law-topic/data-protection/rules-business-and-organisations/legal-grounds-processing-data/are-there-any-specific-safeguards-data-about-children_en
- ICO guidance on sharing children's data and best-interests framing: https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/data-sharing/data-sharing-a-code-of-practice/data-sharing-and-children/

### Insights - privacy-safe growth and proof access

- Competitors are stretching from reimbursement tools into broader financial products: bill pay, credit-building, writing assistance, large storage bundles and paid records. KidCost should treat these as future packaging signals, not MVP scope.
- The recurring user pain is still practical: capture proof quickly, avoid lost receipts, keep records accessible and reduce back-and-forth. Existing KidCost issues already cover receipt capture, proof libraries, reports, storage lifecycle, exports and reimbursement requests.
- Paid proof access is a trust risk. TalkingParents-style paid records and short download windows reinforce KidCost's need for clear downgrade/export/storage behavior before any aggressive monetization.
- Children's data guidance supports KidCost's existing direction: collect only what is needed, share child-related records only with clear purpose and roles, and keep marketing analytics free of child, co-parent, receipt, legal and exact amount details.
- The "credit boost" and payment-speed trends are tempting growth hooks, but they would pull KidCost toward regulated financial promises and third-party payment risk before the core evidence workflow is mature.

### Potential GitHub tasks

- No new GitHub issues created. Rationale: the actionable findings map to existing open issues #34, #40, #46, #48, #51, #52, #55, #82, #91, #92, #99, #110, #111, #117 and #122. Credit-building/payment-speed ideas are intentionally deferred as out of scope for a finance-record MVP.

## 2026-06-24 - Contextual support and paid-app anxiety

### Sources reviewed - contextual support and paid-app anxiety

- AppClose product page covering reimbursements, receipts, transaction tracking, account verification and privacy positioning: https://appclose.com/
- AppClose App Store listing and review surface positioning court-ordered co-parenting, payments and expense records: https://apps.apple.com/us/app/appclose/id1019290876
- 2houses 2026 co-parenting app roundup covering paid vs free tradeoffs, calendars, expense tracking, document storage and support: https://www.2houses.com/en/blog/best-co-parenting-apps-for-separated-parents-2026
- Divorce.law Illinois 2026 co-parenting app guide covering receipt photos, reimbursement requests, documented payments and court-adjacent expense records: https://divorce.law/guides/co-parenting-apps-tools/illinois/
- OurFamilyWizard UK product page covering shared calendars, request/accept schedule changes, records and professional trust positioning: https://www.ourfamilywizard.co.uk/
- UXCam article on finance-app support problems and contextual support expectations: https://uxcam.com/blog/finance-apps-customer-support-problems-and-solutions/
- Chameleon article on contextual help UX patterns: https://www.chameleon.io/blog/contextual-help-ux
- Polish shared-custody/legal-market article noting financial questions around child costs in shared custody: https://okolski.com/en/news/shared-custody-of-children-new-regulations-and-the-direction-of-changes-in-polish-law/

### Insights - contextual support and paid-app anxiety

- The market is still bundling expense records with broader co-parenting suites, professional trust and paid support. KidCost can stay finance-first, but the product needs visible help where parents feel stuck: failed receipts, unclear balances, exports, invites and disputes.
- Paid/free anxiety is not a new feature by itself. It reinforces existing comparison-page, lead-magnet, freemium, downgrade, storage-lifecycle and contextual-help tasks rather than justifying another pricing issue.
- Legal and court-adjacent content keeps validating receipt photos, reimbursement requests and documented payments, but KidCost should continue to phrase this as practical organization, not proof guarantees or legal sufficiency.
- Polish shared-custody signals support careful reporting context around who pays, when, and why, but existing issues already cover PL monthly worksheets (#56), 800+/PIT context (#62), parenting-time report context (#69), public child-cost calculator (#97) and family-order import (#112).

### Potential GitHub tasks

- No new GitHub issues created. Rationale: the strongest actionable gap from this scan is already covered by issue #125, contextual help on stressful screens, while the other signals map to existing open issues #42, #46, #49, #56, #62, #69, #97, #109, #111 and #121.

## 2026-06-24 - Monthly child-cost insights

### Sources reviewed - monthly child-cost insights

- AppClose App Store listing and reviews covering category-organized expenses, reimbursement records, and a user request for pie charts/type breakdowns: https://apps.apple.com/us/app/appclose/id1019290876
- AppClose Google Play listing describing receipts organized by category, reimbursement tracking, child details and shared files: https://play.google.com/store/apps/details?hl=en_US&id=com.appclose.androidapp
- SupportPay product page positioning shared family-finance tracking, receipts, payments, summaries and modern family finance: https://supportpay.com/
- OurFamilyWizard expense getting-started support covering review, approve, dispute and request-receipt workflows: https://support.ourfamilywizard.com/hc/en-us/articles/42693746004621-How-do-I-get-started-with-the-Expenses-feature
- OurFamilyWizard 2026 co-parenting app guide covering expense tracking, documentation, daily digest and centralized co-parenting records: https://www.ourfamilywizard.com/blog/best-app-co-parents

### Insights - monthly child-cost insights

- A review signal from AppClose separates "expense tracking for reimbursement" from "understand where money is going." Parents may want lightweight category/type summaries before they need a formal PDF report.
- KidCost already has report/export work (#30/#117/#122/#123), custom categories (#87), provider defaults (#120), and dashboard tasks (#118), but none explicitly define an in-app monthly spending insights surface.
- The safe version is not a generic budget app or alimony calculator. It should use existing family expense records to show child, category, payer and status totals, then deep-link into filtered expense lists.
- This can become an activation and retention surface: once a parent records several costs, KidCost can answer "what changed this month?" without pushing a legal-style report too early.
- Analytics for this surface must stay coarse: view/filter actions are useful, but child names, exact amounts, notes, receipt text and co-parent identifiers should not be sent to marketing analytics.

### Potential GitHub tasks

- Created issue #124: Monthly child-cost insights. Rationale: give parents a quick category/status spending view without duplicating formal report exports or legal calculator work. https://github.com/gorsky87/KidCost/issues/124
- Not created: predictive budgets, bank sync, public calculators, or chart-heavy dashboards. Those are either too broad, too sensitive, or already covered by report/calculator issues.

## 2026-06-24 - Dispute and category-rule gap check

### Sources reviewed - dispute and category-rule gap check

- DComply product page covering active/documented disputes for co-parent money disagreements: https://www.dcomply.com/
- Custody X Change expense tracking page covering formal invoices, declined expenses with explanations, category-based split percentages, attachments and monthly reports: https://www.custodyxchange.com/topics/software/cxc/expenses.php
- Divorce.law 2026 Wisconsin co-parenting app guide covering price pressure, court-ordered app use, expense disputes, receipt scanning, professional access and app comparisons: https://divorce.law/guides/co-parenting-apps-tools/wisconsin/
- OurFamilyWizard shared-expense guide covering child support vs shared expenses, category examples, parenting-plan rules and non-50/50 splits: https://www.ourfamilywizard.com/blog/co-parenting-shared-expenses
- Alimentor expense documentation guide covering child-related proof, reports and expense documentation context: https://alimentor.org/en/articles/expenses-and-reimbursements.html

### Insights - dispute and category-rule gap check

- Competitors keep emphasizing formal invoices, decline/dispute explanations and category-specific splits. KidCost should preserve the same job-to-be-done while staying neutral: clarify what is disputed and what correction is requested, rather than creating a full conflict-resolution product.
- This run did not reveal a clean new backlog gap. The strongest signals map to existing issues: dispute reasons (#64), shared expense rules and thresholds (#45), provider defaults (#120), bundled reimbursement requests (#115), reports/PDF export (#117/#122/#123), professional access (#44) and comparison-page acquisition (#109).
- Price pressure and free-tier changes remain useful GTM positioning, but they are already covered by the comparison page, lead magnets and monetization work. Avoid adding another broad pricing/research task until those assets ship.
- For future scans, look for narrower uncovered workflows around post-dispute resolution, but only create a task if it is distinct from #64's reason/request microflow and #89's corrections/refunds/cancellations.

### Potential GitHub tasks

- No new GitHub issues created. Rationale: all high-quality opportunities from this scan were already covered by open issues, and creating another task would duplicate existing UX/product scope.

## 2026-06-24 - Privacy-safe routines and widgets

### Sources reviewed - privacy-safe routines and widgets

- Alimentor getting-started guidance on Home Screen/Lock Screen widgets and recurring reminders: https://alimentor.org/en/articles/getting-started-with-alimentor.html
- Alimentor expense documentation article on reminders and widgets for upcoming expenses: https://alimentor.org/en/articles/expenses-and-reimbursements.html
- Apple Human Interface Guidelines for widgets: https://developer.apple.com/design/human-interface-guidelines/widgets/
- Apple WidgetKit security note on sensitive information and Lock Screen widgets: https://support.apple.com/guide/security/widgetkit-security-secbb0a1f9b4/web
- Android permissions/privacy overview: https://developer.android.com/guide/topics/permissions/overview
- SupportPay App Store review surface emphasizing quick receipt capture, notifications and avoiding repeated communication: https://apps.apple.com/us/app/supportpay-split-expenses/id808332758
- Trustpilot review surface for OurFamilyWizard payment/support friction: https://www.trustpilot.com/review/www.ourfamilywizard.com

### Insights - privacy-safe routines and widgets

- Expense tracking has a routine problem, not only a feature problem: parents need calm prompts to add receipts, review due requests and send monthly reports before the documentation trail gets stale.
- Widgets can support retention without another noisy notification channel, but KidCost should default to privacy-preserving counts and generic actions instead of exposing child names, amounts, merchants, disputes or receipt previews.
- This is distinct from the dashboard attention queue (#118), private notifications (#96), daily digest (#63) and monthly PDF report (#117): the widget is an optional launcher/glance surface that deep-links into those flows.
- Payment-provider and support-friction reviews reinforce a broader positioning point: KidCost should keep core recordkeeping usable even when payments, subscriptions or platform-specific surfaces are not available.

### Potential GitHub tasks

- Created issue #119: Design privacy-safe KidCost task widgets. Rationale: use home/lock-screen routines to bring parents back to unresolved expense work without leaking sensitive family-finance details. https://github.com/gorsky87/KidCost/issues/119
- Not created: native widget implementation, live payment activities, or lock-screen balances, because the product/privacy spec should land before platform-specific work and exact financial details are too sensitive for the widget MVP.

## 2026-06-24 - Bundled reimbursement requests

### Sources reviewed - bundled reimbursement requests

- AppClose support page for submitting selected expense(s) as a reimbursement request: https://support.appclose.com/hc/en-us/articles/30666680662555-How-do-I-submit-expenses-for-reimbursement
- AppClose expense support index covering reimbursement status, expense history, comments and exports: https://support.appclose.com/hc/en-us/sections/360004227354-EXPENSES
- OurFamilyWizard expense support covering expense review, receipt requests, approvals and reimbursement records: https://support.ourfamilywizard.com/hc/en-us/articles/42693746004621-How-do-I-get-started-with-the-Expenses-feature
- DComply App Store listing describing outstanding bills, disputed items and PDF transaction reports: https://apps.apple.com/us/app/dcomply-co-parenting-expenses/id1451089998
- SupportPay Google Play listing describing receipt scanning, bill pay, old-expense import and proof storage: https://play.google.com/store/apps/details?hl=en_US&id=com.supportpay

### Insights - bundled reimbursement requests

- Competitor flows distinguish entering expenses from submitting a reimbursement request. Parents may want to settle several small costs in one ask instead of sending multiple noisy notifications.
- A reimbursement bundle is different from batch expense entry (#114): batch entry speeds capture, while bundling improves the recipient-facing payment request and weekly/monthly settlement rhythm.
- Bundles should preserve per-expense proof, status and audit history. The product value is less follow-up and clearer totals, not merging evidence into an opaque lump sum.
- Existing issues cover nearby areas: batch entry (#114), unconnected request packages (#51), historical imports (#66), reports (#30) and payment rails (#99). The new gap is grouping already-entered eligible expenses into one request.

### Potential GitHub tasks

- Created issue #115: Group multiple expenses into one reimbursement request. Rationale: reduce notification fatigue and make periodic settlement easier while preserving per-expense traceability. https://github.com/gorsky87/KidCost/issues/115
- Not created: automatic recurring bundles, payment processing or legal/certified service claims, because those overlap existing payment, reporting and deadline work or are too broad for the current backlog.

## 2026-06-24 - Storage trust and plan-safe attachments

### Sources reviewed - storage trust and plan-safe attachments

- TalkingParents pricing page with storage limits, message records and writing assistance packaging: https://talkingparents.com/pricing
- AppClose product page with co-parenting records, solo records, exports, attachments and subscription positioning: https://appclose.com/
- OurFamilyWizard expenses support page covering expense attachments and request workflow: https://support.ourfamilywizard.com/hc/en-us/articles/34522941780365-Expenses
- SupportPay product page positioning receipt, payment and broader family expense records: https://www.supportpay.com/
- Apple notification and privacy guidance used by related private-preview task: https://developer.apple.com/design/human-interface-guidelines/notifications
- Android screen security guidance used by related private-preview task: https://developer.android.com/security/fraud-prevention/activities
- Polish child-cost calculator examples for acquisition research: https://www.rozwadowska-kucka.pl/kalkulator and https://www.adwokat-jaskula.pl/materialy/alimenty

### Insights - storage trust and plan-safe attachments

- Attachment storage is a product trust surface. Parents will rely on receipts and invoices as practical proof, so KidCost should be explicit about file limits, compression, over-limit behavior and whether existing evidence remains readable after downgrade or storage exhaustion.
- This is distinct from OCR credits and the evidence library: credits price automation, the library helps retrieval, while storage lifecycle controls operating cost, failed-upload UX and plan trust.
- Private notifications and app-switcher protection are already covered by issue #96. Keep future notification work focused on behavior-specific templates and avoid exposing child names, amounts, merchants or dispute context on lock screens.
- A public Polish child-cost calculator is already covered by issue #97. It remains a strong acquisition wedge, but it should stay framed as cost organization rather than an alimony calculator or legal estimate.
- AI or writing-assistance packaging is already covered in issue #67 as local neutral templates first. Do not introduce third-party message rewriting until privacy, analytics and consent are designed.

### Potential GitHub tasks

- Created issue #111: Attachment storage limits and lifecycle. Rationale: make file upload limits, compression, storage exhaustion and downgrade behavior predictable without deleting existing evidence. https://github.com/gorsky87/KidCost/issues/111
- Not created: private notification previews, Polish public calculator or neutral request composer, because open issues #96, #97 and #67 already cover those areas.

## 2026-06-24 - Request accountability and proof privacy

### Sources reviewed - request accountability and proof privacy

- TalkingParents Secure Messaging feature page covering timestamped messages and read receipts: https://talkingparents.com/features/secure-messaging
- TalkingParents Unalterable Records feature page covering timestamps, read receipts, update history, signatures and authentication codes: https://talkingparents.com/features/unalterable-records
- TalkingParents Accountable Payments feature page covering payment requests, tracking and chronological payment activity: https://talkingparents.com/features/accountable-payments
- OurFamilyWizard expenses support page covering expense records, payments and reports: https://support.ourfamilywizard.com/hc/en-us/articles/34522941780365-Expenses
- ICO Children's code guidance on privacy-protective design for children's information: https://ico.org.uk/for-organisations/uk-gdpr-guidance-and-resources/childrens-information/childrens-code-guidance-and-resources/age-appropriate-design-a-code-of-practice-for-online-services/
- GDPR.eu overview of children's personal data and parental consent rules: https://gdpr.eu/children-gdpr/

### Insights - request accountability and proof privacy

- A recurring competitor promise is accountability: timestamps, read/open records, request status and exportable history. KidCost can copy the job-to-be-done, not the messaging product, by recording when a reimbursement request was sent and opened.
- Request visibility should be factual and privacy-conscious. "Opened" helps reduce "I never saw it" disputes, but KidCost should avoid legal-service claims, blame language, real-time presence or broad tracking.
- Proof privacy is more than stripping EXIF. Receipts, invoices, school bills and medical documents can expose visible addresses, order IDs, pharmacy details or unrelated purchases that are not needed for reimbursement.
- A manual redaction step is a practical EU/GDPR trust feature: users can hide nonessential details before sharing a proof packet or export, while preserving the original internally with audit history.
- Existing issues cover the nearby foundations: activity timelines, proof library/export selection, EXIF cleanup and evidence checklists. The new opportunities should extend those surfaces rather than create a separate messaging or document-management product.

### Potential GitHub tasks

- Created issue #102: Request delivery and read/open confirmations. Rationale: record sent/opened state for reimbursement requests without adding full chat or legal-service claims. https://github.com/gorsky87/KidCost/issues/102
- Created issue #103: Manual redaction for sensitive proof data. Rationale: let parents share/export enough evidence without exposing unrelated child, household or medical details. https://github.com/gorsky87/KidCost/issues/103
- Not created: certified legal service, notarized records, full co-parent messaging, automatic OCR redaction and PDF redaction. These are too broad for the current backlog or overlap with existing audit, OCR, proof-library and export-readiness issues.

## 2026-06-24 - Missing proof, comparison acquisition and AI intake

### Sources reviewed - missing proof, comparison acquisition and AI intake

- OurFamilyWizard getting-started expense support, including a "Request Receipt" action when documentation is missing: https://support.ourfamilywizard.com/hc/en-us/articles/42693746004621-How-do-I-get-started-with-the-Expenses-feature
- OurFamilyWizard expense-log product page covering shared expense status, outstanding summaries and category splits: https://www.ourfamilywizard.com/product-features/expense-log
- SupportPay App Store listing/reviews emphasizing notifications, reports and avoiding direct arguments about child support payments: https://apps.apple.com/us/app/supportpay-split-expenses/id808332758
- DComply App Store listing/reviews emphasizing fewer follow-up emails/questions, disputes and in-app payments: https://apps.apple.com/us/app/dcomply-co-parenting-expenses/id1451089998
- AppClose App Store listing/review surface noting value even when the other parent refuses to cooperate: https://apps.apple.com/us/app/appclose/id1019290876
- Reddit discussion on AppClose moving from free to paid and user sensitivity to subscription changes: https://www.reddit.com/r/Divorce/comments/1ouh8p8/free_alternative_to_appclose/
- Reddit thread comparing co-parenting app features, with users wanting calendar, PDF reports, expense/payment tracking and expense categories: https://www.reddit.com/r/coparenting/comments/wuleo4/coparenting_appprogram_what_do_you_use/
- VarannanVecka Google Play listing describing AI extraction from invitations, emails and school notices: https://play.google.com/store/apps/details?hl=en_US&id=app.varannanvecka
- Nuet UK parenting-app roundup positioning inbox/school-email organization as a 2026 family-tech trend: https://www.nuet.ai/blog/best-parenting-apps-uk-2026/
- DivKids Polish 2026 article positioning child-cost apps as useful before court, not only during litigation: https://divkids.com/pl/blog/aplikacja-do-alimentow-2026-przewodnik

### Insights - missing proof, comparison acquisition and AI intake

- Missing documentation deserves its own calm workflow. Instead of forcing a dispute, the recipient should be able to ask for a receipt, invoice or payment proof and have that request tracked on the expense.
- Co-parenting app buyers actively compare features, price and cooperation assumptions. AppClose pricing anxiety plus broad feature-comparison searches create a marketing opening for a neutral KidCost comparison page focused on finance-first use cases.
- School notices, email receipts and activity invitations are becoming an intake surface. KidCost should not start with broad AI automation, but a manual "paste/import notice into draft" flow could later connect expenses, planned purchases and calendar events.
- Polish market positioning should keep the pre-court budgeting message: organize real child costs early, without claiming to calculate legal alimony or guarantee evidence sufficiency.
- Duplicates avoided: OCR (#33), receipt draft inbox (#79), planned purchases (#68), calendar event links (#54), custom categories (#87), request preview (#94), public calculator (#97), and payment rails (#99).

### Potential GitHub tasks

- Created issue #106: Missing-proof request workflow. Rationale: let a co-parent ask for a receipt/invoice/payment proof without escalating directly to dispute. https://github.com/gorsky87/KidCost/issues/106
- Created issue #109: Finance-first co-parenting app comparison page. Rationale: capture search intent from parents comparing expensive all-in-one co-parenting tools against a narrower expense product. https://github.com/gorsky87/KidCost/issues/109
- Not created this run: school notice to expense draft intake. Rationale: promising signal from AI family-tech, but it needs dedupe against receipt draft inbox (#79), planned purchases (#68), calendar event links (#54) and back-to-school activation (#100) before becoming a separate task.

## 2026-06-24 - Export readiness, caregiver roles and request preview

### Sources reviewed - export readiness, caregiver roles and request preview

- Johnson/Turner article on child-expense documentation packets and court-adjacent organization: https://johnsonturner.com/blog/child-custody/12/what-tools-help-track-child-related-expenses-for-court/
- DComply medical expense article covering child medical bills, co-pays and app-based reimbursement records: https://www.dcomply.com/child-support-medical-expenses-and-apps-that-can-help/
- DComply spreadsheet article on disputes over expense trackers and discretionary expenses: https://www.dcomply.com/no-more-child-expense-spreadsheet/
- OurFamilyWizard shared expenses support page: https://support.ourfamilywizard.com/hc/en-us/articles/34522941780365-Expenses
- OurFamilyWizard App Store listing/review surface for expense-detail expectations: https://apps.apple.com/us/app/ourfamilywizard-co-parent-app/id497405393
- AppClose product page with solo records, payments, exports and co-parenting records: https://appclose.com/
- SupportPay product page positioning broader family expense management: https://www.supportpay.com/
- Polish article on receipts, invoices and transfer confirmations in child-cost documentation: https://kancelaria-mohylak.pl/paragon-jako-dowod-w-sprawie-o-alimenty/
- Polish article on documenting child expenses with invoices, transfers, contracts, certificates and monthly summaries: https://www.rozwodowy.pl/dokumentowanie_wydatkow_na_dziecko_w_sprawie_o_alimenty%2C111%2Cp.html

### Insights - export readiness, caregiver roles and request preview

- Export quality is a product surface, not just a file format. Parents need to know whether a report packet is missing practical context before they share it, while KidCost must avoid legal-sufficiency claims.
- Evidence type tags and the evidence library are useful primitives, but an export-readiness checklist can convert those primitives into a calmer pre-send review flow.
- Family finance is not always two-parent only. Grandparents, step-parents, guardians or sponsors may pay for specific costs, but should not receive full co-parent access by default.
- A recipient preview can reduce disputes before they happen: the sending parent can verify what the co-parent will see, which fields are private, and whether the request explains itself without adding a chat product.
- Separate but related ideas were already covered by existing issues: activity/timeline (#90), custom categories (#87), calendar sync/export (#85), evidence library (#82), medical/EOB packets (#80), direct provider payment (#61), professional report access (#44) and OCR (#33).

### Potential GitHub tasks

- Created issue #91: Evidence completeness checklist before export. Rationale: help users spot missing practical context without legal scoring. https://github.com/gorsky87/KidCost/issues/91
- Created issue #92: Limited caregiver and payer roles. Rationale: support real family payment patterns without overexposing sensitive child and attachment data. https://github.com/gorsky87/KidCost/issues/92
- Created issue #94: Co-parent request preview. Rationale: let a sender review exactly what the recipient will see before sharing an expense request. https://github.com/gorsky87/KidCost/issues/94
- Not created: another activity timeline task or terms-of-service task, because open issues #90 and #93 already cover those areas.

## 2026-06-24 - Medical packets and service-period context

### Sources reviewed - medical packets and service-period context

- Johnson/Turner article on child-expense documentation, including EOBs, provider statements, treatment plans and secure medical handling: https://johnsonturner.com/blog/child-custody/12/what-tools-help-track-child-related-expenses-for-court/
- OurFamilyWizard article on co-pays and out-of-pocket medical expense reimbursement: https://www.ourfamilywizard.com/blog/3-key-topics-managing-childs-medical-care-after-divorce
- Minnesota statute on unreimbursed/uninsured health-related expense reimbursement requests: https://www.revisor.mn.gov/statutes/cite/518a.41
- DComply medical expense article covering doctor visits, co-pays and recorded reimbursement: https://www.dcomply.com/child-support-medical-expenses-and-apps-that-can-help/
- OurFamilyWizard App Store listing/review snippet about limited expense details and third-party payment context: https://apps.apple.com/us/app/ourfamilywizard-co-parent-app/id497405393
- DComply spreadsheet article describing recurring disputes over child expense trackers and discretionary expenses: https://www.dcomply.com/no-more-child-expense-spreadsheet/
- Polish article on documenting actual child costs with invoices, transfers, medical/school records and monthly summaries: https://www.rozwodowy.pl/zwrot_kosztow_poniesionych_na_utrzymanie_dzieci%2C334%2Cp.html
- Polish article noting rarer-than-monthly child costs can be annualized into monthly cost tables: https://prawniklewandowska.pl/koszty-utrzymania-dziecka-w-sprawie-o-rozwod/

### Insights - medical packets and service-period context

- Medical reimbursement is not just another receipt category. The useful packet is bill/receipt plus EOB or other coverage statement, patient responsibility, proof of payment and optional treatment-plan context.
- KidCost should distinguish gross provider charges from the out-of-pocket amount requested from the co-parent. This keeps reports credible without making insurance, HIPAA or legal-advice claims.
- Some expenses need a coverage period, not only a payment date. School lunches, therapy packages, monthly tuition, activity installments and camps often need "what days/sessions did this cover?" to reduce follow-up messages.
- Service-period metadata complements, but should not replace, existing ideas for recurring templates, calendar links, planned purchases and itemized bills. The smallest version is optional manual fields shown in detail views and exports.
- Polish positioning can frame both ideas as evidence organization: medical/school records, transfers and monthly summaries are useful context, but KidCost should avoid saying a document is legally sufficient.

### Potential GitHub tasks

- Created issue #80: Medical document and EOB packet. Rationale: capture gross amount, insurance/third-party coverage, patient responsibility and medical attachment types before calculating a requested share. https://github.com/gorsky87/KidCost/issues/80
- Created issue #81: Expense service period and scope. Rationale: show what dates, sessions or period a payment covered without turning it into recurring billing or parenting-time logic. https://github.com/gorsky87/KidCost/issues/81
- Not created: medical OCR, insurance integrations, automatic proration and legal-document scoring. These are either too large for the current backlog or duplicate existing OCR/reporting/payment ideas.

## 2026-06-24 - Itemized bills and separated support context

### Sources reviewed - itemized bills and separated support context

- DComply send-bills page with recurring and multi-item bills: https://www.dcomply.com/send-bills/
- DComply features page with receipt capture, recurring bills and multi-item bills: https://www.dcomply.com/features/
- SupportPay App Store listing with receipt scanning, import/export, bill pay, partial payments and private/recurring expense updates: https://apps.apple.com/us/app/supportpay-split-expenses/id808332758
- AppClose product page with payments, receipt attachments, exports and solo records: https://appclose.com/
- Oklahoma Bar Association article noting co-parenting apps may be recommended or court-ordered: https://www.okbar.org/barjournal/mar2018/obj8907jacksoncalloway/
- Polish article on documenting child expenses with invoices, transfers, contracts, certificates and monthly cost summaries: https://www.rozwodowy.pl/dokumentowanie_wydatkow_na_dziecko_w_sprawie_o_alimenty%2C111%2Cp.html
- Polish article on limits of one parent's right to constantly audit the other parent's spending: https://rozwod-i-podzial-majatku.pl/czy-ojciec-placacy-alimenty-ma-prawo-wgladu-do-wydatkow/

### Insights - itemized bills and separated support context

- Multi-item bills are a distinct need from recurring templates and OCR. Parents often have one receipt or provider invoice containing several children, categories or reimbursable/non-reimbursable items, so KidCost should eventually support reviewed line items under one attachment.
- Itemization can improve trust without over-automating: start with manual line items, category/child assignment and totals validation before using OCR to suggest rows.
- Competitors blur shared expenses, direct bill pay, support payments and reimbursements, but DComply's product copy suggests clean reporting depends on keeping child support separate from bill requests.
- Polish positioning should avoid making KidCost a tool for constant surveillance of the other parent's household spending. A safer product stance is: actual shared expenses and optional support/alimony payment context are separate records with clear report labels.
- SupportPay's private, recurring, import/export and partial-payment release notes show that the category is moving toward richer financial records, but KidCost can sequence this as small ledger primitives rather than full payment rails.

### Potential GitHub tasks

- Created issue #77: Itemized bills and receipt line items. Rationale: split one provider invoice or receipt across children, categories and reimbursable shares without forcing multiple duplicate expenses. https://github.com/gorsky87/KidCost/issues/77
- Created issue #78: Separate support/alimony payment context from reimbursable expenses. Rationale: record support payments for report context without mixing them into expense balances or making legal/enforcement claims. https://github.com/gorsky87/KidCost/issues/78

## 2026-06-24 - Planned purchases and parenting-time context

### Sources reviewed - planned purchases and parenting-time context

- 2houses school-expense article with wishlist/upcoming-needs pattern: https://www.2houses.com/en/blog/co-parenting-managing-school-related-expenses
- 2houses feature page: https://www.2houses.com/en/features
- OurFamilyWizard shared expenses support page: https://support.ourfamilywizard.com/hc/en-us/articles/34522941780365-Expenses
- AppClose product/pricing page: https://appclose.com/
- Custody X Change parenting-time calculation overview: https://www.custodyxchange.com/help/calculations/
- Custody X Change parenting-time report article: https://www.custodyxchange.com/topics/software/cxc/timeshare-overnight-calculator.php
- Custody X Change actual parenting-time tracking article: https://www.custodyxchange.com/topics/software/cxc/tracking-time.php
- Polish alternating custody/800+/PIT article: https://adwokatkropiwnicka.pl/opieka-naprzemienna-kompleksowy-przewodnik-alimenty-800-wiek-dziecka/

### Insights - planned purchases and parenting-time context

- Several co-parenting products sell structured requests, not just completed expense logs. KidCost can reduce disputes by letting parents record an upcoming need before money is spent, while keeping balances untouched until the purchase becomes a real expense.
- A wishlist/planned-purchase flow is distinct from recurring expenses: it covers one-off school, clothing, trip, medical or activity needs where pre-approval matters more than repeat entry.
- Parenting-time reports are a strong custody-tool hook, but KidCost should only use this as report context. Scheduled nights/days can explain a cost period without automatically changing splits or becoming an alimony/support calculator.
- Polish alternating-custody positioning benefits from separating facts: actual expenses, benefits/tax assumptions and parenting-time context should be visible but not blended into a hidden legal formula.

### Potential GitHub tasks

- Created issue #68: Planned purchases before reimbursement. Rationale: help parents approve upcoming child costs before they become disputed expenses. https://github.com/gorsky87/KidCost/issues/68
- Created issue #69: Parenting-time context in cost reports. Rationale: show scheduled care context beside monthly expenses without changing balances or giving legal advice. https://github.com/gorsky87/KidCost/issues/69

## 2026-06-23 - Reimbursement deadlines and PL benefit context

### Sources reviewed - reimbursement deadlines and PL benefit context

- Justia guide on uninsured medical expenses and reimbursement flow: https://www.justia.com/family/child-custody-and-support/child-support/uninsured-medical-expenses-and-child-support/
- California FL-192 child support rights/responsibilities PDF: https://courts.ca.gov/sites/default/files/courts/default/2024-11/fl192.pdf
- Greene County parenting plan PDF with quarterly medical-expense documentation language: https://www.greenecountyohio.gov/DocumentCenter/View/2613/Parenting-Plan-PDF
- Institute for Divorce Financial Analysts article on shared expense tracking: https://institutedfa.com/co-parenting-tips-shared-expenses/
- OurFamilyWizard article on shared vs extraordinary expenses: https://www.ourfamilywizard.com/blog/co-parenting-shared-expenses
- Gov.pl 800+ program page: https://www.gov.pl/web/gov/skorzystaj-z-programu-rodzina-500
- Polish alternating custody/800+/PIT article: https://adwokatkropiwnicka.pl/opieka-naprzemienna-kompleksowy-przewodnik-alimenty-800-wiek-dziecka/
- Polish 800+ and alternating custody article: https://www.plonkaozga.com/post/opieka-naprzemienna-a-800-plus
- Gazeta Prawna article on PIT/child settlement and 800+: https://www.gazetaprawna.pl/podatki/artykuly/10764875%2Crozliczenie-pit-z-dzieckiem-a-800-plus-pobieranie-swiadczenia-nie-zaw.html

### Insights - reimbursement deadlines and PL benefit context

- Reimbursement workflows need timing fields, not just approval states. Parenting-plan and child-support materials repeatedly distinguish when the bill/proof must be shared from when the other parent must pay.
- Some costs should be requested as "pay the provider" rather than "reimburse me". Medical, dental, childcare and therapy bills may need provider details, reference notes and proof fields without moving money through KidCost.
- Deadline and provider-payment features should stay neutral: KidCost can record dates, status and documents, but should not say whether a parent violated a legal duty.
- Polish reports can win trust by separating actual expenses from benefit/tax assumptions. 800+, Dobry Start, PIT relief and alternating-custody notes are useful context, but should not alter balances or become an alimony/tax calculator.
- The market opportunity is a calmer evidence packet: expense, proof, request type, due date, provider/direct-pay context and optional PL assumptions in one export.

### Potential GitHub tasks

- Created issue #60: Reimbursement notice/payment deadlines. Rationale: help parents track whether costs were submitted and paid within agreed windows. https://github.com/gorsky87/KidCost/issues/60
- Created issue #61: Pay-provider request type. Rationale: support bills where the co-parent should pay a clinic, school, therapist or childcare provider directly. https://github.com/gorsky87/KidCost/issues/61
- Created issue #62: Polish 800+/PIT context in reports. Rationale: capture benefit/tax assumptions as report context without changing balances or giving legal/tax advice. https://github.com/gorsky87/KidCost/issues/62

## 2026-06-23 - Calendar-linked costs and PL monthly planning

### Sources reviewed - calendar-linked costs and PL monthly planning

- AppClose feature/pricing page: https://appclose.com/
- OurFamilyWizard feature page: https://www.ourfamilywizard.com/
- TalkingParents Google Play feature list: https://play.google.com/store/apps/details?hl=en_US&id=com.talkingparents.tpandroid
- Oklahoma Bar Association article on co-parenting apps: https://www.okbar.org/barjournal/mar2018/obj8907jacksoncalloway/
- Reddit thread on AppClose subscription change: https://www.reddit.com/r/DivorcedDads/comments/1pu93vt/appclose_the_free_coparenting_app_is_now_going_to/
- Polish monthly child-cost calculator: https://www.rozwadowska-kucka.pl/kalkulator
- Polish printable child-cost calculators: https://www.adwokat-jaskula.pl/materialy/alimenty
- Polish 2026 alimony calculator/search landing page: https://kreator-sadowy.pl/kalkulator-alimentow
- Gazeta Prawna 2026 alimony/cost article: https://www.gazetaprawna.pl/twoje-prawo/prawo-rodzinne/artykuly/11247816%2Calimenty-na-dziecko-2026-ile-wynosza-kalkulator.html

### Insights - calendar-linked costs and PL monthly planning

- Competitors increasingly sell a connected record: calendar events, requests, expenses, approvals, payments and exports reinforce one another. KidCost can stay finance-first but should let expenses point back to the event, activity or appointment that caused them.
- Child information banks are a repeated co-parenting app pattern. A narrow KidCost version should avoid becoming a full family CRM and instead store only details that reduce cost friction: school, medical/insurance, clothing sizes, allergies and activity context.
- Pricing anxiety around AppClose moving from free to paid reinforces the value of low-friction single-parent utility before both parents subscribe or cooperate.
- Polish acquisition can lean into "miesieczny koszt utrzymania dziecka" demand. A monthly cost worksheet with PL categories is a better market fit than promising an alimony calculator, because it organizes evidence without legal claims.
- Polish calculators commonly include housing share, education/childcare, health, food, clothing, travel, holidays and activities. These categories can seed planning presets and reporting copy.

### Potential GitHub tasks

- Created issue #54: Link expenses to calendar events. Rationale: connect a cost to the appointment, activity or custody event that explains it. https://github.com/gorsky87/KidCost/issues/54
- Created issue #57: Narrow child-info vault for expense context. Rationale: reduce back-and-forth questions about school, medical, clothing and activity details while keeping KidCost finance-focused. https://github.com/gorsky87/KidCost/issues/57
- Created issue #56: Monthly child-cost worksheet for the Polish market. Rationale: capture Polish search/user demand for monthly child-cost summaries without making legal advice claims. https://github.com/gorsky87/KidCost/issues/56

## 2026-06-23 - Reimbursement depth and shared rules

### Sources reviewed - reimbursement depth and shared rules

- SupportPay App Store listing/release notes: https://apps.apple.com/us/app/supportpay-split-expenses/id808332758
- Johnson/Turner article on child-expense documentation tools: https://johnsonturner.com/blog/child-custody/12/what-tools-help-track-child-related-expenses-for-court/
- Custody X Change shared expenses list: https://www.custodyxchange.com/topics/custody/advice/co-parenting-shared-expenses-list.php
- AppClose Google Play feature list: https://play.google.com/store/apps/details?hl=en_US&id=com.appclose.androidapp
- Stephens Scown article on co-parenting apps: https://www.stephens-scown.co.uk/family/children-issues/co-parenting-apps/
- Polish article on receipts vs invoices/bank confirmations: https://kancelaria-mohylak.pl/paragon-jako-dowod-w-sprawie-o-alimenty/
- Polish article on alternating custody and shared non-daily costs: https://poradnikprzedsiebiorcy.pl/-w-jakich-przypadkach-ustala-sie-alimenty-przy-opiece-naprzemiennej

### Insights - reimbursement depth and shared rules

- Expense tools should not stop at "settled/unsettled". SupportPay and legal-tech roundups call out partial payments, arrears and payment verification, which suggests KidCost will need a clear path from simple settlements to partial allocation once real families use it.
- Reimbursement proof is a separate evidence surface from expense proof. Users may attach a receipt to the original cost, but still need a bank confirmation, BLIK/PayPal screenshot, cash note or other proof that a settlement happened.
- A shared expense agreement can reduce disputes before individual costs are entered: categories, default split, and optional pre-approval thresholds answer "does this count?" before the reimbursement request appears.
- Polish and EU positioning should keep documentation language careful: receipts, named invoices and bank confirmations can help organize evidence, but KidCost should avoid saying that any record is legally sufficient.
- Broader co-parenting apps keep child-related coordination in one place, but KidCost should continue to avoid full chat scope. Financial comments, rules and proof are enough for the near-term positioning.

### Potential GitHub tasks

- Created issue #45: Shared expense agreement and approval thresholds. Rationale: define what counts as shareable before a cost becomes a dispute. https://github.com/gorsky87/KidCost/issues/45
- Created issue #47: Partial reimbursements and arrears in balance. Rationale: real repayments can be partial or cover multiple expenses, so the balance model needs a follow-up path beyond basic settlements. https://github.com/gorsky87/KidCost/issues/47
- Created issue #48: Payment proof attachments for settlements. Rationale: reimbursement evidence should live beside expense evidence without requiring bank integrations. https://github.com/gorsky87/KidCost/issues/48

## 2026-06-23 - Initial competitor scan

### Sources reviewed

- OurFamilyWizard pricing/features: https://www.ourfamilywizard.com/plans-and-pricing
- 2houses features: https://www.2houses.com/en/features
- AppClose features: https://appclose.com/
- DComply product page: https://www.dcomply.com/
- DComply App Store reviews: https://apps.apple.com/us/app/dcomply-co-parenting-expenses/id1451089998?platform=iphone&see-all=reviews
- Polish legal article on receipts in alimony cases: https://anna-kubica.pl/czy-nalezy-zbierac-paragony-by-zlozyc-je-w-sprawie-o-alimenty/
- Polish article on alternating custody, 800+ and PIT: https://adwokatkropiwnicka.pl/opieka-naprzemienna-kompleksowy-przewodnik-alimenty-800-wiek-dziecka/
- Alimentomat Polish child-cost calculator: https://alimentomat.pl/

### Insights

- Competitors sell "documented peace of mind" more than raw expense tracking. OurFamilyWizard and AppClose emphasize immutable records, PDF exports, professional access, timestamps, and court-friendly documentation. KidCost should keep the MVP promise narrow: fast shared-cost capture plus trustworthy evidence.
- AppClose's solo/non-connected mode is a useful acquisition wedge: one parent can start logging costs before the other parent accepts an invite. This fits high-conflict or low-cooperation cases and lets KidCost show value before network effects.
- DComply highlights recurring bills and multi-item bills. KidCost already has one-off costs, settlements and reports in backlog, but not reusable monthly/weekly child-cost templates for tuition, lessons, therapy, subscriptions or recurring medical costs.
- App store review language around DComply suggests the strongest emotional value is "upload receipt and stop chasing the co-parent." That points to flows that reduce follow-up work: due dates, reminders, status history and clear evidence.
- Polish legal content says receipts can support the scale of child expenses but are weaker than named invoices, bank confirmations, online order confirmations and payment-card traces. KidCost can add evidence type tags without giving legal advice.
- Polish alternating custody articles call out practical financial questions around 800+, tax relief and who covers fixed costs. This suggests future Polish localization should treat benefits and fixed-cost assumptions as explainable fields, not hidden magic.
- Competitor pricing ranges from free/low-cost to premium annual plans. For Poland/EU, a lightweight single-parent trial and later family subscription may be easier to test than forcing both parents to subscribe immediately.

### Potential GitHub tasks

- Created issue #36: Solo ledger mode for adding expenses before the co-parent joins. Rationale: improves activation and supports high-conflict cases where invitation is delayed. https://github.com/gorsky87/KidCost/issues/36
- Created issue #38: Recurring expense templates for weekly/monthly child costs. Rationale: captures predictable costs and reduces repeated manual entry. https://github.com/gorsky87/KidCost/issues/38
- Created issue #40: Evidence type tags for Polish/EU documentation. Rationale: receipts, invoices, bank confirmations and online orders have different practical value in reimbursement/alimony documentation. https://github.com/gorsky87/KidCost/issues/40
- Later idea, not created this run: due dates and reimbursement policy text per family/category. This overlaps with existing notification and status issues, so it needs more product shaping before a separate task.
