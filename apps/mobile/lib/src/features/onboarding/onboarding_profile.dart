class OnboardingProfile {
  const OnboardingProfile({
    required this.familyName,
    required this.childName,
    required this.invitationSkipped,
    this.coParentConnectionState = CoParentConnectionState.solo,
    this.coParentLabel = 'Drugi rodzic',
    this.familyCurrency = 'PLN',
    this.childBirthDate,
    this.coParentEmail,
    this.inviteCode,
  });

  final String familyName;
  final String childName;
  final String? childBirthDate;
  final CoParentConnectionState coParentConnectionState;
  final String coParentLabel;
  final String familyCurrency;
  final String? coParentEmail;
  final String? inviteCode;
  final bool invitationSkipped;

  bool get isSoloFamily =>
      coParentConnectionState == CoParentConnectionState.solo;
}

enum CoParentConnectionState { solo, invited }
