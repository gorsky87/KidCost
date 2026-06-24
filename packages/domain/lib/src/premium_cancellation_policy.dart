enum PremiumCancellationReason {
  tooExpensive('too_expensive', 'Za drogo'),
  noLongerNeeded('no_longer_needed', 'Juz nie potrzebuje'),
  coParentDidNotJoin('coparent_did_not_join', 'Drugi rodzic nie dolaczyl'),
  missingFeature('missing_feature', 'Brakuje waznej funkcji'),
  tooHardToUse('too_hard_to_use', 'Za trudne w uzyciu'),
  privacyConcern('privacy_concern', 'Obawa o prywatnosc'),
  paymentIssue('payment_issue', 'Problem z platnoscia'),
  other('other', 'Inny powod');

  const PremiumCancellationReason(this.code, this.label);

  final String code;
  final String label;
}

enum PremiumCancellationSavePath {
  switchToFree(
    'switch_to_free',
    'Przejdz na Free',
    'Zachowasz podglad kosztow, saldo, dowody i podstawowy eksport.',
  ),
  hardshipHelp(
    'hardship_help',
    'Popros o hardship help',
    'Support moze sprawdzic fee-waiver bez pytania o szczegoly konfliktu.',
  ),
  changeBillingCadence(
    'change_billing_cadence',
    'Zmien rozliczenie',
    'Mozesz wybrac miesieczny albo roczny rytm, gdy billing SDK bedzie gotowy.',
  ),
  exportRecords(
    'export_records',
    'Eksportuj rekordy',
    'Najpierw pobierz dane rodziny, a potem zarzadzaj subskrypcja w sklepie.',
  ),
  remindLater(
    'remind_later',
    'Przypomnij pozniej',
    'Wrocimy z neutralnym przypomnieniem, bez straszenia utrata danych.',
  ),
  contactSupport(
    'contact_support',
    'Kontakt support',
    'Mozesz poprosic o pomoc bez wysylania danych dziecka lub paragonow.',
  );

  const PremiumCancellationSavePath(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;
}

class PremiumCancellationPolicy {
  const PremiumCancellationPolicy({
    required this.recordsRemainReadable,
    required this.featureAccessPreview,
    required this.platformHandoffCopy,
    required this.noPressureCopy,
    required this.reactivationCopy,
    required this.analyticsRequirement,
    required this.reasons,
    required this.savePaths,
  });

  final String recordsRemainReadable;
  final List<String> featureAccessPreview;
  final String platformHandoffCopy;
  final String noPressureCopy;
  final String reactivationCopy;
  final String analyticsRequirement;
  final List<PremiumCancellationReason> reasons;
  final List<PremiumCancellationSavePath> savePaths;
}

const kidCostPremiumCancellationPolicy = PremiumCancellationPolicy(
  recordsRemainReadable:
      'Po anulowaniu nadal widzisz koszty, saldo, dowody i podstawowy eksport.',
  featureAccessPreview: [
    'Reczne koszty i saldo pozostaja dostepne w Free.',
    'Istniejace dowody i historia zostaja czytelne.',
    'Nowe automatyzacje Premium, OCR, PDF i bundle dowodow sa wstrzymane.',
    'Limity storage i raportow pokazywane sa przed kazda akcja Premium.',
  ],
  platformHandoffCopy:
      'Anulowanie platnosci odbywa sie w App Store albo Google Play; KidCost pokazuje instrukcje i nie ukrywa kontroli.',
  noPressureCopy:
      'Nie uzywamy poczucia winy, konfliktu z drugim rodzicem ani strachu przed utrata rekordow jako argumentu retencyjnego.',
  reactivationCopy:
      'Po powrocie do Premium automatyzacje i limity Premium moga zostac wlaczone ponownie dla tej samej rodziny.',
  analyticsRequirement:
      'Analityka zapisuje tylko surface, reason_code, save_path i entitlement_state; bez danych dziecka, wspolrodzica, paragonow i kosztow.',
  reasons: PremiumCancellationReason.values,
  savePaths: PremiumCancellationSavePath.values,
);

bool cancellationReasonCodesAreUnique() {
  final codes = {
    for (final reason in kidCostPremiumCancellationPolicy.reasons) reason.code,
  };
  return codes.length == kidCostPremiumCancellationPolicy.reasons.length;
}

bool cancellationSavePathCodesAreUnique() {
  final codes = {
    for (final path in kidCostPremiumCancellationPolicy.savePaths) path.code,
  };
  return codes.length == kidCostPremiumCancellationPolicy.savePaths.length;
}

bool cancellationCopyAvoidsPressurePatterns() {
  final combined = [
    kidCostPremiumCancellationPolicy.recordsRemainReadable,
    kidCostPremiumCancellationPolicy.platformHandoffCopy,
    kidCostPremiumCancellationPolicy.noPressureCopy,
    kidCostPremiumCancellationPolicy.reactivationCopy,
    ...kidCostPremiumCancellationPolicy.featureAccessPreview,
    for (final path in kidCostPremiumCancellationPolicy.savePaths)
      path.description,
  ].join(' ').toLowerCase();

  const blockedPhrases = {
    'stracisz dziecko',
    'zawiedziesz',
    'drugi rodzic wygra',
    'utracisz rekordy',
    'usunie twoje dane',
  };
  return blockedPhrases.every((phrase) => !combined.contains(phrase));
}
