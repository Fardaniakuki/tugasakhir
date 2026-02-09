import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../login/login_screen.dart';

class WaliKelasProfilePage extends StatefulWidget {
  const WaliKelasProfilePage(
      {super.key, required String namaWaliKelas, required String kelasWali});

  @override
  State<WaliKelasProfilePage> createState() => _WaliKelasProfilePageState();
}

class _WaliKelasProfilePageState extends State<WaliKelasProfilePage> {
  static const Color _primaryColor = Color(0xFF6B1B1B);
  static const Color _accentColor = Color(0xFF9F0712);
  static const Color _lightColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _borderColor = Color(0xFFE0E0E0);

  // Data guru yang sedang login
  Map<String, dynamic> _guruData = {
    'nama': 'WALI KELAS',
    'kode_guru': '-',
    'nip': '-',
    'no_telp': '-',
    'kelas_wali': '-',
    'jurusan': '-',
  };

  bool _isLoading = true;
  bool _isEditing = false;

  // Controller untuk form edit
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _kodeGuruController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _telpController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadGuruData();
  }

  Future<void> _loadGuruData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      print('📥 Loading guru data for Wali Kelas...');

      // Debug: print semua keys untuk melihat data apa yang tersimpan
      final allKeys = prefs.getKeys();
      print('🔑 SEMUA DATA DI SHAREDPREFERENCES:');
      for (final key in allKeys) {
        print('   $key: ${prefs.get(key)}');
      }

      // Ambil ID dari SharedPreferences - ini adalah "id" dari response API
      final int? guruId =
          prefs.getInt('user_id'); // user_id di SharedPreferences = id di API
      print('🔍 ID guru dari SharedPreferences (user_id): $guruId');

      if (guruId == null || guruId == 0) {
        print('❌ ID guru tidak ditemukan atau 0');
        // Fallback ke data dari SharedPreferences
        _loadGuruFromSharedPrefs(prefs);
        return;
      }

      // Ambil data guru dari API menggunakan id
      await _loadGuruFromAPI(guruId, prefs);
    } catch (e) {
      print('❌ Error loading guru data: $e');
      print('Stack trace: $e');

      setState(() {
        _guruData = {
          'nama': 'WALI KELAS',
          'kode_guru': '-',
          'nip': '-',
          'no_telp': '-',
          'kelas_wali': '-',
          'jurusan': '-',
          'id': 0,
        };
        _isLoading = false;
      });
    }
  }

// Fungsi untuk mengambil data guru dari API
  Future<void> _loadGuruFromAPI(int guruId, SharedPreferences prefs) async {
    try {
      await dotenv.load(fileName: '.env');
      final token = prefs.getString('access_token');

      if (token == null) {
        print('❌ Token tidak ditemukan');
        _loadGuruFromSharedPrefs(prefs);
        return;
      }

      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';

      print('🔄 Fetching data guru dari API...');
      print('   URL: $baseUrl/api/guru/$guruId');
      print('   Menggunakan ID: $guruId');

      final response = await http.get(
        Uri.parse('$baseUrl/api/guru/$guruId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📋 Response body: $data');

        if (data['success'] == true && data['data'] != null) {
          final guruData = data['data'] as Map<String, dynamic>;
          print('✅ Data guru berhasil diambil dari API');

          // Debug: print semua data yang diterima
          print('📋 DETAIL DATA GURU DARI API:');
          print('   id: ${guruData['id']}');
          print('   user_id: ${guruData['user_id']}');
          print('   kode_guru: ${guruData['kode_guru']}');
          print('   nip: ${guruData['nip']}');
          print('   nama: ${guruData['nama']}');
          print('   no_telp: ${guruData['no_telp']}');
          print('   is_wali_kelas: ${guruData['is_wali_kelas']}');
          print('   is_koordinator: ${guruData['is_koordinator']}');
          print('   is_pembimbing: ${guruData['is_pembimbing']}');
          print('   is_kaprog: ${guruData['is_kaprog']}');

          // Ambil data kelas wali
          final kelasWali = await _fetchKelasWali(guruId);

          setState(() {
            _guruData = {
              'nama':
                  (guruData['nama'] ?? 'WALI KELAS').toString().toUpperCase(),
              'kode_guru': guruData['kode_guru']?.toString() ?? '-',
              'nip': guruData['nip']?.toString() ?? '-',
              'no_telp': guruData['no_telp']?.toString() ?? '-',
              'kelas_wali': kelasWali['nama_kelas'] ?? '-',
              'jurusan': kelasWali['jurusan'] ?? '-',
              'id': guruData['id'], // ID dari API (39)
              'user_id': guruData['user_id'], // user_id dari API (69)
              'is_wali_kelas': guruData['is_wali_kelas'] ?? false,
              'is_koordinator': guruData['is_koordinator'] ?? false,
              'is_pembimbing': guruData['is_pembimbing'] ?? false,
              'is_kaprog': guruData['is_kaprog'] ?? false,
            };
            _isLoading = false;
          });

          // Set controller untuk form edit
          _namaController.text = guruData['nama']?.toString() ?? '';
          _kodeGuruController.text = guruData['kode_guru']?.toString() ?? '';
          _nipController.text = guruData['nip']?.toString() ?? '';
          _telpController.text = guruData['no_telp']?.toString() ?? '';

          // Simpan ke SharedPreferences untuk cache
          await _saveGuruToSharedPrefs(prefs, guruData, guruId);

          print('\n✅ DATA GURU YANG DIPAKAI:');
          print('   Nama: ${_guruData['nama']}');
          print('   Kode: ${_guruData['kode_guru']}');
          print('   NIP: ${_guruData['nip']}');
          print('   Telp: ${_guruData['no_telp']}');
          print('   Kelas Wali: ${_guruData['kelas_wali']}');
          print('   Jurusan: ${_guruData['jurusan']}');
          print('   ID: ${_guruData['id']}');
          print('   User ID: ${_guruData['user_id']}');
          print('   Is Wali Kelas: ${_guruData['is_wali_kelas']}');
        } else {
          print('❌ Response tidak valid atau success = false');
          _loadGuruFromSharedPrefs(prefs);
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        print('   Response body: ${response.body}');
        _loadGuruFromSharedPrefs(prefs);
      }
    } catch (e) {
      print('❌ Error fetching guru from API: $e');
      print('Stack trace: $e');
      _loadGuruFromSharedPrefs(prefs);
    }
  }

// Fungsi untuk mengambil data dari SharedPreferences (fallback)
  void _loadGuruFromSharedPrefs(SharedPreferences prefs) {
    print('🔄 Menggunakan data dari SharedPreferences sebagai fallback');

    // Ambil data dari berbagai kemungkinan key
    final String? userName = prefs.getString('user_name');
    final String? kodeGuru = prefs.getString('kode_guru');
    final String? userNip = prefs.getString('user_nip');
    final String? userPhone = prefs.getString('user_phone');

    final String nama = userName ?? 'WALI KELAS';
    final String kode = kodeGuru ?? '-';
    final String nip = userNip ?? '-';
    final String telp = userPhone ?? '-';
    final int? id = prefs.getInt('user_id');

    // Set controller untuk form edit
    _namaController.text = nama;
    _kodeGuruController.text = kode;
    _nipController.text = nip;
    _telpController.text = telp;

    setState(() {
      _guruData = {
        'nama': nama.toUpperCase(),
        'kode_guru': kode,
        'nip': nip,
        'no_telp': telp,
        'kelas_wali': '-', // Akan diupdate nanti
        'jurusan': '-', // Akan diupdate nanti
        'id': id ?? 0,
      };
      _isLoading = false;
    });
  }

// Fungsi untuk menyimpan data guru ke SharedPreferences
  Future<void> _saveGuruToSharedPrefs(SharedPreferences prefs,
      Map<String, dynamic> guruData, int guruId) async {
    try {
      // Simpan data utama
      await prefs.setString('user_name', guruData['nama']?.toString() ?? '');
      await prefs.setString(
          'kode_guru', guruData['kode_guru']?.toString() ?? '');
      await prefs.setString('user_nip', guruData['nip']?.toString() ?? '');
      await prefs.setString(
          'user_phone', guruData['no_telp']?.toString() ?? '');

      // Simpan ID - simpan sebagai user_id (untuk kompatibilitas dengan login)
      await prefs.setInt('user_id', guruId); // id dari API

      // Simpan juga sebagai id jika ada
      if (guruData['id'] != null) {
        await prefs.setInt('guru_id', guruData['id']!);
      }

      // Simpan user_id dari API jika ada
      if (guruData['user_id'] != null) {
        await prefs.setInt('api_user_id', guruData['user_id']!);
      }

      // Simpan status roles
      if (guruData['is_wali_kelas'] != null) {
        await prefs.setBool('is_wali_kelas', guruData['is_wali_kelas']!);
      }
      if (guruData['is_koordinator'] != null) {
        await prefs.setBool('is_koordinator', guruData['is_koordinator']!);
      }
      if (guruData['is_pembimbing'] != null) {
        await prefs.setBool('is_pembimbing', guruData['is_pembimbing']!);
      }
      if (guruData['is_kaprog'] != null) {
        await prefs.setBool('is_kaprog', guruData['is_kaprog']!);
      }

      print('💾 Data guru disimpan ke SharedPreferences');
      print('   user_id (untuk API calls): $guruId');
      print('   id dari API: ${guruData['id']}');
      print('   user_id dari API: ${guruData['user_id']}');
    } catch (e) {
      print('❌ Error saving guru to SharedPreferences: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchKelasWali(int? guruId) async {
    if (guruId == null || guruId == 0) {
      print('⚠️ Guru ID tidak valid untuk mencari kelas wali');
      return {'nama_kelas': '-', 'jurusan': '-'};
    }

    try {
      await dotenv.load(fileName: '.env');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        print('❌ Token tidak ditemukan untuk fetch kelas wali');
        return {'nama_kelas': '-', 'jurusan': '-'};
      }

      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';

      // Ambil semua kelas
      print('🔄 Fetching data kelas dari API untuk mencari wali kelas...');
      final response = await http.get(
        Uri.parse('$baseUrl/api/kelas?limit=100'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('📊 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true &&
            data['data'] != null &&
            data['data'] is Map) {
          final kelasData = data['data'] as Map<String, dynamic>;
          final List<dynamic> kelasList = kelasData['data'] ?? [];

          print('   Total kelas: ${kelasList.length}');
          print('   Mencari kelas dengan wali_kelas_guru_id: $guruId');

          // Cari kelas yang memiliki wali_kelas_guru_id sesuai dengan guruId
          for (final kelas in kelasList) {
            final int? waliId = kelas['wali_kelas_guru_id'] != null
                ? int.tryParse(kelas['wali_kelas_guru_id'].toString())
                : null;

            if (waliId == guruId) {
              print('   ✅ Kelas ditemukan: ${kelas['nama']}');

              final String namaKelas = kelas['nama'] ?? '-';
              final int? jurusanId = kelas['jurusan_id'];
              String jurusan = '-';

              // Ambil nama jurusan jika ada
              if (jurusanId != null) {
                print('   🔍 Mengambil nama jurusan ID: $jurusanId');
                jurusan = await _fetchJurusanName(jurusanId, token);
              }

              return {
                'nama_kelas': namaKelas,
                'jurusan': jurusan,
              };
            }
          }

          print('   ❌ Tidak ada kelas dengan wali_kelas_guru_id: $guruId');

          // Debug: Print beberapa kelas untuk pemeriksaan
          print('   📋 Beberapa data kelas:');
          for (int i = 0;
              i < (kelasList.length > 5 ? 5 : kelasList.length);
              i++) {
            final kelas = kelasList[i];
            final int? waliId = kelas['wali_kelas_guru_id'] != null
                ? int.tryParse(kelas['wali_kelas_guru_id'].toString())
                : null;
            print('      [${i + 1}] ${kelas['nama']} - Wali ID: $waliId');
          }
        } else {
          print('   ❌ Response tidak valid atau success = false');
        }
      } else {
        print('   ❌ HTTP Error: ${response.statusCode}');
      }

      return {'nama_kelas': '-', 'jurusan': '-'};
    } catch (e) {
      print('❌ Error fetching kelas wali: $e');
      return {'nama_kelas': '-', 'jurusan': '-'};
    }
  }

  // Fungsi untuk mengambil nama jurusan berdasarkan ID
  Future<String> _fetchJurusanName(int jurusanId, String token) async {
    try {
      await dotenv.load(fileName: '.env');
      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';

      final response = await http.get(
        Uri.parse('$baseUrl/api/jurusan/$jurusanId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final jurusanData = data['data'] as Map<String, dynamic>;
          return jurusanData['nama'] ?? '-';
        }
      }
    } catch (e) {
      print('❌ Error fetching jurusan: $e');
    }

    return '-';
  }

  Future<void> _updateGuruData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await dotenv.load(fileName: '.env');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      print('🔍 DEBUG UPDATE GURU DATA:');
      print('   Token exists: ${token != null}');
      print('   Data yang akan dikirim:');
      print('     Nama: ${_namaController.text.trim()}');
      print('     Kode: ${_kodeGuruController.text.trim()}');
      print('     NIP: ${_nipController.text.trim()}');
      print('     Telp: ${_telpController.text.trim()}');

      if (token == null) {
        _showErrorDialog('Token tidak ditemukan');
        return;
      }

      // Tampilkan loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              color: _primaryColor,
            ),
          ),
        );
      }

      // Data yang akan dikirim sesuai dengan dokumentasi API
      final Map<String, dynamic> requestData = {
        'kode_guru': _kodeGuruController.text.trim(),
        'nama': _namaController.text.trim(),
        'nip': _nipController.text.trim().isNotEmpty
            ? _nipController.text.trim()
            : null,
        'no_telp': _telpController.text.trim(),
      };

      // Hapus field yang null
      requestData.removeWhere((key, value) => value == null);

      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final url = Uri.parse('$baseUrl/api/guru/me');

      print('🔄 Updating guru data...');
      print('   URL: $url');
      print('   Request data: $requestData');
      print('   Headers: Authorization: Bearer ${token.substring(0, 20)}...');

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      // Tutup loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      print('📤 Response status: ${response.statusCode}');
      print('📤 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          print('✅ Update berhasil!');

          // Update data lokal
          final updatedData = data['data'] as Map<String, dynamic>;

          print('📋 Data yang diupdate dari API:');
          print('   Nama: ${updatedData['nama']}');
          print('   Kode: ${updatedData['kode_guru']}');
          print('   NIP: ${updatedData['nip']}');
          print('   Telp: ${updatedData['no_telp']}');

          setState(() {
            _guruData['nama'] =
                (updatedData['nama'] ?? _namaController.text.trim())
                    .toString()
                    .toUpperCase();
            _guruData['kode_guru'] =
                updatedData['kode_guru'] ?? _kodeGuruController.text.trim();
            _guruData['nip'] = updatedData['nip'] ?? _nipController.text.trim();
            _guruData['no_telp'] =
                updatedData['no_telp'] ?? _telpController.text.trim();
            _isEditing = false;
          });

          // Update SharedPreferences
          await prefs.setString('user_name', _guruData['nama']);
          await prefs.setString('kode_guru', _guruData['kode_guru']);
          await prefs.setString('user_nip', _guruData['nip']);
          await prefs.setString('user_phone', _guruData['no_telp']);
          await prefs.setString('guru_nama', _guruData['nama']);
          await prefs.setString('guru_kode_guru', _guruData['kode_guru']);
          await prefs.setString('guru_nip', _guruData['nip']);
          await prefs.setString('guru_no_telp', _guruData['no_telp']);

          _showSuccessDialog('Data berhasil diperbarui');
        } else {
          final errorMsg =
              data['message'] ?? data['error'] ?? 'Gagal memperbarui data';
          print('❌ Update gagal: $errorMsg');
          _showErrorDialog(errorMsg.toString());
        }
      } else if (response.statusCode == 422) {
        // Validation error
        try {
          final errorData = jsonDecode(response.body);
          final errors = errorData['errors'] ?? {};
          String errorMessage = 'Validasi gagal:\n';

          errors.forEach((key, value) {
            if (value is List) {
              errorMessage += '• $key: ${value.join(', ')}\n';
            }
          });

          print('❌ Validation error: $errorMessage');
          _showErrorDialog(errorMessage);
        } catch (e) {
          _showErrorDialog(
              'Terjadi kesalahan validasi: ${response.statusCode}');
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['message'] ??
              errorData['error'] ??
              'Terjadi kesalahan: ${response.statusCode}';
          print('❌ HTTP Error: $errorMsg');
          _showErrorDialog(errorMsg.toString());
        } catch (e) {
          _showErrorDialog(
              'Terjadi kesalahan: ${response.statusCode}\n${response.body}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
      }
      print('❌ Exception during update: $e');
      _showErrorDialog('Terjadi kesalahan: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Sukses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Data Profil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textColor,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(height: 16),

          // Nama
          TextFormField(
            controller: _namaController,
            decoration: InputDecoration(
              labelText: 'Nama',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Kode Guru
          TextFormField(
            controller: _kodeGuruController,
            decoration: InputDecoration(
              labelText: 'Kode Guru',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kode guru tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // NIP - NON EDITABLE (READ ONLY)
          TextFormField(
            controller: _nipController,
            enabled: false, // Ini yang membuatnya non-editable
            decoration: InputDecoration(
              labelText: 'NIP',
              labelStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 1),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          // No Telepon
          TextFormField(
            controller: _telpController,
            decoration: InputDecoration(
              labelText: 'No. Telepon',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'No. Telepon tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Tombol Simpan & Batal
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                    // Reset ke data awal
                    _namaController.text = _guruData['nama'];
                    _kodeGuruController.text = _guruData['kode_guru'];
                    _nipController.text = _guruData['nip'];
                    _telpController.text = _guruData['no_telp'];
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: _textColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _updateGuruData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _borderColor),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightColor,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: _primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Profil Wali Kelas',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (!_isLoading && _guruData['id'] != 0 && !_isEditing)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      icon: const Icon(
                        Icons.edit,
                        color: _primaryColor,
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    // Profile Section
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _primaryColor,
                              border: Border.all(
                                color: _borderColor,
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.people,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _isLoading
                              ? _buildProfileSkeleton()
                              : Column(
                                  children: [
                                    Text(
                                      _guruData['nama']!,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: _textColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    // Role badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withValues(
                                            alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _primaryColor.withValues(
                                              alpha: 0.3),
                                        ),
                                      ),
                                      child: const Text(
                                        'WALI KELAS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),

                    // Data Detail Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _borderColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isEditing)
                            _buildEditForm()
                          else ...[
                            const Text(
                              'Data Profil',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: _borderColor),
                            const SizedBox(height: 16),

                            // Kelas Wali
                            _buildDetailItem(
                                'Kelas Wali', _guruData['kelas_wali']!),
                            const SizedBox(height: 12),
                            _buildDetailItem(
                                'Konsetrasi Keahlian', _guruData['jurusan']!),
                            const SizedBox(height: 12),
                            _buildDetailItem(
                                'Kode Guru', _guruData['kode_guru']!),
                            const SizedBox(height: 12),
                            _buildDetailItem('NIP', _guruData['nip']!),
                            const SizedBox(height: 12),
                            _buildDetailItem(
                                'No. Telepon', _guruData['no_telp']!),
                          ],
                        ],
                      ),
                    ),

                    // Menu Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _borderColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Menu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: _borderColor),
                          const SizedBox(height: 16),
                          _buildMenuTile(
                            icon: Icons.help_outline,
                            title: 'Bantuan & Panduan',
                            subtitle: 'Cara menggunakan aplikasi',
                            onTap: () => _showUnderDevelopment(
                                'Bantuan & Panduan', context),
                          ),
                          const SizedBox(height: 12),
                          _buildMenuTile(
                            icon: Icons.info_outline,
                            title: 'Tentang Aplikasi',
                            subtitle: 'Informasi aplikasi',
                            onTap: () => _showAboutDialog(context),
                          ),
                        ],
                      ),
                    ),

                    // Logout Button dengan jarak
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _logout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                                color: _accentColor, width: 1.5),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Keluar dari Aplikasi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // TAMBAH JARAK KE BAWAH
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSkeleton() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  void _showUnderDevelopment(String featureName, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.construction, color: _primaryColor),
            SizedBox(width: 8),
            Text(
              'Fitur dalam Pengembangan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
          ],
        ),
        content: Text(
          '$featureName sedang dalam tahap pengembangan dan akan segera hadir.',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.info, color: _primaryColor),
            SizedBox(width: 8),
            Text(
              'Tentang Aplikasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SISFO PKL - WALI KELAS',
              style: TextStyle(
                fontSize: 16,
                color: _primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Versi: 1.0.0\nBuild: 2024.01',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aplikasi untuk pengelolaan dan monitoring siswa PKL bagi Wali Kelas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Konfirmasi Logout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.exit_to_app,
              size: 48,
              color: _accentColor,
            ),
            SizedBox(height: 16),
            Text(
              'Yakin ingin keluar dari aplikasi?',
              style: TextStyle(
                fontSize: 16,
                color: _textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Anda perlu login kembali untuk masuk',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: _textColor,
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: CircularProgressIndicator(
              color: _primaryColor,
            ),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      await _processLogout();

      if (context.mounted) {
        Navigator.pop(context);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _processLogout() async {
    print('🔄 Processing logout for Wali Kelas...');

    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('user_name');

    print('👤 Current username: $currentUsername');

    // Hapus semua data login
    print('🗑️ Removing all login data...');
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      // Hapus semua kecuali notifications
      if (!key.startsWith('notifications_')) {
        await prefs.remove(key);
        print('   Removed: $key');
      }
    }

    print('✅ Logout completed successfully');
    print('   - User: ${currentUsername ?? 'unknown_user'}');
    print('   - Role: Wali Kelas');
    print('   - All login data: REMOVED');
    print('   - Notifications: PRESERVED');
  }
}
