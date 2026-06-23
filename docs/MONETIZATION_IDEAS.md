# KidCost monetization ideas

## 2026-06-23

### Sources reviewed

- OurFamilyWizard pricing: https://www.ourfamilywizard.com/plans-and-pricing
- 2houses pricing: https://www.2houses.com/en/pricing
- TalkingParents pricing: https://talkingparents.com/pricing
- Custody X Change parent pricing: https://app.custodyxchange.com/pricing-parents
- CustodySync pricing: https://custodysync.com/pricing
- Cozi Gold pricing: https://www.cozi.com/cozi-gold/
- RevenueCat State of Subscription Apps 2025: https://www.revenuecat.com/state-of-subscription-apps-2025/
- Apple win-back offers: https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-win-back-offers/
- Google Play subscriptions: https://developer.android.com/google/play/billing/subscriptions

### Pricing observations

- Co-parenting pricing clusters around either per-parent subscriptions or one family/workspace subscription.
- OurFamilyWizard uses annual commitments and tiers around $110/year basic, $149.99/year essentials, $216/year premium, and $299.88/year max; storage, PDF records, calling, recordings, and professional access are packaging levers.
- 2houses uses one family price at $169.99/year, a 14-day trial, access for parents/children/third parties/mediators, and avoids making the paying parent the account administrator.
- TalkingParents uses $7/$16/$32 monthly plans, a 30-day trial on higher tiers, storage tiers from 1 GB to 50 GB, PDF records as higher-tier value, and allows co-parents to be on different plans.
- CustodySync anchors low with $50/year covering both parents for shared calendar coordination; this suggests KidCost can compete by staying simple and family-priced.
- Cozi Gold is a mainstream family app benchmark at $39/year for the whole family, but KidCost handles more sensitive financial/legal-adjacent value and can justify higher pricing if trust is clear.

### Insight summaries

- Trust boundary: never paywall the user's ability to see existing expenses, receipts, balances, or export basic personal data. Monetize convenience, automation, storage, and formal reports.
- Free boundary candidate: one family, up to two children, manual expenses, basic balance, limited receipt storage, last 90 days visible in-app, and basic CSV export for user-owned data.
- Premium boundary candidate: unlimited history views, more children, higher storage, OCR receipt extraction, recurring expenses, advanced split rules, PDF/legal-style reports, calendar-linked cost allocation, and priority support.
- Family plan logic should avoid turning payment into leverage between co-parents. If one parent pays for a family plan, both parents retain equal product rights; billing ownership must not become data ownership.
- OCR is a strong premium feature because it saves time and has direct variable cost. It should always require user confirmation before changing expense fields.
- PDF/legal reports are premium-worthy, but language must avoid promising legal advice or court outcomes. Sell "organized evidence" and "mediation-ready summaries," not legal guarantees.
- Storage is a clean packaging lever, but low-income users must retain access to existing records and deletion/export paths.
- Mediator/lawyer access can be a paid growth loop, but only with scoped, revocable, read-only access and audit events.
- Trial/paywall timing should happen after the user sees value: first balance, first receipt, first report preview, or after inviting a co-parent. Avoid blocking first expense creation.
- Subscription churn risk is high in the first month; RevenueCat reports early cancellation spikes and roughly 30% first-month annual cancellation behavior. KidCost should measure activated trials, not raw trial starts.
- EU/Poland launch should support app-store subscriptions first, but entitlement design should not assume one platform forever. Google Play base plans/offers and Apple win-back/offer-code mechanics make later retention campaigns possible.

### Risks

- Paywalling conflict-critical records can feel exploitative and damage trust.
- Per-parent pricing may increase conflict when one co-parent refuses to pay; family/workspace pricing is simpler for KidCost's first positioning.
- "Court-ready" wording can overpromise in Poland/EU contexts unless reviewed; prefer "PDF report for mediation, lawyer review, or personal records."
- OCR errors in financial data can create disputes; premium automation must remain review-first.
- Professional access creates privacy and liability risk if permissions are broad or hard to revoke.

### Potential GitHub tasks

- Created: https://github.com/gorsky87/KidCost/issues/42 - Define KidCost's freemium and premium entitlement model before implementing payments.
- Created: https://github.com/gorsky87/KidCost/issues/43 - Design paywall/trial timing around achieved user value and instrument conversion/churn events.
- Created: https://github.com/gorsky87/KidCost/issues/44 - Prototype scoped mediator/lawyer read-only access for PDF/export workflows.
- Later: add hardship/fee-waiver policy once pricing is public.
- Later: define referral loop where inviting a co-parent extends premium trial, without making either parent lose access.
