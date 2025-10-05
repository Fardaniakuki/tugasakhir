import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DashboardService {
  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  Uri _buildUri(String endpoint, [Map<String, String>? query]) {
    final base = Uri.parse(_baseUrl);
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: endpoint,
      queryParameters: query,
    );
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<Map<String, dynamic>?> fetchDashboardData() async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/api/admin/dashboard'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded['data'] ?? {};
      } else {
        throw Exception('Failed to fetch dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch dashboard data: $e');
    }
  }

  Future<List<Map<String, String>>> fetchKelas() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$_baseUrl/api/kelas'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List data = decoded['data'] ?? [];
        return data
            .map<Map<String, String>>((k) => {
                  'id': (k['id'] ?? '').toString(),
                  'name': (k['nama'] ?? '').toString(),
                })
            .where((m) => m['name']!.isNotEmpty)
            .toList();
      } else {
        throw Exception('Failed to fetch kelas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch kelas: $e');
    }
  }

  Future<List<Map<String, String>>> fetchJurusan() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$_baseUrl/api/jurusan'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List data = decoded['data'] ?? [];
        return data
            .map<Map<String, String>>((j) => {
                  'id': (j['id'] ?? '').toString(),
                  'name': (j['nama'] ?? '').toString(),
                })
            .where((m) => m['name']!.isNotEmpty)
            .toList();
      } else {
        throw Exception('Failed to fetch jurusan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch jurusan: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSiswaData({
    String kelasId = '',
    String jurusanId = '',
    String searchQuery = '',
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final Map<String, String> queryParams = {
        'page': '1',
        'limit': '100',
      };

      if (kelasId.isNotEmpty) queryParams['kelas_id'] = kelasId;
      if (jurusanId.isNotEmpty) queryParams['jurusan_id'] = jurusanId;
      if (searchQuery.isNotEmpty) queryParams['search'] = searchQuery;

      final uri = _buildUri('/api/siswa', queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List data = decoded['data']['data'] ?? [];
        return data.map<Map<String, dynamic>>((m) {
          final String nama = (m['nama_lengkap'] ?? m['nama'] ?? m['name'] ?? '').toString();
          final String kelasName = (m['kelas_name'] ?? m['kelas'] ?? '').toString();
          final String jurusanName = (m['jurusan_name'] ?? m['jurusan'] ?? '').toString();
          return {
            'name': nama,
            'role': 'Murid',
            'kelas': kelasName,
            'jurusan': jurusanName,
            'id': (m['id'] ?? '').toString(),
            'type': 'siswa',
          };
        }).toList();
      } else {
        throw Exception('Failed to fetch siswa data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch siswa data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchGuruData({String searchQuery = ''}) async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final Map<String, String> queryParams = {
        'page': '1',
        'limit': '100',
      };

      if (searchQuery.isNotEmpty) queryParams['search'] = searchQuery;

      final uri = _buildUri('/api/guru', queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List data = decoded['data']['data'] ?? [];
        return data.map<Map<String, dynamic>>((g) {
          final String nama = (g['nama_lengkap'] ?? g['nama'] ?? g['name'] ?? '').toString();
          return {
            'name': nama,
            'role': 'Guru',
            'id': (g['id'] ?? '').toString(),
            'type': 'guru',
          };
        }).toList();
      } else {
        throw Exception('Failed to fetch guru data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch guru data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchJurusanData({String searchQuery = ''}) async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final Map<String, String> queryParams = {
        'page': '1',
        'limit': '100',
      };

      if (searchQuery.isNotEmpty) queryParams['search'] = searchQuery;

      final uri = _buildUri('/api/jurusan', queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List data = decoded['data']['data'] ?? [];
        return data.map<Map<String, dynamic>>((j) {
          final String nama = (j['nama'] ?? j['name'] ?? '').toString();
          return {
            'name': nama,
            'role': 'Jurusan',
            'id': (j['id'] ?? '').toString(),
            'type': 'jurusan',
          };
        }).toList();
      } else {
        throw Exception('Failed to fetch jurusan data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch jurusan data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchIndustriData({String searchQuery = ''}) async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final Map<String, String> queryParams = {
        'page': '1',
        'limit': '100',
      };

      if (searchQuery.isNotEmpty) queryParams['search'] = searchQuery;

      final uri = _buildUri('/api/industri', queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List data = decoded['data']['data'] ?? [];
        return data.map<Map<String, dynamic>>((i) {
          final String nama = (i['nama'] ?? i['name'] ?? '').toString();
          return {
            'name': nama,
            'role': 'Industri',
            'id': (i['id'] ?? '').toString(),
            'type': 'industri',
          };
        }).toList();
      } else {
        throw Exception('Failed to fetch industri data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch industri data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchKelasData({String searchQuery = ''}) async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final Map<String, String> queryParams = {
        'page': '1',
        'limit': '100',
      };

      if (searchQuery.isNotEmpty) queryParams['search'] = searchQuery;

      final uri = _buildUri('/api/kelas', queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List data = decoded['data']['data'] ?? [];
        return data.map<Map<String, dynamic>>((k) {
          final String nama = (k['nama'] ?? k['name'] ?? '').toString();
          return {
            'name': nama,
            'role': 'Kelas',
            'id': (k['id'] ?? '').toString(),
            'type': 'kelas',
          };
        }).toList();
      } else {
        throw Exception('Failed to fetch kelas data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch kelas data: $e');
    }
  }

  Future<Map<String, dynamic>?> fetchKelasById(String kelasId) async {
    try {
      final token = await _getToken();
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/api/kelas/$kelasId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded['data'];
      } else {
        throw Exception('Failed to fetch kelas by id: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch kelas by id: $e');
    }
  }
}
