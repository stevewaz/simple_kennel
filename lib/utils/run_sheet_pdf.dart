import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/booking.dart';
import '../models/customer.dart';
import '../models/pet.dart';

final _dateFmt = DateFormat('MMM d, yyyy');

PdfColor get _brand => const PdfColor.fromInt(0xFF7B5EA7);

/// Prints a one-page "Boarding Data Sheet" for a run: business header,
/// run/client info, every pet on the booking, and blank Feed/Notes boxes
/// for staff to fill in by hand while the pet is boarding.
Future<void> printRunSheet(
  Booking booking,
  Customer? customer,
  List<Pet> pets, {
  required bool isNewClient,
  required String businessName,
}) async {
  await Printing.layoutPdf(
    onLayout: (format) async => (await _buildPdf(booking, customer, pets,
            isNewClient: isNewClient, businessName: businessName))
        .save(),
  );
}

Future<pw.Document> _buildPdf(
  Booking booking,
  Customer? customer,
  List<Pet> pets, {
  required bool isNewClient,
  required String businessName,
}) async {
  final doc = pw.Document();
  final font = await PdfGoogleFonts.interRegular();
  final fontBold = await PdfGoogleFonts.interBold();

  final bizName = businessName;
  final phone = customer?.phoneNumber ?? '';

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Center(
            child: pw.Text(bizName,
                style: pw.TextStyle(font: fontBold, fontSize: 20, color: _brand)),
          ),
          pw.Center(
            child: pw.Text('Boarding Data Sheet',
                style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700)),
          ),
          pw.Center(
            child: pw.Text(_dateFmt.format(DateTime.now()),
                style: pw.TextStyle(font: font, fontSize: 11, color: PdfColors.grey600)),
          ),
          pw.SizedBox(height: 14),

          // Run / New client row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _labelValue('RUN', booking.runName.isEmpty
                  ? '#${booking.runIndex + 1}'
                  : booking.runName, font, fontBold, fontSize: 13),
              _labelValue('NEW CLIENT?', isNewClient ? 'YES' : 'NO', font,
                  fontBold,
                  fontSize: 13,
                  valueColor: isNewClient ? _brand : const PdfColor.fromInt(0xFFD4714D)),
            ],
          ),
          pw.SizedBox(height: 10),

          // Client + arrival info box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _fieldLine('Client', booking.customerName, font, fontBold),
                      _fieldLine('Phone', phone, font, fontBold),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _fieldLine('Arrive', _dateFmt.format(booking.checkInDate),
                          font, fontBold),
                      _fieldLine('Depart', _dateFmt.format(booking.checkOutDate),
                          font, fontBold),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 10),

          // Pets table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  _th('Pet Name', fontBold),
                  _th('Breed', fontBold),
                  _th('Gender', fontBold),
                  _th('Source', fontBold),
                ],
              ),
              if (pets.isEmpty)
                pw.TableRow(children: [
                  _td('', font),
                  _td('', font),
                  _td('', font),
                  _td('', font),
                ])
              else
                ...pets.map((p) => pw.TableRow(children: [
                      _td(p.name, font),
                      _td(p.breed, font),
                      _td(p.gender, font),
                      _td(p.source, font),
                    ])),
            ],
          ),

          pw.SizedBox(height: 10),
          _boxSection('Feed', font, fontBold, height: 110),
          pw.SizedBox(height: 10),
          _boxSection('Notes', font, fontBold,
              height: 160, prefill: booking.notes),
        ],
      ),
    ),
  );

  return doc;
}

pw.Widget _labelValue(String label, String value, pw.Font font,
        pw.Font fontBold,
        {double fontSize = 11, PdfColor? valueColor}) =>
    pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$label: ',
            style: pw.TextStyle(font: fontBold, fontSize: fontSize)),
        pw.Text(value,
            style: pw.TextStyle(
                font: fontBold,
                fontSize: fontSize,
                color: valueColor ?? PdfColors.black)),
      ],
    );

pw.Widget _fieldLine(String label, String value, pw.Font font, pw.Font fontBold) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(children: [
        pw.SizedBox(
          width: 50,
          child: pw.Text('$label:',
              style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.grey700)),
        ),
        pw.Text(value.isEmpty ? '—' : value,
            style: pw.TextStyle(font: font, fontSize: 11)),
      ]),
    );

pw.Widget _th(String text, pw.Font font) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10)),
    );

pw.Widget _td(String text, pw.Font font) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 10)),
    );

pw.Widget _boxSection(String title, pw.Font font, pw.Font fontBold,
        {required double height, String prefill = ''}) =>
    pw.Container(
      width: double.infinity,
      height: height,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.black)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(font: fontBold, fontSize: 11)),
          if (prefill.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(prefill, style: pw.TextStyle(font: font, fontSize: 10)),
          ],
        ],
      ),
    );
