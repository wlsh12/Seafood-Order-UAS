import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uts/pages/demo_payment.dart';

void main() {
  testWidgets('QRIS menampilkan QR demo dan mengembalikan konfirmasi', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showDemoPayment(context, 'QRIS', 95000);
              },
              child: const Text('Buka checkout'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka checkout'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);
    expect(find.text('Total pesanan: Rp 95.000'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('Buka checkout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Selesaikan Pembayaran'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
