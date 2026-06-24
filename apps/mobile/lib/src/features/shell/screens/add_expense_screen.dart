import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../expenses/attachment_storage.dart';
import '../../expenses/expense_models.dart';
import '../../onboarding/onboarding_profile.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    required this.profile,
    required this.userEmail,
    required this.attachmentStorage,
    required this.onExpenseSaved,
    super.key,
  });

  final OnboardingProfile profile;
  final String userEmail;
  final AttachmentStorage attachmentStorage;
  final ValueChanged<ExpenseEntry> onExpenseSaved;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _titleController = TextEditingController();
  late final List<ExpensePayer> _payers;
  ExpenseCategory _category = expenseCategories.first;
  ExpensePayer? _payer;
  AttachmentDraft? _attachmentDraft;
  bool _isSaving = false;
  String? _amountError;
  String? _dateError;
  String? _payerError;

  @override
  void initState() {
    super.initState();
    _payers = [
      ExpensePayer(id: 'self', label: widget.userEmail, isCurrentUser: true),
      const ExpensePayer(
        id: 'co-parent',
        label: 'Drugi rodzic',
        isCurrentUser: false,
      ),
    ];
    _payer = _payers.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nowy koszt', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: InputDecoration(
              labelText: 'Kwota',
              hintText: '0,00',
              prefixIcon: const Icon(Icons.payments_outlined),
              errorText: _amountError,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dateController,
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Data kosztu',
              hintText: 'RRRR-MM-DD',
              prefixIcon: const Icon(Icons.event_outlined),
              errorText: _dateError,
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Dziecko',
              prefixIcon: Icon(Icons.child_care_outlined),
            ),
            child: Text(widget.profile.childName),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExpenseCategory>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Kategoria',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              for (final category in expenseCategories)
                DropdownMenuItem(value: category, child: Text(category.label)),
            ],
            onChanged: _isSaving
                ? null
                : (category) {
                    if (category != null) {
                      setState(() => _category = category);
                    }
                  },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExpensePayer>(
            initialValue: _payer,
            decoration: InputDecoration(
              labelText: 'Kto zaplacil',
              prefixIcon: const Icon(Icons.account_circle_outlined),
              errorText: _payerError,
            ),
            items: [
              for (final payer in _payers)
                DropdownMenuItem(value: payer, child: Text(payer.label)),
            ],
            onChanged: _isSaving
                ? null
                : (payer) {
                    setState(() {
                      _payer = payer;
                      _payerError = null;
                    });
                  },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Opis lub nazwa kosztu',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _isSaving ? null : _chooseAttachment,
            icon: const Icon(Icons.attach_file),
            label: Text(
              _attachmentDraft == null
                  ? 'Dodaj paragon lub PDF'
                  : _attachmentDraft!.fileName,
            ),
          ),
          if (_attachmentDraft != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Zalacznik nie blokuje zapisu kosztu.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveExpense,
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Zapisz koszt'),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseAttachment() async {
    final draft = await showModalBottomSheet<AttachmentDraft>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Zdjecie paragonu'),
                onTap: () => Navigator.of(context).pop(
                  _demoAttachment(
                    fileName: 'paragon.jpg',
                    contentType: 'image/jpeg',
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('PDF'),
                onTap: () => Navigator.of(context).pop(
                  _demoAttachment(
                    fileName: 'rachunek.pdf',
                    contentType: 'application/pdf',
                  ),
                ),
              ),
              if (_attachmentDraft != null)
                ListTile(
                  leading: const Icon(Icons.close),
                  title: const Text('Usun zalacznik'),
                  onTap: () => Navigator.of(context).pop(null),
                ),
            ],
          ),
        );
      },
    );

    setState(() => _attachmentDraft = draft);
  }

  AttachmentDraft _demoAttachment({
    required String fileName,
    required String contentType,
  }) {
    return AttachmentDraft(
      fileName: fileName,
      contentType: contentType,
      bytes: Uint8List.fromList(utf8.encode('KidCost demo attachment')),
    );
  }

  Future<void> _saveExpense() async {
    final payer = _payer;
    int amountCents;
    try {
      amountCents = parseAmountToCents(_amountController.text);
    } on FormatException {
      amountCents = 0;
    }

    final date = _dateController.text.trim();
    setState(() {
      _amountError = amountCents > 0 ? null : 'Podaj kwote wieksza od 0.';
      _dateError = date.isEmpty ? 'Podaj date kosztu.' : null;
      _payerError = payer == null ? 'Wybierz kto zaplacil.' : null;
    });

    if (amountCents <= 0 || date.isEmpty || payer == null) {
      return;
    }

    setState(() => _isSaving = true);

    final expenseId = 'expense-${DateTime.now().microsecondsSinceEpoch}';
    ExpenseAttachment? attachment;
    var uploadFailed = false;
    final draft = _attachmentDraft;
    if (draft != null) {
      try {
        final upload = await widget.attachmentStorage.upload(
          expenseId: expenseId,
          attachment: draft,
        );
        attachment = ExpenseAttachment(
          fileName: draft.fileName,
          contentType: draft.contentType,
          status: AttachmentStatus.uploaded,
          storagePath: upload.storagePath,
        );
      } catch (_) {
        uploadFailed = true;
        attachment = ExpenseAttachment(
          fileName: draft.fileName,
          contentType: draft.contentType,
          status: AttachmentStatus.failed,
          errorMessage: 'Nie udalo sie wyslac zalacznika.',
        );
      }
    }

    final expense = ExpenseEntry(
      id: expenseId,
      amountCents: amountCents,
      expenseDate: date,
      childName: widget.profile.childName,
      category: _category,
      paidBy: payer,
      title: _titleController.text.trim().isEmpty
          ? _category.label
          : _titleController.text.trim(),
      createdAt: DateTime.now().toUtc(),
      attachment: attachment,
    );

    widget.onExpenseSaved(expense);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _amountController.clear();
      _dateController.clear();
      _titleController.clear();
      _category = expenseCategories.first;
      _payer = _payers.first;
      _attachmentDraft = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          uploadFailed
              ? 'Koszt zapisany, ale zalacznik wymaga ponowienia.'
              : 'Koszt zapisany.',
        ),
      ),
    );
  }
}
