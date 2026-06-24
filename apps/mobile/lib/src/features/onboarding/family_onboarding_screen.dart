import 'package:flutter/material.dart';

import 'onboarding_profile.dart';

class FamilyOnboardingScreen extends StatefulWidget {
  const FamilyOnboardingScreen({
    required this.userEmail,
    required this.onComplete,
    super.key,
  });

  final String userEmail;
  final ValueChanged<OnboardingProfile> onComplete;

  @override
  State<FamilyOnboardingScreen> createState() => _FamilyOnboardingScreenState();
}

class _FamilyOnboardingScreenState extends State<FamilyOnboardingScreen> {
  final _familyController = TextEditingController();
  final _childController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _coParentEmailController = TextEditingController();
  var _step = _OnboardingStep.choice;
  String? _message;
  String? _inviteCode;

  @override
  void dispose() {
    _familyController.dispose();
    _childController.dispose();
    _birthDateController.dispose();
    _coParentEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start rodziny')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StepHeader(step: _step),
                  const SizedBox(height: 24),
                  _buildStep(),
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    _InlineMessage(message: _message!),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      _OnboardingStep.choice => _ChoiceStep(
        onCreateFamily: () => setState(() {
          _message = null;
          _step = _OnboardingStep.family;
        }),
        onUseInvitation: () => setState(() {
          _message =
              'Zaproszenia zostana podlaczone do backendu. Na razie mozesz zaczac samodzielnie i dodac rodzica pozniej.';
          _step = _OnboardingStep.family;
        }),
      ),
      _OnboardingStep.family => _FamilyStep(
        controller: _familyController,
        defaultName: _defaultFamilyName,
        onNext: () => setState(() {
          _message = null;
          _step = _OnboardingStep.child;
        }),
      ),
      _OnboardingStep.child => _ChildStep(
        childController: _childController,
        birthDateController: _birthDateController,
        onNext: _goToInvite,
      ),
      _OnboardingStep.invite => _InviteStep(
        controller: _coParentEmailController,
        inviteCode: _inviteCode,
        onGenerate: _generateInvite,
        onSkip: _skipInvite,
        onFinish: _finishWithInvite,
      ),
    };
  }

  String get _defaultFamilyName {
    final emailName = widget.userEmail.split('@').first.trim();
    if (emailName.isEmpty) return 'Moja rodzina';
    return 'Rodzina $emailName';
  }

  String get _familyName {
    final value = _familyController.text.trim();
    return value.isEmpty ? _defaultFamilyName : value;
  }

  void _goToInvite() {
    if (_childController.text.trim().isEmpty) {
      setState(() => _message = 'Dodaj imie dziecka, zeby przejsc dalej.');
      return;
    }
    setState(() {
      _message = null;
      _step = _OnboardingStep.invite;
    });
  }

  void _generateInvite() {
    final email = _coParentEmailController.text.trim();
    if (!email.contains('@')) {
      setState(
        () => _message = 'Podaj email drugiego rodzica albo pomin zaproszenie.',
      );
      return;
    }

    setState(() {
      _message = null;
      _inviteCode = _buildInviteCode(email);
    });
  }

  void _skipInvite() {
    widget.onComplete(
      OnboardingProfile(
        familyName: _familyName,
        childName: _childController.text.trim(),
        childBirthDate: _optionalText(_birthDateController),
        invitationSkipped: true,
      ),
    );
  }

  void _finishWithInvite() {
    if (_inviteCode == null) {
      _generateInvite();
      return;
    }

    widget.onComplete(
      OnboardingProfile(
        familyName: _familyName,
        childName: _childController.text.trim(),
        childBirthDate: _optionalText(_birthDateController),
        coParentEmail: _coParentEmailController.text.trim(),
        inviteCode: _inviteCode,
        invitationSkipped: false,
      ),
    );
  }

  String _buildInviteCode(String email) {
    final seed = '${_familyName.toLowerCase()}-$email'.codeUnits.fold<int>(
      0,
      (sum, value) => (sum + value) % 9000,
    );
    return 'KC-${1000 + seed}';
  }

  String? _optionalText(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : value;
  }
}

enum _OnboardingStep { choice, family, child, invite }

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final _OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = switch (step) {
      _OnboardingStep.choice => 'Jak zaczynamy?',
      _OnboardingStep.family => 'Nazwij rodzine',
      _OnboardingStep.child => 'Dodaj dziecko',
      _OnboardingStep.invite => 'Zapros rodzica',
    };
    final subtitle = switch (step) {
      _OnboardingStep.choice =>
        'Mozesz zalozyc rodzine samodzielnie albo dolaczyc z zaproszenia.',
      _OnboardingStep.family =>
        'Nazwa pomaga rozpoznac wspolny kontekst kosztow.',
      _OnboardingStep.child =>
        'W MVP wystarczy jedno dziecko, kolejne dodamy pozniej.',
      _OnboardingStep.invite =>
        'Zaproszenie nie pokazuje danych rodzinnych przed akceptacja.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(subtitle, style: textTheme.bodyLarge),
      ],
    );
  }
}

class _ChoiceStep extends StatelessWidget {
  const _ChoiceStep({
    required this.onCreateFamily,
    required this.onUseInvitation,
  });

  final VoidCallback onCreateFamily;
  final VoidCallback onUseInvitation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: onCreateFamily,
          icon: const Icon(Icons.group_add_outlined),
          label: const Text('Zakladam rodzine'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onUseInvitation,
          icon: const Icon(Icons.mark_email_read_outlined),
          label: const Text('Mam zaproszenie'),
        ),
      ],
    );
  }
}

class _FamilyStep extends StatelessWidget {
  const _FamilyStep({
    required this.controller,
    required this.defaultName,
    required this.onNext,
  });

  final TextEditingController controller;
  final String defaultName;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Nazwa rodziny',
            hintText: defaultName,
            prefixIcon: const Icon(Icons.home_outlined),
          ),
          onSubmitted: (_) => onNext(),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onNext, child: const Text('Dalej')),
      ],
    );
  }
}

class _ChildStep extends StatelessWidget {
  const _ChildStep({
    required this.childController,
    required this.birthDateController,
    required this.onNext,
  });

  final TextEditingController childController;
  final TextEditingController birthDateController;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: childController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Imie dziecka',
            prefixIcon: Icon(Icons.child_care_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: birthDateController,
          keyboardType: TextInputType.datetime,
          decoration: const InputDecoration(
            labelText: 'Data urodzenia (opcjonalnie)',
            hintText: 'RRRR-MM-DD',
            prefixIcon: Icon(Icons.event_outlined),
          ),
          onSubmitted: (_) => onNext(),
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: onNext, child: const Text('Dalej')),
      ],
    );
  }
}

class _InviteStep extends StatelessWidget {
  const _InviteStep({
    required this.controller,
    required this.inviteCode,
    required this.onGenerate,
    required this.onSkip,
    required this.onFinish,
  });

  final TextEditingController controller;
  final String? inviteCode;
  final VoidCallback onGenerate;
  final VoidCallback onSkip;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email drugiego rodzica',
            prefixIcon: Icon(Icons.alternate_email),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onGenerate,
          icon: const Icon(Icons.key_outlined),
          label: const Text('Wygeneruj kod'),
        ),
        if (inviteCode != null) ...[
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text('Kod zaproszenia: $inviteCode'),
            subtitle: const Text('Kod nie ujawnia kosztow ani danych dziecka.'),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(onPressed: onFinish, child: const Text('Zakoncz')),
        TextButton(onPressed: onSkip, child: const Text('Pomin zaproszenie')),
        const SizedBox(height: 12),
        const _TrustNote(),
      ],
    );
  }
}

class _TrustNote extends StatelessWidget {
  const _TrustNote();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Prywatnosc i zaufanie'),
            subtitle: Text(
              'Dane rodziny widza tylko osoby z aktywnym dostepem do tej rodziny.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.history_outlined),
            title: Text('Historia zmian'),
            subtitle: Text(
              'Koszty i statusy beda mialy historie, zeby bylo widac kto i kiedy zmienil wpis.',
            ),
          ),
          ListTile(
            leading: Icon(Icons.balance_outlined),
            title: Text('Porzadkujemy fakty'),
            subtitle: Text(
              'KidCost pomaga dokumentowac koszty, ale nie zastepuje porady prawnej.',
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          message,
          style: TextStyle(color: colors.onSecondaryContainer),
        ),
      ),
    );
  }
}
