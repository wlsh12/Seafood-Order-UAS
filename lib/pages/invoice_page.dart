import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../main.dart';

class InvoicePage extends StatelessWidget {
  const InvoicePage({super.key, required this.order, required this.items});

  final Map<String, Object?> order;
  final List<Map<String, Object?>> items;

  Future<Uint8List> _buildPdf(PdfPageFormat format) async {
    final font = pw.Font.ttf(
      await rootBundle.load('assets/fonts/OpenSans-Regular.ttf'),
    );
    final doc = pw.Document();
    final total = order['total'] as int;
    final subtotal = items.fold<int>(
      0,
      (sum, item) => sum + (item['quantity'] as int) * (item['price'] as int),
    );
    final date = DateTime.tryParse(order['created_at'] as String? ?? '');
    final dateText = date == null
        ? 'Belum tercatat'
        : '${date.day}/${date.month}/${date.year} '
              '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final pickup = order['pickup'] == 1;

    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/OpenSans-Bold.ttf'),
    );
    final ink = PdfColor.fromInt(0xff103749);
    final sea = PdfColor.fromInt(0xff086675);
    final mist = PdfColor.fromInt(0xffecf6f6);
    final number = "SO-${order['id'].toString().padLeft(5, '0')}";
    final customer = (order['customer_name'] as String? ?? '').trim();
    final schedule = (order['delivery_date'] as String? ?? '').trim();
    pw.TextStyle emphasis(double size, PdfColor color) =>
        pw.TextStyle(font: bold, fontSize: size, color: color);

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(36),
        theme: pw.ThemeData.withFont(base: font, bold: bold),
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 14),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: mist)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Seafood Order  /  $number',
                style: pw.TextStyle(fontSize: 9, color: sea),
              ),
              pw.Text(
                '${ctx.pageNumber} / ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        build: (_) => [
          pw.Container(
            color: ink,
            padding: const pw.EdgeInsets.all(20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Seafood Order',
                      style: emphasis(13, PdfColors.white),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Invoice pesanan',
                      style: emphasis(25, PdfColors.white),
                    ),
                  ],
                ),
                pw.Text(number, style: emphasis(12, PdfColors.white)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(14),
            color: mist,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Rincian pesanan', style: emphasis(13, ink)),
                pw.SizedBox(height: 5),
                if (customer.isNotEmpty) pw.Text('Penerima: $customer'),
                pw.Text('Tanggal pemesanan: $dateText'),
                pw.Text('Penerimaan: ${pickup ? 'Ambil sendiri' : 'Diantar'}'),
                if (schedule.isNotEmpty) pw.Text('Jadwal: $schedule'),
                pw.Text('Metode pembayaran: ${order['payment_method']}'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headers: ['Menu', 'Porsi', 'Harga satuan', 'Jumlah'],
            border: null,
            headerDecoration: pw.BoxDecoration(color: sea),
            headerStyle: emphasis(10, PdfColors.white),
            oddRowDecoration: pw.BoxDecoration(color: mist),
            cellStyle: pw.TextStyle(fontSize: 10, color: ink),
            cellPadding: const pw.EdgeInsets.all(8),
            columnWidths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1.6),
              3: pw.FlexColumnWidth(1.6),
            },
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
            },
            data: [
              for (final item in items)
                [
                  [
                    item['menu_name'],
                    if ((item['options']?.toString().trim() ?? '').isNotEmpty)
                      item['options'],
                    if ((item['note']?.toString().trim() ?? '').isNotEmpty)
                      'Catatan: ${item['note']}',
                  ].join('\n'),
                  item['quantity'].toString(),
                  rupiah(item['price'] as int),
                  rupiah((item['quantity'] as int) * (item['price'] as int)),
                ],
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 225,
              padding: const pw.EdgeInsets.all(14),
              color: mist,
              child: pw.Column(
                children: [
                  for (final row in [
                    ('Subtotal', subtotal),
                    ('Ongkos kirim', total - subtotal),
                  ])
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [pw.Text(row.$1), pw.Text(rupiah(row.$2))],
                      ),
                    ),
                  pw.Divider(color: sea),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Total pesanan', style: emphasis(12, ink)),
                      pw.Text(rupiah(total), style: emphasis(13, sea)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Text(
            order['demo_paid'] == 1
                ? 'Pesanan tercatat. Tidak ada penagihan dana.'
                : 'Status pembayaran belum diverifikasi.',
            style: pw.TextStyle(fontSize: 9, color: ink),
          ),
        ],
      ),
    );
    return doc.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invoice #${order['id']}')),
      body: PdfPreview(
        build: _buildPdf,
        pdfFileName: 'Seafood_Order_Invoice_${order['id']}.pdf',
        initialPageFormat: PdfPageFormat.a4,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: false,
      ),
    );
  }
}
