import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/invoice.dart';
import '../providers/app_provider.dart';
import '../services/theme_service.dart';
import '../utils/payments_csv.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _start;
  late DateTime _end;
  bool _exporting = false;

  static final _dateFmt = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = DateTime(now.year, now.month + 1, 0);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = DateTime(picked.year, picked.month, picked.day);
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        if (_start.isAfter(_end)) _start = _end;
      }
    });
  }

  Future<void> _export(List<Invoice> invoices) async {
    setState(() => _exporting = true);
    try {
      final csv = buildPaymentsCsv(invoices);
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final fileName =
          'runbook-payments-${DateFormat('yyyyMMdd').format(_start)}-${DateFormat('yyyyMMdd').format(_end)}.csv';
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save payments report',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: bytes,
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = context.watch<ThemeService>();
    final endOfDay = DateTime(_end.year, _end.month, _end.day, 23, 59, 59);
    final invoices = app.paidInvoicesBetween(_start, endOfDay);
    final total = invoices.fold<double>(0, (sum, i) => sum + i.totalAmount);

    return Scaffold(
      backgroundColor: theme.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Reports',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Payments',
                style: TextStyle(
                    color: theme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Paid invoices in the selected date range, ready to export for QuickBooks or your bookkeeper.',
                style: TextStyle(color: theme.subtextColor, fontSize: 12)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'From',
                    value: _dateFmt.format(_start),
                    theme: theme,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'To',
                    value: _dateFmt.format(_end),
                    theme: theme,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardBgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.borderColor),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${invoices.length} payment${invoices.length == 1 ? '' : 's'}',
                          style: TextStyle(
                              color: theme.textColor,
                              fontWeight: FontWeight.w600)),
                      Text('\$${total.toStringAsFixed(2)} total',
                          style: TextStyle(
                              color: theme.primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white),
                    icon: _exporting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download, size: 16),
                    label: const Text('Export CSV'),
                    onPressed: invoices.isEmpty || _exporting
                        ? null
                        : () => _export(invoices),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (invoices.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No paid invoices in this range',
                      style: TextStyle(color: theme.subtextColor)),
                ),
              )
            else
              ...invoices.map((inv) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.cardBgColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(inv.customerName,
                                  style: TextStyle(
                                      color: theme.textColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Text(
                                  '${inv.invoiceNumber} · ${inv.paymentMethod} · ${_dateFmt.format(inv.paidAt!)}',
                                  style: TextStyle(
                                      color: theme.subtextColor, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text(inv.amountDisplay,
                            style: TextStyle(
                                color: theme.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final ThemeService theme;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.formBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.inputBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: theme.subtextColor, fontSize: 11)),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(value,
                      style: TextStyle(
                          color: theme.textColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                ),
                Icon(Icons.calendar_today, size: 14, color: theme.subtextColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
