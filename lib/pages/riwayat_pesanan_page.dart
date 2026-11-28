import 'invoice_page.dart';

import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../keranjang_page.dart';
import '../main.dart';
import '../services/menu_api_service.dart';
import '../services/app_database.dart';

class RiwayatPesananPage extends StatefulWidget {
  const RiwayatPesananPage({super.key});

  @override
  State<RiwayatPesananPage> createState() => _RiwayatPesananPageState();
}

class _RiwayatPesananPageState extends State<RiwayatPesananPage> {
  late Future<List<Map<String, Object?>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = AppDatabase.instance.getOrders();
  }

  int? _pesananDiproses;

  // Cocokkan isi pesanan lama dengan katalog saat ini.
  Future<void> _pesanLagi(int id, List<Map<String, Object?>> items) async {
    if (_pesananDiproses != null) return;
    setState(() => _pesananDiproses = id);
    final api = MenuApiService();
    try {
      final records = await api.fetchMenus();
      final katalog = records.map(Menu.fromMap).toList();
      if (!mounted) return;
      final dilewati = <String>[];
      var ditambah = 0;
      for (final item in items) {
        final nama = item['menu_name'] as String;
        // Riwayat lama menyimpan nama menu. Hanya pilih pasangan yang unik.
        final cocok = katalog.where((m) => m.nama == nama).toList();
        if (cocok.length != 1 || !cocok.first.tersedia) {
          dilewati.add(nama);
          continue;
        }
        cart.tambah(
          cocok.first,
          item['options'] as String? ?? '',
          item['note'] as String? ?? '',
          item['quantity'] as int,
        );
        ditambah++;
      }
      if (dilewati.isNotEmpty || ditambah == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              dilewati.isEmpty
                  ? 'Pesanan ini kosong.'
                  : 'Menu dilewati: ${dilewati.join(", ")}.',
            ),
          ),
        );
      }
      if (ditambah > 0) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KeranjangPage()),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memuat katalog terbaru. Coba lagi.'),
          ),
        );
      }
    } finally {
      api.close();
      if (mounted) setState(() => _pesananDiproses = null);
    }
  }

  void _reload() {
    final ordersFuture = AppDatabase.instance.getOrders();
    setState(() {
      _ordersFuture = ordersFuture;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang riwayat',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, Object?>>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const TampilanStatus(judul: 'Memuat riwayat…');
          }
          if (snapshot.hasError) {
            return TampilanStatus(
              ikon: Icons.error_outline,
              judul: 'Riwayat gagal dimuat',
              tindakan: FilledButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            );
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return TampilanStatus(
              ikon: Icons.receipt_long_outlined,
              judul: 'Belum ada pesanan',
              pesan: 'Pesanan yang tersimpan akan muncul di sini.',
              tindakan: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Kembali ke beranda'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              final pickup = order['pickup'] == 1;
              final items = order['items'] as List<Map<String, Object?>>;
              final date = DateTime.tryParse(
                order['created_at'] as String? ?? '',
              );
              final dateText = date == null
                  ? 'Tanggal belum tercatat'
                  : '${date.day.toString().padLeft(2, '0')}/'
                        '${date.month.toString().padLeft(2, '0')}/${date.year} · '
                        '${date.hour.toString().padLeft(2, '0')}:'
                        '${date.minute.toString().padLeft(2, '0')}';

              // Pesanan lama bisa memiliki tanggal pengiriman kosong.
              final tanggalKirim = order['delivery_date'] as String? ?? '';
              return Card(
                key: ValueKey(order['id']),
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    'Pesanan #${order['id']}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateText,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rupiah(order['total'] as int),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Divider(height: 20),
                          Text('Penerima: ${order['customer_name']}'),
                          const SizedBox(height: 6),
                          Text(
                            pickup
                                ? 'Ambil sendiri di restoran'
                                : 'Diantar ke: ${order['address']}',
                          ),
                          const SizedBox(height: 6),
                          Text('Metode pembayaran: ${order['payment_method']}'),
                          if (order['demo_paid'] == 1)
                            const Text('Status: Pesanan tercatat'),
                          const SizedBox(height: 6),
                          Text(
                            'Tanggal ${pickup ? 'pengambilan' : 'pengiriman'}: ${tanggalKirim.isEmpty ? 'Belum tercatat' : tanggalKirim}',
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Alat makan: ${order['needs_cutlery'] == 1 ? 'disertakan' : 'tidak perlu'}',
                          ),
                          const Divider(height: 24),
                          for (final item in items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  BarisHarga(
                                    "${item['quantity']} × ${item['menu_name']}",
                                    rupiah(
                                      (item['quantity'] as int) *
                                          (item['price'] as int),
                                    ),
                                  ),
                                  for (final field in ['options', 'note'])
                                    if ((item[field] as String? ?? '')
                                        .trim()
                                        .isNotEmpty)
                                      Text(
                                        "${field == 'options' ? 'Pilihan' : 'Catatan'}: ${item[field]}",
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ),
                                ],
                              ),
                            ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('Buka invoice PDF'),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    InvoicePage(order: order, items: items),
                              ),
                            ),
                          ),
                          if (Platform.isAndroid)
                            OutlinedButton.icon(
                              icon: const Icon(Icons.share_outlined),
                              label: const Text('Bagikan ringkasan'),
                              onPressed: () async {
                                final lines = [
                                  "Seafood Order · Pesanan #${order['id']}",
                                  for (final item in items)
                                    "${item['quantity']} × ${item['menu_name']} · ${rupiah((item['price'] as int) * (item['quantity'] as int))}",
                                  pickup ? 'Ambil sendiri' : 'Diantar',
                                  "Total: ${rupiah(order['total'] as int)}",
                                ];
                                try {
                                  await const MethodChannel('seafood/share')
                                      .invokeMethod<void>(
                                        'share',
                                        lines.join('\n'),
                                      );
                                } on PlatformException {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Ringkasan gagal dibagikan.',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          FilledButton.icon(
                            onPressed: _pesananDiproses == null
                                ? () => _pesanLagi(order['id'] as int, items)
                                : null,
                            icon: const Icon(Icons.replay),
                            label: Text(
                              _pesananDiproses == order['id']
                                  ? 'Memeriksa menu…'
                                  : 'Pesan lagi',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
