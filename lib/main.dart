import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'menu_restoran_page.dart';
import 'services/app_database.dart';

const Color kPrimary = Color(0xFF075985);
const Color kAccent = Color(0xFFE0F2FE);
const Color kBg = Color(0xFFF4F9FD);
const Color kText = Color(0xFF102A43);
const Color kMuted = Color(0xFF4C6478);
const Color kBorder = Color(0xFFD4E2ED);
const int kOngkir = 10000;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await cart.load();
  runApp(const SeafoodApp());
}

class SeafoodApp extends StatelessWidget {
  const SeafoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(seedColor: kPrimary).copyWith(
      primary: kPrimary,
      primaryContainer: kAccent,
      onPrimaryContainer: kText,
      surface: Colors.white,
      onSurface: kText,
      onSurfaceVariant: kMuted,
      outlineVariant: kBorder,
    );
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kBorder),
    );
    return MaterialApp(
      title: 'Seafood Order',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colors,
        scaffoldBackgroundColor: kBg,
        dividerColor: kBorder,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: kText,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: kText,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          margin: EdgeInsets.zero,
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: kBorder),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationThemeData(
          filled: true,
          fillColor: Colors.white,
          border: inputBorder,
          enabledBorder: inputBorder,
          focusedBorder: inputBorder.copyWith(
            borderSide: const BorderSide(color: kPrimary, width: 2),
          ),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: kAccent,
          side: BorderSide(color: kBorder),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class Menu {
  final String nama, kategori, deskripsi, foto;
  final int harga;
  final String id;
  final bool tersedia;
  const Menu(
    this.nama,
    this.kategori,
    this.harga,
    this.deskripsi,
    this.foto, {
    this.id = '',
    this.tersedia = true,
  });

  factory Menu.fromMap(Map<String, dynamic> m) {
    final rawPrice = m['price'];
    final price = rawPrice is num
        ? rawPrice.toInt()
        : int.tryParse('$rawPrice') ?? 0;
    final rawAvailable = m['available'] ?? m['status'] ?? true;
    final availableText = rawAvailable.toString().toLowerCase();
    return Menu(
      (m['name'] ?? m['nama'] ?? 'Menu').toString(),
      (m['category'] ?? m['kategori'] ?? 'Lainnya').toString(),
      price,
      (m['description'] ?? m['deskripsi'] ?? '').toString(),
      (m['image'] ?? m['imageUrl'] ?? m['foto'] ?? '').toString(),
      id: (m['id'] ?? '').toString(),
      tersedia:
          rawAvailable == true ||
          rawAvailable == 1 ||
          availableText == 'true' ||
          availableText == 'tersedia',
    );
  }
}

class Kategori {
  final String nama, foto;
  final IconData ikon;
  const Kategori(this.nama, this.ikon, this.foto);

  factory Kategori.fromMenu(String name, String image) {
    const ikonMap = {
      'Udang': Icons.set_meal,
      'Kepiting': Icons.pest_control,
      'Ikan': Icons.phishing,
      'Minuman': Icons.local_drink,
    };
    return Kategori(name, ikonMap[name] ?? Icons.restaurant, image);
  }
}

class CartItem {
  final Menu menu;
  final String opsi;
  final String catatan;
  int qty;
  CartItem(this.menu, this.opsi, this.catatan, this.qty);
  int get total => menu.harga * qty;

  Map<String, Object?> toDatabaseMap() => {
    'menu_name': menu.nama,
    'category': menu.kategori,
    'price': menu.harga,
    'description': menu.deskripsi,
    'image_url': menu.foto,
    'options': opsi,
    'note': catatan,
    'quantity': qty,
  };

  factory CartItem.fromDatabaseMap(Map<String, Object?> row) {
    final menu = Menu(
      row['menu_name'] as String,
      row['category'] as String,
      row['price'] as int,
      row['description'] as String,
      row['image_url'] as String,
    );
    return CartItem(
      menu,
      row['options'] as String,
      row['note'] as String,
      row['quantity'] as int,
    );
  }
}

class Cart extends ChangeNotifier {
  final List<CartItem> items = [];
  Future<void> _saveQueue = Future<void>.value();

  Future<void> load() async {
    final savedItems = await AppDatabase.instance.getCartItems();
    items
      ..clear()
      ..addAll(savedItems.map(CartItem.fromDatabaseMap));
    notifyListeners();
  }

  void _save() {
    final snapshot = items.map((item) => item.toDatabaseMap()).toList();
    _saveQueue = _saveSnapshot(_saveQueue, snapshot);
  }

  Future<void> _saveSnapshot(
    Future<void> previous,
    List<Map<String, Object?>> snapshot,
  ) async {
    try {
      await previous;
    } catch (_) {
      // Continue with the newest snapshot even if an earlier save failed.
    }
    try {
      await AppDatabase.instance.replaceCartItems(snapshot);
    } catch (error) {
      debugPrint('Gagal menyimpan keranjang: $error');
    }
  }

  Future<void> flush() => _saveQueue;

  void bersihkanSetelahCheckout() {
    items.clear();
    notifyListeners();

  }

  int get jumlah => items.fold(0, (t, e) => t + e.qty);
  int get subtotal => items.fold(0, (t, e) => t + e.total);
  bool get kosong => items.isEmpty;

  void tambah(Menu m, String opsi, String catatan, int qty) {
    for (final it in items) {
      if (it.menu.nama == m.nama && it.opsi == opsi && it.catatan == catatan) {
        it.qty += qty;
        _save();
        notifyListeners();
        return;
      }
    }
    items.add(CartItem(m, opsi, catatan, qty));
    _save();
    notifyListeners();
  }

  void tambahQty(CartItem it) {
    it.qty++;
    _save();
    notifyListeners();
  }

  void kurangQty(CartItem it) {
    if (it.qty > 1) {
      it.qty--;
    } else {
      items.remove(it);
    }
    _save();
    notifyListeners();
  }

  void hapus(CartItem it) {
    items.remove(it);
    _save();
    notifyListeners();
  }
}

final Cart cart = Cart();

String rupiah(int angka) {
  final s = angka.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp ${buf.toString()}';
}

class FotoNetwork extends StatelessWidget {
  final String url;
  final double? width, height;
  final BorderRadius radius;
  final IconData ikon;
  const FotoNetwork(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.radius = BorderRadius.zero,
    this.ikon = Icons.set_meal,
  });

  @override
  Widget build(BuildContext context) {
    final pengganti = Container(
      width: width,
      height: height,
      color: kAccent,
      alignment: Alignment.center,
      child: Icon(
        ikon,
        color: kPrimary,
        size: 28,
        semanticLabel: 'Foto tidak tersedia',
      ),
    );
    return ClipRRect(
      borderRadius: radius,
      child: url.trim().isEmpty
          ? pengganti
          : ColoredBox(
              color: kAccent,
              child: Image.network(
                url,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => pengganti,
              ),
            ),
    );
  }
}

class PanelBawah extends StatelessWidget {
  final Widget child;
  const PanelBawah({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: child,
      ),
    );
  }
}

class TampilanStatus extends StatelessWidget {
  final IconData? ikon;
  final String judul;
  final String? pesan;
  final Widget? tindakan;
  const TampilanStatus({
    super.key,
    this.ikon,
    required this.judul,
    this.pesan,
    this.tindakan,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ikon == null)
              const CircularProgressIndicator()
            else
              CircleAvatar(
                radius: 28,
                backgroundColor: kAccent,
                foregroundColor: kPrimary,
                child: Icon(ikon),
              ),
            const SizedBox(height: 16),
            Text(
              judul,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (pesan != null) ...[
              const SizedBox(height: 6),
              Text(
                pesan!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: kMuted),
              ),
            ],
            if (tindakan != null) ...[const SizedBox(height: 16), tindakan!],
          ],
        ),
      ),
    );
  }
}

class PengaturJumlah extends StatelessWidget {
  final int jumlah;
  final VoidCallback? onKurang;
  final VoidCallback? onTambah;
  final String labelKurang;

  const PengaturJumlah({
    super.key,
    required this.jumlah,
    required this.onKurang,
    required this.onTambah,
    this.labelKurang = 'Kurangi jumlah',
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: labelKurang,
            onPressed: onKurang,
            icon: const Icon(Icons.remove, size: 20),
          ),
          Text(
            '$jumlah',
            semanticsLabel: '$jumlah porsi',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          IconButton(
            tooltip: 'Tambah jumlah',
            onPressed: onTambah,
            icon: const Icon(Icons.add, size: 20),
          ),
        ],
      ),
    );
  }
}
