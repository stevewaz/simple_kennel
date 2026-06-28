import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../services/prefs_service.dart';

final _dateFmt = DateFormat('MMM d, yyyy');
final _moneyFmt = NumberFormat.currency(symbol: '\$');

PdfColor get _brand => const PdfColor.fromInt(0xFF7B5EA7);

Future<void> printInvoice(
    Invoice inv, List<InvoiceLineItem> items) async {
  await Printing.layoutPdf(
    onLayout: (format) async => (await _buildPdf(inv, items)).save(),
  );
}

Future<pw.Document> _buildPdf(
    Invoice inv, List<InvoiceLineItem> items) async {
  final doc = pw.Document();
  final font = await PdfGoogleFonts.interRegular();
  final fontBold = await PdfGoogleFonts.interBold();

  final bizName = PrefsService.displayName;
  final bizAddr = PrefsService.businessAddress;
  final bizPhone = PrefsService.businessPhone;
  final bizEmail = PrefsService.businessEmail;

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(bizName,
                        style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 20,
                            color: _brand)),
                    if (bizAddr.isNotEmpty)
                      pw.Text(bizAddr,
                          style: pw.TextStyle(font: font, fontSize: 10)),
                    if (bizPhone.isNotEmpty)
                      pw.Text(bizPhone,
                          style: pw.TextStyle(font: font, fontSize: 10)),
                    if (bizEmail.isNotEmpty)
                      pw.Text(bizEmail,
                          style: pw.TextStyle(font: font, fontSize: 10)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('INVOICE',
                      style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 28,
                          color: _brand)),
                  pw.SizedBox(height: 4),
                  pw.Text(inv.invoiceNumber,
                      style: pw.TextStyle(font: fontBold, fontSize: 12)),
                  pw.SizedBox(height: 2),
                  _labelValue('Issued', _dateFmt.format(inv.issueDate), font, fontBold),
                  _labelValue('Due', _dateFmt.format(inv.dueDate), font, fontBold),
                  pw.SizedBox(height: 4),
                  _statusBadge(inv.status, fontBold),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 24),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 12),

          // Bill to
          pw.Text('Bill To',
              style: pw.TextStyle(
                  font: fontBold, fontSize: 10, color: PdfColors.grey600)),
          pw.SizedBox(height: 4),
          pw.Text(inv.customerName,
              style: pw.TextStyle(font: fontBold, fontSize: 14)),

          pw.SizedBox(height: 20),

          // Line items table
          pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FixedColumnWidth(52),
              2: const pw.FixedColumnWidth(80),
              3: const pw.FixedColumnWidth(88),
            },
            children: [
              // Table header
              pw.TableRow(
                decoration: pw.BoxDecoration(color: _brand),
                children: [
                  _th('Description', fontBold),
                  _th('Qty', fontBold, align: pw.TextAlign.center),
                  _th('Unit Price', fontBold, align: pw.TextAlign.right),
                  _th('Total', fontBold, align: pw.TextAlign.right),
                ],
              ),
              // Items
              ...items.map((item) => pw.TableRow(
                    decoration: pw.BoxDecoration(
                        color: items.indexOf(item).isEven
                            ? PdfColors.grey50
                            : PdfColors.white),
                    children: [
                      _td(item.description, font),
                      _td(_qty(item.quantity), font,
                          align: pw.TextAlign.center),
                      _td(_moneyFmt.format(item.unitPrice), font,
                          align: pw.TextAlign.right),
                      _td(_moneyFmt.format(item.lineTotal), font,
                          align: pw.TextAlign.right),
                    ],
                  )),
            ],
          ),

          pw.SizedBox(height: 12),

          // Totals
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.SizedBox(
              width: 220,
              child: pw.Column(
                children: [
                  _totalRow('Subtotal', _moneyFmt.format(inv.subTotal), font,
                      fontBold),
                  if (inv.taxRate > 0) ...[
                    _totalRow(
                        'Tax (${(inv.taxRate * 100).toStringAsFixed(0)}%)',
                        _moneyFmt.format(inv.taxAmount),
                        font,
                        fontBold),
                  ],
                  pw.Divider(color: PdfColors.grey300),
                  _totalRow('Total', _moneyFmt.format(inv.totalAmount), fontBold,
                      fontBold,
                      valueColor: _brand, fontSize: 14),
                ],
              ),
            ),
          ),

          // Notes
          if (inv.notes.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Text('Notes',
                style: pw.TextStyle(
                    font: fontBold, fontSize: 10, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text(inv.notes,
                style: pw.TextStyle(font: font, fontSize: 10)),
          ],

          pw.Spacer(),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 4),
          pw.Center(
            child: pw.Text('Thank you for your business!',
                style: pw.TextStyle(
                    font: font, fontSize: 10, color: PdfColors.grey500)),
          ),
        ],
      ),
    ),
  );

  return doc;
}

pw.Widget _th(String text, pw.Font font,
        {pw.TextAlign align = pw.TextAlign.left}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text,
          textAlign: align,
          style: pw.TextStyle(
              font: font, fontSize: 10, color: PdfColors.white)),
    );

pw.Widget _td(String text, pw.Font font,
        {pw.TextAlign align = pw.TextAlign.left}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(text,
          textAlign: align,
          style: pw.TextStyle(font: font, fontSize: 10)),
    );

pw.Widget _totalRow(String label, String value, pw.Font labelFont,
        pw.Font valueFont,
        {PdfColor? valueColor, double fontSize = 11}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(
              child: pw.Text(label,
                  style: pw.TextStyle(font: labelFont, fontSize: fontSize))),
          pw.Text(value,
              style: pw.TextStyle(
                  font: valueFont,
                  fontSize: fontSize,
                  color: valueColor ?? PdfColors.black)),
        ],
      ),
    );

pw.Widget _labelValue(
        String label, String value, pw.Font font, pw.Font fontBold) =>
    pw.Row(children: [
      pw.Text('$label: ',
          style:
              pw.TextStyle(font: font, fontSize: 10, color: PdfColors.grey600)),
      pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 10)),
    ]);

pw.Widget _statusBadge(String status, pw.Font font) {
  final color = switch (status) {
    'Paid' => const PdfColor.fromInt(0xFF4CAF50),
    'Sent' => const PdfColor.fromInt(0xFF2196F3),
    'Overdue' => const PdfColor.fromInt(0xFFD4714D),
    _ => PdfColors.grey500,
  };
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: pw.BoxDecoration(
        color: color, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
    child: pw.Text(status,
        style: pw.TextStyle(font: font, fontSize: 9, color: PdfColors.white)),
  );
}

String _qty(double q) =>
    q == q.truncateToDouble() ? q.toInt().toString() : q.toStringAsFixed(1);
