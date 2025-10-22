import 'dart:async';
import 'package:flutter/material.dart';
import '../crud/add_person_page.dart';
import 'murid/student_detail_page.dart';
import 'guru/teacher_detail_page.dart';
import 'jurusan/major_detail_page.dart';
import 'industri/industry_detail_page.dart';
import 'kelas/class_detail_page.dart';
import 'dashboard_service.dart';
import 'stat_grid.dart';
import 'person_tile.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DashboardService _service = DashboardService();
  String selectedStatus = 'Murid';
  String selectedKelasDisplay = 'Semua Kelas';
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  
  // Cache untuk data yang sudah di-fetch
  final Map<String, List<Map<String, dynamic>>> _dataCache = {};
  final Map<String, Map<String, dynamic>> _dashboardCache = {};
  
  List<Map<String, dynamic>> get muridList => _dataCache['murid'] ?? [];
  List<Map<String, dynamic>> get guruList => _dataCache['guru'] ?? [];
  List<Map<String, dynamic>> get jurusanDataList => _dataCache['jurusan'] ?? [];
  List<Map<String, dynamic>> get industriList => _dataCache['industri'] ?? [];
  List<Map<String, dynamic>> get kelasDataList => _dataCache['kelas'] ?? [];
  
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  Timer? _debounce;

  // Untuk filter kelas
  List<Map<String, String>> availableKelas = [];
  String selectedKelasId = '';

  @override
  void initState() {
    super.initState();
    _initAll();

    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 800), () {
      final newQuery = searchController.text.trim();
      if (newQuery != searchQuery) {
        _fetchDataWithCache(newQuery);
      }
    });
  }

  Future<void> _initAll() async {
    await Future.wait([
      fetchDashboardData(),
      fetchKelasOptions(),
    ]);
    await _fetchDataWithCache(searchQuery);
  }

  Future<void> fetchKelasOptions() async {
    try {
      final kelasData = await _service.fetchKelas();
      setState(() {
        availableKelas = kelasData;
      });
    } catch (e) {
      debugPrint('❌ Error fetching kelas options: $e');
      setState(() {
        availableKelas = [];
      });
    }
  }

  Future<void> refreshData() async {
    // Clear cache saat refresh
    _dataCache.clear();
    _dashboardCache.clear();
    _service.clearCache();
    
    setState(() => isLoading = true);
    await _fetchDataWithCache(searchQuery, forceRefresh: true);
    setState(() => isLoading = false);
  }

  Future<void> fetchDashboardData() async {
    const String cacheKey = 'dashboard';
    if (_dashboardCache.containsKey(cacheKey) && !isLoading) {
      setState(() {
        dashboardData = _dashboardCache[cacheKey];
      });
      return;
    }

    try {
      final data = await _service.fetchDashboardData();
      _dashboardCache[cacheKey] = data!;
      setState(() {
        dashboardData = data;
      });
    } catch (e) {
      debugPrint('Exception fetchDashboardData: $e');
    }
  }

  Future<void> _fetchDataWithCache(String query, {bool forceRefresh = false}) async {
    final cacheKey = _getCacheKey(query);
    
    if (!forceRefresh && _dataCache.containsKey(cacheKey)) {
      setState(() {
        searchQuery = query;
        isLoading = false;
      });
      return;
    }

    setState(() {
      searchQuery = query;
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> data;
      
      switch (selectedStatus) {
        case 'Murid':
          data = await _service.fetchSiswaData(
            searchQuery: query,
            kelasId: selectedKelasId,
            jurusanId: '',
          );
          break;
        case 'Guru':
          data = await _service.fetchGuruData(searchQuery: query);
          break;
        case 'Jurusan':
          data = await _service.fetchJurusanData(searchQuery: query);
          break;
        case 'Industri':
          data = await _service.fetchIndustriData(searchQuery: query);
          break;
        case 'Kelas':
          data = await _service.fetchKelasData(searchQuery: query);
          break;
        default:
          data = [];
      }

      // Cache the data
      _dataCache[cacheKey] = data;
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Exception fetching $selectedStatus: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _getCacheKey(String query) {
    if (selectedStatus == 'Murid') {
      return '${selectedStatus.toLowerCase()}-$query-$selectedKelasId';
    }
    return '${selectedStatus.toLowerCase()}-$query';
  }

  List<Map<String, dynamic>> get _currentList {
    final cacheKey = _getCacheKey(searchQuery);
    return _dataCache[cacheKey] ?? [];
  }

  void _handleItemTap(Map<String, dynamic> item) async {
    final String itemId = item['id'] ?? '';
    if (itemId.isEmpty) return;

    Widget? targetPage;

    switch (selectedStatus) {
      case 'Murid':
        targetPage = StudentDetailPage(studentId: itemId);
        break;
      case 'Guru':
        targetPage = TeacherDetailPage(teacherId: itemId);
        break;
      case 'Jurusan':
        targetPage = MajorDetailPage(majorId: itemId);
        break;
      case 'Industri':
        targetPage = IndustryDetailPage(industryId: itemId);
        break;
      case 'Kelas':
        targetPage = ClassDetailPage(classId: itemId);
        break;
    }

    if (targetPage != null) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => targetPage!),
      );
      
      if (!mounted) return;
      
      // PERBAIKAN: Handle semua jenis perubahan data (update dan delete)
      if (result != null) {
        if (result['deleted'] == true || result['updated'] == true) {
          // Clear cache untuk type yang berubah
          final cacheKeysToRemove = _dataCache.keys.where(
            (key) => key.startsWith('${selectedStatus.toLowerCase()}-')
          ).toList();
          
          for (final key in cacheKeysToRemove) {
            _dataCache.remove(key);
          }
          
          // Juga clear dashboard cache karena statistik mungkin berubah
          _dashboardCache.clear();
          _service.clearCache();
          
          // Refresh data
          await Future.wait([
            fetchDashboardData(),
            _fetchDataWithCache(searchQuery, forceRefresh: true),
          ]);
        }
      }
    }
  }

  // Method untuk handle perubahan role
  Future<void> _handleRoleChange(String newRole) async {
    if (newRole == selectedStatus) return;
    
    // Clear cache untuk role sebelumnya dan role baru
    _clearRoleCache(selectedStatus, newRole);
    
    setState(() {
      selectedStatus = newRole;
      selectedKelasDisplay = 'Semua Kelas';
      selectedKelasId = '';
      searchQuery = '';
      searchController.text = '';
      isLoading = true;
    });
    
    await _fetchDataWithCache('');
  }

  void _clearRoleCache(String previousRole, String newRole) {
    // Clear cache untuk role sebelumnya
    final previousRoleKeys = _dataCache.keys.where(
      (key) => key.startsWith('${previousRole.toLowerCase()}-')
    ).toList();
    
    for (final key in previousRoleKeys) {
      _dataCache.remove(key);
    }
    
    // Clear cache untuk role baru (jika ada)
    final newRoleKeys = _dataCache.keys.where(
      (key) => key.startsWith('${newRole.toLowerCase()}-')
    ).toList();
    
    for (final key in newRoleKeys) {
      _dataCache.remove(key);
    }
    
    // Clear service cache untuk role-role tersebut
    _service.clearCacheByPattern(previousRole.toLowerCase());
    _service.clearCacheByPattern(newRole.toLowerCase());
  }

  Widget _buildSearchAndFilter() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    icon: const Icon(Icons.search),
                    hintText: 'Cari ${selectedStatus.toLowerCase()}',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedStatus,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    isExpanded: true,
                    dropdownColor: Colors.grey[100],
                    style: const TextStyle(
                      color: Color.fromARGB(255, 129, 129, 129),
                      fontWeight: FontWeight.w600,
                    ),
                    items: const [
                      'Murid',
                      'Guru',
                      'Jurusan',
                      'Industri',
                      'Kelas'
                    ].map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        )).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        await _handleRoleChange(value);
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Kelas filter hanya untuk Murid
        if (selectedStatus == 'Murid') _buildKelasFilter(),
      ],
    );
  }

  Widget _buildKelasFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: PopupMenuButton<String>(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width * 0.6,
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: 250,
        ),
        position: PopupMenuPosition.under,
        offset: const Offset(0, 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        onSelected: (value) async {
          setState(() {
            selectedKelasDisplay = value;
            selectedKelasId = value == 'Semua Kelas' ? '' : 
                availableKelas.firstWhere(
                  (k) => k['name'] == value,
                  orElse: () => {'id': ''},
                )['id'] ?? '';
            isLoading = true;
          });
          
          await _fetchDataWithCache(searchQuery, forceRefresh: true);
        },
        itemBuilder: (context) {
          // FIX: Gunakan List biasa, bukan PopupMenuItem dengan enabled: false
          final menuItems = <PopupMenuEntry<String>>[];

          // Tambahkan "Semua Kelas"
          menuItems.add(
            PopupMenuItem<String>(
              value: 'Semua Kelas',
              height: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Semua Kelas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(255, 129, 129, 129),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.only(top: 8),
                    color: Colors.grey[300],
                  ),
                ],
              ),
            ),
          );

          // Tambahkan semua kelas
          for (var kelas in availableKelas) {
            menuItems.add(
              PopupMenuItem<String>(
                value: kelas['name']!,
                height: 40,
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    kelas['name']!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color.fromARGB(255, 129, 129, 129),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }

          return menuItems;
        },
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedKelasDisplay,
                style: const TextStyle(
                  color: Color.fromARGB(255, 129, 129, 129),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Color.fromARGB(255, 129, 129, 129),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentList = _currentList;
    
    if (currentList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'Tidak ada data ditemukan',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: currentList.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final item = currentList[index];
        
        final String name = item['name'] ?? item['nama'] ?? '';
        
        // Untuk Jurusan, gunakan JurusanTile dengan jumlah kelas
        if (selectedStatus == 'Jurusan') {
          final String kode = item['kode'] ?? '';
          final int jumlahKelas = item['jumlah_kelas'] ?? 0;
          return JurusanTile(
            nama: name,
            kode: kode,
            jumlahKelas: jumlahKelas,
            onTap: () => _handleItemTap(item),
          );
        }
        
        // Untuk Industri, gunakan IndustriTile
        if (selectedStatus == 'Industri') {
          final String noTelp = item['no_telp'] ?? '';
          final String alamat = item['alamat'] ?? '';
          final String bidang = item['bidang'] ?? '';
          
          return IndustriTile(
            nama: name,
            noTelp: noTelp,
            alamat: alamat,
            bidang: bidang,
            onTap: () => _handleItemTap(item),
          );
        }
        
        // Untuk Kelas, gunakan KelasTile dengan jumlah murid
        if (selectedStatus == 'Kelas') {
          final String jurusanNama = item['jurusan_nama'] ?? '';
          final int jumlahMurid = item['jumlah_murid'] ?? 0;
          return KelasTile(
            nama: name,
            jurusanNama: jurusanNama,
            jumlahMurid: jumlahMurid,
            onTap: () => _handleItemTap(item),
          );
        }
        
        // Untuk Murid dan Guru, gunakan PersonTile
        final String nisn = item['nisn'] ?? item['no_induk'] ?? item['nomor_induk'] ?? '';
        
        String tglLahir = item['tgl_lahir'] ?? 
                        item['tanggal_lahir'] ?? 
                        item['tglLahir'] ?? 
                        item['tanggalLahir'] ?? 
                        item['birth_date'] ?? 
                        item['date_of_birth'] ?? 
                        item['lahir'] ?? 
                        '-';
        
        if (tglLahir == '-') {
          tglLahir = item['profile']?['tgl_lahir'] ?? 
                    item['data']?['tgl_lahir'] ?? 
                    '-';
        }
        
        final String? jurusan = item['jurusan'] ?? item['major'] ?? item['jurusan_nama'];
        final String? kelas = item['kelas'] ?? item['class'] ?? item['kelas_nama'];
        final String role = selectedStatus;

        // PASS DATA GURU YANG LENGKAP
        final String? kodeGuru = item['kode_guru'];
        final String? userId = item['user_id'];

        return PersonTile(
          name: name,
          nisn: nisn,
          tglLahir: tglLahir,
          jurusan: jurusan,
          kelas: kelas,
          role: role,
          kodeGuru: kodeGuru,
          userId: userId,
          onTap: () => _handleItemTap(item),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B1A1A),
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (dashboardData != null) 
                  StatGrid(
                    data: dashboardData!,
                    onAddPressed: _showAddOptions,
                    onBoxTap: (type) async {
                      await _handleRoleChange(type);
                    },
                  ),
                const SizedBox(height: 20),
                _buildSearchAndFilter(),
                const SizedBox(height: 16),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAddTile(Icons.menu_book, 'Tambah Murid', 'Siswa'),
              _buildAddTile(Icons.person, 'Tambah Guru', 'Guru'),
              _buildAddTile(Icons.school, 'Tambah Jurusan', 'Jurusan'),
              _buildAddTile(Icons.class_, 'Tambah Kelas', 'Kelas'),
              _buildAddTile(Icons.factory, 'Tambah Industri', 'Industri'),
            ],
          ),
        );
      },
    );
  }

  ListTile _buildAddTile(IconData icon, String title, String jenis) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () async {
        Navigator.pop(context);
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddPersonPage(jenisData: jenis)),
        );
        
        if (!mounted) return;
        
        if (result != null) {
          // Clear cache untuk jenis data yang baru ditambahkan
          final cacheKeysToRemove = _dataCache.keys.where(
            (key) => key.startsWith('${jenis.toLowerCase()}-')
          ).toList();
          
          for (final key in cacheKeysToRemove) {
            _dataCache.remove(key);
          }
          
          await _fetchDataWithCache(searchQuery, forceRefresh: true);
        }
      },
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }
}