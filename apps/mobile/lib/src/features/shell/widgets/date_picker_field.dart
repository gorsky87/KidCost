import 'package:flutter/material.dart';

class KidCostDateField extends StatelessWidget {
  const KidCostDateField({
    required this.controller,
    required this.labelText,
    this.fieldKey,
    this.hintText = 'RRRR-MM-DD',
    this.helperText,
    this.errorText,
    this.prefixIcon = const Icon(Icons.event_outlined),
    this.currentDate,
    this.firstDate,
    this.lastDate,
    this.onChanged,
    this.validator,
    this.allowManualEntry = true,
    super.key,
  });

  final TextEditingController controller;
  final String labelText;
  final Key? fieldKey;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget prefixIcon;
  final DateTime? currentDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool allowManualEntry;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: fieldKey,
      controller: controller,
      keyboardType: TextInputType.datetime,
      readOnly: !allowManualEntry,
      showCursor: allowManualEntry,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixIcon: IconButton(
          tooltip: 'Wybierz date',
          onPressed: () => _pickDate(context),
          icon: const Icon(Icons.calendar_month_outlined),
        ),
      ),
      onTap: () => _openPickerFromField(context),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Future<void> _openPickerFromField(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await _pickDate(context);
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = _dateOnly(currentDate ?? DateTime.now());
    final first = _dateOnly(firstDate ?? DateTime(now.year - 10, 1, 1));
    final last = _dateOnly(lastDate ?? DateTime(now.year + 10, 12, 31));
    final parsed = DateTime.tryParse(controller.text.trim());
    final initial = _clampDate(_dateOnly(parsed ?? now), first, last);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      currentDate: now,
      helpText: labelText,
    );
    if (picked == null) {
      return;
    }

    final value = _formatDate(picked);
    controller.text = value;
    onChanged?.call(value);
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime _clampDate(DateTime date, DateTime first, DateTime last) {
  if (date.isBefore(first)) {
    return first;
  }
  if (date.isAfter(last)) {
    return last;
  }
  return date;
}

String _formatDate(DateTime date) {
  return [
    date.year.toString().padLeft(4, '0'),
    date.month.toString().padLeft(2, '0'),
    date.day.toString().padLeft(2, '0'),
  ].join('-');
}
