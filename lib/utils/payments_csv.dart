import 'package:intl/intl.dart';
import '../models/invoice.dart';

final _dateFmt = DateFormat('MM/dd/yyyy');

/// Builds a CSV of paid invoices — Date, Customer, Invoice #, Amount,
/// Payment Method — suitable for a bookkeeper/accountant or manual entry
/// into QuickBooks. [invoices] should already be filtered/sorted (see
/// AppProvider.paidInvoicesBetween).
String buildPaymentsCsv(List<Invoice> invoices) {
  final buf = StringBuffer()
    ..writeln('Date,Customer,Invoice #,Amount,Payment Method');
  for (final inv in invoices) {
    final date = inv.paidAt != null ? _dateFmt.format(inv.paidAt!) : '';
    buf.writeln([
      date,
      inv.customerName,
      inv.invoiceNumber,
      inv.totalAmount.toStringAsFixed(2),
      inv.paymentMethod,
    ].map(_csvField).join(','));
  }
  return buf.toString();
}

String _csvField(String value) {
  if (value.contains(RegExp('[,"\n]'))) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
