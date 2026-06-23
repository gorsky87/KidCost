# KidCost marketing ideas

## 2026-06-23

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
