import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kidcost_domain/domain.dart' as domain;

import '../../child_info/child_info_models.dart';
import '../../expenses/attachment_storage.dart';
import '../../expenses/expense_models.dart';
import '../../expenses/expense_visuals.dart';
import '../../onboarding/onboarding_profile.dart';
import '../../premium/premium_discovery.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({
    required this.profile,
    required this.userEmail,
    required this.attachmentStorage,
    required this.onExpenseSaved,
    this.initialTemplate,
    this.currentDate,
    this.calendarEvents = const [],
    this.childInfoCards = const [],
    this.existingExpenses = const [],
    this.showReceiptOcrPremiumHint = false,
    this.onPremiumHintDismissed,
    super.key,
  });

  final OnboardingProfile profile;
  final String userEmail;
  final AttachmentStorage attachmentStorage;
  final ValueChanged<ExpenseEntry> onExpenseSaved;
  final ExpenseTemplate? initialTemplate;
  final DateTime? currentDate;
  final List<ExpenseCalendarEventLink> calendarEvents;
  final List<ChildInfoCard> childInfoCards;
  final List<ExpenseEntry> existingExpenses;
  final bool showReceiptOcrPremiumHint;
  final ValueChanged<PremiumDiscoveryPoint>? onPremiumHintDismissed;

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
  static const _defaultReimbursementDeadlineWindow = Duration(days: 30);

  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _serviceStartController = TextEditingController();
  final _serviceEndController = TextEditingController();
  final _serviceQuantityController = TextEditingController();
  final _serviceScopeController = TextEditingController();
  final _titleController = TextEditingController();
  final _manualPayerController = TextEditingController();
  final _serviceDateController = TextEditingController();
  final _documentDateController = TextEditingController();
  final _merchantController = TextEditingController();
  final _documentNumberController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  final _originalReceiptAmountController = TextEditingController();
  final _submittedAtController = TextEditingController();
  final _noticeDueAtController = TextEditingController();
  final _paymentDueAtController = TextEditingController();
  final _paidAtController = TextEditingController();
  final _providerNameController = TextEditingController();
  final _providerReferenceController = TextEditingController();
  final _providerAmountDueController = TextEditingController();
  final _providerDueDateController = TextEditingController();
  final _medicalServiceDateController = TextEditingController();
  final _medicalProviderController = TextEditingController();
  final _medicalGrossAmountController = TextEditingController();
  final _medicalCoveredAmountController = TextEditingController();
  final _medicalPatientResponsibilityController = TextEditingController();
  late final List<ExpensePayer> _payers;
  ExpenseCategory _category = expenseCategories.first;
  ExpensePayer? _payer;
  ReimbursementRequestKind _requestKind =
      ReimbursementRequestKind.reimburseParent;
  ProviderPaymentStatus _providerPaymentStatus = ProviderPaymentStatus.sent;
  String _receiptCurrency = 'PLN';
  AttachmentDraft? _attachmentDraft;
  EvidenceType? _evidenceType;
  bool? _buyerNamePresent;
  bool _isSaving = false;
  bool _attachmentFailedOnLastSave = false;
  String? _calendarEventId;
  String? _childInfoCardId;
  String? _relatedExpenseId;
  String? _amountError;
  String? _dateError;
  String? _payerError;
  String? _deadlineError;
  String? _providerPaymentError;
  String? _lineItemsError;
  List<ExpenseLineItem> _lineItems = const [];
  bool _duplicateCueDismissed = false;
  bool _ocrDraftNeedsReview = false;
  bool _ocrDraftManuallyConfirmed = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_refreshAgreementPreview);
    _amountController.addListener(_refreshDuplicatePreview);
    _dateController.addListener(_refreshDuplicatePreview);
    _serviceDateController.addListener(_refreshDuplicatePreview);
    _documentDateController.addListener(_refreshDuplicatePreview);
    _merchantController.addListener(_refreshDuplicatePreview);
    _documentNumberController.addListener(_refreshDuplicatePreview);
    final currentDate = widget.currentDate ?? DateTime.now();
    _dateController.text = _formatDate(currentDate);
    _submittedAtController.text = _formatDate(currentDate);
    _noticeDueAtController.text = _formatDate(
      currentDate.add(_defaultReimbursementDeadlineWindow),
    );
    _paymentDueAtController.text = _formatDate(
      currentDate.add(_defaultReimbursementDeadlineWindow),
    );
    _manualPayerController.text = widget.profile.coParentLabel;
    _receiptCurrency = widget.profile.familyCurrency;
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
    _applyInitialTemplate();
  }

  @override
  void dispose() {
    _amountController.removeListener(_refreshAgreementPreview);
    _amountController.removeListener(_refreshDuplicatePreview);
    _dateController.removeListener(_refreshDuplicatePreview);
    _serviceDateController.removeListener(_refreshDuplicatePreview);
    _documentDateController.removeListener(_refreshDuplicatePreview);
    _merchantController.removeListener(_refreshDuplicatePreview);
    _documentNumberController.removeListener(_refreshDuplicatePreview);
    _amountController.dispose();
    _dateController.dispose();
    _serviceStartController.dispose();
    _serviceEndController.dispose();
    _serviceQuantityController.dispose();
    _serviceScopeController.dispose();
    _titleController.dispose();
    _manualPayerController.dispose();
    _serviceDateController.dispose();
    _documentDateController.dispose();
    _merchantController.dispose();
    _documentNumberController.dispose();
    _paymentMethodController.dispose();
    _originalReceiptAmountController.dispose();
    _submittedAtController.dispose();
    _noticeDueAtController.dispose();
    _paymentDueAtController.dispose();
    _paidAtController.dispose();
    _providerNameController.dispose();
    _providerReferenceController.dispose();
    _providerAmountDueController.dispose();
    _providerDueDateController.dispose();
    _medicalServiceDateController.dispose();
    _medicalProviderController.dispose();
    _medicalGrossAmountController.dispose();
    _medicalCoveredAmountController.dispose();
    _medicalPatientResponsibilityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nowy koszt', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          if (widget.profile.isSoloFamily) ...[
            const _SoloModeBanner(),
            const SizedBox(height: 12),
          ],
          if (widget.initialTemplate != null) ...[
            _TemplateSourceBanner(template: widget.initialTemplate!),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            style: Theme.of(context).textTheme.headlineMedium,
            decoration: InputDecoration(
              labelText: 'Kwota do rozliczenia',
              hintText: '0,00',
              prefixIcon: const Icon(Icons.payments_outlined),
              suffixText: widget.profile.familyCurrency,
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
          if (widget.calendarEvents.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              key: const Key('expense-calendar-event-picker'),
              initialValue: _calendarEventId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Wydarzenie kalendarza',
                prefixIcon: Icon(Icons.event_available_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Bez wydarzenia'),
                ),
                for (final event in widget.calendarEvents)
                  DropdownMenuItem<String?>(
                    value: event.id,
                    child: Text(event.displayLabel),
                  ),
              ],
              onChanged: _isSaving
                  ? null
                  : (eventId) => setState(() => _calendarEventId = eventId),
            ),
            if (_selectedCalendarEvent != null) ...[
              const SizedBox(height: 8),
              _CalendarEventLinkCard(event: _selectedCalendarEvent!),
            ],
          ],
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
              setState(() {
                _category = category;
                _duplicateCueDismissed = false;
                _relatedExpenseId = null;
              });
            },
          ),
          if (_potentialDuplicateExpenses.isNotEmpty &&
              !_duplicateCueDismissed) ...[
            const SizedBox(height: 12),
            _PotentialDuplicateCue(
              matches: _potentialDuplicateExpenses,
              selectedExpenseId: _relatedExpenseId,
              onViewExisting: _showExistingExpensePreview,
              onContinueAnyway: () {
                setState(() => _duplicateCueDismissed = true);
              },
              onLinkRelated: (expense) {
                setState(() {
                  _relatedExpenseId = expense.id;
                  _duplicateCueDismissed = true;
                });
              },
            ),
          ],
          if (_selectedRelatedExpense != null) ...[
            const SizedBox(height: 8),
            _RelatedExpenseDraftCard(
              expense: _selectedRelatedExpense!,
              onRemove: () => setState(() => _relatedExpenseId = null),
            ),
          ],
          if (widget.childInfoCards.isNotEmpty) ...[
            const SizedBox(height: 12),
            if (_suggestedChildInfoCards.isNotEmpty) ...[
              _ChildInfoSuggestionCard(cards: _suggestedChildInfoCards),
              const SizedBox(height: 8),
            ],
            DropdownButtonFormField<String?>(
              key: const Key('expense-child-info-card-picker'),
              initialValue: _childInfoCardId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Kontekst dziecka',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Bez karty informacji'),
                ),
                for (final card in widget.childInfoCards)
                  DropdownMenuItem<String?>(
                    value: card.id,
                    child: Text(
                      '${card.type.label}: ${card.title} (${card.visibilityLabel})',
                    ),
                  ),
              ],
              onChanged: _isSaving
                  ? null
                  : (cardId) => setState(() => _childInfoCardId = cardId),
            ),
          ],
          const SizedBox(height: 12),
          _SharedExpenseRuleCard(decision: _currentAgreementDecision),
          const SizedBox(height: 12),
          _ReimbursementDeadlineFields(
            submittedAtController: _submittedAtController,
            noticeDueAtController: _noticeDueAtController,
            paymentDueAtController: _paymentDueAtController,
            paidAtController: _paidAtController,
            errorText: _deadlineError,
          ),
          const SizedBox(height: 12),
          _ProviderPaymentFields(
            requestKind: _requestKind,
            providerNameController: _providerNameController,
            providerReferenceController: _providerReferenceController,
            providerAmountDueController: _providerAmountDueController,
            providerDueDateController: _providerDueDateController,
            status: _providerPaymentStatus,
            errorText: _providerPaymentError,
            onRequestKindChanged: (kind) {
              setState(() {
                _requestKind = kind;
                _providerPaymentError = null;
              });
            },
            onStatusChanged: (status) {
              setState(() => _providerPaymentStatus = status);
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ExpensePayer>(
            key: const Key('expense-payer-picker'),
            initialValue: _payer,
            isExpanded: true,
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
            key: const Key('expense-title-field'),
            controller: _titleController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Opis lub nazwa kosztu',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 12),
          _ServicePeriodFields(
            startController: _serviceStartController,
            endController: _serviceEndController,
            quantityController: _serviceQuantityController,
            scopeController: _serviceScopeController,
          ),
          const SizedBox(height: 12),
          _ExpenseLineItemsCard(
            lineItems: _lineItems,
            parentAmountCents: _parsedAmountOrZero,
            errorText: _lineItemsError,
            onAddLineItem: _showAddLineItemSheet,
            onRemoveLineItem: (item) {
              setState(() {
                _lineItems = _lineItems
                    .where((lineItem) => lineItem.id != item.id)
                    .toList();
                _lineItemsError = null;
              });
            },
          ),
          if (_isMedicalCategory) ...[
            const SizedBox(height: 12),
            _MedicalExpensePacketFields(
              requestedReimbursementCents: _parsedAmountOrZero,
              serviceDateController: _medicalServiceDateController,
              providerController: _medicalProviderController,
              patientName: widget.profile.childName,
              grossAmountController: _medicalGrossAmountController,
              coveredAmountController: _medicalCoveredAmountController,
              patientResponsibilityController:
                  _medicalPatientResponsibilityController,
            ),
          ],
          if (_attachmentDraft == null) ...[
            const SizedBox(height: 12),
            _ExpenseVerificationFields(
              evidenceType: _evidenceType,
              serviceDateController: _serviceDateController,
              documentDateController: _documentDateController,
              merchantController: _merchantController,
              documentNumberController: _documentNumberController,
              paymentMethodController: _paymentMethodController,
              buyerNamePresent: _buyerNamePresent,
              initiallyExpanded: false,
              onEvidenceTypeChanged: (type) {
                setState(() {
                  _evidenceType = type;
                  _duplicateCueDismissed = false;
                });
              },
              onBuyerNamePresentChanged: (value) {
                setState(() => _buyerNamePresent = value);
              },
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('receipt-currency-picker'),
            initialValue: _receiptCurrency,
            decoration: const InputDecoration(
              labelText: 'Waluta na paragonie',
              prefixIcon: Icon(Icons.currency_exchange_outlined),
            ),
            items: [
              for (final currency in _supportedReceiptCurrencies)
                DropdownMenuItem(value: currency, child: Text(currency)),
            ],
            onChanged: _isSaving
                ? null
                : (currency) {
                    if (currency == null) return;
                    setState(() => _receiptCurrency = currency);
                  },
          ),
          const SizedBox(height: 12),
          _CurrencyGuardrailCard(
            familyCurrency: widget.profile.familyCurrency,
            receiptCurrency: _receiptCurrency,
          ),
          if (_usesForeignReceiptCurrency) ...[
            const SizedBox(height: 12),
            TextField(
              key: const Key('original-receipt-amount-field'),
              controller: _originalReceiptAmountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Kwota z paragonu',
                hintText: '0,00',
                prefixIcon: const Icon(Icons.receipt_long_outlined),
                suffixText: _receiptCurrency,
                helperText:
                    'Opcjonalny kontekst. KidCost nie przelicza kursow w MVP.',
              ),
            ),
          ],
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
              showReceiptOcrPremiumHint: widget.showReceiptOcrPremiumHint,
              onPreview: _previewAttachment,
              onReplace: _chooseAttachment,
              onRemove: _removeAttachment,
              onAddAnother: _explainSingleAttachmentMvp,
              onSaveWithoutReceipt: _removeAttachment,
              evidenceType: _evidenceType,
              serviceDateController: _serviceDateController,
              documentDateController: _documentDateController,
              merchantController: _merchantController,
              documentNumberController: _documentNumberController,
              paymentMethodController: _paymentMethodController,
              buyerNamePresent: _buyerNamePresent,
              showOcrReview: _shouldShowOcrReview,
              ocrFields: _ocrReviewFields,
              isOcrReviewComplete: _isOcrReviewComplete,
              onConfirmOcrReview: _confirmOcrReview,
              onEvidenceTypeChanged: (type) {
                setState(() => _evidenceType = type);
              },
              onBuyerNamePresentChanged: (value) {
                setState(() => _buyerNamePresent = value);
              },
              onPremiumHintDismissed: () => widget.onPremiumHintDismissed?.call(
                PremiumDiscoveryPoint.receiptOcr,
              ),
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
      _ocrDraftNeedsReview = draft?.contentType.startsWith('image/') == true;
      _ocrDraftManuallyConfirmed = false;
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
    final deadlineError = _deadlineValidationError();
    final providerPaymentError = _providerPaymentValidationError();
    final lineItemsError = _lineItemsValidationError(amountCents);
    setState(() {
      _amountError = amountCents > 0 ? null : 'Podaj kwote wieksza od 0.';
      _dateError = date.isEmpty ? 'Podaj date kosztu.' : null;
      _payerError = payer == null
          ? 'Wybierz kto zaplacil.'
          : selectedPayer!.isManual && manualPayerLabel.isEmpty
          ? 'Wpisz etykiete drugiego rodzica.'
          : null;
      _deadlineError = deadlineError;
      _providerPaymentError = providerPaymentError;
      _lineItemsError = lineItemsError;
    });

    if (amountCents <= 0 ||
        date.isEmpty ||
        payer == null ||
        _payerError != null ||
        deadlineError != null ||
        providerPaymentError != null ||
        lineItemsError != null) {
      return;
    }

    if (_attachmentDraft != null &&
        _ocrDraftNeedsReview &&
        !_isOcrReviewComplete &&
        !_ocrDraftManuallyConfirmed) {
      final confirmed = await _showOcrReviewConfirmation();
      if (confirmed != true) {
        return;
      }
      setState(() {
        _ocrDraftManuallyConfirmed = true;
        _ocrDraftNeedsReview = false;
      });
    }

    if (!mounted) return;
    if (_usesForeignReceiptCurrency) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(Icons.currency_exchange_outlined),
            title: const Text('Potwierdz walute rozliczenia'),
            content: Text(
              'Zapiszemy saldo w ${widget.profile.familyCurrency}. '
              'Kwota z paragonu w $_receiptCurrency zostaje tylko jako informacja; KidCost nie liczy kursow w MVP.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Wroc'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Zapisz w walucie rodziny'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) {
        return;
      }
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
          evidence: _currentEvidenceMetadata(),
          storagePath: upload.storagePath,
        );
      } catch (_) {
        uploadFailed = true;
        attachment = ExpenseAttachment(
          fileName: draft.fileName,
          contentType: draft.contentType,
          status: AttachmentStatus.failed,
          evidence: _currentEvidenceMetadata(),
          errorMessage: 'Nie udalo sie wyslac zalacznika.',
        );
      }
    } else if (draft != null) {
      skippedInvalidAttachment = true;
    }

    final createdAt = DateTime.now().toUtc();
    final draftReview = uploadFailed || skippedInvalidAttachment
        ? ExpenseDraftReview(
            capturedAt: createdAt,
            issues: [
              if (uploadFailed || skippedInvalidAttachment)
                ExpenseDraftIssue.receiptUploadFailed,
              ExpenseDraftIssue.privateDraft,
            ],
          )
        : null;
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
      createdAt: createdAt,
      visibility: widget.profile.isSoloFamily
          ? ExpenseVisibility.privateAuthor
          : ExpenseVisibility.sharedFamily,
      attachment: attachment,
      sourceTemplateId: widget.initialTemplate?.id,
      sourceTemplateName: widget.initialTemplate?.name,
      originalReceiptAmountCents: _originalReceiptAmountCents,
      originalReceiptCurrency: _originalReceiptAmountCents == null
          ? null
          : _receiptCurrency,
      servicePeriod: _currentServicePeriod(),
      calendarEvent: _selectedCalendarEvent,
      childInfoCard: _selectedChildInfoCard?.toLink(),
      verification: _currentEvidenceMetadata(),
      relatedExpense: _selectedRelatedExpense == null
          ? null
          : relatedRecordLinkForExpense(_selectedRelatedExpense!),
      reimbursementDeadlines: _currentDeadlineSnapshot(createdAt),
      reimbursementRequestKind: _requestKind,
      providerPayment: _currentProviderPaymentDetails(),
      draftReview: draftReview,
      lineItems: _lineItems,
      medicalPacket: _currentMedicalPacket(amountCents),
    );

    widget.onExpenseSaved(expense);
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _amountController.clear();
      final currentDate = widget.currentDate ?? DateTime.now();
      _dateController.text = _formatDate(currentDate);
      _serviceStartController.clear();
      _serviceEndController.clear();
      _serviceQuantityController.clear();
      _serviceScopeController.clear();
      _titleController.clear();
      _category = expenseCategories.first;
      _payer = _payers.first;
      _manualPayerController.text = widget.profile.coParentLabel;
      _receiptCurrency = widget.profile.familyCurrency;
      _originalReceiptAmountController.clear();
      _submittedAtController.text = _formatDate(currentDate);
      _noticeDueAtController.text = _formatDate(
        currentDate.add(_defaultReimbursementDeadlineWindow),
      );
      _paymentDueAtController.text = _formatDate(
        currentDate.add(_defaultReimbursementDeadlineWindow),
      );
      _paidAtController.clear();
      _deadlineError = null;
      _requestKind = ReimbursementRequestKind.reimburseParent;
      _providerPaymentStatus = ProviderPaymentStatus.sent;
      _providerNameController.clear();
      _providerReferenceController.clear();
      _providerAmountDueController.clear();
      _providerDueDateController.clear();
      _providerPaymentError = null;
      _medicalServiceDateController.clear();
      _medicalProviderController.clear();
      _medicalGrossAmountController.clear();
      _medicalCoveredAmountController.clear();
      _medicalPatientResponsibilityController.clear();
      _lineItems = const [];
      _lineItemsError = null;
      _calendarEventId = null;
      _childInfoCardId = null;
      _relatedExpenseId = null;
      _duplicateCueDismissed = false;
      _attachmentDraft = null;
      _clearEvidenceFields();
      _ocrDraftNeedsReview = false;
      _ocrDraftManuallyConfirmed = false;
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

  int get _parsedAmountOrZero {
    try {
      return parseAmountToCents(_amountController.text);
    } on FormatException {
      return 0;
    }
  }

  String? _lineItemsValidationError(int amountCents) {
    if (_lineItems.isEmpty) {
      return null;
    }
    final lineItemsTotal = _lineItems.fold<int>(
      0,
      (sum, item) => sum + item.amountCents,
    );
    if (lineItemsTotal != amountCents) {
      return 'Suma pozycji ${formatCents(lineItemsTotal)} musi zgadzac sie z kwota kosztu ${formatCents(amountCents)}.';
    }
    return null;
  }

  Future<void> _showAddLineItemSheet() async {
    final item = await showModalBottomSheet<ExpenseLineItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ExpenseLineItemSheet(
        childName: widget.profile.childName,
        defaultCategory: _category,
      ),
    );
    if (item == null) return;
    setState(() {
      _lineItems = [..._lineItems, item];
      _lineItemsError = null;
    });
  }

  ProviderPaymentDetails? _currentProviderPaymentDetails() {
    if (_requestKind != ReimbursementRequestKind.payProvider) {
      return null;
    }
    int amountDueCents;
    try {
      amountDueCents = parseAmountToCents(_providerAmountDueController.text);
    } on FormatException {
      amountDueCents = 0;
    }
    return ProviderPaymentDetails(
      providerName: _providerNameController.text.trim(),
      paymentReference: _providerReferenceController.text.trim().isEmpty
          ? null
          : _providerReferenceController.text.trim(),
      amountDueCents: amountDueCents,
      dueDate: _providerDueDateController.text.trim(),
      status: _providerPaymentStatus,
    );
  }

  bool get _isMedicalCategory => _category.id == 'health';

  MedicalExpensePacket? _currentMedicalPacket(int requestedReimbursementCents) {
    if (!_isMedicalCategory) {
      return null;
    }
    final gross = _parseOptionalAmountCents(_medicalGrossAmountController.text);
    final covered = _parseOptionalAmountCents(
      _medicalCoveredAmountController.text,
    );
    final responsibility = _parseOptionalAmountCents(
      _medicalPatientResponsibilityController.text,
    );
    final providerName = _trimmedOrNull(_medicalProviderController.text);
    final serviceDate = _trimmedOrNull(_medicalServiceDateController.text);
    final hasMedicalDetails =
        gross != null ||
        covered != null ||
        responsibility != null ||
        providerName != null ||
        serviceDate != null;
    if (!hasMedicalDetails) {
      return null;
    }
    return MedicalExpensePacket(
      providerName: providerName,
      patientName: widget.profile.childName,
      serviceDate: serviceDate,
      grossBilledCents: gross,
      coveredAmountCents: covered,
      patientResponsibilityCents: responsibility,
      requestedReimbursementCents: requestedReimbursementCents,
    );
  }

  int? _parseOptionalAmountCents(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return null;
    }
    try {
      return parseAmountToCents(text);
    } on FormatException {
      return null;
    }
  }

  String? _providerPaymentValidationError() {
    if (_requestKind != ReimbursementRequestKind.payProvider) {
      return null;
    }
    final providerName = _providerNameController.text.trim();
    final dueDate = _providerDueDateController.text.trim();
    int amountDueCents;
    try {
      amountDueCents = parseAmountToCents(_providerAmountDueController.text);
    } on FormatException {
      amountDueCents = 0;
    }
    if (providerName.isEmpty) {
      return 'Wpisz nazwe dostawcy platnosci.';
    }
    if (amountDueCents <= 0) {
      return 'Podaj kwote do zaplaty dostawcy.';
    }
    if (dueDate.isEmpty || DateTime.tryParse(dueDate) == null) {
      return 'Podaj termin platnosci do dostawcy w formacie RRRR-MM-DD.';
    }
    return null;
  }

  domain.ReimbursementDeadlineSnapshot? _currentDeadlineSnapshot(
    DateTime createdAt,
  ) {
    final submittedAt = _parseOptionalDate(_submittedAtController.text);
    final noticeDueAt = _parseOptionalDate(_noticeDueAtController.text);
    final paymentDueAt = _parseOptionalDate(_paymentDueAtController.text);
    final paidAt = _parseOptionalDate(_paidAtController.text);
    if (submittedAt == null &&
        noticeDueAt == null &&
        paymentDueAt == null &&
        paidAt == null) {
      return null;
    }
    return domain.buildReimbursementDeadlineSnapshot(
      requestCreatedAt: createdAt,
      submittedAt: submittedAt,
      noticeDueAt: noticeDueAt,
      paymentDueAt: paymentDueAt,
      paidAt: paidAt,
    );
  }

  String? _deadlineValidationError() {
    final fields = {
      'data zgloszenia': _submittedAtController.text,
      'termin przekazania dokumentow': _noticeDueAtController.text,
      'termin platnosci': _paymentDueAtController.text,
      'data zaplaty': _paidAtController.text,
    };
    for (final entry in fields.entries) {
      final text = entry.value.trim();
      if (text.isNotEmpty && DateTime.tryParse(text) == null) {
        return 'Sprawdz ${entry.key}. Uzyj formatu RRRR-MM-DD.';
      }
    }
    return null;
  }

  DateTime? _parseOptionalDate(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return null;
    }
    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      return null;
    }
    return DateTime.utc(parsed.year, parsed.month, parsed.day);
  }

  void _applyInitialTemplate() {
    final template = widget.initialTemplate;
    if (template == null) return;
    _amountController.text = formatCents(
      template.amountCents,
      currencyCode: widget.profile.familyCurrency,
    ).replaceAll(' ${widget.profile.familyCurrency}', '');
    _dateController.text = template.nextDueDate;
    _titleController.text = template.note?.trim().isNotEmpty == true
        ? template.note!.trim()
        : template.name;
    _category = template.category;
    ExpensePayer? matchingPayer;
    for (final payer in _payers) {
      if (payer.id == template.paidBy.id ||
          payer.label == template.paidBy.label) {
        matchingPayer = payer;
        break;
      }
    }
    _payer = matchingPayer ?? _payers.first;
  }

  domain.SharedExpenseRuleDecision get _currentAgreementDecision {
    var amountCents = 0;
    try {
      amountCents = parseAmountToCents(_amountController.text);
    } on FormatException {
      amountCents = 0;
    }
    return domain.evaluateSharedExpenseRule(
      categoryId: _category.id,
      amountCents: amountCents,
    );
  }

  void _refreshAgreementPreview() {
    if (!mounted) return;
    setState(() {});
  }

  void _refreshDuplicatePreview() {
    if (!mounted) return;
    setState(() => _duplicateCueDismissed = false);
  }

  bool get _usesForeignReceiptCurrency =>
      _receiptCurrency != widget.profile.familyCurrency;

  ExpenseCalendarEventLink? get _selectedCalendarEvent {
    final selectedId = _calendarEventId;
    if (selectedId == null) return null;
    for (final event in widget.calendarEvents) {
      if (event.id == selectedId) {
        return event;
      }
    }
    return null;
  }

  ChildInfoCard? get _selectedChildInfoCard {
    final selectedId = _childInfoCardId;
    if (selectedId == null) return null;
    for (final card in widget.childInfoCards) {
      if (card.id == selectedId) {
        return card;
      }
    }
    return null;
  }

  List<ChildInfoCard> get _suggestedChildInfoCards {
    return suggestedChildInfoCardsForExpenseCategory(
      expenseCategoryId: _category.id,
      cards: widget.childInfoCards,
    );
  }

  List<PotentialDuplicateExpense> get _potentialDuplicateExpenses {
    var amountCents = 0;
    try {
      amountCents = parseAmountToCents(_amountController.text);
    } on FormatException {
      return const [];
    }
    final date = _dateController.text.trim();
    if (amountCents <= 0 || date.isEmpty) {
      return const [];
    }
    return findPotentialDuplicateExpenses(
      candidate: ExpenseDuplicateCandidate(
        amountCents: amountCents,
        expenseDate: date,
        childName: widget.profile.childName,
        category: _category,
        verification: _currentEvidenceMetadata(),
      ),
      existingExpenses: widget.existingExpenses,
    );
  }

  ExpenseEntry? get _selectedRelatedExpense {
    final selectedId = _relatedExpenseId;
    if (selectedId == null) return null;
    for (final expense in widget.existingExpenses) {
      if (expense.id == selectedId) {
        return expense;
      }
    }
    return null;
  }

  int? get _originalReceiptAmountCents {
    if (!_usesForeignReceiptCurrency) {
      return null;
    }
    final text = _originalReceiptAmountController.text.trim();
    if (text.isEmpty) {
      return null;
    }
    try {
      return parseAmountToCents(text);
    } on FormatException {
      return null;
    }
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

  bool get _isOcrReviewComplete =>
      _ocrDraftManuallyConfirmed ||
      _ocrReviewFields.every((field) => field.state == _OcrFieldState.reviewed);

  bool get _shouldShowOcrReview =>
      _attachmentDraft?.contentType.startsWith('image/') == true;

  List<_OcrReviewField> get _ocrReviewFields {
    return [
      _OcrReviewField(
        label: 'Kwota',
        value: _amountController.text.trim().isEmpty
            ? null
            : _amountController.text.trim(),
        state: _reviewState(
          _amountController.text.trim().isEmpty
              ? _OcrFieldState.missing
              : _OcrFieldState.uncertain,
        ),
        actionLabel: 'Check amount',
      ),
      _OcrReviewField(
        label: 'Data kosztu',
        value: _dateController.text.trim().isEmpty
            ? null
            : _dateController.text.trim(),
        state: _reviewState(
          _dateController.text.trim().isEmpty
              ? _OcrFieldState.missing
              : _OcrFieldState.uncertain,
        ),
        actionLabel: _dateController.text.trim().isEmpty
            ? 'Date not found'
            : 'Check date',
      ),
      _OcrReviewField(
        label: 'Sprzedawca',
        value: _merchantController.text.trim().isEmpty
            ? null
            : _merchantController.text.trim(),
        state: _reviewState(
          _merchantController.text.trim().isEmpty
              ? _OcrFieldState.missing
              : _OcrFieldState.reviewed,
        ),
        actionLabel: _merchantController.text.trim().isEmpty
            ? 'Provider needs review'
            : 'Reviewed',
      ),
      _OcrReviewField(
        label: 'Kategoria',
        value: _category.label,
        state: _reviewState(_OcrFieldState.uncertain),
        actionLabel: 'Check category',
      ),
      _OcrReviewField(
        label: 'Dziecko',
        value: widget.profile.childName,
        state: _OcrFieldState.reviewed,
        actionLabel: 'Reviewed',
      ),
      _OcrReviewField(
        label: 'Platnik',
        value: _payer?.label,
        state: _reviewState(
          _payer == null ? _OcrFieldState.missing : _OcrFieldState.uncertain,
        ),
        actionLabel: _payer == null ? 'Payer not found' : 'Check payer',
      ),
      _OcrReviewField(
        label: 'Podzial',
        value: _currentAgreementDecision.rule.splitSummary,
        state: _reviewState(_OcrFieldState.uncertain),
        actionLabel: 'Check split',
      ),
      _OcrReviewField(
        label: 'Data uslugi',
        value: _serviceDateController.text.trim().isEmpty
            ? null
            : _serviceDateController.text.trim(),
        state: _serviceDateController.text.trim().isEmpty
            ? _OcrFieldState.missing
            : _OcrFieldState.reviewed,
        actionLabel: _serviceDateController.text.trim().isEmpty
            ? 'Service date optional'
            : 'Reviewed',
        isRequired: false,
      ),
    ];
  }

  _OcrFieldState _reviewState(_OcrFieldState state) {
    if (_ocrDraftManuallyConfirmed) {
      return _OcrFieldState.reviewed;
    }
    return state;
  }

  void _confirmOcrReview() {
    setState(() {
      _ocrDraftNeedsReview = false;
      _ocrDraftManuallyConfirmed = true;
    });
  }

  Future<bool?> _showOcrReviewConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.fact_check_outlined),
          title: const Text('Potwierdz pola z paragonu'),
          content: const Text(
            'Ten paragon jest prywatnym szkicem. Przed zapisem potwierdz recznie pola oznaczone do sprawdzenia. Po zapisie koszt trafi do salda rodziny i moze byc widoczny dla wspolrodzica.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Wroc do sprawdzenia'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Potwierdzam recznie'),
            ),
          ],
        );
      },
    );
  }

  void _showExistingExpensePreview(ExpenseEntry expense) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final evidence = expense.searchableEvidence;
        return AlertDialog(
          icon: const Icon(Icons.receipt_long_outlined),
          title: Text(expense.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data: ${expense.expenseDate}'),
              Text('Kwota: ${formatCents(expense.amountCents)}'),
              Text('Status: ${expense.status.label}'),
              if (evidence?.merchant?.trim().isNotEmpty == true)
                Text('Wystawca: ${evidence!.merchant}'),
              if (evidence?.documentNumber?.trim().isNotEmpty == true)
                Text('Numer dokumentu: ${evidence!.documentNumber}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Zamknij'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _relatedExpenseId = expense.id;
                  _duplicateCueDismissed = true;
                });
              },
              child: const Text('Powiaz jako related'),
            ),
          ],
        );
      },
    );
  }

  void _removeAttachment() {
    setState(() {
      _attachmentDraft = null;
      _clearEvidenceFields();
      _ocrDraftNeedsReview = false;
      _ocrDraftManuallyConfirmed = false;
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

  EvidenceMetadata? _currentEvidenceMetadata() {
    final metadata = EvidenceMetadata(
      type: _evidenceType,
      serviceDate: _trimmedOrNull(_serviceDateController.text),
      documentDate: _trimmedOrNull(_documentDateController.text),
      merchant: _trimmedOrNull(_merchantController.text),
      documentNumber: _trimmedOrNull(_documentNumberController.text),
      paymentMethod: _trimmedOrNull(_paymentMethodController.text),
      buyerNamePresent: _buyerNamePresent,
    );
    return metadata.hasDetails ? metadata : null;
  }

  ExpenseServicePeriod? _currentServicePeriod() {
    final servicePeriod = ExpenseServicePeriod(
      startDate: _trimmedOrNull(_serviceStartController.text),
      endDate: _trimmedOrNull(_serviceEndController.text),
      quantityLabel: _trimmedOrNull(_serviceQuantityController.text),
      scopeNote: _trimmedOrNull(_serviceScopeController.text),
    );
    return servicePeriod.hasDetails ? servicePeriod : null;
  }

  String? _trimmedOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  void _clearEvidenceFields() {
    _evidenceType = null;
    _buyerNamePresent = null;
    _serviceDateController.clear();
    _documentDateController.clear();
    _merchantController.clear();
    _documentNumberController.clear();
    _paymentMethodController.clear();
  }

  String _formatDate(DateTime date) {
    return [
      date.year.toString().padLeft(4, '0'),
      date.month.toString().padLeft(2, '0'),
      date.day.toString().padLeft(2, '0'),
    ].join('-');
  }
}

class _CalendarEventLinkCard extends StatelessWidget {
  const _CalendarEventLinkCard({required this.event});

  final ExpenseCalendarEventLink event;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_available_outlined),
        title: Text(event.title),
        subtitle: Text(
          'Koszt pojawi sie na szczegolach wydarzenia z dnia ${event.eventDate}.',
        ),
      ),
    );
  }
}

class _ServicePeriodFields extends StatelessWidget {
  const _ServicePeriodFields({
    required this.startController,
    required this.endController,
    required this.quantityController,
    required this.scopeController,
  });

  final TextEditingController startController;
  final TextEditingController endController;
  final TextEditingController quantityController;
  final TextEditingController scopeController;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      key: const Key('expense-service-period-section'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      leading: const Icon(Icons.date_range_outlined),
      title: const Text('Okres i zakres uslugi'),
      subtitle: const Text('Opcjonalnie, gdy koszt pokrywa wiecej niz zakup.'),
      children: [
        TextField(
          key: const Key('expense-service-start-field'),
          controller: startController,
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Poczatek uslugi',
            hintText: 'RRRR-MM-DD',
            prefixIcon: Icon(Icons.event_available_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('expense-service-end-field'),
          controller: endController,
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Koniec uslugi',
            hintText: 'RRRR-MM-DD',
            prefixIcon: Icon(Icons.event_busy_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('expense-service-quantity-field'),
          controller: quantityController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Ilosc lub zakres',
            hintText: 'np. 12 obiadow, 4 sesje, wrzesien',
            prefixIcon: Icon(Icons.format_list_numbered_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('expense-service-scope-field'),
          controller: scopeController,
          textCapitalization: TextCapitalization.sentences,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Notatka zakresu',
            hintText: 'Co dokladnie pokrywa platnosc',
            prefixIcon: Icon(Icons.subject_outlined),
          ),
        ),
      ],
    );
  }
}

class _PotentialDuplicateCue extends StatelessWidget {
  const _PotentialDuplicateCue({
    required this.matches,
    required this.selectedExpenseId,
    required this.onViewExisting,
    required this.onContinueAnyway,
    required this.onLinkRelated,
  });

  final List<PotentialDuplicateExpense> matches;
  final String? selectedExpenseId;
  final ValueChanged<ExpenseEntry> onViewExisting;
  final VoidCallback onContinueAnyway;
  final ValueChanged<ExpenseEntry> onLinkRelated;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      liveRegion: true,
      label:
          'Ten koszt wyglada podobnie do juz zapisanego. To tylko podpowiedz, zapis nie jest blokowany.',
      child: Card(
        color: colors.tertiaryContainer.withValues(alpha: 0.38),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.manage_search_outlined),
                title: const Text(
                  'Ten koszt wyglada podobnie do juz zapisanego',
                ),
                subtitle: const Text(
                  'To neutralna podpowiedz. Mozesz sprawdzic rekord, kontynuowac albo powiazac je jako related.',
                ),
              ),
              for (final match in matches)
                _PotentialDuplicateTile(
                  match: match,
                  isSelected: match.expense.id == selectedExpenseId,
                  onViewExisting: () => onViewExisting(match.expense),
                  onLinkRelated: () => onLinkRelated(match.expense),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: onContinueAnyway,
                  icon: const Icon(Icons.arrow_forward_outlined),
                  label: const Text('Kontynuuj mimo podobienstwa'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PotentialDuplicateTile extends StatelessWidget {
  const _PotentialDuplicateTile({
    required this.match,
    required this.isSelected,
    required this.onViewExisting,
    required this.onLinkRelated,
  });

  final PotentialDuplicateExpense match;
  final bool isSelected;
  final VoidCallback onViewExisting;
  final VoidCallback onLinkRelated;

  @override
  Widget build(BuildContext context) {
    final expense = match.expense;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isSelected ? Icons.link_outlined : Icons.receipt_outlined,
              ),
              title: Text(expense.title),
              subtitle: Text(
                '${expense.expenseDate} - ${formatCents(expense.amountCents)} - ${expense.status.label}\n${match.reasons.join(', ')}',
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onViewExisting,
                  icon: const Icon(Icons.open_in_new_outlined),
                  label: const Text('Zobacz istniejacy'),
                ),
                FilledButton.tonalIcon(
                  onPressed: onLinkRelated,
                  icon: const Icon(Icons.link_outlined),
                  label: const Text('Powiaz jako related'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatedExpenseDraftCard extends StatelessWidget {
  const _RelatedExpenseDraftCard({
    required this.expense,
    required this.onRemove,
  });

  final ExpenseEntry expense;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.link_outlined),
        title: Text('Powiazany rekord: ${expense.title}'),
        subtitle: Text(
          '${expense.expenseDate} - ${formatCents(expense.amountCents)} - ${expense.status.label}',
        ),
        trailing: IconButton(
          tooltip: 'Usun powiazanie',
          onPressed: onRemove,
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}

class _ExpenseVerificationFields extends StatelessWidget {
  const _ExpenseVerificationFields({
    required this.evidenceType,
    required this.serviceDateController,
    required this.documentDateController,
    required this.merchantController,
    required this.documentNumberController,
    required this.paymentMethodController,
    required this.buyerNamePresent,
    required this.onEvidenceTypeChanged,
    required this.onBuyerNamePresentChanged,
    this.initiallyExpanded = false,
  });

  final EvidenceType? evidenceType;
  final TextEditingController serviceDateController;
  final TextEditingController documentDateController;
  final TextEditingController merchantController;
  final TextEditingController documentNumberController;
  final TextEditingController paymentMethodController;
  final bool? buyerNamePresent;
  final ValueChanged<EvidenceType?> onEvidenceTypeChanged;
  final ValueChanged<bool?> onBuyerNamePresentChanged;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        key: const Key('expense-verification-fields'),
        leading: const Icon(Icons.fact_check_outlined),
        title: const Text('Pola weryfikacyjne'),
        subtitle: const Text('Opcjonalne, pomagaja wykryc podobne rachunki.'),
        initiallyExpanded: initiallyExpanded,
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          const _AttachmentSaveNotice(
            icon: Icons.info_outline,
            text: 'To pomaga uporzadkowac dokumenty; nie jest porada prawna.',
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<EvidenceType?>(
            key: const Key('evidence-type-picker'),
            initialValue: evidenceType,
            decoration: const InputDecoration(
              labelText: 'Typ dowodu',
              prefixIcon: Icon(Icons.fact_check_outlined),
            ),
            items: [
              const DropdownMenuItem<EvidenceType?>(
                value: null,
                child: Text('Nie wybrano'),
              ),
              for (final type in EvidenceType.values)
                DropdownMenuItem<EvidenceType?>(
                  value: type,
                  child: Text(type.label),
                ),
            ],
            onChanged: onEvidenceTypeChanged,
          ),
          if (evidenceType != null) ...[
            const SizedBox(height: 6),
            Text(
              evidenceType!.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            key: const Key('expense-service-date-field'),
            controller: serviceDateController,
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Data uslugi',
              hintText: 'RRRR-MM-DD',
              prefixIcon: Icon(Icons.event_available_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('expense-document-date-field'),
            controller: documentDateController,
            keyboardType: TextInputType.datetime,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Data dokumentu',
              hintText: 'RRRR-MM-DD',
              prefixIcon: Icon(Icons.event_note_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('expense-provider-field'),
            controller: merchantController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Sprzedawca lub wystawca',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('expense-document-number-field'),
            controller: documentNumberController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Numer dokumentu',
              prefixIcon: Icon(Icons.tag_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: paymentMethodController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Metoda platnosci',
              prefixIcon: Icon(Icons.credit_card_outlined),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            tristate: true,
            value: buyerNamePresent,
            onChanged: onBuyerNamePresentChanged,
            title: const Text('Na dokumencie jest imie/nazwisko kupujacego'),
            subtitle: Text(_buyerNameStateLabel(buyerNamePresent)),
          ),
        ],
      ),
    );
  }
}

class _ChildInfoSuggestionCard extends StatelessWidget {
  const _ChildInfoSuggestionCard({required this.cards});

  final List<ChildInfoCard> cards;

  @override
  Widget build(BuildContext context) {
    final labels = cards.map((card) => card.title).join(', ');
    return Card(
      child: ListTile(
        leading: const Icon(Icons.tips_and_updates_outlined),
        title: const Text('Podpowiedz z kart dziecka'),
        subtitle: Text('Do tej kategorii pasuje: $labels.'),
      ),
    );
  }
}

const _supportedReceiptCurrencies = ['PLN', 'EUR', 'USD', 'GBP', 'CHF'];

class _CurrencyGuardrailCard extends StatelessWidget {
  const _CurrencyGuardrailCard({
    required this.familyCurrency,
    required this.receiptCurrency,
  });

  final String familyCurrency;
  final String receiptCurrency;

  @override
  Widget build(BuildContext context) {
    final usesForeignReceiptCurrency = receiptCurrency != familyCurrency;
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        leading: Icon(
          usesForeignReceiptCurrency
              ? Icons.currency_exchange_outlined
              : Icons.verified_outlined,
          color: usesForeignReceiptCurrency ? colors.tertiary : colors.primary,
        ),
        title: Text('Saldo rodziny: $familyCurrency'),
        subtitle: Text(
          usesForeignReceiptCurrency
              ? 'Paragon jest w $receiptCurrency. Wpisz kwote przeliczona na $familyCurrency; oryginalna kwota jest tylko informacyjna.'
              : 'Raporty i pulpit pokazuja laczne kwoty w jednej walucie. KidCost nie liczy kursow w MVP.',
        ),
      ),
    );
  }
}

class _ReimbursementDeadlineFields extends StatelessWidget {
  const _ReimbursementDeadlineFields({
    required this.submittedAtController,
    required this.noticeDueAtController,
    required this.paymentDueAtController,
    required this.paidAtController,
    required this.errorText,
  });

  final TextEditingController submittedAtController;
  final TextEditingController noticeDueAtController;
  final TextEditingController paymentDueAtController;
  final TextEditingController paidAtController;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.pending_actions_outlined),
        title: const Text('Terminy zwrotu'),
        subtitle: const Text('Opcjonalne daty zgloszenia i platnosci.'),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Daty porzadkuja ustalenia rodziny bez oceny prawnej terminu.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('expense-submitted-at-field'),
                controller: submittedAtController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Data zgloszenia',
                  hintText: 'RRRR-MM-DD',
                  prefixIcon: Icon(Icons.send_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('expense-notice-due-at-field'),
                controller: noticeDueAtController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Termin przekazania dokumentow',
                  hintText: 'RRRR-MM-DD',
                  prefixIcon: Icon(Icons.event_note_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('expense-payment-due-at-field'),
                controller: paymentDueAtController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Termin platnosci',
                  hintText: 'RRRR-MM-DD',
                  prefixIcon: Icon(Icons.event_available_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('expense-paid-at-field'),
                controller: paidAtController,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Data zaplaty',
                  hintText: 'RRRR-MM-DD',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ProviderPaymentFields extends StatelessWidget {
  const _ProviderPaymentFields({
    required this.requestKind,
    required this.providerNameController,
    required this.providerReferenceController,
    required this.providerAmountDueController,
    required this.providerDueDateController,
    required this.status,
    required this.errorText,
    required this.onRequestKindChanged,
    required this.onStatusChanged,
  });

  final ReimbursementRequestKind requestKind;
  final TextEditingController providerNameController;
  final TextEditingController providerReferenceController;
  final TextEditingController providerAmountDueController;
  final TextEditingController providerDueDateController;
  final ProviderPaymentStatus status;
  final String? errorText;
  final ValueChanged<ReimbursementRequestKind> onRequestKindChanged;
  final ValueChanged<ProviderPaymentStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.storefront_outlined),
        title: const Text('Typ prosby'),
        subtitle: Text(requestKind.description),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<ReimbursementRequestKind>(
                key: const Key('expense-request-kind-picker'),
                initialValue: requestKind,
                decoration: const InputDecoration(
                  labelText: 'Co ma zrobic drugi rodzic?',
                  prefixIcon: Icon(Icons.swap_horiz_outlined),
                ),
                items: [
                  for (final kind in ReimbursementRequestKind.values)
                    DropdownMenuItem(value: kind, child: Text(kind.label)),
                ],
                onChanged: (kind) {
                  if (kind != null) {
                    onRequestKindChanged(kind);
                  }
                },
              ),
              if (requestKind == ReimbursementRequestKind.payProvider) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const Key('provider-name-field'),
                  controller: providerNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nazwa dostawcy',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('provider-reference-field'),
                  controller: providerReferenceController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Tytul platnosci lub notatka',
                    helperText: 'Nie wpisuj pelnych danych bankowych.',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('provider-amount-due-field'),
                  controller: providerAmountDueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Kwota do zaplaty dostawcy',
                    prefixIcon: Icon(Icons.payments_outlined),
                    suffixText: 'PLN',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('provider-due-date-field'),
                  controller: providerDueDateController,
                  keyboardType: TextInputType.datetime,
                  decoration: const InputDecoration(
                    labelText: 'Termin platnosci do dostawcy',
                    hintText: 'RRRR-MM-DD',
                    prefixIcon: Icon(Icons.event_available_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProviderPaymentStatus>(
                  key: const Key('provider-payment-status-picker'),
                  initialValue: status,
                  decoration: const InputDecoration(
                    labelText: 'Status platnosci dostawcy',
                    prefixIcon: Icon(Icons.fact_check_outlined),
                  ),
                  items: [
                    for (final status in ProviderPaymentStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onStatusChanged(value);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'KidCost zapisuje prosbe i status. Nie sprawdza rachunku dostawcy ani nie wykonuje platnosci.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    errorText!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseLineItemsCard extends StatelessWidget {
  const _ExpenseLineItemsCard({
    required this.lineItems,
    required this.parentAmountCents,
    required this.onAddLineItem,
    required this.onRemoveLineItem,
    this.errorText,
  });

  final List<ExpenseLineItem> lineItems;
  final int parentAmountCents;
  final String? errorText;
  final VoidCallback onAddLineItem;
  final ValueChanged<ExpenseLineItem> onRemoveLineItem;

  @override
  Widget build(BuildContext context) {
    final totalCents = lineItems.fold<int>(
      0,
      (sum, item) => sum + item.amountCents,
    );
    final reimbursableCents = lineItems.fold<int>(
      0,
      (sum, item) => sum + (item.isReimbursable ? item.amountCents : 0),
    );
    final differenceCents = parentAmountCents - totalCents;
    final isBalanced = lineItems.isEmpty || differenceCents == 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.splitscreen_outlined),
              title: const Text('Pozycje rachunku'),
              subtitle: Text(
                lineItems.isEmpty
                    ? 'Opcjonalnie rozbij jeden paragon na kilka pozycji bez duplikowania zalacznika.'
                    : '${lineItems.length} pozycji, suma ${formatCents(totalCents)}.',
              ),
            ),
            if (lineItems.isNotEmpty) ...[
              _LineItemSummaryRow(
                label: 'Suma pozycji',
                value: formatCents(totalCents),
              ),
              _LineItemSummaryRow(
                label: 'Reimbursable',
                value: formatCents(reimbursableCents),
              ),
              _LineItemSummaryRow(
                label: isBalanced
                    ? 'Zgodne z kosztem'
                    : 'Roznica do wyjasnienia',
                value: formatCents(differenceCents.abs()),
              ),
              const SizedBox(height: 8),
              for (final item in lineItems)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    item.isReimbursable
                        ? Icons.check_circle_outline
                        : Icons.remove_circle_outline,
                  ),
                  title: Text(item.description),
                  subtitle: Text(
                    '${item.childName} - ${item.category.label} - ${item.splitLabel}',
                  ),
                  trailing: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Text(item.amountLabel),
                      IconButton(
                        tooltip: 'Usun pozycje',
                        icon: const Icon(Icons.close),
                        onPressed: () => onRemoveLineItem(item),
                      ),
                    ],
                  ),
                ),
            ],
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(
                errorText!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                key: const Key('add-expense-line-item-button'),
                onPressed: onAddLineItem,
                icon: const Icon(Icons.add_outlined),
                label: const Text('Dodaj pozycje rachunku'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineItemSummaryRow extends StatelessWidget {
  const _LineItemSummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _ExpenseLineItemSheet extends StatefulWidget {
  const _ExpenseLineItemSheet({
    required this.childName,
    required this.defaultCategory,
  });

  final String childName;
  final ExpenseCategory defaultCategory;

  @override
  State<_ExpenseLineItemSheet> createState() => _ExpenseLineItemSheetState();
}

class _ExpenseLineItemSheetState extends State<_ExpenseLineItemSheet> {
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _splitController = TextEditingController();
  late ExpenseCategory _category = widget.defaultCategory;
  bool _isReimbursable = true;
  String? _descriptionError;
  String? _amountError;

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _splitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          0,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.splitscreen_outlined),
              title: Text('Pozycja rachunku'),
              subtitle: Text(
                'Manualny MVP: jeden zalacznik, kilka pozycji, bez OCR i bez autosubmission.',
              ),
            ),
            TextField(
              key: const Key('line-item-description-field'),
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Opis pozycji',
                prefixIcon: const Icon(Icons.notes_outlined),
                errorText: _descriptionError,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('line-item-amount-field'),
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Kwota pozycji',
                prefixIcon: const Icon(Icons.payments_outlined),
                errorText: _amountError,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              key: const Key('line-item-category-picker'),
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Kategoria pozycji',
                prefixIcon: Icon(Icons.label_outline),
              ),
              items: [
                for (final category in expenseCategories)
                  DropdownMenuItem(
                    value: category,
                    child: Text(category.label),
                  ),
              ],
              onChanged: (category) {
                if (category != null) setState(() => _category = category);
              },
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Dziecko',
                prefixIcon: Icon(Icons.child_care_outlined),
              ),
              child: Text(widget.childName),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              key: const Key('line-item-reimbursable-switch'),
              contentPadding: EdgeInsets.zero,
              value: _isReimbursable,
              onChanged: (value) => setState(() => _isReimbursable = value),
              title: const Text('Podlega zwrotowi'),
              subtitle: const Text(
                'Nie zmienia salda automatycznie; raport pokazuje reimbursable total.',
              ),
            ),
            TextField(
              key: const Key('line-item-split-field'),
              controller: _splitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Override podzialu procentowego',
                helperText: 'Opcjonalnie, np. 50. Puste = reguly rodzinne.',
                prefixIcon: Icon(Icons.percent_outlined),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('save-line-item-button'),
              onPressed: _save,
              icon: const Icon(Icons.check_outlined),
              label: const Text('Dodaj pozycje'),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final description = _descriptionController.text.trim();
    int amountCents;
    try {
      amountCents = parseAmountToCents(_amountController.text);
    } on FormatException {
      amountCents = 0;
    }
    setState(() {
      _descriptionError = description.isEmpty ? 'Dodaj opis pozycji.' : null;
      _amountError = amountCents > 0 ? null : 'Podaj kwote pozycji.';
    });
    if (_descriptionError != null || _amountError != null) {
      return;
    }
    final splitPercent = int.tryParse(_splitController.text.trim());
    Navigator.of(context).pop(
      ExpenseLineItem(
        id: 'line-${DateTime.now().microsecondsSinceEpoch}',
        description: description,
        amountCents: amountCents,
        category: _category,
        childName: widget.childName,
        isReimbursable: _isReimbursable,
        splitPercent: splitPercent,
      ),
    );
  }
}

class _MedicalExpensePacketFields extends StatelessWidget {
  const _MedicalExpensePacketFields({
    required this.requestedReimbursementCents,
    required this.serviceDateController,
    required this.providerController,
    required this.patientName,
    required this.grossAmountController,
    required this.coveredAmountController,
    required this.patientResponsibilityController,
  });

  final int requestedReimbursementCents;
  final TextEditingController serviceDateController;
  final TextEditingController providerController;
  final String patientName;
  final TextEditingController grossAmountController;
  final TextEditingController coveredAmountController;
  final TextEditingController patientResponsibilityController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        key: const Key('medical-expense-packet-fields'),
        leading: const Icon(Icons.medical_information_outlined),
        title: const Text('Pakiet medyczny / EOB'),
        subtitle: const Text(
          'Opcjonalny kontekst dla rachunku, EOB i kwoty pacjenta.',
        ),
        initiallyExpanded: true,
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          const _AttachmentSaveNotice(
            icon: Icons.privacy_tip_outlined,
            text:
                'Udostepniaj tylko dokumenty potrzebne do rozliczenia. KidCost nie ocenia ubezpieczenia ani uprawnien prawnych.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('medical-service-date-field'),
            controller: serviceDateController,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              labelText: 'Data uslugi medycznej',
              hintText: 'RRRR-MM-DD',
              prefixIcon: Icon(Icons.event_available_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('medical-provider-field'),
            controller: providerController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Dostawca / placowka',
              prefixIcon: Icon(Icons.local_hospital_outlined),
            ),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Pacjent / dziecko',
              prefixIcon: Icon(Icons.child_care_outlined),
            ),
            child: Text(patientName),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('medical-gross-amount-field'),
            controller: grossAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Kwota brutto z rachunku',
              hintText: '0,00',
              prefixIcon: Icon(Icons.request_quote_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('medical-covered-amount-field'),
            controller: coveredAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Pokryte przez ubezpieczenie / strone trzecia',
              hintText: '0,00',
              prefixIcon: Icon(Icons.health_and_safety_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('medical-patient-responsibility-field'),
            controller: patientResponsibilityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Odpowiedzialnosc pacjenta / out-of-pocket',
              hintText: '0,00',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.splitscreen_outlined),
            title: const Text('Kwota proszona do zwrotu'),
            subtitle: const Text(
              'To glowna kwota kosztu powyzej; nie zmieniamy algorytmu salda.',
            ),
            trailing: Text(formatCents(requestedReimbursementCents)),
          ),
        ],
      ),
    );
  }
}

class _SharedExpenseRuleCard extends StatelessWidget {
  const _SharedExpenseRuleCard({required this.decision});

  final domain.SharedExpenseRuleDecision decision;

  @override
  Widget build(BuildContext context) {
    final rule = decision.rule;
    final colors = Theme.of(context).colorScheme;
    final warning =
        decision.requiresPriorApproval || !rule.isShareableByDefault;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  warning
                      ? Icons.rule_folder_outlined
                      : Icons.check_circle_outline,
                  color: warning ? colors.tertiary : colors.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Regula kosztu: ${rule.label}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(rule.splitSummary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(decision.guidance),
            const SizedBox(height: 8),
            Text(
              domain.kidCostSharedExpenseAgreement.addExpenseCopy,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateSourceBanner extends StatelessWidget {
  const _TemplateSourceBanner({required this.template});

  final ExpenseTemplate template;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_repeat_outlined),
        title: Text('Koszt z szablonu: ${template.name}'),
        subtitle: const Text(
          'Sprawdz kwote i date przed zapisem. Szablon nie ksieguje kosztu automatycznie.',
        ),
      ),
    );
  }
}

class _AttachmentReviewTray extends StatelessWidget {
  const _AttachmentReviewTray({
    required this.attachment,
    required this.status,
    required this.showReceiptOcrPremiumHint,
    required this.onPreview,
    required this.onReplace,
    required this.onRemove,
    required this.onAddAnother,
    required this.onSaveWithoutReceipt,
    required this.evidenceType,
    required this.serviceDateController,
    required this.documentDateController,
    required this.merchantController,
    required this.documentNumberController,
    required this.paymentMethodController,
    required this.buyerNamePresent,
    required this.showOcrReview,
    required this.ocrFields,
    required this.isOcrReviewComplete,
    required this.onConfirmOcrReview,
    required this.onEvidenceTypeChanged,
    required this.onBuyerNamePresentChanged,
    required this.onPremiumHintDismissed,
  });

  final AttachmentDraft attachment;
  final _AttachmentReviewStatus status;
  final bool showReceiptOcrPremiumHint;
  final VoidCallback onPreview;
  final VoidCallback onReplace;
  final VoidCallback onRemove;
  final VoidCallback onAddAnother;
  final VoidCallback onSaveWithoutReceipt;
  final EvidenceType? evidenceType;
  final TextEditingController serviceDateController;
  final TextEditingController documentDateController;
  final TextEditingController merchantController;
  final TextEditingController documentNumberController;
  final TextEditingController paymentMethodController;
  final bool? buyerNamePresent;
  final bool showOcrReview;
  final List<_OcrReviewField> ocrFields;
  final bool isOcrReviewComplete;
  final VoidCallback onConfirmOcrReview;
  final ValueChanged<EvidenceType?> onEvidenceTypeChanged;
  final ValueChanged<bool?> onBuyerNamePresentChanged;
  final VoidCallback onPremiumHintDismissed;

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
            if (status == _AttachmentReviewStatus.ready) ...[
              const SizedBox(height: 8),
              _AttachmentSaveNotice(
                icon: Icons.privacy_tip_outlined,
                text: _attachmentPrivacyText(attachment.contentType),
              ),
            ],
            if (showReceiptOcrPremiumHint) ...[
              const SizedBox(height: 12),
              PremiumDiscoveryCard(
                point: PremiumDiscoveryPoint.receiptOcr,
                onDismiss: onPremiumHintDismissed,
                compact: true,
              ),
            ],
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (showOcrReview) ...[
              _OcrReviewPanel(
                fields: ocrFields,
                isComplete: isOcrReviewComplete,
                onConfirmReview: onConfirmOcrReview,
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
            ],
            _ExpenseVerificationFields(
              evidenceType: evidenceType,
              serviceDateController: serviceDateController,
              documentDateController: documentDateController,
              merchantController: merchantController,
              documentNumberController: documentNumberController,
              paymentMethodController: paymentMethodController,
              buyerNamePresent: buyerNamePresent,
              onEvidenceTypeChanged: onEvidenceTypeChanged,
              onBuyerNamePresentChanged: onBuyerNamePresentChanged,
              initiallyExpanded: true,
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

class _OcrReviewField {
  const _OcrReviewField({
    required this.label,
    required this.state,
    required this.actionLabel,
    this.value,
    this.isRequired = true,
  });

  final String label;
  final String? value;
  final _OcrFieldState state;
  final String actionLabel;
  final bool isRequired;
}

enum _OcrFieldState {
  reviewed,
  uncertain,
  missing;

  String get label {
    switch (this) {
      case _OcrFieldState.reviewed:
        return 'Reviewed';
      case _OcrFieldState.uncertain:
        return 'Needs review';
      case _OcrFieldState.missing:
        return 'Missing';
    }
  }

  IconData get icon {
    switch (this) {
      case _OcrFieldState.reviewed:
        return Icons.check_circle_outline;
      case _OcrFieldState.uncertain:
        return Icons.error_outline;
      case _OcrFieldState.missing:
        return Icons.help_outline;
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case _OcrFieldState.reviewed:
        return Theme.of(context).colorScheme.primary;
      case _OcrFieldState.uncertain:
        return Theme.of(context).colorScheme.tertiary;
      case _OcrFieldState.missing:
        return Theme.of(context).colorScheme.error;
    }
  }
}

class _OcrReviewPanel extends StatelessWidget {
  const _OcrReviewPanel({
    required this.fields,
    required this.isComplete,
    required this.onConfirmReview,
  });

  final List<_OcrReviewField> fields;
  final bool isComplete;
  final VoidCallback onConfirmReview;

  @override
  Widget build(BuildContext context) {
    final requiredOpen = fields
        .where(
          (field) => field.isRequired && field.state != _OcrFieldState.reviewed,
        )
        .length;
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: isComplete
          ? 'OCR review complete. Private draft ready to submit.'
          : 'Private OCR draft. $requiredOpen required fields need review.',
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isComplete
                        ? Icons.verified_outlined
                        : Icons.document_scanner_outlined,
                    color: isComplete ? colors.primary : colors.tertiary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isComplete ? 'Ready to submit' : 'Private OCR draft',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isComplete
                              ? 'Reviewed fields can now be saved. The expense will affect the family balance after submit.'
                              : 'No balance change or co-parent notification happens until you explicitly save this expense.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final field in fields) ...[
                _OcrReviewFieldTile(field: field),
                const SizedBox(height: 8),
              ],
              TextButton.icon(
                onPressed: onConfirmReview,
                icon: const Icon(Icons.edit_note_outlined),
                label: const Text('Potwierdz pola recznie'),
              ),
              const SizedBox(height: 4),
              Text(
                'Gdy OCR jest niedostepny, pomylony albo poza limitem, wpisz koszt recznie i zapisz bez sugestii.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OcrReviewFieldTile extends StatelessWidget {
  const _OcrReviewFieldTile({required this.field});

  final _OcrReviewField field;

  @override
  Widget build(BuildContext context) {
    final color = field.state.color(context);
    final value = field.value?.trim().isNotEmpty == true
        ? field.value!.trim()
        : 'No value';
    return Semantics(
      label:
          '${field.label}: ${field.state.label}. ${field.actionLabel}. $value.',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(field.state.icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.label, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Chip(
                avatar: Icon(field.state.icon, size: 16, color: color),
                label: Text(field.actionLabel),
                side: BorderSide(color: color.withValues(alpha: 0.32)),
                backgroundColor: color.withValues(alpha: 0.08),
                labelStyle: TextStyle(color: color),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _buyerNameStateLabel(bool? value) {
  if (value == null) {
    return 'Nie zaznaczono';
  }
  return value ? 'Tak' : 'Nie';
}

String _attachmentPrivacyText(String contentType) {
  if (contentType.startsWith('image/')) {
    return 'Zdjecie zapiszemy bez metadanych lokalizacji i opisow technicznych.';
  }
  if (contentType == 'application/pdf') {
    return 'PDF zapisujemy jako zalacznik; czyszczenie metadanych PDF jest poza MVP.';
  }
  return 'Zalacznik zapiszemy tylko w obslugiwanym formacie.';
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxLabelWidth = constraints.hasBoundedWidth
              ? (constraints.maxWidth - 80).clamp(120.0, 260.0)
              : 220.0;

          return Wrap(
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
                  label: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxLabelWidth),
                    child: Text(category.label, softWrap: true),
                  ),
                  selected: category.id == selectedCategory.id,
                  onSelected: isEnabled
                      ? (_) => onCategorySelected(category)
                      : null,
                ),
            ],
          );
        },
      ),
    );
  }
}
