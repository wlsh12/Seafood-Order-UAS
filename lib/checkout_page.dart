import 'package:flutter/material.dart';

import 'keranjang_page.dart';
import 'main.dart';
import 'pages/demo_payment.dart';
import 'pages/invoice_page.dart';
import 'pages/riwayat_pesanan_page.dart';
import 'services/app_database.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const List<(IconData, String)> metode = [
    (Icons.qr_code_2, 'QRIS'),
    (Icons.account_balance, 'Transfer Bank'),
    (Icons.account_balance_wallet, 'E-Wallet (OVO / GoPay / DANA)'),
    (Icons.payments_outlined, 'Bayar di Tempat (COD)'),
  ];
  bool _pickup = false;
  int pilihan = 0;
  bool _perluAlatMakan = false;
  bool _alamatSudahDicek = false;
  bool _tampilkanPesanKonfirmasi = false;

  void _dataPengirimanBerubah(String _) {
    if (_alamatSudahDicek) setState(() => _alamatSudahDicek = false);
  }

  bool _sedangMenyimpan = false;
  late DateTime _tanggalPengiriman;

  final _formKey = GlobalKey<FormState>();
  final _konfirmasiKey = GlobalKey();
  final _scrollController = ScrollController();
  final namaCtrl = TextEditingController();
  final hpCtrl = TextEditingController();
  final alamatCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tanggalPengiriman = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    namaCtrl.dispose();
    hpCtrl.dispose();
    alamatCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTanggal(DateTime tanggal) =>
      '${tanggal.day.toString().padLeft(2, '0')}/'
      '${tanggal.month.toString().padLeft(2, '0')}/${tanggal.year}';

  Future<void> _pilihTanggal() async {
    final tanggal = await showDatePicker(
      context: context,
      initialDate: _tanggalPengiriman,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: _pickup
          ? 'Pilih tanggal pengambilan'
          : 'Pilih tanggal pengiriman',
    );
    if (mounted && tanggal != null) {
      setState(() => _tanggalPengiriman = tanggal);
    }
  }

  // Periksa formulir dan konfirmasi sebelum menyimpan pesanan.
  Future<void> _simpanPesanan(int total) async {
    if (_sedangMenyimpan || cart.kosong) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      return;
    }
    if (!_alamatSudahDicek) {
      setState(() => _tampilkanPesanKonfirmasi = true);
      await Scrollable.ensureVisible(
        _konfirmasiKey.currentContext!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 220),
      );
      return;
    }

    final metodePembayaran = metode[pilihan].$2;
    final nama = namaCtrl.text.trim();
    final nomorHp = hpCtrl.text.trim();
    final alamat = _pickup ? '' : alamatCtrl.text.trim();
    final tanggal = _formatTanggal(_tanggalPengiriman);
    final perluAlatMakan = _perluAlatMakan;

    // Kunci checkout sampai proses simpan dan dialog selesai.
    setState(() => _sedangMenyimpan = true);
    try {
      final simulated = await showDemoPayment(context, metodePembayaran, total);
      if (!mounted) return;
      if (simulated != true) {
        setState(() => _sedangMenyimpan = false);
        return;
      }

      await cart.flush();
      final items = cart.items
          .map(
            (item) => <String, Object?>{
              'menu_name': item.menu.nama,
              'price': item.menu.harga,
              'quantity': item.qty,
              'options': item.opsi,
              'note': item.catatan,
            },
          )
          .toList();
      final createdAt = DateTime.now().toIso8601String();
      final orderId = await AppDatabase.instance.saveOrder(
        customerName: nama,
        phone: nomorHp,
        address: alamat,
        paymentMethod: metodePembayaran,
        deliveryDate: tanggal,
        needsCutlery: perluAlatMakan,
        pickup: _pickup,
        total: total,
        items: items,
        createdAt: createdAt,
      );

      // Keranjang dikosongkan setelah pesanan berhasil masuk ke SQLite.
      cart.bersihkanSetelahCheckout();
      if (!mounted) return;
      final tujuan = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => PopScope(
          canPop: false,
          child: AlertDialog(
            scrollable: true,
            icon: Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.primary,
              size: 44,
            ),
            title: const Text('Pesanan berhasil disimpan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pesanan #$orderId tersimpan.'),
                const SizedBox(height: 12),
                Text('Total pesanan: ${rupiah(total)}'),
                Text('Metode pembayaran: $metodePembayaran'),
                Text(
                  'Tanggal ${_pickup ? 'pengambilan' : 'pengiriman'}: $tanggal',
                ),
                Text(
                  'Alat makan: ${perluAlatMakan ? 'disertakan' : 'tidak perlu'}',
                ),
                const SizedBox(height: 12),
                Text(
                  _pickup
                      ? 'Ambil sendiri di restoran'
                      : 'Alamat pengiriman: $alamat',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop('home'),
                child: const Text('Kembali ke beranda'),
              ),
              OutlinedButton(
                onPressed: () => Navigator.of(dialogContext).pop('invoice'),
                child: const Text('Buka invoice PDF'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop('history'),
                child: const Text('Lihat riwayat'),
              ),
            ],
          ),
        ),
      );
      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (tujuan == 'invoice') {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => InvoicePage(
              order: {
                'id': orderId,
                'created_at': createdAt,
                'payment_method': metodePembayaran,
                'pickup': _pickup ? 1 : 0,
                'delivery_date': tanggal,
                'demo_paid': 1,
                'total': total,
              },
              items: items,
            ),
          ),
          (route) => route.isFirst,
        );
      } else if (tujuan == 'history') {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const RiwayatPesananPage()),
          (route) => route.isFirst,
        );
      } else {
        navigator.popUntil((route) => route.isFirst);
      }
    } catch (error) {
      debugPrint('Pesanan gagal disimpan: $error');
      if (!mounted) return;
      setState(() => _sedangMenyimpan = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pesanan gagal disimpan. Coba lagi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ongkir = _pickup ? 0 : kOngkir;
    final total = cart.subtotal + ongkir;
    final keyboardTerbuka = MediaQuery.viewInsetsOf(context).bottom > 0;
    return PopScope(
      canPop: !_sedangMenyimpan,
      child: Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: AbsorbPointer(
          absorbing: _sedangMenyimpan,
          // Semua field tetap terpasang agar validasi bekerja dari bagian bawah.
          child: SingleChildScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KartuSeksi(
                  judul: 'Penerimaan pesanan',
                  ikon: Icons.place_outlined,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Ambil sendiri'),
                          subtitle: Text(
                            _pickup
                                ? 'Tanpa ongkir'
                                : 'Diantar ke alamat penerima',
                          ),
                          value: _pickup,
                          onChanged: (value) => setState(() {
                            _pickup = value;
                            _alamatSudahDicek = false;
                            _tampilkanPesanKonfirmasi = false;
                          }),
                        ),
                        TextFormField(
                          controller: namaCtrl,
                          onChanged: _dataPengirimanBerubah,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nama penerima',
                          ),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Nama wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: hpCtrl,
                          onChanged: _dataPengirimanBerubah,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Nomor HP',
                            hintText: '0812xxxxxxxx',
                          ),
                          validator: (value) {
                            final nomor = (value ?? '').trim();
                            if (nomor.isEmpty) return 'Nomor HP wajib diisi';
                            if (nomor.length < 9) {
                              return 'Nomor HP terlalu pendek';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        if (!_pickup)
                          TextFormField(
                            controller: alamatCtrl,
                            onChanged: _dataPengirimanBerubah,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Alamat lengkap',
                              alignLabelWithHint: true,
                              hintText: 'Jalan, nomor rumah, dan kota',
                            ),
                            validator: (value) =>
                                (value == null || value.trim().length < 10)
                                ? 'Alamat wajib diisi (minimal 10 karakter)'
                                : null,
                          ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          key: _konfirmasiKey,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          tileColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            _pickup ? 'Saya sudah memeriksa nama dan nomor HP' : 'Saya sudah memeriksa nama, nomor HP, dan alamat',
                          ),
                          value: _alamatSudahDicek,
                          onChanged: (value) => setState(() {
                            _alamatSudahDicek = value ?? false;
                            _tampilkanPesanKonfirmasi = false;
                          }),
                        ),
                        if (_tampilkanPesanKonfirmasi)
                          Text(
                            'Periksa kembali data penerima, lalu centang konfirmasi.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                _KartuSeksi(
                  judul: 'Jadwal & perlengkapan',
                  ikon: Icons.event_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pilihTanggal,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            'Tanggal ${_pickup ? 'pengambilan' : 'pengiriman'} · ${_formatTanggal(_tanggalPengiriman)}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Perlu alat makan'),
                        value: _perluAlatMakan,
                        onChanged: (value) =>
                            setState(() => _perluAlatMakan = value),
                      ),
                    ],
                  ),
                ),
                _KartuSeksi(
                  judul: 'Metode pembayaran',
                  ikon: Icons.payments_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih metode untuk pesanan ini.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RadioGroup<int>(
                        groupValue: pilihan,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => pilihan = value);
                          }
                        },
                        child: Column(
                          children: [
                            for (var i = 0; i < metode.length; i++)
                              RadioListTile<int>(
                                contentPadding: EdgeInsets.zero,
                                value: i,
                                title: Text(metode[i].$2),
                                secondary: Icon(
                                  metode[i].$1,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _KartuSeksi(
                  judul: 'Ringkasan pesanan',
                  ikon: Icons.receipt_long_outlined,
                  child: Column(
                    children: [
                      for (final item in cart.items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: BarisHarga(
                            '${item.qty} × ${item.menu.nama}',
                            rupiah(item.total),
                          ),
                        ),
                      const Divider(height: 20),
                      BarisHarga('Subtotal', rupiah(cart.subtotal)),
                      const SizedBox(height: 8),
                      BarisHarga('Ongkos kirim', rupiah(ongkir)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: keyboardTerbuka
            ? null
            : PanelBawah(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BarisHarga('Total pesanan', rupiah(total), tebal: true),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _sedangMenyimpan || cart.kosong
                          ? null
                          : () => _simpanPesanan(total),
                      child: Text(
                        _sedangMenyimpan
                            ? 'Memproses…'
                            : 'Lanjut ke pembayaran',
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _KartuSeksi extends StatelessWidget {
  final String judul;
  final IconData ikon;
  final Widget child;
  const _KartuSeksi({
    required this.judul,
    required this.ikon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final gayaJudul = Theme.of(context).textTheme.titleMedium;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    ikon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      judul,
                      style: gayaJudul?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
