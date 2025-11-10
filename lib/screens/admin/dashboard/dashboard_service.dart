import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class DashboardService {
  String get _baseUrl => dotenv.env['API_BASE_URL'] ?? '';

  // Cache untuk menghindari request berulang
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheDuration = const Duration(minutes: 10);

  // Cache untuk bulk counts
  Map<String, int>? _studentCountsCache;
  Map<String, int>? _classCountsCache;
  DateTime? _bulkCacheTimestamp;
  final Duration _bulkCacheDuration = const Duration(minutes: 15);

  void setCacheData(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
    if (kDebugMode) {
      print('🔄 Cache updated: $key');
    }
  }

  dynamic getCachedData(String key) {
    final cachedData = _cache[key];
    final cachedTimestamp = _cacheTimestamps[key];
    
    if (cachedData != null && cachedTimestamp != null) {
      final now = DateTime.now();
      if (now.difference(cachedTimestamp) < _cacheDuration) {
        if (kDebugMode) {
          print('✅ Cache HIT: $key');
        }
        return cachedData;
      } else {
        _cache.remove(key);
        _cacheTimestamps.remove(key);
        if (kDebugMode) {
          print('❌ Cache EXPIRED: $key');
        }
      }
    }
    return null;
  }

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

  Future<dynamic> _fetchWithCache(String cacheKey, Future<dynamic> Function() fetchFunction, {bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedData = getCachedData(cacheKey);
      if (cachedData != null) {
        return cachedData;
      }
    }

    final data = await fetchFunction();
    setCacheData(cacheKey, data);
    return data;
  }

  // METHOD BARU: Pie Chart - Distribusi Murid per Jurusan
  Future<Map<String, int>> getStudentDistributionByMajor({bool forceRefresh = false}) async {
    return await _fetchWithCache('student_major_distribution', () async {
      try {
        final siswaData = await fetchSiswaData(forceRefresh: forceRefresh);
        final kelasData = await fetchKelasData(forceRefresh: forceRefresh);
        
        final Map<String, int> distribution = {};
        
        for (var siswa in siswaData) {
          final kelasId = siswa['original_kelas_id'];
          if (kelasId != null && kelasId.isNotEmpty) {
            // Cari jurusan dari kelas
            final kelas = kelasData.firstWhere(
              (k) => k['id'] == kelasId,
              orElse: () => {},
            );
            
            final jurusanNama = kelas['jurusan_nama'] ?? 'Tidak Diketahui';
            distribution[jurusanNama] = (distribution[jurusanNama] ?? 0) + 1;
          } else {
            // Jika tidak ada kelas, masukkan ke "Tidak Diketahui"
            distribution['Tidak Diketahui'] = (distribution['Tidak Diketahui'] ?? 0) + 1;
          }
        }
        
        return distribution;
      } catch (e) {
        debugPrint('Error getting student distribution by major: $e');
        return {};
      }
    }, forceRefresh: forceRefresh);
  }

  // METHOD BARU: Distribusi Murid per Kelas
  Future<Map<String, int>> getStudentDistributionByClass({bool forceRefresh = false}) async {
    return await _fetchWithCache('student_class_distribution', () async {
      try {
        final siswaData = await fetchSiswaData(forceRefresh: forceRefresh);
        final kelasData = await fetchKelasData(forceRefresh: forceRefresh);
        
        final Map<String, int> distribution = {};
        
        for (var siswa in siswaData) {
          final kelasId = siswa['original_kelas_id'];
          if (kelasId != null && kelasId.isNotEmpty) {
            // Cari nama kelas
            final kelas = kelasData.firstWhere(
              (k) => k['id'] == kelasId,
              orElse: () => {'name': 'Kelas $kelasId'},
            );
            
            final kelasNama = kelas['name'] ?? 'Kelas $kelasId';
            distribution[kelasNama] = (distribution[kelasNama] ?? 0) + 1;
          } else {
            distribution['Tidak Diketahui'] = (distribution['Tidak Diketahui'] ?? 0) + 1;
          }
        }
        
        return distribution;
      } catch (e) {
        debugPrint('Error getting student distribution by class: $e');
        return {};
      }
    }, forceRefresh: forceRefresh);
  }

  // METHOD BARU: Distribusi Kelas per Jurusan
  Future<Map<String, int>> getClassDistributionByMajor({bool forceRefresh = false}) async {
    return await _fetchWithCache('class_major_distribution', () async {
      try {
        final kelasData = await fetchKelasData(forceRefresh: forceRefresh);
        
        final Map<String, int> distribution = {};
        
        for (var kelas in kelasData) {
          final jurusanNama = kelas['jurusan_nama'] ?? 'Tidak Diketahui';
          distribution[jurusanNama] = (distribution[jurusanNama] ?? 0) + 1;
        }
        
        return distribution;
      } catch (e) {
        debugPrint('Error getting class distribution by major: $e');
        return {};
      }
    }, forceRefresh: forceRefresh);
  }

  // METHOD BARU: Hitung jumlah murid untuk semua kelas sekaligus
  Future<Map<String, int>> _getAllStudentCounts({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    if (!forceRefresh && 
        _studentCountsCache != null && 
        _bulkCacheTimestamp != null && 
        now.difference(_bulkCacheTimestamp!) < _bulkCacheDuration) {
      return _studentCountsCache!;
    }

    try {
      final token = await _getToken();
      if (token == null) return {};

      final response = await http.get(
        _buildUri('/api/siswa', {'limit': '1000'}),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List data = [];
        
        if (decoded['data'] != null && decoded['data']['data'] is List) {
          data = decoded['data']['data'];
        } else if (decoded['data'] is List) {
          data = decoded['data'];
        }

        final Map<String, int> counts = {};
        for (var student in data) {
          final kelasId = (student['kelas_id'] ?? '').toString();
          if (kelasId.isNotEmpty) {
            counts[kelasId] = (counts[kelasId] ?? 0) + 1;
          }
        }
        
        _studentCountsCache = counts;
        _bulkCacheTimestamp = now;
        return counts;
      }
      return {};
    } catch (e) {
      debugPrint('Error counting all students: $e');
      return {};
    }
  }

  // METHOD BARU: Hitung jumlah kelas untuk semua jurusan sekaligus
  Future<Map<String, int>> _getAllClassCounts({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    if (!forceRefresh && 
        _classCountsCache != null && 
        _bulkCacheTimestamp != null && 
        now.difference(_bulkCacheTimestamp!) < _bulkCacheDuration) {
      return _classCountsCache!;
    }

    try {
      final token = await _getToken();
      if (token == null) return {};

      final response = await http.get(
        _buildUri('/api/kelas', {'limit': '1000'}),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List data = [];
        
        if (decoded['data'] != null && decoded['data']['data'] is List) {
          data = decoded['data']['data'];
        } else if (decoded['data'] is List) {
          data = decoded['data'];
        }

        final Map<String, int> counts = {};
        for (var kelas in data) {
          final jurusanId = (kelas['jurusan_id'] ?? '').toString();
          if (jurusanId.isNotEmpty) {
            counts[jurusanId] = (counts[jurusanId] ?? 0) + 1;
          }
        }
        
        _classCountsCache = counts;
        _bulkCacheTimestamp = now;
        return counts;
      }
      return {};
    } catch (e) {
      debugPrint('Error counting all classes: $e');
      return {};
    }
  }

  // DASHBOARD DATA
  Future<Map<String, dynamic>?> fetchDashboardData({bool forceRefresh = false}) async {
    return await _fetchWithCache('dashboard', () async {
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
    }, forceRefresh: forceRefresh);
  }

  // KELAS OPTIONS
  Future<List<Map<String, String>>> fetchKelas({bool forceRefresh = false}) async {
    return await _fetchWithCache('kelas', () async {
      try {
        final token = await _getToken();
        if (token == null) return [];

        final response = await http.get(
          Uri.parse('$_baseUrl/api/kelas?page=1&limit=100'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          
          List data = [];
          
          if (decoded['data'] is List) {
            data = decoded['data'];
          } else if (decoded['data'] != null && decoded['data']['data'] is List) {
            data = decoded['data']['data'];
          } else if (decoded is List) {
            data = decoded;
          }
          
          final result = data
              .map<Map<String, String>>((k) => {
                    'id': (k['id'] ?? '').toString(),
                    'name': (k['nama'] ?? '').toString(),
                  })
              .where((m) => m['name']!.isNotEmpty)
              .toList();

          return result;
        } else {
          throw Exception('Failed to fetch kelas: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Failed to fetch kelas: $e');
      }
    }, forceRefresh: forceRefresh);
  }

  // SISWA DATA
  Future<List<Map<String, dynamic>>> fetchSiswaData({
    String kelasId = '',
    String jurusanId = '',
    String searchQuery = '',
    bool forceRefresh = false,
  }) async {
    final normalizedKelasId = kelasId.isEmpty ? 'all' : kelasId;
    final normalizedJurusanId = jurusanId.isEmpty ? 'all' : jurusanId;
    final normalizedSearchQuery = searchQuery.isEmpty ? 'all' : searchQuery;
    
    final cacheKey = 'siswa-$normalizedSearchQuery-$normalizedKelasId-$normalizedJurusanId';
    
    return await _fetchWithCache(cacheKey, () async {
      try {
        final token = await _getToken();
        if (token == null) return [];

        final Map<String, String> queryParams = {
          'page': '1',
          'limit': '100',
          'with_detail': 'true',
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

          List data = [];
          if (decoded['data'] != null && decoded['data']['data'] is List) {
            data = decoded['data']['data'];
          } else if (decoded['data'] is List) {
            data = decoded['data'];
          }

          final List<Map<String, String>> kelasList = await fetchKelas();

          final List<Map<String, dynamic>> siswaList = [];

          for (var m in data) {
            final String nama = (m['nama_lengkap'] ?? 'Unknown').toString();
            final String nisn = (m['nisn'] ?? '').toString();
            final String siswaId = (m['id'] ?? '').toString();
            
            final String kelasIdStr = (m['kelas_id'] ?? '').toString();
            String kelasName = '-';
            
            if (kelasIdStr.isNotEmpty && kelasList.isNotEmpty) {
              try {
                final kelasData = kelasList.firstWhere(
                  (k) => k['id'] == kelasIdStr,
                  orElse: () => {'name': 'Kelas $kelasIdStr'},
                );
                kelasName = kelasData['name']!;
              } catch (e) {
                kelasName = 'Kelas $kelasIdStr';
              }
            }
            
            final String tanggalLahir = (m['tanggal_lahir'] ?? 
                                  m['tgl_lahir'] ?? 
                                  m['birth_date'] ?? 
                                  m['profile']?['tanggal_lahir'] ??
                                  m['profile']?['tgl_lahir'] ??
                                  '-').toString();

            siswaList.add({
              'name': nama,
              'role': 'Murid',
              'kelas': kelasName,
              'jurusan': '-',
              'nisn': nisn,
              'tgl_lahir': tanggalLahir,
              'id': siswaId,
              'type': 'siswa',
              'original_kelas_id': kelasIdStr,
            });
          }

          return siswaList;
        } else {
          throw Exception('Failed to fetch siswa data: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Failed to fetch siswa data: $e');
      }
    }, forceRefresh: forceRefresh);
  }

  // GURU DATA
  Future<List<Map<String, dynamic>>> fetchGuruData({
    String searchQuery = '',
    bool forceRefresh = false,
  }) async {
    final normalizedSearchQuery = searchQuery.isEmpty ? 'all' : searchQuery;
    final cacheKey = 'guru-$normalizedSearchQuery';
    
    return await _fetchWithCache(cacheKey, () async {
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
          
          List data = [];
          
          if (decoded['data'] != null && decoded['data']['data'] is List) {
            data = decoded['data']['data'];
          } else if (decoded['data'] is List) {
            data = decoded['data'];
          } else {
            return [];
          }

          final List<Map<String, dynamic>> guruList = [];
          
          for (var g in data) {
            final String nama = (g['nama_lengkap'] ?? g['nama'] ?? 'Unknown').toString();
            final String nip = (g['nip'] ?? '').toString();
            final String kodeGuru = (g['kode_guru'] ?? '').toString();
            final String userId = (g['user_id'] ?? '').toString();
            
            guruList.add({
              'name': nama,
              'role': 'Guru',
              'nisn': nip,
              'kode_guru': kodeGuru,
              'user_id': userId,
              'id': (g['id'] ?? '').toString(),
              'type': 'guru',
            });
          }
          
          return guruList;
        } else {
          throw Exception('Failed to fetch guru data: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Failed to fetch guru data: $e');
      }
    }, forceRefresh: forceRefresh);
  }

  // JURUSAN DATA
  Future<List<Map<String, dynamic>>> fetchJurusanData({
    String searchQuery = '',
    bool forceRefresh = false,
  }) async {
    final normalizedSearchQuery = searchQuery.isEmpty ? 'all' : searchQuery;
    final cacheKey = 'jurusan-$normalizedSearchQuery';
    
    return await _fetchWithCache(cacheKey, () async {
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
          
          List data = [];
          if (decoded['data'] is List) {
            data = decoded['data'];
          } else if (decoded['data'] != null && decoded['data']['data'] is List) {
            data = decoded['data']['data'];
          }

          final Map<String, int> classCounts = await _getAllClassCounts(forceRefresh: forceRefresh);
          
          final List<Map<String, dynamic>> jurusanList = [];
          
          for (var j in data) {
            final String jurusanId = (j['id'] ?? '').toString();
            final int jumlahKelas = classCounts[jurusanId] ?? 0;
            
            jurusanList.add({
              'name': (j['nama'] ?? 'Unknown').toString(),
              'kode': (j['kode'] ?? '').toString(),
              'role': 'Jurusan',
              'id': jurusanId,
              'type': 'jurusan',
              'jumlah_kelas': jumlahKelas,
            });
          }
          
          return jurusanList;
        } else {
          throw Exception('Failed to fetch jurusan data: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Failed to fetch jurusan data: $e');
      }
    }, forceRefresh: forceRefresh);
  }

  // INDUSTRI DATA
  Future<List<Map<String, dynamic>>> fetchIndustriData({
    String searchQuery = '',
    bool forceRefresh = false,
  }) async {
    final normalizedSearchQuery = searchQuery.isEmpty ? 'all' : searchQuery;
    final cacheKey = 'industri-$normalizedSearchQuery';
    
    return await _fetchWithCache(cacheKey, () async {
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
          
          List data = [];
          if (decoded['data'] is List) {
            data = decoded['data'];
          } else if (decoded['data'] != null && decoded['data']['data'] is List) {
            data = decoded['data']['data'];
          }

          return data.map<Map<String, dynamic>>((i) {
            final String nama = (i['nama'] ?? 'Unknown').toString();
            final String noTelp = (i['no_telp'] ?? '').toString();
            final String alamat = (i['alamat'] ?? '').toString();
            final String bidang = (i['bidang'] ?? '').toString();
            
            return {
              'name': nama,
              'no_telp': noTelp,
              'alamat': alamat,
              'bidang': bidang,
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
    }, forceRefresh: forceRefresh);
  }

  // KELAS DATA
  Future<List<Map<String, dynamic>>> fetchKelasData({
    String searchQuery = '',
    bool forceRefresh = false,
  }) async {
    final normalizedSearchQuery = searchQuery.isEmpty ? 'all' : searchQuery;
    final cacheKey = 'kelas-data-$normalizedSearchQuery';
    
    return await _fetchWithCache(cacheKey, () async {
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
          
          List data = [];
          if (decoded['data'] is List) {
            data = decoded['data'];
          } else if (decoded['data'] != null && decoded['data']['data'] is List) {
            data = decoded['data']['data'];
          }

          final List<Map<String, dynamic>> jurusanList = await fetchJurusanData(forceRefresh: forceRefresh);
          final Map<String, int> studentCounts = await _getAllStudentCounts(forceRefresh: forceRefresh);

          final List<Map<String, dynamic>> kelasList = [];
          
          for (var k in data) {
            final String kelasId = (k['id'] ?? '').toString();
            final String jurusanId = (k['jurusan_id'] ?? '').toString();
            final int jumlahMurid = studentCounts[kelasId] ?? 0;
            
            String jurusanNama = 'Tidak ada jurusan';
            if (jurusanId.isNotEmpty) {
              try {
                final jurusanData = jurusanList.firstWhere(
                  (j) => j['id'] == jurusanId,
                  orElse: () => {'name': 'Jurusan $jurusanId'},
                );
                jurusanNama = jurusanData['name'] ?? 'Jurusan $jurusanId';
              } catch (e) {
                jurusanNama = 'Jurusan $jurusanId';
              }
            }
            
            kelasList.add({
              'name': (k['nama'] ?? 'Unknown').toString(),
              'jurusan_id': jurusanId,
              'jurusan_nama': jurusanNama,
              'role': 'Kelas',
              'id': kelasId,
              'type': 'kelas',
              'jumlah_murid': jumlahMurid,
            });
          }
          
          return kelasList;
        } else {
          throw Exception('Failed to fetch kelas data: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Failed to fetch kelas data: $e');
      }
    }, forceRefresh: forceRefresh);
  }

  // Method untuk clear cache
  void clearCache([String? specificKey]) {
    if (specificKey != null) {
      _cache.remove(specificKey);
      _cacheTimestamps.remove(specificKey);
      if (kDebugMode) {
        print('🗑️ Cache cleared: $specificKey');
      }
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
      _studentCountsCache = null;
      _classCountsCache = null;
      _bulkCacheTimestamp = null;
      if (kDebugMode) {
        print('🗑️ All cache cleared');
      }
    }
  }

  void clearCacheByPattern(String pattern) {
    final keysToRemove = _cache.keys.where((key) => key.contains(pattern)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
    if (kDebugMode) {
      print('🗑️ Cache cleared for pattern: $pattern');
    }
  }

  void clearBulkCache() {
    _studentCountsCache = null;
    _classCountsCache = null;
    _bulkCacheTimestamp = null;
    if (kDebugMode) {
      print('🗑️ Bulk cache cleared');
    }
  }

  Map<String, dynamic> getCacheInfo() {
    return {
      'totalCachedItems': _cache.length,
      'cacheKeys': _cache.keys.toList(),
      'bulkCacheStatus': {
        'studentCounts': _studentCountsCache != null,
        'classCounts': _classCountsCache != null,
        'lastUpdate': _bulkCacheTimestamp?.toString(),
      }
    };
  }
}