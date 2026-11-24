import 'package:flutter/material.dart';

import '../keranjang_page.dart';
import '../main.dart';
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
                        Text(dateText, style: const TextStyle(color: kMuted)),
                        const SizedBox(height: 4),
                        Text(
                          rupiah(order['total'] as int),
                          style: const TextStyle(
                            color: kPrimary,
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
                          Text('Alamat: ${order['address']}'),
                          const SizedBox(height: 6),
                          Text('Metode pembayaran: ${order['payment_method']}'),
                          const SizedBox(height: 6),
                          Text(
                            'Tanggal pengiriman: ${tanggalKirim.isEmpty ? 'Belum tercatat' : tanggalKirim}',
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
                                    if ((item[field] as String? ?? '').trim().isNotEmpty)
                                      Text(
                                        "${field == 'options' ? 'Pilihan' : 'Catatan'}: ${item[field]}",
                                        style: const TextStyle(color: kMuted),
                                      ),
                                ],
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
