import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../main.dart';

Future<bool?> showDemoPayment(BuildContext context, String method, int total) {
  final showQr = method == 'QRIS' || method == 'Transfer Bank';
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      title: Text(method),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Konfirmasi ini hanya mencatat pesanan. Saldo Anda tidak akan terpotong.',
          ),
          const SizedBox(height: 8),
          Text('Total pesanan: ${rupiah(total)}'),
          if (method == 'Transfer Bank')
            const Text('Transfer dana tidak diperlukan.'),
          if (showQr) ...[
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                width: 168,
                height: 168,
                child: QrImageView(
                  // Beri ukuran tetap untuk tata letak dialog.
                  data: 'SEAFOOD ORDER | DEMO ONLY | $method | IDR $total',
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Selesaikan Pembayaran'),
        ),
      ],
    ),
  );
}
