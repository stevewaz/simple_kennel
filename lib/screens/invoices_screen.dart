import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/theme_service.dart';
import '../models/invoice.dart';
import '../widgets/dialogs/add_invoice_dialog.dart';
import '../utils/invoice_pdf.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  String _search = '';
  String _filter = 'All';

  static const _statuses = ['All', 'Draft', 'Sent', 'Paid', 'Overdue'];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final theme = context.watch<ThemeService>();

    var list = app.invoices;
    if (_filter != 'All') list = list.where((i) => i.status == _filter).toList();
    if (_search.isNotEmpty) {
      list = list
          .where((i) =>
              i.customerName.toLowerCase().contains(_search.toLowerCase()) ||
              i.invoiceNumber.toLowerCase().contains(_search.toLowerCase()))
          .toList();
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search invoices...',
                        prefixIcon:
                            Icon(Icons.search, color: theme.subtextColor),
                        hintStyle: TextStyle(color: theme.subtextColor),
                      ),
                      style: TextStyle(color: theme.textColor),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Invoice'),
                    onPressed: () => _showAdd(context, app, theme),
                  ),
                ],
              ),
            ),
            // Status filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _statuses.map((s) {
                  final selected = _filter == s;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(s,
                          style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : theme.textColor,
                              fontSize: 12)),
                      selected: selected,
                      selectedColor: theme.primaryColor,
                      backgroundColor: theme.cardBgColor,
                      side: BorderSide(color: theme.borderColor),
                      onSelected: (_) => setState(() => _filter = s),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('No invoices',
                          style: TextStyle(color: theme.subtextColor)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _InvoiceTile(
                          inv: list[i], theme: theme, app: app),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdd(BuildContext context, AppProvider app, ThemeService theme) {
    showDialog(
      context: context,
      builder: (_) => AddInvoiceDialog(
        customers: app.customers,
        bookings: app.bookings,
        services: app.services,
        getNextInvoiceNumber: app.getNextInvoiceNumber,
        hasInvoiceForBooking: app.hasInvoiceForBooking,
        defaultTaxRate: theme.isDark ? 0 : 0, // loaded from prefs in dialog
        onSave: (inv, items) => app.saveInvoice(inv, items),
        theme: theme,
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Invoice inv;
  final ThemeService theme;
  final AppProvider app;
  const _InvoiceTile(
      {required this.inv, required this.theme, required this.app});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardBgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.borderColor),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: theme.primaryColor,
          child: Text(inv.initials,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
        title: Row(
          children: [
            Text(inv.customerName,
                style: TextStyle(
                    color: theme.textColor, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(inv.amountDisplay,
                style: TextStyle(
                    color: theme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
        subtitle: Row(
          children: [
            Text(inv.invoiceNumber,
                style: TextStyle(color: theme.subtextColor, fontSize: 12)),
            const SizedBox(width: 8),
            Text(
                '${DateFormat('MMM d').format(inv.issueDate)} – ${DateFormat('MMM d, yyyy').format(inv.dueDate)}',
                style: TextStyle(color: theme.subtextColor, fontSize: 12)),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: inv.statusColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(inv.status,
                  style: TextStyle(
                      color: inv.statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          color: theme.cardBgColor,
          itemBuilder: (_) => [
            PopupMenuItem(
                value: 'print',
                child: Row(children: [
                  const Icon(Icons.print, size: 16),
                  const SizedBox(width: 8),
                  Text('Print', style: TextStyle(color: theme.textColor)),
                ])),
            PopupMenuItem(
                value: 'edit',
                child: Text('Edit', style: TextStyle(color: theme.textColor))),
            ..._statuses(inv.status).map((s) => PopupMenuItem(
                value: s,
                child:
                    Text('Mark $s', style: TextStyle(color: theme.textColor)))),
            PopupMenuItem(
                value: 'delete',
                child: const Text('Delete',
                    style: TextStyle(color: Color(0xFFD4714D)))),
          ],
          onSelected: (v) => _onAction(context, v),
        ),
      ),
    );
  }

  List<String> _statuses(String current) {
    const all = ['Draft', 'Sent', 'Paid', 'Overdue'];
    return all.where((s) => s != current).toList();
  }

  void _onAction(BuildContext context, String action) async {
    if (action == 'print') {
      final items = await app.getLineItems(inv.id);
      await printInvoice(inv, items);
    } else if (action == 'delete') {
      app.deleteInvoice(inv);
    } else if (action == 'edit') {
      final items = await app.getLineItems(inv.id);
      if (!context.mounted) return;
      final theme = context.read<ThemeService>();
      showDialog(
        context: context,
        builder: (_) => AddInvoiceDialog(
          existing: inv,
          existingItems: items,
          customers: app.customers,
          bookings: app.bookings,
          services: app.services,
          getNextInvoiceNumber: app.getNextInvoiceNumber,
          hasInvoiceForBooking: app.hasInvoiceForBooking,
          defaultTaxRate: 0,
          onSave: (updated, newItems) => app.saveInvoice(updated, newItems),
          theme: theme,
        ),
      );
    } else {
      app.saveInvoice(inv.copyWith(status: action), []);
    }
  }
}
