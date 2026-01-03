import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'ajukan_pkl_dialog.dart';
import '../../login/login_screen.dart';
import 'detail_popup.dart';
import 'industri_list_page.dart'; // File baru untuk popup

class SiswaDashboard extends StatefulWidget {
  const SiswaDashboard({super.key});

  @override
  State<SiswaDashboard> createState() => _SiswaDashboardState();
}

class _SiswaDashboardState extends State<SiswaDashboard> {
  String _namaSiswa = 'Loading...';
  String _kelasSiswa = 'Loading...';
  int? _kelasId;
  bool _isLoading = true;

  Map<String, dynamic>? _pklData;
  List<dynamic> _pklApplications = [];
  Map<String, dynamic>? _industriData;
  Map<String, dynamic>? _pembimbingData;
  Map<String, dynamic>? _processedByData;

  // ========== PERBAIKAN UTAMA ==========
  // HAPUS SEMUA KEYWORD 'STATIC' DARI CACHE!
  // Instance cache saja, bukan static cache
  Map<String, dynamic>? _cachedPklData;
  List<dynamic>? _cachedPklApplications;
  Map<String, dynamic>? _cachedIndustriData;
  Map<String, dynamic>? _cachedPembimbingData;
  Map<String, dynamic>? _cachedProcessedByData;
  bool _isCached = false;
  String? _cachedNamaSiswa;
  String? _cachedKelasSiswa;
  int? _cachedKelasId;
  // =====================================

  // Tambahan: tracking user saat ini
  String? _currentUsername;
  StreamSubscription? _prefsSubscription;

  // Neo Brutalism Colors
  final Color _primaryColor = const Color(0xFFE63946); // Merah cerah
  final Color _secondaryColor = const Color(0xFFF1FAEE); // Putih krem
  final Color _accentColor = const Color(0xFFA8DADC); // Biru muda
  final Color _darkColor = const Color(0xFF1D3557); // Biru tua
  final Color _yellowColor = const Color(0xFFFFB703); // Kuning cerah
  final Color _blackColor = Colors.black;

  // Neo Brutalism Shadows
  static const BoxShadow _heavyShadow = BoxShadow(
    color: Colors.black,
    offset: Offset(6, 6),
    blurRadius: 0,
  );

  final BoxShadow _lightShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.2),
    offset: const Offset(4, 4),
    blurRadius: 0,
  );

  @override
  void initState() {
    super.initState();
    
    print('🚀 SiswaDashboard State dibuat');
    
    // ========== SOLUSI PENTING ==========
    // SELALU CLEAR CACHE SAAT INIT STATE UNTUK USER BARU
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearCache(); // Clear cache saat widget pertama kali dibuat
      _checkAuthAndLoadData();
    });
    
    _startPrefsListener(); // Tambahkan listener
  }

  @override
  void dispose() {
    _prefsSubscription?.cancel(); // Jangan lupa cancel subscription
    super.dispose();
  }

  void _startPrefsListener() async {
    final prefs = await SharedPreferences.getInstance();

    // Listen untuk perubahan token atau username
    _prefsSubscription = Stream.periodic(const Duration(seconds: 2))
        .asyncMap((_) async {
          return {
            'token': prefs.getString('access_token'),
            'username': prefs.getString('user_name'),
            'shouldClear': prefs.getBool('should_clear_cache') ?? false,
          };
        })
        .distinct()
        .listen((Map<String, dynamic> data) {
          final token = data['token'] as String?;
          final username = data['username'] as String?;
          final shouldClear = data['shouldClear'] as bool;

          // Jika ada flag clear cache dari halaman pengaturan
          if (shouldClear) {
            print('🔄 Mendapatkan perintah clear cache dari logout');
            prefs.remove('should_clear_cache');
            _clearCache();
          }

          // Jika token hilang atau username berubah
          if (token == null ||
              token.isEmpty ||
              (_currentUsername != null && _currentUsername != username)) {
            print('🔄 Token/username berubah, clearing cache...');
            _clearCache();
            if (mounted && token == null) {
              _redirectToLogin();
            }
          }
        });
  }

  Future<void> _checkAuthAndLoadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userName = prefs.getString('user_name');

    print('🔄 _checkAuthAndLoadData dipanggil');
    print('   - Username dari SharedPreferences: $userName');
    print('   - _currentUsername sebelumnya: $_currentUsername');
    print('   - _isCached: $_isCached');

    // ========== PERBAIKAN PENTING ==========
    // VALIDASI USER DENGAN TELITI
    bool userBerubah = false;
    
    if (userName != null) {
      if (_currentUsername == null) {
        // Pertama kali load
        print('✅ Pertama kali load, set _currentUsername: $userName');
        _currentUsername = userName;
      } else if (_currentUsername != userName) {
        // User berubah
        print('🚨 DETEKSI PERUBAHAN USER!');
        print('   - User lama: $_currentUsername');
        print('   - User baru: $userName');
        userBerubah = true;
      }
    }
    
    // Jika user berubah atau cache kosong, load data baru
    if (userBerubah || !_isCached || _cachedNamaSiswa == null) {
      if (userBerubah) {
        _clearCache();
      }
      _currentUsername = userName;
      await _loadAllData();
      return;
    }
    // =====================================

    // Cek apakah ada flag clear cache (dari logout)
    final shouldClear = prefs.getBool('should_clear_cache') ?? false;
    if (shouldClear) {
      print('🔄 Clear cache dari flag logout...');
      await prefs.remove('should_clear_cache');
      _clearCache();
      _currentUsername = userName;
      await _loadAllData();
      return;
    }

    // Cek apakah ada access token
    if (token == null || token.isEmpty) {
      print('❌ Token tidak ada, redirect ke login');
      _redirectToLogin();
      return;
    }

    // ========== LOGIKA CACHE YANG DIPERBAIKI ==========
    // Gunakan cache HANYA jika semua kondisi terpenuhi
    if (_isCached && 
        _currentUsername != null && 
        userName != null && 
        _currentUsername == userName &&
        _cachedNamaSiswa != null &&
        _cachedNamaSiswa == userName) {
      print('✅ Menggunakan cache untuk user: $userName');
      _loadFromCache();
      setState(() {
        _isLoading = false;
      });
    } else {
      print('🔄 Load data fresh karena:');
      print('   - _isCached: $_isCached');
      print('   - _currentUsername: $_currentUsername');
      print('   - _cachedNamaSiswa: $_cachedNamaSiswa');
      print('   - userName: $userName');
      await _loadAllData();
    }
    // ================================================
  }

  void _loadFromCache() {
    print('📦 Loading dari cache...');
    print('   - _cachedNamaSiswa: $_cachedNamaSiswa');
    print('   - _cachedKelasSiswa: $_cachedKelasSiswa');
    
    if (_cachedPklData != null) _pklData = _cachedPklData;
    if (_cachedPklApplications != null) {
      _pklApplications = _cachedPklApplications!;
    }
    if (_cachedIndustriData != null) _industriData = _cachedIndustriData;
    if (_cachedPembimbingData != null) _pembimbingData = _cachedPembimbingData;
    if (_cachedProcessedByData != null) {
      _processedByData = _cachedProcessedByData;
    }
    if (_cachedNamaSiswa != null) _namaSiswa = _cachedNamaSiswa!;
    if (_cachedKelasSiswa != null) _kelasSiswa = _cachedKelasSiswa!;
    if (_cachedKelasId != null) _kelasId = _cachedKelasId;
    
    print('✅ Cache loaded untuk $_namaSiswa');
  }

  void _saveToCache() {
    print('💾 _saveToCache() dipanggil');
    print('   - Username saat save: $_currentUsername');
    print('   - Nama siswa: $_namaSiswa');
    print('   - Kelas siswa: $_kelasSiswa');

    // Hanya save jika ada current username
    if (_currentUsername == null) {
      print('⚠️  Tidak bisa save cache karena _currentUsername null');
      return;
    }

    _cachedPklData = _pklData;
    _cachedPklApplications = _pklApplications;
    _cachedIndustriData = _industriData;
    _cachedPembimbingData = _pembimbingData;
    _cachedProcessedByData = _processedByData;
    _cachedNamaSiswa = _namaSiswa;
    _cachedKelasSiswa = _kelasSiswa;
    _cachedKelasId = _kelasId;
    _isCached = true;

    print('✅ Cache disimpan untuk user: $_currentUsername');
  }

  void _clearCache() {
    print('🧹 _clearCache() dipanggil - RESET TOTAL');
    print('   - Sebelum clear: _isCached = $_isCached');
    print('   - _currentUsername sebelum clear: $_currentUsername');
    print('   - _cachedNamaSiswa sebelum clear: $_cachedNamaSiswa');

    // Reset semua cache variables
    _isCached = false;
    
    _cachedPklData = null;
    _cachedPklApplications = null;
    _cachedIndustriData = null;
    _cachedPembimbingData = null;
    _cachedProcessedByData = null;
    _cachedNamaSiswa = null;
    _cachedKelasSiswa = null;
    _cachedKelasId = null;
    
    // Reset state data
    if (mounted) {
      setState(() {
        _pklData = null;
        _pklApplications = [];
        _industriData = null;
        _pembimbingData = null;
        _processedByData = null;
        _namaSiswa = 'Loading...';
        _kelasSiswa = 'Loading...';
        _kelasId = null;
        _isLoading = true;
      });
    }
    
    print('   - Setelah clear: _isCached = $_isCached');
    print('   - _cachedNamaSiswa setelah clear: $_cachedNamaSiswa');
    print('✅ Semua cache telah di-reset');
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    // Cek token lagi sebelum load data
    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _loadProfileData();
      await _loadPklApplications();
      _saveToCache();
    } catch (e) {
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        _redirectToLogin();
        return;
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userName = prefs.getString('user_name');

    print('🔍 DEBUG _loadProfileData:');
    print('   - Token: ${token != null ? "Ada" : "Tidak ada"}');
    print('   - Username: $userName');

    if (token == null || token.isEmpty) {
      print('❌ Token tidak ada, redirect ke login');
      _redirectToLogin();
      return;
    }

    try {
      final apiUrl = '${dotenv.env['API_BASE_URL']}/api/siswa?search=$userName';
      print('🌐 Mengambil data siswa dari API: $apiUrl');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📊 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ API Response Body:');
        print('   - success: ${data['success']}');
        print('   - data: ${data['data'] != null ? "Ada" : "Tidak ada"}');

        if (data['data'] != null) {
          print(
              '   - data.data: ${data['data']['data'] != null ? "Ada" : "Tidak ada"}');
          print(
              '   - data.data length: ${data['data']['data'] != null ? data['data']['data'].length : 0}');
        }

        if (data['success'] == true &&
            data['data'] != null &&
            data['data']['data'] != null &&
            data['data']['data'].isNotEmpty) {
          final List<dynamic> siswaList = data['data']['data'];
          print('👥 Ditemukan ${siswaList.length} siswa');

          // Print detail setiap siswa untuk debugging
          for (var i = 0; i < siswaList.length; i++) {
            final siswa = siswaList[i];
            print('   Siswa $i:');
            print('     - nama_lengkap: ${siswa['nama_lengkap']}');
            print('     - kelas_id: ${siswa['kelas_id']}');
            print('     - kelas: ${siswa['kelas']}');
            print('     - kelas_nama: ${siswa['kelas_nama']}');
          }

          final matchedSiswa = siswaList.firstWhere(
              (siswa) => siswa['nama_lengkap'] == userName, orElse: () {
            print(
                '⚠️  Tidak menemukan siswa dengan nama $userName, ambil siswa pertama');
            return siswaList.first;
          });

          print('🎯 Siswa yang dipilih:');
          print('   - nama_lengkap: ${matchedSiswa['nama_lengkap']}');
          print('   - kelas_id: ${matchedSiswa['kelas_id']}');

          final kelasId = matchedSiswa['kelas_id'];
          String kelasNama = 'Kelas Tidak Tersedia';

          // ========= PERBAIKAN UTAMA =========
          // Ambil nama kelas dari endpoint terpisah
          if (kelasId != null) {
            try {
              print('📚 Mengambil data kelas dari API...');
              final kelasResponse = await http.get(
                Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas/$kelasId'),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
              );

              if (kelasResponse.statusCode == 200) {
                final kelasData = jsonDecode(kelasResponse.body);
                print('✅ Data kelas: $kelasData');

                if (kelasData['success'] == true && kelasData['data'] != null) {
                  kelasNama =
                      kelasData['data']['nama'] ?? 'Kelas Tidak Tersedia';
                  print('✅ Nama kelas ditemukan: $kelasNama');
                } else {
                  print('❌ Data kelas tidak valid');
                }
              } else {
                print(
                    '❌ Gagal mengambil data kelas. Status: ${kelasResponse.statusCode}');
                print('   Response: ${kelasResponse.body}');

                // Coba alternatif: cari kelas dari list semua kelas
                try {
                  print('🔄 Mencoba alternatif: mengambil semua kelas');
                  final allKelasResponse = await http.get(
                    Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas'),
                    headers: {
                      'Authorization': 'Bearer $token',
                      'Content-Type': 'application/json',
                    },
                  );

                  if (allKelasResponse.statusCode == 200) {
                    final allKelasData = jsonDecode(allKelasResponse.body);
                    if (allKelasData['success'] == true &&
                        allKelasData['data'] != null &&
                        allKelasData['data']['data'] != null) {
                      final kelasList = allKelasData['data']['data'] as List;
                      final kelasItem = kelasList.firstWhere(
                          (kelas) => kelas['id'] == kelasId,
                          orElse: () => null);

                      if (kelasItem != null) {
                        kelasNama = kelasItem['nama'] ?? 'Kelas Tidak Tersedia';
                        print('✅ Nama kelas ditemukan dari list: $kelasNama');
                      } else {
                        print('❌ Kelas tidak ditemukan dalam list semua kelas');
                      }
                    }
                  }
                } catch (e) {
                  print('❌ Error mengambil semua kelas: $e');
                }
              }
            } catch (e) {
              print('❌ Error mengambil data kelas: $e');
            }
          } else {
            print('⚠️  kelas_id null, tidak bisa mengambil data kelas');
          }
          // ===================================

          print('💾 Menyimpan data ke SharedPreferences:');
          print('   - kelas_id: $kelasId');
          print('   - kelas_nama: $kelasNama');

          await prefs.setInt('kelas_id', kelasId);
          await prefs.setInt('user_kelas_id', kelasId);
          await prefs.setString('kelas_nama', kelasNama);
          await prefs.setString('user_kelas', kelasNama);

          // Verifikasi penyimpanan
          final savedKelasId = prefs.getInt('kelas_id');
          final savedKelasNama = prefs.getString('kelas_nama');
          print('✅ Data tersimpan:');
          print('   - saved kelas_id: $savedKelasId');
          print('   - saved kelas_nama: $savedKelasNama');

          if (mounted) {
            setState(() {
              _namaSiswa = userName ?? 'Nama Tidak Tersedia';
              _kelasSiswa = kelasNama;
              _kelasId = kelasId;
            });

            print('🎨 State diupdate:');
            print('   - _namaSiswa: $_namaSiswa');
            print('   - _kelasSiswa: $_kelasSiswa');
            print('   - _kelasId: $_kelasId');
          }
          return;
        } else {
          print('❌ Struktur data tidak sesuai atau kosong');
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized (401), redirect ke login');
        _redirectToLogin();
        return;
      } else {
        print('❌ Status code tidak 200: ${response.statusCode}');
        print('   Response body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error loading profile from API: $e');
      print('   Stack trace: ${e.toString()}');
    }

    // Fallback jika gagal dari API
    print('🔄 Menggunakan fallback dari SharedPreferences');
    if (mounted) {
      final kelasIdFromPrefs =
          prefs.getInt('kelas_id') ?? prefs.getInt('user_kelas_id');
      final kelasNamaFromPrefs = prefs.getString('kelas_nama') ??
          prefs.getString('user_kelas') ??
          'Kelas Tidak Tersedia';

      print('📋 Data dari SharedPreferences:');
      print('   - kelasIdFromPrefs: $kelasIdFromPrefs');
      print('   - kelasNamaFromPrefs: $kelasNamaFromPrefs');

      setState(() {
        _namaSiswa = userName ?? 'Nama Tidak Tersedia';
        _kelasSiswa = kelasNamaFromPrefs;
        _kelasId = kelasIdFromPrefs;
      });

      print('🎨 Fallback state diupdate:');
      print('   - _namaSiswa: $_namaSiswa');
      print('   - _kelasSiswa: $_kelasSiswa');
      print('   - _kelasId: $_kelasId');
    }
  }

  Future<void> _loadPklApplications() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/applications/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data'] != null && data['data'].isNotEmpty) {
          if (mounted) {
            setState(() {
              _pklApplications = data['data'];
              _pklApplications.sort((a, b) => b['id'].compareTo(a['id']));
            });
          }

          final approvedApplications = _pklApplications.where((app) {
            final status = app['status'].toString().toLowerCase();
            return status == 'approved' || status == 'disetujui';
          }).toList();

          if (approvedApplications.isNotEmpty) {
            if (mounted) {
              setState(() {
                _pklData = approvedApplications.first;
              });
            }

            if (_pklData?['industri_id'] != null) {
              await _loadIndustriData(_pklData!['industri_id']);
            }
            if (_pklData?['pembimbing_guru_id'] != null) {
              await _loadPembimbingData(_pklData!['pembimbing_guru_id']);
            }
            if (_pklData?['processed_by'] != null) {
              await _loadProcessedByData(_pklData!['processed_by']);
            }
          } else {
            // Jika tidak ada yang disetujui, ambil pengajuan terbaru
            final latestApplication = _pklApplications.first;
            if (mounted) {
              setState(() {
                _pklData = latestApplication;
              });
            }
            
            // Load data terkait untuk aplikasi terbaru
            if (latestApplication['industri_id'] != null) {
              await _loadIndustriData(latestApplication['industri_id']);
            }
            if (latestApplication['processed_by'] != null) {
              await _loadProcessedByData(latestApplication['processed_by']);
            }
            if (latestApplication['pembimbing_guru_id'] != null) {
              await _loadPembimbingData(latestApplication['pembimbing_guru_id']);
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _pklData = null;
            });
          }
        }
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      }
    } catch (_) {}
  }

  Future<void> _loadIndustriData(int industriId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/industri/$industriId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() => _industriData = data['data']);
        }
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      }
    } catch (_) {}
  }

  Future<void> _loadPembimbingData(int? guruId) async {
    if (guruId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru/$guruId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() => _pembimbingData = data['data']);
        }
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      }
    } catch (_) {}
  }

  Future<void> _loadProcessedByData(int? guruId) async {
    if (guruId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru/$guruId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() => _processedByData = data['data']);
        }
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      }
    } catch (_) {}
  }

  // Fungsi untuk mengajukan PKL
  Future<void> _ajukanPKL() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    try {
      if (_kelasId == null) {
        await _loadProfileData();
      }

      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AjukanPKLDialog(
          token: token,
          kelasId: _kelasId,
        ),
      );

      if (result != null) {
        final response = await http.post(
          Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/applications'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'catatan': result['catatan'],
            'industri_id': result['industri_id'],
          }),
        );

        if (response.statusCode == 201) {
          _clearCache();
          await _loadAllData();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pengajuan PKL berhasil dikirim')),
            );
          }
        } else if (response.statusCode == 401) {
          _redirectToLogin();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengajukan PKL: ${response.body}')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Terjadi kesalahan saat mengajukan PKL')),
        );
      }
    }
  }

  Future<void> _bukaIndustri() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const IndustriListPage(),
        ),
      );
    }
  }

  // Fungsi untuk membuka popup riwayat PKL
  Future<void> _bukaRiwayat() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    try {
      if (_pklApplications.isEmpty) {
        await _loadPklApplications();
      }

      // Panggil fungsi dari file terpisah
      if (mounted) {
        await DetailPopup.showRiwayatPopup(
          context,
          _pklApplications,
          industriData: _industriData,
          formatTanggal: _formatTanggal,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat riwayat')),
        );
      }
    }
  }


  String _formatTanggal(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';

    try {
      final date = DateTime.parse(dateString);
      final bulan = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ];

      return '${date.day} ${bulan[date.month - 1]} ${date.year}';
    } catch (e) {
      return '-';
    }
  }

  int _getCurrentProgressStatus(String? status) {
    if (status == null) return 0;

    switch (status.toLowerCase()) {
      case 'pending':
      case 'menunggu':
        return 1;
      case 'approved':
      case 'disetujui':
        return 2;
      case 'completed':
      case 'selesai':
        return 3;
      default:
        return 0;
    }
  }

  String _getStatusText(String? status) {
    if (status == null) return 'Belum Mengajukan';

    switch (status.toLowerCase()) {
      case 'pending':
      case 'menunggu':
        return 'Menunggu';
      case 'approved':
      case 'disetujui':
        return 'Menjalankan PKL';
      case 'completed':
      case 'selesai':
        return 'Selesai PKL';
      case 'rejected':
      case 'ditolak':
        return 'Pengajuan Ditolak';
      default:
        return 'Mengajukan';
    }
  }

  bool _hasApprovedApplication() {
    if (_pklData == null) return false;
    final status = _pklData!['status'].toString().toLowerCase();
    return status == 'approved' || status == 'disetujui';
  }

  bool _hasRejectedApplication() {
    if (_pklData == null) return false;
    final status = _pklData!['status'].toString().toLowerCase();
    return status == 'rejected' || status == 'ditolak';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header dengan sapaan dan notifikasi - Neo Brutalism Style
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border.all(color: _blackColor, width: 3),
                  boxShadow: const [_heavyShadow],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, $_namaSiswa!',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kelas $_kelasSiswa',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _secondaryColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _yellowColor,
                              border: Border.all(color: _blackColor, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Dashboard PKL',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _blackColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _yellowColor,
                        border: Border.all(color: _blackColor, width: 3),
                        boxShadow: [_lightShadow],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.notifications,
                        size: 28,
                        color: _blackColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Container waktu PKL dengan progress bar - Neo Brutalism
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _secondaryColor,
                  border: Border.all(color: _blackColor, width: 3),
                  boxShadow: const [_heavyShadow],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isLoading
                    ? _buildTimeSectionSkeleton()
                    : Column(
                        children: [
                          // Baris untuk tanggal mulai dan selesai
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildTimeItem(
                                  'Mulai',
                                  _pklData != null
                                      ? _formatTanggal(
                                          _pklData!['tanggal_mulai'])
                                      : '-'),
                              Container(
                                width: 4,
                                height: 50,
                                color: _blackColor,
                              ),
                              _buildTimeItem(
                                  'Selesai',
                                  _pklData != null
                                      ? _formatTanggal(
                                          _pklData!['tanggal_selesai'])
                                      : '-'),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Progress bar dengan style brutalism
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _secondaryColor,
                                  border:
                                      Border.all(color: _blackColor, width: 3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Stack(
                                  children: [
                                    // Background progress
                                    Container(
                                      width:
                                          (MediaQuery.of(context).size.width -
                                                  72) *
                                              ((_getCurrentProgressStatus(
                                                          _pklData?['status']) +
                                                      1.2) /
                                                  4),
                                      height: 34,
                                      margin: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: _primaryColor,
                                        borderRadius: BorderRadius.circular(17),
                                      ),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12),
                                          child: Text(
                                            _getStatusText(_pklData?['status']),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.3,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),

              // Container utama dengan background putih - Neo Brutalism
              Container(
                margin: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  color: _secondaryColor,
                  border: Border.all(color: _blackColor, width: 4),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: const [_heavyShadow],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Aksi cepat dengan style brutalism
                      _isLoading
                          ? _buildQuickActionsSkeleton()
                          : Container(
                              width: double.infinity,
                              height: 160,
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                border:
                                    Border.all(color: _blackColor, width: 3),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [_heavyShadow],
                              ),
                              child: Stack(
                                children: [
                                  // Garis vertikal tebal
                                  Positioned(
                                    left: 150,
                                    top: 20,
                                    bottom: 20,
                                    child: Container(
                                      width: 4,
                                      color: _blackColor,
                                    ),
                                  ),

                                  // Garis horizontal tebal
                                  Positioned(
                                    left: 166,
                                    right: 20,
                                    top: 80,
                                    child: Container(
                                      height: 4,
                                      color: _blackColor,
                                    ),
                                  ),

                                  // Menu 1: Pengajuan
                                  Positioned(
                                    left: 30,
                                    top: 25,
                                    child: _buildMenuOptionKiri('Pengajuan',
                                        Icons.assignment_add, _ajukanPKL),
                                  ),

                                  // Menu 2: Industri
                                  Positioned(
                                    right: 40,
                                    top: 20,
                                    child: _buildMenuOptionKanan('Industri',
                                        Icons.factory, _bukaIndustri),
                                  ),

                                  // Menu 3: Riwayat
                                  Positioned(
                                    right: 40,
                                    bottom: 15,
                                    child: _buildMenuOptionKanan(
                                        'Riwayat', Icons.history, _bukaRiwayat),
                                  ),
                                ],
                              ),
                            ),

                      const SizedBox(height: 32),

                      // Judul Daftar Pengajuan PKL - Brutalism Style
                      _isLoading
                          ? _buildTitleSkeleton()
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: _yellowColor,
                                border:
                                    Border.all(color: _blackColor, width: 3),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [_lightShadow],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'PENGAJUAN PKL',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: _blackColor,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _secondaryColor,
                                      border: Border.all(
                                          color: _blackColor, width: 2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _hasApprovedApplication()
                                          ? '1 DISETUJUI'
                                          : (_hasRejectedApplication()
                                              ? '1 DITOLAK'
                                              : '0 DISETUJUI'),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: _blackColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                      const SizedBox(height: 20),

                      // Tampilkan pengajuan
                      if (_isLoading)
                        _buildPKLCardSkeleton()
                      else if (_pklData != null)
                        _buildPengajuanCard({
                          'status': _pklData!['status'],
                          'industri_nama': _industriData?['nama'] ?? 'Industri',
                          'tanggal_permohonan':
                              _formatTanggal(_pklData!['tanggal_permohonan']),
                          'tanggal_mulai':
                              _formatTanggal(_pklData!['tanggal_mulai']),
                          'tanggal_selesai':
                              _formatTanggal(_pklData!['tanggal_selesai']),
                          'catatan': _pklData!['catatan'] ?? '-',
                          'kaprog_note':
                              _pklData!['kaprog_note'] ?? 'Tidak ada catatan',
                          'decided_at': _formatTanggal(_pklData!['decided_at']),
                          'diproses_oleh': _processedByData?['nama'] ?? '-',
                          'pembimbing_pkl': _pembimbingData?['nama'] ?? '-',
                        })
                      else
                        _buildNoPengajuanCard(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== SKELETON LOADING WIDGETS ==========
  Widget _buildTimeSectionSkeleton() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTimeItemSkeleton(),
            Container(
              width: 4,
              height: 50,
              color: _blackColor,
            ),
            _buildTimeItemSkeleton(),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: _secondaryColor,
            border: Border.all(color: _blackColor, width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeItemSkeleton() {
    return Column(
      children: [
        Container(
          width: 50,
          height: 12,
          color: _blackColor.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 24,
          decoration: BoxDecoration(
            color: _secondaryColor,
            border: Border.all(color: _blackColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSkeleton() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: _primaryColor,
        border: Border.all(color: _blackColor, width: 3),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [_heavyShadow],
      ),
    );
  }

  Widget _buildTitleSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _yellowColor,
        border: Border.all(color: _blackColor, width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
              width: 150,
              height: 20,
              color: _blackColor.withValues(alpha: 0.3)),
          Container(
              width: 80, height: 20, color: _blackColor.withValues(alpha: 0.3)),
        ],
      ),
    );
  }

  Widget _buildPKLCardSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _secondaryColor,
        border: Border.all(color: _blackColor, width: 3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 30,
            decoration: BoxDecoration(
              color: _primaryColor,
              border: Border.all(color: _blackColor, width: 2),
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          const SizedBox(height: 16),
          Container(
              width: 200,
              height: 24,
              color: _blackColor.withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Container(
              width: double.infinity,
              height: 16,
              color: _blackColor.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Container(
              width: 150,
              height: 16,
              color: _blackColor.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accentColor,
              border: Border.all(color: _blackColor, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: 100,
                    height: 14,
                    color: _blackColor.withValues(alpha: 0.2)),
                const SizedBox(height: 8),
                Container(
                    width: double.infinity,
                    height: 14,
                    color: _blackColor.withValues(alpha: 0.2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPengajuanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: _secondaryColor,
        border: Border.all(color: _blackColor, width: 4),
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [_heavyShadow],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _primaryColor,
              border: Border.all(color: _blackColor, width: 3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 40,
              color: _secondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'BELUM ADA PENGAJUAN DISETUJUI',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _blackColor,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Ajukan PKL untuk memulai praktik kerja lapangan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _darkColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _ajukanPKL,
            style: ElevatedButton.styleFrom(
              backgroundColor: _yellowColor,
              foregroundColor: _blackColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _blackColor, width: 3),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            child: const Text(
              'AJUKAN PKL SEKARANG',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ========== END SKELETON LOADING WIDGETS ==========

  Widget _buildPengajuanCard(Map<String, dynamic> pengajuan) {
    final status = pengajuan['status'];
    final isApproved = status.toLowerCase() == 'approved' ||
        status.toLowerCase() == 'disetujui';
    final isRejected =
        status.toLowerCase() == 'rejected' || status.toLowerCase() == 'ditolak';

    // Warna berdasarkan status
    final statusColor = isRejected 
        ? const Color(0xFFE63946) 
        : (isApproved ? const Color(0xFF06D6A0) : const Color(0xFFFFB703));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _secondaryColor,
        border: Border.all(
          color: _blackColor,
          width: 4,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [_heavyShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER STATUS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: _blackColor, width: 4),
              ),
            ),
            child: Row(
              children: [
                // Icon status
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _blackColor, width: 3),
                    shape: BoxShape.circle,
                    boxShadow: [_lightShadow],
                  ),
                  child: Icon(
                    isRejected
                        ? Icons.cancel
                        : (isApproved ? Icons.check_circle : Icons.access_time),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Text status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRejected
                            ? 'DITOLAK'
                            : (isApproved ? 'DISETUJUI' : 'MENUNGGU'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        isRejected
                            ? 'Pengajuan PKL Anda ditolak'
                            : (isApproved
                                ? 'Pengajuan PKL Anda telah disetujui'
                                : 'Pengajuan PKL Anda sedang diproses'),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // KONTEN UTAMA
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // INDUSTRI
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isRejected 
                        ? const Color(0xFFE63946).withValues(alpha: 0.1) 
                        : _primaryColor.withValues(alpha: 0.1),
                    border: Border.all(
                      color: isRejected ? const Color(0xFFE63946) : _primaryColor, 
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isRejected ? const Color(0xFFE63946) : _primaryColor,
                          border: Border.all(color: _blackColor, width: 3),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isRejected ? Icons.block : Icons.factory,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isRejected ? 'LOKASI YG DIAJUKAN' : 'LOKASI PKL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: _darkColor,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pengajuan['industri_nama'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: _blackColor,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // CATATAN PENGAJUAN (TAMPIL UNTUK SEMUA STATUS KECUALI DITOLAK JIKA ADA KAPROG_NOTE)
                if (pengajuan['catatan'] != null && 
                    pengajuan['catatan'].isNotEmpty && 
                    pengajuan['catatan'] != '-')
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _secondaryColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                border: Border.all(color: _blackColor, width: 2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.note_add,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'CATATAN PENGAJUAN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _blackColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: _blackColor, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pengajuan['catatan'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // TAMPILAN KHUSUS UNTUK STATUS DITOLAK
                if (isRejected) ...[
                  // ALASAN PENOLAKAN (PENTING!)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE63946).withValues(alpha: 0.15),
                      border: Border.all(
                        color: const Color(0xFFE63946),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE63946),
                                border: Border.all(color: _blackColor, width: 2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.warning_amber,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'ALASAN PENOLAKAN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _blackColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: _blackColor, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pengajuan['kaprog_note'] ?? 'Tidak ada alasan yang diberikan',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // INFORMASI PENGAJUAN
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [_lightShadow],
                    ),
                    child: Column(
                      children: [
                        // DIAJUKAN PADA
                        _buildInfoRowCompact(
                          icon: Icons.calendar_today_outlined,
                          iconColor: const Color(0xFFFFB703),
                          title: 'DIAJUKAN PADA',
                          value: pengajuan['tanggal_permohonan'],
                        ),

                        const SizedBox(height: 16),

                        // DIPUTUSKAN PADA
                        _buildInfoRowCompact(
                          icon: Icons.gavel_outlined,
                          iconColor: const Color(0xFFE63946),
                          title: 'DIPUTUSKAN PADA',
                          value: pengajuan['decided_at'],
                        ),

                        const SizedBox(height: 16),

                        // DIPROSES OLEH (KAPROG)
                        _buildInfoRowCompact(
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFFA8DADC),
                          title: 'DIPROSES OLEH',
                          value: pengajuan['diproses_oleh'],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // TOMBOL AJUKAN ULANG
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _secondaryColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BUTUH REVISI?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: _blackColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Perbaiki pengajuan Anda berdasarkan alasan penolakan di atas, lalu ajukan kembali.',
                          style: TextStyle(
                            fontSize: 14,
                            color: _darkColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _ajukanPKL,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _yellowColor,
                                  foregroundColor: _blackColor,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: _blackColor, width: 3),
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.refresh, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'AJUKAN ULANG',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else if (isApproved) ...[
                  // TAMPILAN UNTUK DISETUJUI
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [_lightShadow],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRowCompact(
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFFE63946),
                          title: 'DIPROSES OLEH',
                          value: pengajuan['diproses_oleh'],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRowCompact(
                          icon: Icons.school_outlined,
                          iconColor: const Color(0xFF06D6A0),
                          title: 'PEMBIMBING',
                          value: pengajuan['pembimbing_pkl'],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRowCompact(
                          icon: Icons.calendar_today_outlined,
                          iconColor: const Color(0xFFFFB703),
                          title: 'DIAJUKAN',
                          value: pengajuan['tanggal_permohonan'],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRowCompact(
                          icon: Icons.gavel_outlined,
                          iconColor: const Color(0xFFA8DADC),
                          title: 'DIPUTUSKAN',
                          value: pengajuan['decided_at'],
                        ),
                      ],
                    ),
                  ),
                  
                  // CATATAN APPROVAL JIKA ADA
                  if (pengajuan['kaprog_note'] != null && 
                      pengajuan['kaprog_note'].isNotEmpty && 
                      pengajuan['kaprog_note'] != 'Tidak ada catatan')
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06D6A0).withValues(alpha: 0.1),
                        border: Border.all(color: const Color(0xFF06D6A0), width: 3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF06D6A0),
                                  border: Border.all(color: _blackColor, width: 2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'CATATAN APPROVAL',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: _blackColor,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: _blackColor, width: 2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              pengajuan['kaprog_note'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ] else ...[
                  // TAMPILAN UNTUK MENUNGGU
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      border: Border.all(color: _blackColor, width: 3),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [_lightShadow],
                    ),
                    child: Column(
                      children: [
                        _buildInfoRowCompact(
                          icon: Icons.person_outline,
                          iconColor: const Color(0xFFE63946),
                          title: 'DIAJUKAN PADA',
                          value: pengajuan['tanggal_permohonan'],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRowCompact(
                          icon: Icons.access_time,
                          iconColor: const Color(0xFFFFB703),
                          title: 'STATUS',
                          value: 'Menunggu Persetujuan',
                        ),
                        const SizedBox(height: 16),
                        if (pengajuan['diproses_oleh'] != null && 
                            pengajuan['diproses_oleh'] != '-')
                          _buildInfoRowCompact(
                            icon: Icons.person_outline,
                            iconColor: const Color(0xFFA8DADC),
                            title: 'SEDANG DIPROSES',
                            value: pengajuan['diproses_oleh'],
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET HELPER UNTUK INFO ROW KOMPAK
  Widget _buildInfoRowCompact({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _blackColor, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor,
              border: Border.all(color: _blackColor, width: 2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 18,
              color: Colors.white,
            ),
          ),

          const SizedBox(width: 12),

          // Title & Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: _darkColor,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: _blackColor,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptionKiri(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _secondaryColor,
              border: Border.all(color: _blackColor, width: 3),
              shape: BoxShape.circle,
              boxShadow: [_lightShadow],
            ),
            child: Icon(
              icon,
              color: _primaryColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _yellowColor,
              border: Border.all(color: _blackColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: _blackColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptionKanan(
      String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _secondaryColor,
              border: Border.all(color: _blackColor, width: 3),
              shape: BoxShape.circle,
              boxShadow: [_lightShadow],
            ),
            child: Icon(
              icon,
              color: _primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _yellowColor,
              border: Border.all(color: _blackColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: _blackColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem(String label, String date) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: _blackColor,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _yellowColor,
            border: Border.all(color: _blackColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            date,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _blackColor,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}