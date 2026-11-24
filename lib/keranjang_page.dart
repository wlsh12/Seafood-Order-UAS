import 'package:flutter/material.dart';

import 'checkout_page.dart';
import 'main.dart';

class KeranjangPage extends StatelessWidget {
  const KeranjangPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Keranjang Pesanan')),
          body: cart.kosong
              ? TampilanStatus(
                  ikon: Icons.shopping_cart_outlined,
                  judul: 'Keranjang masih kosong',
                  pesan: 'Pilih menu seafood untuk mulai memesan.',
                  tindakan: FilledButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst),
                    child: const Text('Lihat menu'),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final item in cart.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _KartuItem(item),
                      ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ringkasan biaya',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            BarisHarga('Subtotal', rupiah(cart.subtotal)),
                            const SizedBox(height: 8),
                            BarisHarga('Ongkir jika diantar', rupiah(kOngkir)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: cart.kosong
              ? null
              : PanelBawah(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      BarisHarga(
                        'Total jika diantar',
                        rupiah(cart.subtotal + kOngkir),
                        tebal: true,
                      ),
                      const SizedBox(height: 10),
                      FilledButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckoutPage(),
                          ),
                        ),
                        child: const Text('Checkout'),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _KartuItem extends StatelessWidget {
  final CartItem item;
  const _KartuItem(this.item);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FotoNetwork(
                  item.menu.foto,
                  width: 72,
                  height: 72,
                  radius: BorderRadius.circular(36),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.menu.nama,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.opsi,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                      if (item.catatan.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Catatan: ${item.catatan}',
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus ${item.menu.nama}',
                  onPressed: () => cart.hapus(item),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                PengaturJumlah(
                  jumlah: item.qty,
                  labelKurang: item.qty == 1
                      ? 'Kurangi dan hapus item'
                      : 'Kurangi jumlah',
                  onKurang: () => cart.kurangQty(item),
                  onTambah: () => cart.tambahQty(item),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rupiah(item.total),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BarisHarga extends StatelessWidget {
  final String label, nilai;
  final bool tebal;
  const BarisHarga(this.label, this.nilai, {super.key, this.tebal = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: tebal ? FontWeight.w700 : FontWeight.normal,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: Text(label, style: style)),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            nilai,
            textAlign: TextAlign.end,
            style: style.copyWith(color: tebal ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
