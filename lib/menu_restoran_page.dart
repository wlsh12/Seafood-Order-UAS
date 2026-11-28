import 'package:flutter/material.dart';

import 'detail_menu_page.dart';
import 'keranjang_page.dart';
import 'main.dart';
import 'pages/riwayat_pesanan_page.dart';
import 'pages/favorit_page.dart';
import 'services/menu_api_service.dart';

class TombolKeranjang extends StatelessWidget {
  const TombolKeranjang({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => IconButton(
        tooltip: 'Keranjang',
        icon: Badge(
          isLabelVisible: cart.jumlah > 0,
          label: Text('${cart.jumlah}'),
          child: const Icon(Icons.shopping_cart_outlined),
        ),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KeranjangPage()),
        ),
      ),
    );
  }
}

class BarKeranjang extends StatelessWidget {
  const BarKeranjang({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        if (cart.kosong) return const SizedBox.shrink();
        return PanelBawah(
          child: FilledButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KeranjangPage()),
            ),
            icon: const Icon(Icons.shopping_cart_outlined),
            label: Text(
              'Keranjang (${cart.jumlah}) · ${rupiah(cart.subtotal)}',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback onGantiTema;
  final VoidCallback onKeluar;
  const HomePage({
    super.key,
    required this.onGantiTema,
    required this.onKeluar,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MenuApiService _api = MenuApiService();
  late Future<List<Menu>> _menusFuture;
  String? _kategoriTerpilih;

  @override
  void initState() {
    super.initState();
    _menusFuture = _loadMenus();
  }

  @override
  void dispose() {
    _api.close();
    super.dispose();
  }

  // Ambil data API, lalu ubah setiap record menjadi Menu.
  Future<List<Menu>> _loadMenus() async {
    final records = await _api.fetchMenus();
    return records
        .map<Menu>((Map<String, dynamic> record) => Menu.fromMap(record))
        .toList(growable: false);
  }

  // Muat ulang katalog dan reset filter kategori.
  void _refresh() {
    final menusFuture = _loadMenus();
    setState(() {
      _menusFuture = menusFuture;
      _kategoriTerpilih = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final teks = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Seafood Order'),
        ),
        actions: [
          IconButton(
            tooltip: Theme.of(context).brightness == Brightness.dark
                ? 'Pakai mode terang'
                : 'Pakai mode gelap',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: widget.onGantiTema,
          ),
          IconButton(
            tooltip: 'Muat ulang menu dari API',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Riwayat pesanan',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RiwayatPesananPage()),
            ),
          ),
          const TombolKeranjang(),
          PopupMenuButton<String>(
            tooltip: 'Akun',
            onSelected: (_) => widget.onKeluar(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'keluar', child: Text('Keluar akun')),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Menu>>(
        future: _menusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const TampilanStatus(judul: 'Memuat menu…');
          }
          final menus = snapshot.data ?? const <Menu>[];
          if (snapshot.hasError || menus.isEmpty) {
            return TampilanStatus(
              ikon: snapshot.hasError
                  ? Icons.cloud_off_outlined
                  : Icons.set_meal_outlined,
              judul: snapshot.hasError ? 'Menu gagal dimuat' : 'Belum ada menu',
              pesan: snapshot.hasError
                  ? 'Periksa koneksi internet, lalu coba lagi.'
                  : 'Katalog sedang kosong. Muat ulang untuk memeriksa kembali.',
              tindakan: FilledButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            );
          }

          final categories = <String>{
            for (final menu in menus) menu.kategori,
          }.toList()..sort();
          final categoriesToShow = _kategoriTerpilih == null
              ? categories
              : categories.where((name) => name == _kategoriTerpilih).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Foto dan nama pada banner berasal dari menu yang sama di API.
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    Positioned.fill(child: FotoNetwork(menus.first.foto)),
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xE6000000)],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 88, 18, 16),
                      child: Text(
                        menus.first.nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: teks.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.favorite_border),
                label: const Text('Menu favorit'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => FavoritPage(menus: menus)),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Kategori menu',
                style: teks.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              // Dropdown berfungsi sebagai Spinner kategori dalam alur pemesanan.
              DropdownButtonFormField<int>(
                initialValue: _kategoriTerpilih == null
                    ? -1
                    : categories.indexOf(_kategoriTerpilih!),
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Filter kategori',
                  prefixIcon: Icon(
                    Icons.filter_list,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: -1,
                    child: Text('Semua kategori'),
                  ),
                  for (var i = 0; i < categories.length; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        categories[i],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(
                      () => _kategoriTerpilih = value < 0
                          ? null
                          : categories[value],
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final textScaler = MediaQuery.textScalerOf(context);
                  final satuKolom =
                      categoriesToShow.length == 1 ||
                      constraints.maxWidth < 270 ||
                      textScaler.scale(16) > 22;
                  return GridView.builder(
                    itemCount: categoriesToShow.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: satuKolom ? 1 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent:
                          (satuKolom ? 136 : 100) + textScaler.scale(70),
                    ),
                    itemBuilder: (context, index) {
                      final name = categoriesToShow[index];
                      final categoryMenus = menus
                          .where((menu) => menu.kategori == name)
                          .toList();
                      final category = Kategori.fromMenu(
                        name,
                        categoryMenus.first.foto,
                      );
                      return _KategoriCard(
                        kategori: category,
                        jumlahMenu: categoryMenus.length,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MenuKategoriPage(
                              kategori: category,
                              menus: categoryMenus,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const BarKeranjang(),
    );
  }
}

class _KategoriCard extends StatelessWidget {
  final Kategori kategori;
  final int jumlahMenu;
  final VoidCallback onTap;
  const _KategoriCard({
    required this.kategori,
    required this.jumlahMenu,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: FotoNetwork(
                kategori.foto,
                width: double.infinity,
                ikon: kategori.ikon,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kategori.nama,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '$jumlahMenu menu',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuKategoriPage extends StatelessWidget {
  final Kategori kategori;
  final List<Menu> menus;
  const MenuKategoriPage({
    super.key,
    required this.kategori,
    required this.menus,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(kategori.nama),
        actions: const [TombolKeranjang()],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: menus.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _MenuTile(menus[index]),
      ),
      bottomNavigationBar: const BarKeranjang(),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final Menu menu;
  const _MenuTile(this.menu);

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: menu.tersedia
            ? () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailMenuPage(menu: menu)),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FotoNetwork(
                menu.foto,
                width: 88,
                height: 88,
                radius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      menu.nama,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (menu.deskripsi.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        menu.deskripsi,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      rupiah(menu.harga),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      menu.tersedia ? 'Tersedia' : 'Stok habis',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (menu.tersedia)
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
