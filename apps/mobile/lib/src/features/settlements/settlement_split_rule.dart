import 'package:kidcost_domain/domain.dart' as domain;

class SettlementSplitRule {
  const SettlementSplitRule({
    required this.id,
    required this.currentUserWeight,
    required this.coParentWeight,
    required this.label,
    required this.description,
  });

  final String id;
  final int currentUserWeight;
  final int coParentWeight;
  final String label;
  final String description;

  static const equal = SettlementSplitRule(
    id: 'equal',
    currentUserWeight: 50,
    coParentWeight: 50,
    label: '50/50',
    description: 'Ty 50% / drugi rodzic 50%',
  );

  static const seventyThirty = SettlementSplitRule(
    id: 'seventy-thirty',
    currentUserWeight: 70,
    coParentWeight: 30,
    label: '70/30',
    description: 'Ty 70% / drugi rodzic 30%',
  );

  static const presets = [equal, seventyThirty];

  domain.SplitRule toDomainRule({
    required String currentUserParticipantId,
    required String coParentParticipantId,
  }) {
    return domain.SplitRule.custom({
      currentUserParticipantId: currentUserWeight,
      coParentParticipantId: coParentWeight,
    });
  }

  String get dashboardHelper =>
      'Liczymy podzial $label: Ty $currentUserWeight%, drugi rodzic $coParentWeight%.';

  @override
  bool operator ==(Object other) {
    return other is SettlementSplitRule && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
