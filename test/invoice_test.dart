import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:uts/pages/invoice_page.dart';

void main() {
  testWidgets('Builder invoice menghasilkan dokumen PDF dalam memori', (
    tester,
  ) async {
    late PdfPreview preview;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            const invoice = InvoicePage(
              order: {
                'id': 7,
                'created_at': '2026-11-26T18:00:00',
                'payment_method': 'QRIS',
                'pickup': 0,
                'demo_paid': 1,
                'total': 95000,
              },
              items: [
                {
                  'menu_name': 'Ikan Bakar Jimbaran',
                  'price': 85000,
                  'quantity': 1,
                },
              ],
            );
            final scaffold = invoice.build(context) as Scaffold;
            preview = scaffold.body! as PdfPreview;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final result = await tester.runAsync(
      () async => preview.build(PdfPageFormat.a4),
    );
    expect(ascii.decode(result!.take(5).toList()), '%PDF-');
    expect(preview.pdfFileName, 'Seafood_Order_Invoice_7.pdf');
  });
}
