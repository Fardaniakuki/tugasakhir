import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../login/login_screen.dart';

// ========== THEME CONFIGURATION ==========
class PengaturanTheme {
  static const Color primaryRed = Color(0xFFB41004);
  static const Color primaryDark = Color(0xFF8A0C03);
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF2D3748);
  static const Color textGrey = Color(0xFF718096);
  static const Color border = Color(0xFFE2E8F0);
  static const Color error = Color(0xFFE53E3E);
}

class SiswaPengaturan extends StatefulWidget {
  const SiswaPengaturan({super.key});

  @override
  State<SiswaPengaturan> createState() => _SiswaPengaturanState();
}

class _SiswaPengaturanState extends State<SiswaPengaturan> {
  // --- Variabel Data Siswa ---
  String _namaSiswa = 'Memuat...';
  String _nisnSiswa = '-';
  String _kelasSiswa = '-';
  String _jurusanSiswa = '-';
  String _role = 'Siswa';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // ======================================================================
  // ==================== LOGIKA PENGAMBILAN DATA =========================
  // ======================================================================

  // Helper untuk mencari NISN yang valid dari berbagai key
  String _getSafeNisn(Map<String, dynamic> data) {
    if (data['nisn'] != null &&
        data['nisn'].toString().isNotEmpty &&
        data['nisn'].toString() != 'null') {
      return data['nisn'].toString();
    }
    if (data['nis'] != null &&
        data['nis'].toString().isNotEmpty &&
        data['nis'].toString() != 'null') {
      return data['nis'].toString();
    }
    if (data['nomor_induk'] != null &&
        data['nomor_induk'].toString().isNotEmpty) {
      return data['nomor_induk'].toString();
    }
    // Fallback ke username jika username adalah NISN
    if (data['username'] != null &&
        RegExp(r'^[0-9]+$').hasMatch(data['username'].toString())) {
      return data['username'].toString();
    }
    return '-';
  }
// GANTI method _loadProfileData() dengan yang berikut:

Future<void> _loadProfileData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userName = prefs.getString('user_name');

    // Set Role & Nama Awal dari Cache
    setState(() {
      _role = prefs.getString('user_role') ?? 'Siswa';
      _namaSiswa = userName ?? 'Siswa';
    });

    if (token == null || userName == null) {
      await _loadFromSharedPrefs();
      return;
    }

    // 1. AMBIL DATA SISWA BERDASARKAN NAMA DENGAN SEARCH PARAMETER
    await dotenv.load();
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
    
    // Gunakan search parameter untuk mencari siswa berdasarkan nama
    final siswaUrl = Uri.parse('$baseUrl/api/siswa').replace(
      queryParameters: {
        'search': userName, // Search by username from login
        'limit': '10', // Limit results
      },
    );

    print('DEBUG: Request ke $siswaUrl');

    final siswaResponse = await http.get(
      siswaUrl,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (siswaResponse.statusCode == 200) {
      final dynamic responseData = jsonDecode(siswaResponse.body);
      
      if (responseData['success'] == true && responseData['data'] != null) {
        final dynamic data = responseData['data'];
        
        if (data is Map && data['data'] is List) {
          final List<dynamic> siswaList = data['data'];
          
          // Debug: Tampilkan semua siswa yang ditemukan
          print('DEBUG: Jumlah siswa ditemukan: ${siswaList.length}');
          
          if (siswaList.isNotEmpty) {
            // Ambil siswa pertama (karena search sudah spesifik)
            final siswaMap = _convertToStringMap(siswaList[0] as Map);
            
            // --- DEBUGGING: Cek Key Data di Console ---
            print('=== DATA SISWA DITEMUKAN ===');
            siswaMap.forEach((key, value) {
              print('$key: $value');
            });
            // ------------------------------------------

            final String extractedNisn = _getSafeNisn(siswaMap);
            final String nama = siswaMap['nama_lengkap']?.toString() ?? userName;

            // Ambil kelas_id untuk mendapatkan data kelas dan jurusan
            final int? kelasId = int.tryParse(siswaMap['kelas_id']?.toString() ?? '');

            if (mounted) {
              setState(() {
                _namaSiswa = nama.toUpperCase();
                _nisnSiswa = extractedNisn;
              });
            }

            // Simpan ke cache
            await prefs.setString('siswa_nama_lengkap', nama);
            await prefs.setString('siswa_nisn', extractedNisn);
            if (kelasId != null) {
              await prefs.setInt('siswa_kelas_id', kelasId);
            }

            // 2. AMBIL DETAIL KELAS & JURUSAN
            if (kelasId != null) {
              await _fetchKelasAndJurusan(token, kelasId, prefs);
            } else {
              // Jika tidak ada kelas_id, set default
              if (mounted) {
                setState(() {
                  _kelasSiswa = '-';
                  _jurusanSiswa = '-';
                });
              }
              await prefs.setString('siswa_kelas_nama', '-');
              await prefs.setString('siswa_jurusan_nama', '-');
            }
            
          } else {
            print('DEBUG: Siswa tidak ditemukan dengan nama: $userName');
            await _loadFromSharedPrefs();
          }
        }
      }
    } else {
      print('DEBUG: API Error ${siswaResponse.statusCode}');
      await _loadFromSharedPrefs();
    }
  } catch (e) {
    print('ERROR: $e');
    await _loadFromSharedPrefs();
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

// GANTI method _fetchKelasAndJurusan dengan yang berikut:

Future<void> _fetchKelasAndJurusan(
  String token, 
  int kelasId, 
  SharedPreferences prefs
) async {
  try {
    String kelasNama = '-';
    String jurusanNama = '-';

    // --- FETCH KELAS BERDASARKAN ID ---
    await dotenv.load();
    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
    final kelasUrl = '$baseUrl/api/kelas/$kelasId';
    
    print('DEBUG: Fetch kelas dari: $kelasUrl');
    
    final kelasResponse = await http.get(
      Uri.parse(kelasUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (kelasResponse.statusCode == 200) {
      final dynamic kelasData = jsonDecode(kelasResponse.body);
      if (kelasData['success'] == true && kelasData['data'] is Map) {
        final kelasMap = _convertToStringMap(kelasData['data'] as Map);
        kelasNama = kelasMap['nama'] ?? '-';
        
        print('DEBUG: Kelas ditemukan: $kelasNama');
        
        // --- FETCH JURUSAN BERDASARKAN jurusan_id ---
        final int? jurusanId = int.tryParse(kelasMap['jurusan_id']?.toString() ?? '');
        
        if (jurusanId != null) {
          final jurusanUrl = '$baseUrl/api/jurusan/$jurusanId';
          print('DEBUG: Fetch jurusan dari: $jurusanUrl');
          
          final jurusanResponse = await http.get(
            Uri.parse(jurusanUrl),
            headers: {'Authorization': 'Bearer $token'},
          );

          if (jurusanResponse.statusCode == 200) {
            final jData = jsonDecode(jurusanResponse.body);
            if (jData['success'] == true && jData['data'] is Map) {
              final jMap = _convertToStringMap(jData['data'] as Map);
              jurusanNama = jMap['nama'] ?? '-';
              print('DEBUG: Jurusan ditemukan: $jurusanNama');
            }
          } else {
            print('DEBUG: Jurusan API Error ${jurusanResponse.statusCode}');
          }
        } else {
          print('DEBUG: Jurusan ID tidak ditemukan di data kelas');
        }
      }
    } else {
      print('DEBUG: Kelas API Error ${kelasResponse.statusCode}');
    }

    if (mounted) {
      setState(() {
        _kelasSiswa = kelasNama;
        _jurusanSiswa = jurusanNama;
      });
    }

    await prefs.setString('siswa_kelas_nama', kelasNama);
    await prefs.setString('siswa_jurusan_nama', jurusanNama);

  } catch (e) {
    print('Error fetching detail: $e');
  }
}

// TAMBAHKAN method ini untuk mencoba endpoint alternatif jika ada:


  Future<void> _loadFromSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // Coba cari NISN di cache dengan berbagai key
    String? cachedNisn = prefs.getString('siswa_nisn');
    if (cachedNisn == null) {
      for (var key in prefs.getKeys()) {
        if (key.toLowerCase().contains('nis')) {
          final val = prefs.getString(key);
          if (val != null && val.isNotEmpty) {
            cachedNisn = val;
            break;
          }
        }
      }
    }

    setState(() {
      _namaSiswa = prefs.getString('siswa_nama_lengkap') ??
          prefs.getString('user_name') ??
          'Siswa';
      _kelasSiswa = prefs.getString('siswa_kelas_nama') ?? '-';
      _jurusanSiswa = prefs.getString('siswa_jurusan_nama') ?? '-';
      _nisnSiswa = cachedNisn ?? '-';
      _isLoading = false;
    });
  }

  Map<String, dynamic> _convertToStringMap(Map<dynamic, dynamic> map) {
    final Map<String, dynamic> result = {};
    map.forEach((key, value) {
      result[key.toString()] = value;
    });
    return result;
  }

  // ======================================================================
  // ======================== LOGIKA LOGOUT ===============================
  // ======================================================================

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    // Hapus data login
    await prefs.remove('access_token');
    await prefs.remove('user_id');
    await prefs.clear();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: PengaturanTheme.textGrey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PengaturanTheme.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ======================================================================
  // ============================ TAMPILAN UI =============================
  // ======================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PengaturanTheme.background,
      body: Stack(
        children: [
          // 1. HEADER BACKGROUND GRADIENT
          _buildHeaderBackground(),

          // 2. CONTENT
          SafeArea(
            child: Column(
              children: [
                _buildCustomAppBar(),
                _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Center(
                            child:
                                CircularProgressIndicator(color: Colors.white)),
                      )
                    : _buildProfileHeader(),
                const SizedBox(height: 24),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: PengaturanTheme.background,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: Column(
                        children: [
                          _buildSectionLabel('APLIKASI'),
                          _buildSettingsGroup([
                            _buildSettingItem(
                              icon: Icons.notifications_none_rounded,
                              title: 'Notifikasi',
                              onTap: () {},
                            ),
                            _buildSettingItem(
                              icon: Icons.help_outline_rounded,
                              title: 'Bantuan & Dukungan',
                              onTap: () {},
                            ),
                            _buildSettingItem(
                              icon: Icons.info_outline_rounded,
                              title: 'Tentang Aplikasi',
                              subtitle: 'Versi 1.0.0',
                              showDivider: false,
                              onTap: () {},
                            ),
                          ]),
                          const SizedBox(height: 32),
                          _buildLogoutButton(),
                          const SizedBox(height: 20),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground() {
    return Container(
      height: 300,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [PengaturanTheme.primaryRed, PengaturanTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Pengaturan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _namaSiswa.isNotEmpty ? _namaSiswa[0].toUpperCase() : 'S',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: PengaturanTheme.primaryRed,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _namaSiswa,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _jurusanSiswa != '-' && _jurusanSiswa != 'null'
                        ? '$_kelasSiswa • $_jurusanSiswa'
                        : '$_role • $_kelasSiswa',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'NISN: $_nisnSiswa',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: PengaturanTheme.textGrey,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: PengaturanTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: PengaturanTheme.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        Icon(icon, color: PengaturanTheme.primaryRed, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: PengaturanTheme.textDark,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: PengaturanTheme.textGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: PengaturanTheme.textGrey),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            indent: 60,
            endIndent: 0,
            color: PengaturanTheme.border,
          ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: PengaturanTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showLogoutDialog,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: PengaturanTheme.error),
                SizedBox(width: 8),
                Text(
                  'Keluar Akun',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: PengaturanTheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
