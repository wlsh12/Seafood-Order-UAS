import 'package:flutter/material.dart';
import '../main.dart';
import '../detail_menu_page.dart';
import '../services/app_database.dart';

class FavoritPage extends StatefulWidget {
  final List<Menu> menus;
  const FavoritPage({super.key, required this.menus});

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {
  late Future<Set<String>> _favorit;
  bool _semua = false;
  bool _sibuk = false;

  @override
  void initState() {
    super.initState();
    _favorit = AppDatabase.instance.getFavorites();
  }

  Future<void> _ubah(Menu menu, bool pilih) async {
    if (_sibuk) return;
    setState(() => _sibuk = true);
    try {
      await AppDatabase.instance.setFavorite(menu.id, pilih);
      if (mounted) setState(() { _favorit = AppDatabase.instance.getFavorites(); });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilihan favorit gagal disimpan.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Menu favorit')),
      body: FutureBuilder<Set<String>>(
        future: _favorit,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: TextButton(
              onPressed: () => setState(() { _favorit = AppDatabase.instance.getFavorites(); }),
              child: const Text('Gagal membaca favorit. Coba lagi'),
            ));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final ids = snapshot.data!;
          final menus = widget.menus.where((m) => _semua || ids.contains(m.id));
          return ListView(padding: const EdgeInsets.all(16), children: [
            SwitchListTile(title: const Text('Pilih dari semua menu'),
              value: _semua, onChanged: (v) => setState(() => _semua = v)),
            if (menus.isEmpty)
              const Padding(padding: EdgeInsets.all(16),
                child: Text('Aktifkan pilihan di atas, lalu ketuk hati pada menu favoritmu.')),
            for (final m in menus)
              Card(child: ListTile(
                leading: FotoNetwork(m.foto, width: 46, height: 46),
                title: Text(m.nama),
                subtitle: Text(m.tersedia ? rupiah(m.harga) : 'Stok habis'),
                onTap: m.tersedia ? () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => DetailMenuPage(menu: m))) : null,
                trailing: IconButton(
                  tooltip: ids.contains(m.id) ? 'Hapus dari favorit' : 'Tambah ke favorit',
                  onPressed: _sibuk || m.id.isEmpty ? null : () => _ubah(m, !ids.contains(m.id)),
                  icon: Icon(ids.contains(m.id) ? Icons.favorite : Icons.favorite_border,
                      color: Theme.of(context).colorScheme.primary),
                ),
              )),
          ]);
        },
      ),
    );
  }
}
