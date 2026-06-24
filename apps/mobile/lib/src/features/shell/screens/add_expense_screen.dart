import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../expenses/attachment_storage.dart';
import '../../expenses/expense_models.dart';
import '../../expenses/expense_visuals.dart';
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
  static const _maxAttachmentBytes = 8 * 1024 * 1024;
  static const _supportedAttachmentTypes = {
    'image/jpeg',
    'image/png',
    'application/pdf',
  };

  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _titleController = TextEditingController();
  final _manualPayerController = TextEditingController();
  late final List<ExpensePayer> _payers;
  ExpenseCategory _category = expenseCategories.first;
  ExpensePayer? _payer;
  AttachmentDraft? _attachmentDraft;
  bool _isSaving = false;
  bool _attachmentFailedOnLastSave = false;
  String? _amountError;
  String? _dateError;
  String? _payerError;

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(DateTime.now());
    _manualPayerController.text = widget.profile.coParentLabel;
    _payers = [
      ExpensePayer(id: 'self', label: widget.userEmail, isCurrentUser: true),
      ExpensePayer(
        id: widget.profile.isSoloFamily ? 'manual-co-parent' : 'co-parent',
        label: widget.profile.coParentLabel,
        isCurrentUser: false,
        isManual: widget.profile.isSoloFamily,
      ),
    ];
    _payer = _payers.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dateController.dispose();
    _titleController.dispose();
    _manualPayerController.dispose();
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
          if (widget.profile.isSoloFamily) ...[
            const _SoloModeBanner(),
            const SizedBox(height: 12),
          ],
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
          _CategoryPicker(
            selectedCategory: _category,
            isEnabled: !_isSaving,
            onCategorySelected: (category) {
              setState(() => _category = category);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExpensePayer>(
            key: const Key('expense-payer-picker'),
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
                      if (payer?.isManual == true &&
                          _manualPayerController.text.trim().isEmpty) {
                        _manualPayerController.text = payer!.label;
                      }
                    });
                  },
          ),
          if (_payer?.isManual == true) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _manualPayerController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Reczna etykieta platnika',
                helperText: 'To nie jest konto uzytkownika ani user_id.',
                prefixIcon: const Icon(Icons.badge_outlined),
                errorText: _payerError,
              ),
              onChanged: (_) {
                if (_payerError != null) {
                  setState(() => _payerError = null);
                }
              },
            ),
          ],
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
            label: const Text('Dodaj paragon lub PDF'),
          ),
          if (_attachmentDraft != null) ...[
            const SizedBox(height: 12),
            _AttachmentReviewTray(
              attachment: _attachmentDraft!,
              status: _attachmentStatus,
              onPreview: _previewAttachment,
              onReplace: _chooseAttachment,
              onRemove: _removeAttachment,
              onAddAnother: _explainSingleAttachmentMvp,
              onSaveWithoutReceipt: _removeAttachment,
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Paragon jest opcjonalny. Mozesz zapisac koszt bez dowodu i dodac go pozniej.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_attachmentFailedOnLastSave) ...[
            const SizedBox(height: 8),
            const _AttachmentSaveNotice(
              icon: Icons.cloud_off_outlined,
              text:
                  'Ostatni koszt zostal zapisany, ale upload zalacznika wymaga ponowienia.',
            ),
          ],
          const SizedBox(height: 16),
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
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Aparat'),
                subtitle: const Text('Zrob zdjecie paragonu'),
                onTap: () => Navigator.of(context).pop(
                  _demoAttachment(
                    fileName: 'paragon.jpg',
                    contentType: 'image/jpeg',
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeria'),
                subtitle: const Text('Wybierz zdjecie z telefonu'),
                onTap: () => Navigator.of(context).pop(
                  _demoAttachment(
                    fileName: 'paragon-z-galerii.jpg',
                    contentType: 'image/jpeg',
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('PDF'),
                subtitle: const Text('Dodaj fakture lub rachunek'),
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

    setState(() {
      _attachmentDraft = draft;
      _attachmentFailedOnLastSave = false;
    });
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
    final selectedPayer = _payer;
    final manualPayerLabel = _manualPayerController.text.trim();
    final payer = selectedPayer?.isManual == true
        ? selectedPayer!.copyWith(label: manualPayerLabel)
        : selectedPayer;
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
      _payerError = payer == null
          ? 'Wybierz kto zaplacil.'
          : selectedPayer!.isManual && manualPayerLabel.isEmpty
          ? 'Wpisz etykiete drugiego rodzica.'
          : null;
    });

    if (amountCents <= 0 ||
        date.isEmpty ||
        payer == null ||
        _payerError != null) {
      return;
    }

    final attachmentStatusBeforeSave = _attachmentStatus;
    setState(() => _isSaving = true);

    final expenseId = 'expense-${DateTime.now().microsecondsSinceEpoch}';
    ExpenseAttachment? attachment;
    var uploadFailed = false;
    var skippedInvalidAttachment = false;
    final draft = _attachmentDraft;
    if (draft != null &&
        attachmentStatusBeforeSave == _AttachmentReviewStatus.ready) {
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
    } else if (draft != null) {
      skippedInvalidAttachment = true;
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
      visibility: widget.profile.isSoloFamily
          ? ExpenseVisibility.privateAuthor
          : ExpenseVisibility.sharedFamily,
      attachment: attachment,
    );

    widget.onExpenseSaved(expense);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _amountController.clear();
      _dateController.text = _formatDate(DateTime.now());
      _titleController.clear();
      _category = expenseCategories.first;
      _payer = _payers.first;
      _manualPayerController.text = widget.profile.coParentLabel;
      _attachmentDraft = null;
      _attachmentFailedOnLastSave = uploadFailed;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          skippedInvalidAttachment
              ? 'Koszt zapisany bez paragonu.'
              : uploadFailed
              ? 'Koszt zapisany, ale zalacznik wymaga ponowienia.'
              : 'Koszt zapisany.',
        ),
      ),
    );
  }

  _AttachmentReviewStatus get _attachmentStatus {
    final draft = _attachmentDraft;
    if (draft == null) return _AttachmentReviewStatus.ready;
    if (!_supportedAttachmentTypes.contains(draft.contentType)) {
      return _AttachmentReviewStatus.unsupported;
    }
    if (draft.bytes.lengthInBytes > _maxAttachmentBytes) {
      return _AttachmentReviewStatus.tooLarge;
    }
    if (_isSaving) return _AttachmentReviewStatus.uploading;
    return _AttachmentReviewStatus.ready;
  }

  void _removeAttachment() {
    setState(() {
      _attachmentDraft = null;
      _attachmentFailedOnLastSave = false;
    });
  }

  void _previewAttachment() {
    final draft = _attachmentDraft;
    if (draft == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_attachmentIcon(draft.contentType)),
                  title: Text(draft.fileName),
                  subtitle: Text(
                    '${draft.contentType} • ${_formatBytes(draft.bytes.lengthInBytes)}',
                  ),
                ),
                const _AttachmentSaveNotice(
                  icon: Icons.fact_check_outlined,
                  text:
                      'Sprawdz, czy widac caly paragon, czytelna kwote i date. To pomaga uniknac pozniejszych niejasnosci.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _explainSingleAttachmentMvp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'W tej wersji wybierz jeden najlepiej czytelny dowod. Kolejne pliki sa przygotowane jako nastepny krok.',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return [
      date.year.toString().padLeft(4, '0'),
      date.month.toString().padLeft(2, '0'),
      date.day.toString().padLeft(2, '0'),
    ].join('-');
  }
}

class _AttachmentReviewTray extends StatelessWidget {
  const _AttachmentReviewTray({
    required this.attachment,
    required this.status,
    required this.onPreview,
    required this.onReplace,
    required this.onRemove,
    required this.onAddAnother,
    required this.onSaveWithoutReceipt,
  });

  final AttachmentDraft attachment;
  final _AttachmentReviewStatus status;
  final VoidCallback onPreview;
  final VoidCallback onReplace;
  final VoidCallback onRemove;
  final VoidCallback onAddAnother;
  final VoidCallback onSaveWithoutReceipt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AttachmentThumbnail(attachment: attachment, status: status),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        attachment.fileName,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${attachment.contentType} • ${_formatBytes(attachment.bytes.lengthInBytes)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      _AttachmentStatusPill(status: status),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _AttachmentSaveNotice(
              icon: Icons.tips_and_updates_outlined,
              text: status.guidanceText,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onPreview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Podejrzyj'),
                ),
                OutlinedButton.icon(
                  onPressed: onReplace,
                  icon: const Icon(Icons.cameraswitch_outlined),
                  label: const Text('Zamien'),
                ),
                OutlinedButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Usun'),
                ),
                OutlinedButton.icon(
                  onPressed: onAddAnother,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Dodaj kolejny'),
                ),
                TextButton.icon(
                  onPressed: onSaveWithoutReceipt,
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: Text(
                    'Zapisz bez paragonu',
                    style: TextStyle(color: colors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  const _AttachmentThumbnail({required this.attachment, required this.status});

  final AttachmentDraft attachment;
  final _AttachmentReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);
    return Semantics(
      label: 'Miniatura zalacznika: ${attachment.fileName}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: color.withValues(alpha: 0.32)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox.square(
          dimension: 72,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(_attachmentIcon(attachment.contentType), color: color),
              if (status == _AttachmentReviewStatus.uploading)
                const Positioned(
                  right: 8,
                  bottom: 8,
                  child: SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentStatusPill extends StatelessWidget {
  const _AttachmentStatusPill({required this.status});

  final _AttachmentReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color(context);
    return Chip(
      avatar: Icon(status.icon, color: color, size: 18),
      label: Text(status.label),
      side: BorderSide(color: color.withValues(alpha: 0.32)),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _AttachmentSaveNotice extends StatelessWidget {
  const _AttachmentSaveNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(text),
    );
  }
}

enum _AttachmentReviewStatus {
  ready,
  uploading,
  tooLarge,
  unsupported;

  String get label {
    switch (this) {
      case _AttachmentReviewStatus.ready:
        return 'Gotowy do wyslania';
      case _AttachmentReviewStatus.uploading:
        return 'Wysylanie';
      case _AttachmentReviewStatus.tooLarge:
        return 'Plik za duzy';
      case _AttachmentReviewStatus.unsupported:
        return 'Nieobslugiwany format';
    }
  }

  String get guidanceText {
    switch (this) {
      case _AttachmentReviewStatus.ready:
        return 'Sprawdz, czy widac caly paragon, czytelna kwote i date. Zalacznik nie blokuje zapisu kosztu.';
      case _AttachmentReviewStatus.uploading:
        return 'Zapisujemy koszt i wysylamy zalacznik. Jesli upload sie nie uda, koszt nadal zostanie zapisany.';
      case _AttachmentReviewStatus.tooLarge:
        return 'Ten plik moze byc za duzy do wyslania. Mozesz go usunac i zapisac koszt bez paragonu.';
      case _AttachmentReviewStatus.unsupported:
        return 'Obslugujemy JPG, PNG i PDF. Mozesz zamienic plik albo zapisac koszt bez paragonu.';
    }
  }

  IconData get icon {
    switch (this) {
      case _AttachmentReviewStatus.ready:
        return Icons.check_circle_outline;
      case _AttachmentReviewStatus.uploading:
        return Icons.cloud_upload_outlined;
      case _AttachmentReviewStatus.tooLarge:
        return Icons.sd_storage_outlined;
      case _AttachmentReviewStatus.unsupported:
        return Icons.block_outlined;
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case _AttachmentReviewStatus.ready:
        return Theme.of(context).colorScheme.primary;
      case _AttachmentReviewStatus.uploading:
        return Theme.of(context).colorScheme.tertiary;
      case _AttachmentReviewStatus.tooLarge:
      case _AttachmentReviewStatus.unsupported:
        return Theme.of(context).colorScheme.error;
    }
  }
}

IconData _attachmentIcon(String contentType) {
  if (contentType == 'application/pdf') return Icons.picture_as_pdf_outlined;
  if (contentType.startsWith('image/')) return Icons.image_outlined;
  return Icons.insert_drive_file_outlined;
}

String _formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(mb >= 10 ? 0 : 1)} MB';
  }
  if (bytes >= 1024) {
    final kb = bytes / 1024;
    return '${kb.toStringAsFixed(kb >= 10 ? 0 : 1)} KB';
  }
  return '$bytes B';
}

class _SoloModeBanner extends StatelessWidget {
  const _SoloModeBanner();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.lock_person_outlined),
        title: Text('Tryb solo'),
        subtitle: Text(
          'Koszt zapiszesz prywatnie dla siebie. Drugi rodzic nie zobaczy go bez zaproszenia i jawnego udostepnienia.',
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({
    required this.selectedCategory,
    required this.isEnabled,
    required this.onCategorySelected,
  });

  final ExpenseCategory selectedCategory;
  final bool isEnabled;
  final ValueChanged<ExpenseCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Kategoria',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final category in expenseCategories)
            ChoiceChip(
              avatar: Icon(
                category.icon,
                color: category.accentColor,
                size: 18,
              ),
              label: Text(category.label),
              selected: category.id == selectedCategory.id,
              onSelected: isEnabled
                  ? (_) => onCategorySelected(category)
                  : null,
            ),
        ],
      ),
    );
  }
}
