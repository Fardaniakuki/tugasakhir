import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../login/login_screen.dart';

class SiswaPengaturan extends StatefulWidget {
  const SiswaPengaturan({super.key});

  @override
  State<SiswaPengaturan> createState() => _SiswaPengaturanState();
}

class _SiswaPengaturanState extends State<SiswaPengaturan> {
  // Warna-warna profesional untuk siswa
  static const Color _primaryColor = Color(0xFF9f0712); // Merah utama siswa
  static const Color _accentColor = Color(0xFF8B0000); // Merah lebih gelap
  static const Color _lightColor = Color(0xFFF5F5F5); // Abu-abu muda
  static const Color _textColor = Color(0xFF333333); // Teks gelap
  static const Color _borderColor = Color(0xFFE0E0E0); // Border abu-abu muda

  Map<String, String> _profileData = {
    'nama': 'SISWA',
    'nisn': '-',
    'kelas': '-',
    'jurusan': '-'
  };
  bool _isLoading = true;
  String _debugInfo = '';
  int? _siswaId; // Untuk menyimpan ID siswa

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final userId = prefs.getInt('user_id');
      final userName = prefs.getString('user_name');

      print('=== DEBUG: LOAD PROFILE START ===');
      print('Token: ${token != null ? "Ada" : "Tidak ada"}');
      print('User ID: $userId');
      print('User Name: $userName');
      
      // Print semua keys di SharedPreferences untuk debugging
      final allKeys = prefs.getKeys();
      print('All SharedPreferences Keys: ${allKeys.join(', ')}');
      
      // Print semua data di SharedPreferences
      for (var key in allKeys) {
        final value = prefs.get(key);
        print('$key: $value');
      }
      
      _debugInfo = 'Memulai load profile siswa...\n';
      
      if (token == null) {
        print('ERROR: Token tidak ditemukan');
        _debugInfo += 'Token tidak ditemukan\n';
        await _loadFromSharedPrefs();
        return;
      }

      if (userId == null) {
        print('ERROR: User ID tidak ditemukan');
        _debugInfo += 'User ID tidak ditemukan\n';
        await _loadFromSharedPrefs();
        return;
      }

      if (userName == null || userName.isEmpty) {
        print('WARNING: User name tidak ditemukan atau kosong');
        _debugInfo += 'User name tidak ditemukan\n';
      }

      _debugInfo += 'User ID: $userId\n';
      _debugInfo += 'User Name: $userName\n';

      // Langkah 1: Ambil data siswa dari endpoint /api/siswa
      try {
        final siswaUrl = '${dotenv.env['API_BASE_URL']}/api/siswa';
        print('DEBUG: Fetching siswa dari: $siswaUrl');
        _debugInfo += 'Fetching semua siswa data from: $siswaUrl\n';
        
        final siswaResponse = await http.get(
          Uri.parse(siswaUrl),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        print('DEBUG: Response status: ${siswaResponse.statusCode}');
        print('DEBUG: Response body: ${siswaResponse.body}');
        
        if (siswaResponse.statusCode == 200) {
          final dynamic responseData = jsonDecode(siswaResponse.body);
          
          print('DEBUG: Response success: ${responseData['success']}');
          
          if (responseData['success'] == true && responseData['data'] != null) {
            final dynamic data = responseData['data'];
            
            if (data is Map && data['data'] is List) {
              final List<dynamic> siswaList = data['data'];
              
              print('DEBUG: Jumlah siswa dalam list: ${siswaList.length}');
              
              // Debug: Print semua nama siswa untuk melihat data
              for (int i = 0; i < siswaList.length; i++) {
                if (siswaList[i] is Map) {
                  final siswaMap = _convertToStringMap(siswaList[i] as Map);
                  final namaSiswa = siswaMap['nama_lengkap']?.toString() ?? 'Tidak ada nama';
                  final nisnSiswa = siswaMap['nisn']?.toString() ?? 'Tidak ada NISN';
                  final kelasId = siswaMap['kelas_id']?.toString() ?? 'Tidak ada kelas_id';
                  print('DEBUG: Siswa[$i]: $namaSiswa | NISN: $nisnSiswa | Kelas ID: $kelasId');
                }
              }
              
              // Cari siswa yang sesuai dengan user_name
              dynamic foundSiswa;
              final String searchName = userName ?? '';
              
              print('DEBUG: Mencari siswa dengan nama: "$searchName"');
              
              if (searchName.isNotEmpty) {
                // Coba cari dengan exact match (case insensitive)
                for (var siswa in siswaList) {
                  if (siswa is Map) {
                    final siswaMap = _convertToStringMap(siswa);
                    final String namaSiswa = siswaMap['nama_lengkap']?.toString() ?? '';
                    
                    if (namaSiswa.isNotEmpty && searchName.isNotEmpty) {
                      print('DEBUG: Comparing "$namaSiswa" with "$searchName"');
                      
                      // Check exact match (case insensitive)
                      if (namaSiswa.toLowerCase() == searchName.toLowerCase()) {
                        foundSiswa = siswa;
                        print('DEBUG: Found exact match: $namaSiswa');
                        break;
                      }
                      
                      // Check partial match (jika nama lengkap mengandung username)
                      if (searchName.toLowerCase().contains(namaSiswa.toLowerCase()) || 
                          namaSiswa.toLowerCase().contains(searchName.toLowerCase())) {
                        foundSiswa = siswa;
                        print('DEBUG: Found partial match: $namaSiswa contains $searchName');
                        break;
                      }
                    }
                  }
                }
              }
              
              // Jika tidak ditemukan dengan nama, coba ambil siswa pertama (untuk testing)
              if (foundSiswa == null && siswaList.isNotEmpty) {
                print('WARNING: Tidak menemukan siswa dengan nama "$searchName", mengambil siswa pertama');
                foundSiswa = siswaList[0];
              }
              
              if (foundSiswa != null) {
                final siswaMap = _convertToStringMap(foundSiswa as Map);
                _siswaId = int.tryParse(siswaMap['id']?.toString() ?? '');
                
                print('DEBUG: Found siswa ID: $_siswaId');
                print('DEBUG: Siswa data:');
                siswaMap.forEach((key, value) {
                  print('  $key: $value');
                });
                
                _debugInfo += 'Found siswa with ID: $_siswaId\n';
                
                // Langkah 2: Ambil data kelas dan jurusan
                await _fetchKelasAndJurusan(token, siswaMap, prefs);
                return;
              } else {
                print('ERROR: Siswa tidak ditemukan dalam list');
                _debugInfo += 'Siswa not found in list. Total siswa: ${siswaList.length}\n';
                _debugInfo += 'User name from prefs: $userName\n';
              }
            } else {
              print('ERROR: Format response tidak valid');
              _debugInfo += 'Invalid response format\n';
            }
          } else {
            print('ERROR: Response tidak success');
            _debugInfo += 'API response not successful\n';
          }
        } else {
          print('ERROR: API gagal dengan status ${siswaResponse.statusCode}');
          _debugInfo += 'Siswa API failed: ${siswaResponse.statusCode}\n';
        }
      } catch (e) {
        print('ERROR: Exception saat fetch siswa: $e');
        _debugInfo += 'Siswa API Error: $e\n';
      }
      
      // Fallback ke SharedPreferences
      print('INFO: Fallback ke SharedPreferences');
      _debugInfo += 'Falling back to SharedPreferences\n';
      await _loadFromSharedPrefs();
      
    } catch (e) {
      print('ERROR: General Error: $e');
      _debugInfo += 'General Error: $e\n';
      await _loadFromSharedPrefs();
    } finally {
      setState(() {
        _isLoading = false;
      });
      
      print('=== DEBUG INFO FINAL ===');
      print(_debugInfo);
      print('=== END DEBUG ===');
    }
  }

  Future<void> _fetchKelasAndJurusan(
    String token, 
    Map<String, dynamic> siswaMap, 
    SharedPreferences prefs
  ) async {
    try {
      final int? kelasId = int.tryParse(siswaMap['kelas_id']?.toString() ?? '');
      String kelasNama = '-';
      String jurusanNama = '-';
      
      print('DEBUG: Kelas ID dari siswa: $kelasId');
      
      // Ambil data kelas
      if (kelasId != null) {
        final kelasUrl = '${dotenv.env['API_BASE_URL']}/api/kelas';
        print('DEBUG: Fetching kelas dari: $kelasUrl');
        
        final kelasResponse = await http.get(
          Uri.parse(kelasUrl),
          headers: {'Authorization': 'Bearer $token'},
        );
        
        print('DEBUG: Kelas response status: ${kelasResponse.statusCode}');
        
        if (kelasResponse.statusCode == 200) {
          final dynamic kelasData = jsonDecode(kelasResponse.body);
          
          if (kelasData['success'] == true && kelasData['data'] != null) {
            final dynamic data = kelasData['data'];
            
            if (data is Map && data['data'] is List) {
              final List<dynamic> kelasList = data['data'];
              
              print('DEBUG: Jumlah kelas dalam list: ${kelasList.length}');
              
              // Print semua kelas untuk debugging
              for (int i = 0; i < kelasList.length; i++) {
                if (kelasList[i] is Map) {
                  final kelasMap = _convertToStringMap(kelasList[i] as Map);
                  final kelasIdFromList = kelasMap['id']?.toString() ?? 'Tidak ada ID';
                  final kelasNamaFromList = kelasMap['nama']?.toString() ?? 'Tidak ada nama';
                  print('DEBUG: Kelas[$i]: ID=$kelasIdFromList, Nama=$kelasNamaFromList');
                }
              }
              
              // Cari kelas berdasarkan ID
              dynamic foundKelas;
              for (var kelas in kelasList) {
                if (kelas is Map) {
                  final kelasMap = _convertToStringMap(kelas);
                  final int? currentKelasId = int.tryParse(kelasMap['id']?.toString() ?? '');
                  if (currentKelasId == kelasId) {
                    foundKelas = kelas;
                    break;
                  }
                }
              }
              
              if (foundKelas != null) {
                final kelasMap = _convertToStringMap(foundKelas as Map);
                kelasNama = kelasMap['nama']?.toString() ?? '-';
                
                print('DEBUG: Found kelas: $kelasNama');
                
                // Ambil jurusan ID dari kelas
                final int? jurusanId = int.tryParse(kelasMap['jurusan_id']?.toString() ?? '');
                print('DEBUG: Jurusan ID dari kelas: $jurusanId');
                
                // Ambil data jurusan
                if (jurusanId != null) {
                  final jurusanUrl = '${dotenv.env['API_BASE_URL']}/api/jurusan';
                  print('DEBUG: Fetching jurusan dari: $jurusanUrl');
                  
                  final jurusanResponse = await http.get(
                    Uri.parse(jurusanUrl),
                    headers: {'Authorization': 'Bearer $token'},
                  );
                  
                  print('DEBUG: Jurusan response status: ${jurusanResponse.statusCode}');
                  
                  if (jurusanResponse.statusCode == 200) {
                    final dynamic jurusanData = jsonDecode(jurusanResponse.body);
                    
                    if (jurusanData['success'] == true && jurusanData['data'] != null) {
                      final dynamic data = jurusanData['data'];
                      
                      if (data is Map && data['data'] is List) {
                        final List<dynamic> jurusanList = data['data'];
                        
                        print('DEBUG: Jumlah jurusan dalam list: ${jurusanList.length}');
                        
                        // Print semua jurusan untuk debugging
                        for (int i = 0; i < jurusanList.length; i++) {
                          if (jurusanList[i] is Map) {
                            final jurusanMap = _convertToStringMap(jurusanList[i] as Map);
                            final jurusanIdFromList = jurusanMap['id']?.toString() ?? 'Tidak ada ID';
                            final jurusanNamaFromList = jurusanMap['nama']?.toString() ?? 'Tidak ada nama';
                            print('DEBUG: Jurusan[$i]: ID=$jurusanIdFromList, Nama=$jurusanNamaFromList');
                          }
                        }
                        
                        // Cari jurusan berdasarkan ID
                        dynamic foundJurusan;
                        for (var jurusan in jurusanList) {
                          if (jurusan is Map) {
                            final jurusanMap = _convertToStringMap(jurusan);
                            final int? currentJurusanId = int.tryParse(jurusanMap['id']?.toString() ?? '');
                            if (currentJurusanId == jurusanId) {
                              foundJurusan = jurusan;
                              break;
                            }
                          }
                        }
                        
                        if (foundJurusan != null) {
                          final jurusanMap = _convertToStringMap(foundJurusan as Map);
                          jurusanNama = jurusanMap['nama']?.toString() ?? '-';
                          print('DEBUG: Found jurusan: $jurusanNama');
                        } else {
                          print('WARNING: Jurusan dengan ID $jurusanId tidak ditemukan');
                        }
                      }
                    }
                  } else {
                    print('ERROR: Jurusan API failed: ${jurusanResponse.statusCode}');
                  }
                } else {
                  print('WARNING: Kelas tidak memiliki jurusan_id');
                }
              } else {
                print('WARNING: Kelas dengan ID $kelasId tidak ditemukan');
              }
            }
          }
        } else {
          print('ERROR: Kelas API failed: ${kelasResponse.statusCode}');
        }
      } else {
        print('WARNING: Siswa tidak memiliki kelas_id');
      }
      
      // Proses dan simpan data
      final String nama = siswaMap['nama_lengkap']?.toString() ?? 'SISWA';
      final String nisn = siswaMap['nisn']?.toString() ?? '-';
      final String alamat = siswaMap['alamat']?.toString() ?? '-';
      final String noTelp = siswaMap['no_telp']?.toString() ?? '-';
      final String tanggalLahir = siswaMap['tanggal_lahir']?.toString() ?? '-';
      
      print('=== FINAL DATA ===');
      print('Nama: $nama');
      print('NISN: $nisn');
      print('Kelas: $kelasNama');
      print('Jurusan: $jurusanNama');
      
      _debugInfo += 'Data siswa berhasil diambil:\n';
      _debugInfo += 'Nama: $nama\n';
      _debugInfo += 'NISN: $nisn\n';
      _debugInfo += 'Kelas: $kelasNama\n';
      _debugInfo += 'Jurusan: $jurusanNama\n';
      
      setState(() {
        _profileData = {
          'nama': nama.toUpperCase(),
          'nisn': nisn,
          'kelas': kelasNama,
          'jurusan': jurusanNama,
        };
      });
      
      // Simpan ke SharedPreferences untuk cache
      await prefs.setString('siswa_nama_lengkap', nama);
      await prefs.setString('siswa_nisn', nisn);
      await prefs.setString('siswa_kelas_nama', kelasNama);
      await prefs.setString('siswa_jurusan_nama', jurusanNama);
      await prefs.setString('siswa_alamat', alamat);
      await prefs.setString('siswa_no_telp', noTelp);
      await prefs.setString('siswa_tanggal_lahir', tanggalLahir);
      
    } catch (e) {
      print('ERROR: Exception saat fetch kelas/jurusan: $e');
      _debugInfo += 'Error fetching kelas/jurusan: $e\n';
      await _loadFromSharedPrefs();
    }
  }

  Map<String, dynamic> _convertToStringMap(Map<dynamic, dynamic> map) {
    final Map<String, dynamic> result = {};
    map.forEach((key, value) {
      result[key.toString()] = value;
    });
    return result;
  }

  Future<void> _loadFromSharedPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    
    print('DEBUG: Memuat dari SharedPreferences');
    _debugInfo += 'Loading from SharedPreferences...\n';
    
    // Cari data siswa dari SharedPreferences
    final String? userName = prefs.getString('user_name');
    final String? namaLengkap = prefs.getString('siswa_nama_lengkap');
    
    print('DEBUG: User Name dari prefs: $userName');
    print('DEBUG: Nama Lengkap dari prefs: $namaLengkap');
    
    // Cari NISN dari berbagai kemungkinan key
    String? nisn;
    final Set<String> allKeys = prefs.getKeys();
    for (var key in allKeys) {
      if (key.toLowerCase().contains('nisn') || 
          key.toLowerCase().contains('nis') || 
          key.toLowerCase().contains('nomor_induk')) {
        final String? value = prefs.getString(key);
        print('DEBUG: Found key $key: $value');
        if (value != null && value.isNotEmpty && value != '-') {
          nisn = value;
          break;
        }
      }
    }
    
    // Ambil kelas dan jurusan dari cache
    final String kelas = prefs.getString('siswa_kelas_nama') ?? 
                         prefs.getString('kelas_nama') ?? 
                         prefs.getString('user_kelas') ?? '-';
    final String jurusan = prefs.getString('siswa_jurusan_nama') ?? 
                           prefs.getString('jurusan_nama') ?? 
                           prefs.getString('user_jurusan') ?? '-';
    
    final String namaTerpilih = namaLengkap ?? userName ?? 'SISWA';
    final String nisnTerpilih = nisn ?? '-';
    final String kelasTerpilih = kelas;
    final String jurusanTerpilih = jurusan;
    
    print('DEBUG: Data final dari SharedPreferences:');
    print('  Nama: $namaTerpilih');
    print('  NISN: $nisnTerpilih');
    print('  Kelas: $kelasTerpilih');
    print('  Jurusan: $jurusanTerpilih');
    
    _debugInfo += 'Final - Nama: $namaTerpilih, NISN: $nisnTerpilih, Kelas: $kelasTerpilih, Jurusan: $jurusanTerpilih\n';
    
    setState(() {
      _profileData = {
        'nama': namaTerpilih.toUpperCase(),
        'nisn': nisnTerpilih,
        'kelas': kelasTerpilih,
        'jurusan': jurusanTerpilih,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightColor,
      body: SafeArea(
        child: Column(
          children: [

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                              Icons.person,
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
                                      _profileData['nama']!,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: _textColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withValues(alpha:0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _primaryColor.withValues(alpha:0.3),
                                        ),
                                      ),
                                      child: const Text(
                                        'SISWA PKL',
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

                    // Informasi Pribadi Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _borderColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha:0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: _primaryColor,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Informasi Siswa',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: _borderColor),
                          const SizedBox(height: 16),

                          // NISN
                          _buildInfoItem(
                            icon: Icons.badge_outlined,
                            label: 'NISN',
                            value: _isLoading 
                                ? 'Memuat...'
                                : (_profileData['nisn']!.isNotEmpty && _profileData['nisn']! != '-' 
                                    ? _profileData['nisn']! 
                                    : 'NISN tidak ditemukan'),
                          ),

                          const SizedBox(height: 16),

                          // Kelas
                          _buildInfoItem(
                            icon: Icons.school_outlined,
                            label: 'Kelas',
                            value: _isLoading ? 'Memuat...' : _profileData['kelas']!,
                          ),

                          const SizedBox(height: 16),

                          // Jurusan
                          _buildInfoItem(
                            icon: Icons.work_outlined,
                            label: 'Jurusan',
                            value: _isLoading ? 'Memuat...' : _profileData['jurusan']!,
                          ),

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
                            color: Colors.grey.withValues(alpha:0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pengaturan',
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
                            onTap: () => _showUnderDevelopment('Bantuan & Panduan', context),
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

                    // Logout Button
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
                            side: const BorderSide(color: _accentColor, width: 1.5),
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

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: _primaryColor,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
            ],
          ),
        ),
      ],
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
                  color: _primaryColor.withValues(alpha:0.1),
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
              'SISFO PKL - SISWA',
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
              'Aplikasi untuk monitoring dan pelaporan PKL bagi siswa',
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
    final prefs = await SharedPreferences.getInstance();

    // Hapus data login siswa
    await prefs.remove('access_token');
    await prefs.remove('user_name');
    await prefs.remove('user_id');
    await prefs.remove('siswa_nisn');
    await prefs.remove('siswa_nama_lengkap');
    await prefs.remove('siswa_kelas_nama');
    await prefs.remove('siswa_jurusan_nama');
    await prefs.remove('siswa_alamat');
    await prefs.remove('siswa_no_telp');
    await prefs.remove('siswa_tanggal_lahir');
    
    // Jangan hapus notifikasi agar tetap bisa dilihat saat login kembali
    final String? userName = prefs.getString('user_name');
    if (userName != null) {
      print('⚠️ Preserving notifications for: $userName');
    }
  }
}