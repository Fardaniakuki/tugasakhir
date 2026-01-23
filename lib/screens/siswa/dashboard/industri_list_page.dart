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

  // Warna serius - menggunakan warna merah tua sebagai utama
  final Color _primaryColor = const Color.fromARGB(255, 180, 16, 4); // Merah tua serius
  final Color _secondaryColor = Colors.white; // Putih bersih
  final Color _accentColor = const Color.fromARGB(255, 240, 240, 240); // Abu-abu sangat muda
// Hitam gelap
  final Color _borderColor = const Color.fromARGB(255, 200, 200, 200); // Abu-abu untuk border
  final Color _textColor = const Color.fromARGB(255, 50, 50, 50); // Abu-abu gelap untuk teks
  final Color _hintColor = const Color.fromARGB(255, 120, 120, 120); // Abu-abu untuk hint

  // Shadow yang lebih halus
  final BoxShadow _softShadow = BoxShadow(
    color: Colors.black.withValues(alpha:.1),
    offset: const Offset(0, 2),
    blurRadius: 6,
    spreadRadius: 0,
  );

  final BoxShadow _mediumShadow = BoxShadow(
    color: Colors.black.withValues(alpha:.15),
    offset: const Offset(0, 4),
    blurRadius: 8,
    spreadRadius: 0,
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
          color: _primaryColor.withValues(alpha:.1),
          border: Border.all(color: _primaryColor.withValues(alpha:.3), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_alt,
              color: _primaryColor,
              size: 20,
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
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Menampilkan industri yang sesuai dengan jurusan Anda',
                    style: TextStyle(
                      fontSize: 12,
                      color: _hintColor,
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
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: _secondaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [_mediumShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Industri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _secondaryColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: _secondaryColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Icon profil
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: _primaryColor,
                          child: Icon(
                            Icons.business,
                            size: 60,
                            color: _secondaryColor,
                          ),
                        ),
                      ),
                      
                      // Nama industri
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          industri['nama'] ?? 'Industri',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: _textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      // Informasi detail
                      _buildDetailItem(
                        icon: Icons.location_on,
                        label: 'Alamat',
                        value: industri['alamat'] ?? '-',
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildDetailItem(
                        icon: Icons.phone,
                        label: 'Telepon',
                        value: industri['telepon'] ?? industri['no_telp'] ?? '-',
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildDetailItem(
                        icon: Icons.email,
                        label: 'Email',
                        value: industri['email'] ?? '-',
                      ),
                      
                      if (industri['bidang'] != null && (industri['bidang'] as String).isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildDetailItem(
                          icon: Icons.work,
                          label: 'Bidang',
                          value: industri['bidang'] ?? '-',
                        ),
                      ],
                      
                      if (industri['deskripsi'] != null && (industri['deskripsi'] as String).isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Deskripsi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _accentColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _borderColor),
                              ),
                              child: Text(
                                industri['deskripsi'] ?? '-',
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: _hintColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 30),
                      
                      // Tombol tutup
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Tutup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _secondaryColor,
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

  // Widget untuk item detail dalam modal
  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _accentColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: _primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: _hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk card industri dalam list
  Widget _buildIndustriCard(int index) {
    final industri = _filteredIndustriList[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _secondaryColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [_softShadow],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showIndustriDetail(context, industri),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.business,
                    color: _secondaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Detail
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nama industri
                      Text(
                        industri['nama'] ?? 'Industri',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Alamat
                      Text(
                        industri['alamat'] ?? 'Alamat tidak tersedia',
                        style: TextStyle(
                          fontSize: 13,
                          color: _hintColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Telepon (jika ada)
                      if (industri['telepon'] != null && industri['telepon'].toString().isNotEmpty)
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: 14,
                              color: _hintColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              industri['telepon'].toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: _hintColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                
                // Arrow indicator
                Icon(
                  Icons.chevron_right,
                  color: _hintColor,
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
      backgroundColor: _secondaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar sederhana
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryColor,
                boxShadow: [_softShadow],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: _secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daftar Industri',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: _secondaryColor,
                          ),
                        ),
                        Text(
                          'Pilih industri untuk PKL',
                          style: TextStyle(
                            fontSize: 12,
                            color: _secondaryColor.withValues(alpha:.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  IconButton(
                    onPressed: _refreshData,
                    icon: Icon(
                      Icons.refresh,
                      color: _secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Container(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: _secondaryColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _borderColor),
                  boxShadow: [_softShadow],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterIndustri,
                  decoration: InputDecoration(
                    hintText: 'Cari industri...',
                    hintStyle: TextStyle(
                      color: _hintColor,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: _hintColor,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              _filterIndustri('');
                            },
                            icon: Icon(
                              Icons.clear,
                              color: _hintColor,
                            ),
                          )
                        : null,
                  ),
                  style: TextStyle(
                    color: _textColor,
                  ),
                ),
              ),
            ),

            // Content
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
                            // Info filter jurusan
                            _buildFilterInfo(),
                            
                            if (_filteredIndustriList.isEmpty)
                              _buildEmptyState()
                            else
                              Column(
                                children: [
                                  // Info jumlah
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _isSearching
                                              ? '${_filteredIndustriList.length} hasil ditemukan'
                                              : 'Total ${_filteredIndustriList.length} industri',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _hintColor,
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
    );
  }

  // Loading state
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
            boxShadow: [_softShadow],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeleton icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              const SizedBox(width: 12),
              
              // Skeleton content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _accentColor,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.business_outlined,
              size: 80,
              color: _hintColor,
            ),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'Industri tidak ditemukan' : 'Belum ada industri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching
                  ? 'Coba kata kunci pencarian lainnya'
                  : 'Data industri akan ditampilkan di sini',
              style: TextStyle(
                fontSize: 14,
                color: _hintColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_isSearching)
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  _filterIndustri('');
                },
                child: Text(
                  'Hapus Pencarian',
                  style: TextStyle(
                    color: _primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}