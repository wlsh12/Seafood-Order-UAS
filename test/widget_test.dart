import 'package:flutter_test/flutter_test.dart';
import 'package:uts/main.dart';

void main() {
  test('Menu dibaca dari field JSON MockAPI', () {
    final menu = Menu.fromMap({
      'id': '1',
      'name': 'Udang Saus Padang',
      'category': 'Udang',
      'price': 65000,
      'description': 'Udang dengan saus Padang.',
      'image': 'https://example.com/udang.jpg',
      'available': true,
    });

    expect(menu.nama, 'Udang Saus Padang');
    expect(menu.kategori, 'Udang');
    expect(menu.harga, 65000);
    expect(menu.foto, 'https://example.com/udang.jpg');
    expect(menu.tersedia, isTrue);
  });

  test('Status tidak tersedia dibaca sebagai stok habis', () {
    final menu = Menu.fromMap({'name': 'Ikan', 'price': '50000', 'available': false});
    expect(menu.harga, 50000);
    expect(menu.tersedia, isFalse);
  });
}
