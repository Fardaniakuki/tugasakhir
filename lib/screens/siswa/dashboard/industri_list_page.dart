import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../login/login_screen.dart';

class IndustriListPage extends StatefulWidget {
  const IndustriListPage({super.key});

  @override
  State<IndustriListPage> createState() => _IndustriListPageState();
}

class _IndustriListPageState extends State<IndustriListPage> {
  List<dynamic> _industriList = [];
  bool _isLoading = true;
  bool _isSearching = false;
  List<dynamic> _filteredIndustriList = [];
  final TextEditingController _searchController = TextEditingController();
  
  // Variabel baru untuk jurusan_id dan kelas_id
  int? _jurusanId;
  int? _kelasId;
  String? _token;

  // Cache untuk menyimpan data industri
  static final Map<int?, List<dynamic>> _industriCache = {};
  static DateTime? _lastFetchTime;

  // Neo Brutalism Colors - SAMA DENGAN SISWA DASHBOARD
  final Color _primaryColor = const Color(0xFFE63946); // Merah cerah
  final Color _secondaryColor = const Color(0xFFF1FAEE); // Putih krem
  final Color _accentColor = const Color(0xFFA8DADC); // Biru muda
  final Color _darkColor = const Color(0xFF1D3557); // Biru tua
  final Color _yellowColor = const Color(0xFFFFB703); // Kuning cerah
  final Color _blackColor = Colors.black;

  // Neo Brutalism Shadows - SAMA DENGAN SISWA DASHBOARD
  static const BoxShadow _heavyShadow = BoxShadow(
    color: Colors.black,
    offset: Offset(6, 6),
    blurRadius: 0,
  );

  static const BoxShadow _lightShadow = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.2),
    offset: Offset(4, 4),
    blurRadius: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    
    if (_token == null || _token!.isEmpty) {
      _redirectToLogin();
      return;
    }

    // Cari kelas_id dari berbagai kemungkinan key
    _kelasId = prefs.getInt('kelas_id');
    
    if (_kelasId == null) {
      final possibleKeys = ['kelas_id', 'user_kelas_id', 'kelas', 'id_kelas', 'class_id'];
      
      for (var key in possibleKeys) {
        final value = prefs.get(key);
        if (value != null) {
          if (value is int) {
            _kelasId = value;
            break;
          } else if (value is String) {
            try {
              _kelasId = int.parse(value);
              break;
            } catch (e) {
              // continue
            }
          }
        }
      }
    }
    
    if (_kelasId != null && _kelasId! > 0) {
      await _loadJurusanId();
    } else {
      await _loadIndustriData();
    }
  }

  Future<void> _loadJurusanId() async {
    try {
      final kelasResponse = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas/$_kelasId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (kelasResponse.statusCode == 200) {
        final kelasData = jsonDecode(kelasResponse.body);
        
        _jurusanId = null;
        
        if (kelasData['data'] != null && kelasData['data'] is Map) {
          if (kelasData['data']['jurusan_id'] != null) {
            _jurusanId = kelasData['data']['jurusan_id'];
          } 
          else if (kelasData['data']['jurusan'] != null && kelasData['data']['jurusan']['id'] != null) {
            _jurusanId = kelasData['data']['jurusan']['id'];
          }
          else if (kelasData['data']['id_jurusan'] != null) {
            _jurusanId = kelasData['data']['id_jurusan'];
          }
        } 
        else if (kelasData['jurusan_id'] != null) {
          _jurusanId = kelasData['jurusan_id'];
        }
        else if (kelasData['jurusan'] != null && kelasData['jurusan']['id'] != null) {
          _jurusanId = kelasData['jurusan']['id'];
        }
        else if (kelasData['id_jurusan'] != null) {
          _jurusanId = kelasData['id_jurusan'];
        }
      }
    } catch (e) {
      _jurusanId = null;
    }
    
    await _loadIndustriData();
  }

  Future<void> _loadIndustriData() async {
    if (_token == null || _token!.isEmpty) {
      _redirectToLogin();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Cek cache terlebih dahulu
      if (_isCacheValid()) {
        final cachedIndustri = _getCachedIndustri();
        if (cachedIndustri != null && cachedIndustri.isNotEmpty) {
          if (mounted) {
            setState(() {
              _industriList = cachedIndustri;
              _filteredIndustriList = cachedIndustri;
              _isLoading = false;
            });
          }
          return;
        }
      }

      // Jika tidak ada cache atau cache tidak valid, ambil dari API
      final url = _jurusanId != null
          ? '${dotenv.env['API_BASE_URL']}/api/industri?jurusan_id=$_jurusanId&limit=100'
          : '${dotenv.env['API_BASE_URL']}/api/industri?limit=100';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        List<dynamic> industriList = [];
        
        // Parsing data berdasarkan berbagai kemungkinan struktur API
        if (data['data'] != null) {
          if (data['data']['data'] != null && data['data']['data'] is List) {
            // Struktur paginated: {data: {data: [...], ...}}
            industriList = data['data']['data'];
          } else if (data['data'] is List) {
            // Struktur langsung: {data: [...]}
            industriList = data['data'];
          } else if (data['data']['industri'] != null && data['data']['industri'] is List) {
            // Struktur lain: {data: {industri: [...]}}
            industriList = data['data']['industri'];
          }
        } else if (data is List) {
          // Struktur: [...]
          industriList = data;
        }
        
        // Simpan ke cache
        _cacheIndustri(industriList);
        
        if (mounted) {
          setState(() {
            _industriList = industriList;
            _filteredIndustriList = industriList;
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        // Fallback: coba load semua industri
        await _loadAllIndustriAsFallback();
      }
    } catch (e) {
      // Fallback: coba load semua industri
      await _loadAllIndustriAsFallback();
    }
  }

  // Fallback function untuk load semua industri
  Future<void> _loadAllIndustriAsFallback() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/industri?limit=100'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> industriList = [];
        
        // Parsing data seperti di atas
        if (data['data'] != null) {
          if (data['data']['data'] != null && data['data']['data'] is List) {
            industriList = data['data']['data'];
          } else if (data['data'] is List) {
            industriList = data['data'];
          } else if (data['data']['industri'] != null && data['data']['industri'] is List) {
            industriList = data['data']['industri'];
          }
        } else if (data is List) {
          industriList = data;
        }
        
        // Simpan ke cache dengan jurusan_id null
        _cacheIndustri(industriList);
        
        if (mounted) {
          setState(() {
            _industriList = industriList;
            _filteredIndustriList = industriList;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Gagal memuat data industri');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi untuk mengecek validitas cache (5 menit)
  bool _isCacheValid() {
    if (_lastFetchTime == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(_lastFetchTime!);
    return difference.inMinutes < 5; // Cache berlaku 5 menit
  }

  // Fungsi untuk mendapatkan data dari cache
  List<dynamic>? _getCachedIndustri() {
    return _industriCache[_jurusanId];
  }

  // Fungsi untuk menyimpan data ke cache
  void _cacheIndustri(List<dynamic> industriList) {
    _industriCache[_jurusanId] = industriList;
    _lastFetchTime = DateTime.now();
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

  void _filterIndustri(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      
      if (query.isEmpty) {
        _filteredIndustriList = _industriList;
      } else {
        _filteredIndustriList = _industriList.where((industri) {
          final nama = (industri['nama'] ?? '').toString().toLowerCase();
          final alamat = (industri['alamat'] ?? '').toString().toLowerCase();
          final telepon = (industri['telepon'] ?? '').toString();
          final email = (industri['email'] ?? '').toString().toLowerCase();
          final bidang = (industri['bidang'] ?? '').toString().toLowerCase();
          
          return nama.contains(query.toLowerCase()) ||
                 alamat.contains(query.toLowerCase()) ||
                 telepon.contains(query) ||
                 email.contains(query.toLowerCase()) ||
                 bidang.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // Fungsi untuk refresh data
  Future<void> _refreshData() async {
    // Clear cache untuk memaksa reload dari API
    _industriCache.remove(_jurusanId);
    _lastFetchTime = null;
    
    await _loadIndustriData();
  }

  // Widget untuk header dengan informasi filter - HANYA JIKA ADA JURUSAN
  Widget _buildFilterInfo() {
    if (_jurusanId != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _yellowColor,
          border: Border.all(color: _blackColor, width: 3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [_lightShadow],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _darkColor,
                border: Border.all(color: _blackColor, width: 2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_alt,
                color: _yellowColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Industri Sesuai Jurusan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _blackColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Menampilkan industri yang sesuai dengan jurusan Anda',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color.fromRGBO(0, 0, 0, 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    
    // Jika tidak ada jurusan_id, return widget kosong
    return const SizedBox.shrink();
  }

  void _showIndustriDetail(BuildContext context, Map<String, dynamic> industri) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: _secondaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(40),
              topRight: Radius.circular(40),
            ),
            border: Border.all(color: _blackColor, width: 4),
            boxShadow: const [_heavyShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header dengan tombol close
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(36),
                    topRight: Radius.circular(36),
                  ),
                  border: Border(
                    bottom: BorderSide(color: _blackColor, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    // Close button - Neo Brutalism Style
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _yellowColor,
                          border: Border.all(color: _blackColor, width: 3),
                          shape: BoxShape.circle,
                          boxShadow: const [_lightShadow],
                        ),
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: _blackColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DETAIL INDUSTRI',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            industri['nama'] ?? 'Industri',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _accentColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content - Scrollable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ICON PROFILE BESAR - Neo Brutalism Style
                      Container(
                        margin: const EdgeInsets.only(bottom: 30),
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            border: Border.all(color: _blackColor, width: 4),
                            shape: BoxShape.circle,
                            boxShadow: const [_heavyShadow],
                          ),
                          child: const Icon(
                            Icons.factory_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      
                      // DATA INDUSTRI - Menggunakan warna putih
                      Column(
                        children: [
                          // NAMA INDUSTRI
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white, // Warna putih
                              border: Border.all(color: _blackColor, width: 3),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [_lightShadow],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    border: Border.all(color: _blackColor, width: 2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.business,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'NAMA INDUSTRI',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: _darkColor,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        industri['nama'] ?? '-',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: _blackColor,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 16),

                          // ALAMAT
                          _buildDetailItem(
                            icon: Icons.location_on,
                            title: 'ALAMAT',
                            value: industri['alamat'] ?? '-',
                          ),

                          const SizedBox(height: 16),

                          // TELEPON
                          _buildDetailItem(
                            icon: Icons.phone,
                            title: 'TELEPON',
                            value: industri['telepon'] ?? industri['no_telp'] ?? '-',
                          ),

                          const SizedBox(height: 16),

                          // EMAIL
                          _buildDetailItem(
                            icon: Icons.email,
                            title: 'EMAIL',
                            value: industri['email'] ?? '-',
                          ),
                          
                          // BIDANG (jika ada)
                          if (industri['bidang'] != null && (industri['bidang'] as String).isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildDetailItem(
                              icon: Icons.work,
                              title: 'BIDANG',
                              value: industri['bidang'] ?? '-',
                            ),
                          ],
                          
                          // DESKRIPSI (jika ada)
                          if (industri['deskripsi'] != null && (industri['deskripsi'] as String).isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white, // Warna putih
                                border: Border.all(color: _blackColor, width: 3),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [_lightShadow],
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
                                          color: _primaryColor,
                                          border: Border.all(color: _blackColor, width: 2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.description,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'DESKRIPSI',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: _blackColor,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _secondaryColor,
                                      border: Border.all(color: _blackColor, width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      industri['deskripsi'] ?? '-',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 30),
                        ],
                      ),
                      
                      // TOMBOL TUTUP - Neo Brutalism Style
                      Container(
                        margin: const EdgeInsets.only(bottom: 30),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _yellowColor,
                            border: Border.all(color: _blackColor, width: 3),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [_heavyShadow],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(27),
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 22,
                                        color: _blackColor,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'TUTUP',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: _blackColor,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget untuk item detail dalam modal - Warna putih
  Widget _buildDetailItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Warna putih
        border: Border.all(color: _blackColor, width: 3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_lightShadow],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _primaryColor,
              border: Border.all(color: _blackColor, width: 2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 22,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
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
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk card industri dalam list - Neo Brutalism Style
  Widget _buildIndustriCard(int index) {
    final industri = _filteredIndustriList[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _secondaryColor,
        border: Border.all(color: _blackColor, width: 3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_heavyShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => _showIndustriDetail(context, industri),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon/Logo - Neo Brutalism Style
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    border: Border.all(color: _blackColor, width: 3),
                    shape: BoxShape.circle,
                    boxShadow: const [_lightShadow],
                  ),
                  child: const Icon(
                    Icons.factory,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Detail
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama industri
                      Text(
                        industri['nama'] ?? 'Industri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _blackColor,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Alamat
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: _darkColor,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              industri['alamat'] ?? 'Alamat tidak tersedia',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color.fromRGBO(29, 53, 87, 0.8),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Telepon
                      if (industri['telepon'] != null && industri['telepon'].toString().isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: _darkColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              industri['telepon'].toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: _darkColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                
                // Arrow indicator - Neo Brutalism Style
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _yellowColor,
                    border: Border.all(color: _blackColor, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: _blackColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkColor,
      body: SafeArea(
        child: Column(
          children: [
            // APPBAR CUSTOM - Header yang lebih sederhana
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _primaryColor,
                border: Border(
                  bottom: BorderSide(color: _blackColor, width: 3),
                ),
              ),
              child: Row(
                children: [
                  // Back button
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _blackColor, width: 3),
                      shape: BoxShape.circle,
                      boxShadow: const [_lightShadow],
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: _blackColor,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Title dengan design lebih minimalis
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Daftar Industri',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Pilih industri untuk PKL',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Refresh button
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: _yellowColor,
                      border: Border.all(color: _blackColor, width: 3),
                      shape: BoxShape.circle,
                      boxShadow: const [_lightShadow],
                    ),
                    child: IconButton(
                      onPressed: _refreshData,
                      icon: Icon(
                        Icons.refresh,
                        color: _blackColor,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            
            // CONTAINER UTAMA - tanpa lengkungan atas
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _secondaryColor,
                  border: Border.all(color: _blackColor, width: 3),
                  boxShadow: const [_heavyShadow],
                ),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: _blackColor, width: 3),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: const [_lightShadow],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 16),
                            Icon(
                              Icons.search,
                              size: 20,
                              color: _darkColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: _filterIndustri,
                                decoration: const InputDecoration(
                                  hintText: 'Cari nama industri...',
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: Color.fromRGBO(29, 53, 87, 0.5),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _blackColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _filterIndustri('');
                                },
                                icon: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: _darkColor,
                                ),
                              ),
                            const SizedBox(width: 12),
                          ],
                        ),
                      ),
                    ),

                    // Content dengan RefreshIndicator
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshData,
                        color: _primaryColor,
                        backgroundColor: _secondaryColor,
                        child: _isLoading
                            ? _buildLoadingState()
                            : SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  children: [
                                    // Info filter jurusan - HANYA JIKA ADA
                                    _buildFilterInfo(),
                                    
                                    if (_filteredIndustriList.isEmpty)
                                      _buildEmptyState()
                                    else
                                      Column(
                                        children: [
                                          // Info jumlah - dengan border sederhana
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 16),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: _yellowColor,
                                              border: Border.all(color: _blackColor, width: 2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.info,
                                                  size: 16,
                                                  color: _blackColor,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  _isSearching
                                                      ? '${_filteredIndustriList.length} hasil ditemukan'
                                                      : 'Total ${_filteredIndustriList.length} industri',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    color: _blackColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // List industri
                                          ...List.generate(_filteredIndustriList.length, (index) {
                                            return _buildIndustriCard(index);
                                          }),
                                          
                                          const SizedBox(height: 30),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading state dengan skeleton
  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _secondaryColor,
            border: Border.all(color: _blackColor, width: 3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeleton icon circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _accentColor,
                  border: Border.all(color: _blackColor, width: 3),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              
              // Skeleton content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 18,
                      decoration: BoxDecoration(
                        color: _accentColor,
                        border: Border.all(color: _blackColor, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _accentColor,
                        border: Border.all(color: _blackColor, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _accentColor,
                        border: Border.all(color: _blackColor, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _secondaryColor,
            border: Border.all(color: _blackColor, width: 3),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [_heavyShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _accentColor,
                  border: Border.all(color: _blackColor, width: 2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.factory_outlined,
                  size: 50,
                  color: _darkColor,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isSearching ? 'Industri tidak ditemukan' : 'Belum ada industri',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _blackColor,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isSearching
                    ? 'Coba kata kunci pencarian lainnya'
                    : 'Data industri akan ditampilkan di sini',
                style: TextStyle(
                  fontSize: 13,
                  color: _darkColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_isSearching)
                Container(
                  decoration: BoxDecoration(
                    color: _yellowColor,
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        _searchController.clear();
                        _filterIndustri('');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          'Hapus Pencarian',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: _blackColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      )
    );
  }
}