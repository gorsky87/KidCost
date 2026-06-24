class OnboardingProfile {
  const OnboardingProfile({
    required this.familyName,
    required this.childName,
    required this.invitationSkipped,
    this.childBirthDate,
    this.coParentEmail,
    this.inviteCode,
  });

  final String familyName;
  final String childName;
  final String? childBirthDate;
  final String? coParentEmail;
  final String? inviteCode;
  final bool invitationSkipped;
}
