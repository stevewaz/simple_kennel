import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/booking.dart';
import '../../models/customer.dart';
import '../../services/theme_service.dart';

class AddBookingDialog extends StatefulWidget {
  final int initialDay;
  final int initialMonth;
  final int initialYear;
  final int initialRunIndex;
  final String initialRunName;
  final List<Customer> customers;
  final Future<void> Function(Booking) onSave;
  final ThemeService theme;

  const AddBookingDialog({
    super.key,
    required this.initialDay,
    required this.initialMonth,
    required this.initialYear,
    required this.initialRunIndex,
    required this.initialRunName,
    required this.customers,
    required this.onSave,
    required this.theme,
  });

  @override
  State<AddBookingDialog> createState() => _AddBookingDialogState();
}

class _AddBookingDialogState extends State<AddBookingDialog> {
  late int _runIndex;
  late String _runName;
  Customer? _customer;
  late DateTime _checkIn;
  late DateTime _checkOut;
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _runIndex = widget.initialRunIndex;
    _runName = widget.initialRunName;
    _checkIn =
        DateTime(widget.initialYear, widget.initialMonth, widget.initialDay);
    _checkOut = _checkIn;
    if (widget.customers.isNotEmpty) _customer = widget.customers.first;
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (isCheckIn) {
        _checkIn = picked;
        if (_checkOut.isBefore(_checkIn)) _checkOut = _checkIn;
      } else {
        _checkOut = picked;
        if (_checkIn.isAfter(_checkOut)) _checkIn = _checkOut;
      }
    });
  }

  Future<void> _save() async {
    if (_customer == null) return;
    setState(() => _saving = true);
    final booking = Booking(
      customerName: _customer!.name,
      day: _checkIn.day,
      month: _checkIn.month,
      year: _checkIn.year,
      endDay: _checkOut.day,
      runIndex: _runIndex,
      runName: _runName,
      notes: _notesCtrl.text.trim(),
    );
    await widget.onSave(booking);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return AlertDialog(
      backgroundColor: theme.cardBgColor,
      title:
          Text('New Booking', style: TextStyle(color: theme.textColor)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Customer
            DropdownButtonFormField<Customer>(
              initialValue: _customer,
              decoration: InputDecoration(
                  labelText: 'Customer',
                  labelStyle: TextStyle(color: theme.subtextColor)),
              dropdownColor: theme.cardBgColor,
              style: TextStyle(color: theme.textColor),
              items: widget.customers
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _customer = v),
            ),
            const SizedBox(height: 12),
            // Run selector
            DropdownButtonFormField<int>(
              initialValue: _runIndex,
              decoration: InputDecoration(
                  labelText: 'Run',
                  labelStyle: TextStyle(color: theme.subtextColor)),
              dropdownColor: theme.cardBgColor,
              style: TextStyle(color: theme.textColor),
              items: List.generate(
                  15,
                  (i) => DropdownMenuItem(
                      value: i, child: Text('Run ${i + 1}'))).toList(),
              onChanged: (v) => setState(() {
                _runIndex = v!;
                _runName = 'Run ${v + 1}';
              }),
            ),
            const SizedBox(height: 12),
            // Check-in date
            _DateRow(
              label: 'Check-in',
              date: _checkIn,
              theme: theme,
              onTap: () => _pickDate(true),
            ),
            const SizedBox(height: 8),
            _DateRow(
              label: 'Check-out',
              date: _checkOut,
              theme: theme,
              onTap: () => _pickDate(false),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                  labelText: 'Notes',
                  labelStyle: TextStyle(color: theme.subtextColor)),
              style: TextStyle(color: theme.textColor),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                Text('Cancel', style: TextStyle(color: theme.subtextColor))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save Booking'),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final DateTime date;
  final ThemeService theme;
  final VoidCallback onTap;
  const _DateRow(
      {required this.label,
      required this.date,
      required this.theme,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.formBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.inputBorderColor),
        ),
        child: Row(
          children: [
            Text('$label: ',
                style: TextStyle(color: theme.subtextColor, fontSize: 13)),
            Text(DateFormat('MMM d, yyyy').format(date),
                style: TextStyle(
                    color: theme.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(Icons.calendar_today, size: 16, color: theme.subtextColor),
          ],
        ),
      ),
    );
  }
}
