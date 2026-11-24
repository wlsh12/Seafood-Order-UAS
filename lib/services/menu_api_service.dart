import 'dart:convert';

import 'package:http/http.dart' as http;

// URL resource menus dari screenshot MockAPI. Dapat diganti lewat dart-define.
const String _menuApiUrl = String.fromEnvironment(
  'MENU_API_URL',
  defaultValue: 'https://6afd25642a9c141d36b83a44.mockapi.io/api/v1/menus',
);
const String _menuApiKey = String.fromEnvironment('MENU_API_KEY');

class MenuApiService {
  final http.Client _client;
  MenuApiService({http.Client? client}) : _client = client ?? http.Client();

  void close() => _client.close();

  Future<List<Map<String, dynamic>>> fetchMenus() async {
    if (_menuApiUrl.trim().isEmpty) {
      throw StateError(
        'URL API belum diatur. Jalankan dengan --dart-define=MENU_API_URL=https://.../menus.',
      );
    }

    final uri = Uri.tryParse(_menuApiUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw const FormatException('MENU_API_URL bukan URL yang valid.');
    }

    final headers = <String, String>{'Accept': 'application/json'};
    if (_menuApiKey.isNotEmpty) headers['x-api-key'] = _menuApiKey;

    final response = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API membalas HTTP ${response.statusCode}.');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final List<dynamic> rows;
    if (decoded is List) {
      rows = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['data'] is List) {
      rows = decoded['data'] as List<dynamic>;
    } else {
      throw const FormatException(
        'Format respons API tidak sesuai. API harus mengembalikan array menu JSON.',
      );
    }

    final menus = rows.whereType<Map<String, dynamic>>().toList(growable: false);
    if (menus.length != rows.length) {
      throw const FormatException('Ada data menu yang formatnya tidak valid.');
    }
    return menus;
  }
}
