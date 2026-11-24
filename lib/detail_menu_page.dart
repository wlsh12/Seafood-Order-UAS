import 'package:flutter/material.dart';

import 'main.dart';

class DetailMenuPage extends StatefulWidget {
  final Menu menu;
  const DetailMenuPage({super.key, required this.menu});

  @override
  State<DetailMenuPage> createState() => _DetailMenuPageState();
}

class _DetailMenuPageState extends State<DetailMenuPage> {
  int qty = 1;
  bool _menambah = false;
  final TextEditingController catatanCtrl = TextEditingController();

  late final Map<String, List<String>> opsi;
  late final Map<String, int> terpilih;

  @override
  void initState() {
    super.initState();
    if (widget.menu.kategori == 'Minuman') {
      opsi = {
        'Level Gula': ['Less Sugar', 'Normal', 'Extra Sugar'],
        'Es Batu': ['Tanpa Es', 'Normal', 'Banyak Es'],
      };
    } else {
      opsi = {
        'Tingkat Kepedasan': ['Tidak Pedas', 'Sedang', 'Pedas', 'Extra Pedas'],
        'Pilihan Nasi': ['Tanpa Nasi', 'Nasi Putih', 'Nasi Uduk'],
      };
    }
    terpilih = {for (final k in opsi.keys) k: 1};
  }

  @override
  void dispose() {
    catatanCtrl.dispose();
    super.dispose();
  }

  String get ringkasanOpsi =>
      opsi.entries.map((e) => e.value[terpilih[e.key]!]).join(', ');

  Future<void> _tambahKeKeranjang() async {
    if (_menambah) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _menambah = true);
    cart.tambah(widget.menu, ringkasanOpsi, catatanCtrl.text.trim(), qty);
    await cart.flush();
    if (!mounted) return;
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(content: Text('${widget.menu.nama} ditambahkan ke keranjang')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menu = widget.menu;
    final teks = Theme.of(context).textTheme;
    final keyboardTerbuka = MediaQuery.viewInsetsOf(context).bottom > 0;

    return PopScope(
      canPop: !_menambah,
      child: Scaffold(
        appBar: AppBar(title: const Text('Detail menu')),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          children: [
            FotoNetwork(
              menu.foto,
              width: double.infinity,
              height: 230,
              radius: BorderRadius.circular(16),
            ),
            const SizedBox(height: 16),
            Text(
              menu.nama,
              style: teks.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '${rupiah(menu.harga)} / porsi',
              style: teks.titleMedium?.copyWith(
                color: kPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (menu.deskripsi.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                menu.deskripsi,
                style: const TextStyle(color: kMuted, height: 1.45),
              ),
            ],
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final pilihan in opsi.entries) ...[
                      Text(pilihan.key, style: teks.titleMedium),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          for (var i = 0; i < pilihan.value.length; i++)
                            ChoiceChip(
                              label: Text(pilihan.value[i]),
                              selected: terpilih[pilihan.key] == i,
                              onSelected: _menambah
                                  ? null
                                  : (_) => setState(
                                      () => terpilih[pilihan.key] = i,
                                    ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: catatanCtrl,
                      maxLines: 3,
                      enabled: !_menambah,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        alignLabelWithHint: true,
                        hintText: 'Contoh: sambal dipisah',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: keyboardTerbuka
            ? null
            : PanelBawah(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: Text('Jumlah porsi')),
                        const SizedBox(width: 12),
                        PengaturJumlah(
                          jumlah: qty,
                          onKurang: qty > 1 && !_menambah
                              ? () => setState(() => qty--)
                              : null,
                          onTambah: _menambah
                              ? null
                              : () => setState(() => qty++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _menambah ? null : _tambahKeKeranjang,
                      child: Text(
                        _menambah
                            ? 'Menambahkan…'
                            : 'Tambah · ${rupiah(menu.harga * qty)}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
