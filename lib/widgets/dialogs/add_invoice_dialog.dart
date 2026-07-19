import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/invoice.dart';
import '../../models/customer.dart';
import '../../models/booking.dart';
import '../../models/service.dart';
import '../../services/theme_service.dart';
import '../../services/tenant_settings_service.dart';

class AddInvoiceDialog extends StatefulWidget {
  final Invoice? existing;
  final List<InvoiceLineItem> existingItems;
  final List<Customer> customers;
  final List<Booking> bookings;
  final List<Service> services;
  final Future<String> Function() getNextInvoiceNumber;
  final Future<bool> Function(String) hasInvoiceForBooking;
  final double defaultTaxRate;
  final Future<void> Function(Invoice, List<InvoiceLineItem>) onSave;
  final ThemeService theme;

  final Customer? initialCustomer;
  final Booking? initialBooking;

  const AddInvoiceDialog({
    super.key,
    this.existing,
    this.existingItems = const [],
    this.initialCustomer,
    this.initialBooking,
    required this.customers,
    required this.bookings,
    required this.services,
    required this.getNextInvoiceNumber,
    required this.hasInvoiceForBooking,
    required this.defaultTaxRate,
    required this.onSave,
    required this.theme,
  });

  @override
  State<AddInvoiceDialog> createState() => _AddInvoiceDialogState();
}

class _AddInvoiceDialogState extends State<AddInvoiceDialog> {
  Customer? _customer;
  Booking? _booking;
  String _invoiceNumber = '';
  DateTime _issueDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _status = 'Draft';
  final _notesCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  List<_LineItemRow> _items = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final taxRate = context.read<TenantSettingsService>().defaultTaxRate;
    _taxCtrl.text = taxRate > 0 ? taxRate.toStringAsFixed(0) : '';

    if (widget.existing != null) {
      final inv = widget.existing!;
      _customer =
          widget.customers.where((c) => c.id == inv.customerId).firstOrNull;
      _invoiceNumber = inv.invoiceNumber;
      _issueDate = inv.issueDate;
      _dueDate = inv.dueDate;
      _status = inv.status;
      _notesCtrl.text = inv.notes;
      _taxCtrl.text =
          inv.taxRate > 0 ? (inv.taxRate * 100).toStringAsFixed(0) : '';
      _items = widget.existingItems
          .map((i) => _LineItemRow(
                desc: TextEditingController(text: i.description),
                qty: TextEditingController(text: i.quantity.toStringAsFixed(1)),
                price: TextEditingController(
                    text: i.unitPrice.toStringAsFixed(2)),
              ))
          .toList();
    } else {
      _customer = widget.initialCustomer;
      _booking = widget.initialBooking;
      _items = [_LineItemRow.empty()];
      _loadInvoiceNumber();
    }
  }

  Future<void> _loadInvoiceNumber() async {
    final num = await widget.getNextInvoiceNumber();
    if (mounted) setState(() => _invoiceNumber = num);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _taxCtrl.dispose();
    for (final i in _items) {
      i.desc.dispose();
      i.qty.dispose();
      i.price.dispose();
    }
    super.dispose();
  }

  double get _subTotal => _items.fold(
      0,
      (sum, i) =>
          sum +
          (double.tryParse(i.qty.text) ?? 0) *
              (double.tryParse(i.price.text) ?? 0));

  double get _taxRate =>
      (double.tryParse(_taxCtrl.text) ?? 0) / 100;

  double get _taxAmount => _subTotal * _taxRate;
  double get _total => _subTotal + _taxAmount;

  Future<void> _pickDate(bool isIssue) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isIssue ? _issueDate : _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (isIssue) { _issueDate = picked; } else { _dueDate = picked; }
    });
  }

  Future<void> _save() async {
    if (_customer == null) return;
    setState(() => _saving = true);
    final inv = Invoice(
      id: widget.existing?.id ?? '',
      customerId: _customer!.id,
      customerName: _customer!.name,
      invoiceNumber: _invoiceNumber,
      bookingId: _booking?.id ?? widget.existing?.bookingId ?? '',
      issueDate: _issueDate,
      dueDate: _dueDate,
      status: _status,
      notes: _notesCtrl.text.trim(),
      subTotal: _subTotal,
      taxRate: _taxRate,
      taxAmount: _taxAmount,
      totalAmount: _total,
      createdAt: widget.existing?.createdAt ?? DateTime.now().toUtc(),
    );
    final lineItems = _items
        .where((i) => i.desc.text.isNotEmpty)
        .map((i) => InvoiceLineItem(
              invoiceId: inv.id,
              description: i.desc.text.trim(),
              quantity: double.tryParse(i.qty.text) ?? 1,
              unitPrice: double.tryParse(i.price.text) ?? 0,
            ))
        .toList();
    await widget.onSave(inv, lineItems);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isEdit = widget.existing != null;

    return AlertDialog(
      backgroundColor: theme.cardBgColor,
      title: Text(isEdit ? 'Edit Invoice' : 'New Invoice',
          style: TextStyle(color: theme.textColor)),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer + Invoice number row
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<Customer>(
                    initialValue: _customer,
                    decoration: InputDecoration(
                        labelText: 'Customer',
                        labelStyle: TextStyle(color: theme.subtextColor)),
                    dropdownColor: theme.cardBgColor,
                    style: TextStyle(color: theme.textColor),
                    items: widget.customers
                        .map((c) =>
                            DropdownMenuItem(value: c, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _customer = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                        labelText: 'Invoice #',
                        labelStyle: TextStyle(color: theme.subtextColor)),
                    controller: TextEditingController(text: _invoiceNumber),
                    style: TextStyle(color: theme.textColor),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              // Date row
              Row(children: [
                Expanded(
                  child: _DatePicker(
                    label: 'Issue Date',
                    date: _issueDate,
                    theme: theme,
                    onTap: () => _pickDate(true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePicker(
                    label: 'Due Date',
                    date: _dueDate,
                    theme: theme,
                    onTap: () => _pickDate(false),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              // Status
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: InputDecoration(
                    labelText: 'Status',
                    labelStyle: TextStyle(color: theme.subtextColor)),
                dropdownColor: theme.cardBgColor,
                style: TextStyle(color: theme.textColor),
                items: ['Draft', 'Sent', 'Paid', 'Overdue']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'Draft'),
              ),
              const SizedBox(height: 16),

              // Line items header
              Row(children: [
                Expanded(
                    flex: 4,
                    child: Text('Description',
                        style: TextStyle(color: theme.subtextColor, fontSize: 12))),
                Expanded(
                    child: Text('Qty',
                        style: TextStyle(color: theme.subtextColor, fontSize: 12),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('Price',
                        style: TextStyle(color: theme.subtextColor, fontSize: 12),
                        textAlign: TextAlign.center)),
                Expanded(
                    child: Text('Total',
                        style: TextStyle(color: theme.subtextColor, fontSize: 12),
                        textAlign: TextAlign.right)),
                const SizedBox(width: 32),
              ]),
              Divider(color: theme.borderColor),

              // Line items
              ...List.generate(_items.length, (i) {
                final item = _items[i];
                final lineTotal =
                    (double.tryParse(item.qty.text) ?? 0) *
                        (double.tryParse(item.price.text) ?? 0);
                final activeServices =
                    widget.services.where((s) => s.isActive).toList();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Expanded(
                        flex: 4,
                        child: TextField(
                          controller: item.desc,
                          decoration: InputDecoration(
                              hintText: 'Description',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              suffixIcon: activeServices.isNotEmpty
                                  ? IconButton(
                                      tooltip: 'Pick from catalog',
                                      icon: Icon(Icons.list_alt_outlined,
                                          size: 16, color: theme.subtextColor),
                                      onPressed: () =>
                                          _pickService(i, activeServices),
                                    )
                                  : null),
                          style: TextStyle(color: theme.textColor, fontSize: 13),
                          onChanged: (_) => setState(() {}),
                        )),
                    const SizedBox(width: 6),
                    Expanded(
                        child: TextField(
                          controller: item.qty,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6)),
                          style: TextStyle(color: theme.textColor, fontSize: 13),
                          textAlign: TextAlign.center,
                          onChanged: (_) => setState(() {}),
                        )),
                    const SizedBox(width: 6),
                    Expanded(
                        child: TextField(
                          controller: item.price,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                              prefixText: '\$',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6)),
                          style: TextStyle(color: theme.textColor, fontSize: 13),
                          textAlign: TextAlign.center,
                          onChanged: (_) => setState(() {}),
                        )),
                    const SizedBox(width: 6),
                    Expanded(
                        child: Text(
                          '\$${lineTotal.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: theme.textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        )),
                    IconButton(
                      icon: Icon(Icons.remove_circle_outline,
                          color: theme.subtextColor, size: 18),
                      onPressed: _items.length > 1
                          ? () => setState(() => _items.removeAt(i))
                          : null,
                    ),
                  ]),
                );
              }),

              TextButton.icon(
                onPressed: () => setState(() => _items.add(_LineItemRow.empty())),
                icon: Icon(Icons.add, color: theme.primaryColor, size: 16),
                label: Text('Add line item',
                    style: TextStyle(color: theme.primaryColor, fontSize: 13)),
              ),

              Divider(color: theme.borderColor),

              // Totals
              _TotalRow('Subtotal', '\$${_subTotal.toStringAsFixed(2)}', theme),
              Row(children: [
                Expanded(
                    child: Text('Tax Rate',
                        style: TextStyle(color: theme.subtextColor, fontSize: 13))),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _taxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        suffixText: '%',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 6)),
                    style: TextStyle(color: theme.textColor, fontSize: 13),
                    textAlign: TextAlign.right,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ]),
              _TotalRow('Tax', '\$${_taxAmount.toStringAsFixed(2)}', theme),
              Divider(color: theme.borderColor),
              _TotalRow('Total', '\$${_total.toStringAsFixed(2)}', theme,
                  bold: true, color: theme.primaryColor),

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
          child: Text(_saving
              ? 'Saving…'
              : (isEdit ? 'Update Invoice' : 'Save Invoice')),
        ),
      ],
    );
  }

  void _pickService(int rowIndex, List<Service> services) {
    final theme = widget.theme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardBgColor,
        title: Text('Select Service',
            style: TextStyle(color: theme.textColor)),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: services
                .map((s) => ListTile(
                      title: Text(s.name,
                          style: TextStyle(color: theme.textColor)),
                      subtitle: Text(s.priceDisplay,
                          style: TextStyle(color: theme.subtextColor)),
                      onTap: () {
                        setState(() {
                          _items[rowIndex].desc.text = s.name;
                          _items[rowIndex].price.text =
                              s.defaultPrice.toStringAsFixed(2);
                        });
                        Navigator.pop(ctx);
                      },
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _LineItemRow {
  final TextEditingController desc;
  final TextEditingController qty;
  final TextEditingController price;

  _LineItemRow(
      {required this.desc, required this.qty, required this.price});

  factory _LineItemRow.empty() => _LineItemRow(
        desc: TextEditingController(),
        qty: TextEditingController(text: '1'),
        price: TextEditingController(text: '0.00'),
      );
}

class _DatePicker extends StatelessWidget {
  final String label;
  final DateTime date;
  final ThemeService theme;
  final VoidCallback onTap;
  const _DatePicker(
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
                style: TextStyle(color: theme.subtextColor, fontSize: 12)),
            Text(DateFormat('MMM d, yyyy').format(date),
                style: TextStyle(
                    color: theme.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            Icon(Icons.calendar_today, size: 14, color: theme.subtextColor),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeService theme;
  final bool bold;
  final Color? color;
  const _TotalRow(this.label, this.value, this.theme,
      {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    color: bold ? theme.textColor : theme.subtextColor,
                    fontSize: 13,
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.normal)),
          ),
          Text(value,
              style: TextStyle(
                  color: color ?? theme.textColor,
                  fontSize: 13,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
