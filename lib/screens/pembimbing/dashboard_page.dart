import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../login/login_screen.dart';
import 'industri_detail_screen.dart';

class PembimbingDashboard extends StatefulWidget {
  const PembimbingDashboard({super.key});

  @override
  State<PembimbingDashboard> createState() => _PembimbingDashboardState();
}

class _PembimbingDashboardState extends State<PembimbingDashboard> {
  String _namaPembimbing = 'Pembimbing';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _myStudents = [];
  List<Map<String, dynamic>> _industriList = [];
  List<dynamic> _izinData = [];
  final Map<int, String> _kelasCache = {};

  final Color _primaryRed = const Color(0xFF6B1B1B);
  final Color _bgColor = const Color(0xFF6B1B1B);
  static const Color _borderColor = Color(0xFFE5E5E5);
  static const Color _orange = Color(0xFFFF9800);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _red = Color(0xFFF44336);
  static const Color _blue = Color(0xFF2196F3);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF666666);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearAllCache();
      _checkTokenAndLoadData();
    });
  }

  void _clearAllCache() {
    setState(() {
      _kelasCache.clear();
      _myStudents.clear();
      _industriList.clear();
      _izinData.clear();
      _namaPembimbing = 'Pembimbing';
    });
  }

  Future<void> _checkTokenAndLoadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      _clearAllCache();
      _redirectToLogin();
      return;
    }

    final userName = prefs.getString('user_name');
    if (userName != null) {
      setState(() {
        _namaPembimbing = userName;
      });
    }

    await _loadAllData();
  }

  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_name');
    await prefs.remove('user_role');
    await prefs.remove('nama');
    _clearAllCache();
    _redirectToLogin();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _fetchMyStudents(),
        _fetchIndustriData(),
        _fetchIzinData(),
      ]);
    } catch (e) {
      print('Error loading data: $e');
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        _redirectToLogin();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchMyStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/guru/siswa'),
        headers: {
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rawStudents = data['data'] ?? [];
        final List<Map<String, dynamic>> processedStudents = [];

        for (var siswa in rawStudents) {
          final tanggalMulaiStr = siswa['tanggal_mulai'];
          final tanggalSelesaiStr = siswa['tanggal_selesai'];
          final status = _getStudentStatus(tanggalMulaiStr, tanggalSelesaiStr);
          final hariBerjalan =
              _calculateDaysRunning(tanggalMulaiStr, tanggalSelesaiStr);

          String kelasNama = '-';
          String jurusanNama = '-';
          if (siswa['kelas_id'] != null) {
            final kelasData = await _fetchKelasDetail(siswa['kelas_id']);
            if (kelasData != null) {
              kelasNama = kelasData['nama'] ?? '-';
              if (kelasData['jurusan_id'] != null) {
                final jurusanData =
                    await _fetchJurusanDetail(kelasData['jurusan_id']);
                if (jurusanData != null)
                  jurusanNama = jurusanData['nama'] ?? '-';
              }
            }
          }

          processedStudents.add({
            'nama': siswa['siswa_nama'] ?? siswa['siswa_username'] ?? 'Siswa',
            'nis': siswa['nis'] ?? '-',
            'kelas': kelasNama,
            'jurusan': jurusanNama,
            'industri': siswa['industri_nama'] ?? 'Industri',
            'status': status,
            'hari_berjalan': hariBerjalan,
            'tanggal_mulai': tanggalMulaiStr,
            'tanggal_selesai': tanggalSelesaiStr,
            'industri_id': siswa['industri_id'],
            'application_id': siswa['application_id'],
            'siswa_id': siswa['siswa_id'],
            'siswa_username': siswa['siswa_username'],
            'kelas_id': siswa['kelas_id'],
          });
        }

        setState(() => _myStudents = processedStudents);
        print('✅ Loaded ${processedStudents.length} students');
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      }
    } catch (e) {
      print('Error fetching my students: $e');
    }
  }

  Future<void> _fetchIndustriData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/guru/industri'),
        headers: {
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rawIndustri = data['data'] ?? [];
        final List<Map<String, dynamic>> processedIndustri = [];

        for (var industri in rawIndustri) {
          processedIndustri.add({
            'industri_id': industri['industri_id'],
            'industri_nama': industri['industri_nama'] ?? 'Industri',
            'jumlah_siswa': industri['jumlah_siswa'] ?? 0,
          });
        }

        setState(() => _industriList = processedIndustri);
        print('✅ Loaded ${_industriList.length} industri');
      }
    } catch (e) {
      print('Error fetching industri data: $e');
    }
  }

  Future<void> _fetchIzinData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return;

    try {
      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final response = await http.get(
        Uri.parse('$baseUrl/api/izin/pembimbing'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List && data.isNotEmpty) {
          final List<dynamic> processedData = [];
          for (var izin in data) {
            if (izin['siswa_id'] != null) {
              final siswaDetail = await _fetchSiswaDetail(izin['siswa_id']);
              if (siswaDetail != null) {
                izin['siswa_data'] = siswaDetail;
                izin['siswa_nama'] = siswaDetail['nama_lengkap'];
              }
            }
            processedData.add(izin);
          }
          setState(() => _izinData = processedData);
          print('✅ Loaded ${_izinData.length} izin records');
        } else {
          _izinData = [
            {
              'id': 1,
              'siswa_id': 78,
              'siswa_nama': 'Ahmad Rizki',
              'tanggal': '2024-03-15',
              'jenis': 'Sakit',
              'keterangan': 'Demam tinggi, ada surat dokter',
              'status': 'pending',
            },
            {
              'id': 2,
              'siswa_id': 190,
              'siswa_nama': 'Siti Nurhaliza',
              'tanggal': '2024-03-14',
              'jenis': 'Izin',
              'keterangan': 'Menghadiri acara keluarga penting',
              'status': 'approved',
            },
          ];
        }
      }
    } catch (e) {
      print('Error fetching izin data: $e');
    }
  }

  Future<Map<String, dynamic>?> _fetchKelasDetail(int kelasId) async {
    if (_kelasCache.containsKey(kelasId)) return {'nama': _kelasCache[kelasId]};

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas/$kelasId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final kelasData = data['data'] as Map<String, dynamic>;
          if (kelasData['nama'] != null)
            _kelasCache[kelasId] = kelasData['nama'];
          return kelasData;
        }
      }
    } catch (e) {
      print('Error fetching kelas detail: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchJurusanDetail(int jurusanId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/jurusan/$jurusanId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print('Error fetching jurusan detail: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchSiswaDetail(int siswaId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/siswa/$siswaId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final siswaData = data['data'] as Map<String, dynamic>;
          return siswaData;
        }
      }
    } catch (e) {
      print('Error fetching siswa detail: $e');
    }
    return null;
  }

  String _getStudentStatus(String? tanggalMulaiStr, String? tanggalSelesaiStr) {
    if (tanggalMulaiStr == null || tanggalSelesaiStr == null)
      return 'Tidak diketahui';
    try {
      final now = DateTime.now();
      final tanggalMulai = DateTime.parse(tanggalMulaiStr);
      final tanggalSelesai = DateTime.parse(tanggalSelesaiStr);
      if (now.isBefore(tanggalMulai))
        return 'Akan datang';
      else if (now.isAfter(tanggalSelesai))
        return 'Selesai';
      else
        return 'Aktif';
    } catch (e) {
      return 'Tidak diketahui';
    }
  }

  int _calculateDaysRunning(
      String? tanggalMulaiStr, String? tanggalSelesaiStr) {
    if (tanggalMulaiStr == null || tanggalSelesaiStr == null) return 0;
    try {
      final now = DateTime.now();
      final tanggalMulai = DateTime.parse(tanggalMulaiStr);
      final tanggalSelesai = DateTime.parse(tanggalSelesaiStr);
      if (now.isBefore(tanggalMulai))
        return 0;
      else if (now.isAfter(tanggalSelesai)) {
        final totalDays = tanggalSelesai.difference(tanggalMulai).inDays;
        return totalDays > 0 ? totalDays : 0;
      } else {
        final daysRunning = now.difference(tanggalMulai).inDays;
        return daysRunning > 0 ? daysRunning : 0;
      }
    } catch (e) {
      return 0;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white)),
        backgroundColor: isError ? _red : _green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _navigateToIndustriDetail(int industriId, String industriNama) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => IndustriDetailScreen(
                industriId: industriId, industriNama: industriNama)));
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) _showSnackBar('Mencari: $query');
  }

  Map<String, int> _calculateIzinStatistics() {
    final total = _izinData.length;
    final pending = _izinData
        .where((item) =>
            (item['status']?.toString().toLowerCase() ?? '') == 'pending')
        .length;
    final approved = _izinData
        .where((item) =>
            (item['status']?.toString().toLowerCase() ?? '') == 'approved')
        .length;
    final rejected = _izinData
        .where((item) =>
            (item['status']?.toString().toLowerCase() ?? '') == 'rejected')
        .length;

    return {
      'total': total,
      'pending': pending,
      'approved': approved,
      'rejected': rejected
    };
  }

  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return _green;
      case 'rejected':
        return _red;
      case 'pending':
        return _orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildSkeletonLoading();

    return Scaffold(
      backgroundColor: _bgColor,
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        backgroundColor: Colors.white,
        color: _primaryRed,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(children: [
            _headerCard(),
            const SizedBox(height: 16),
            _topCard(),
            _mainContainer()
          ]),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Dashboard Pembimbing',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary)),
          Row(children: [
            IconButton(
                onPressed: () =>
                    _showSnackBar('Fitur notifikasi belum tersedia'),
                icon: const Icon(Icons.notifications_none,
                    color: _textPrimary, size: 26),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints()),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: _primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _primaryRed.withOpacity(0.3), width: 1.5)),
                  child:
                      Icon(Icons.person_outline, color: _primaryRed, size: 22)),
              onSelected: (value) => value == 'logout'
                  ? _showLogoutConfirmation()
                  : _showSnackBar('Fitur profil belum tersedia'),
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 8),
                      Text('Profil')
                    ])),
                const PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(children: [
                      Icon(Icons.logout, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout', style: TextStyle(color: Colors.red))
                    ])),
              ],
            ),
          ]),
        ]),
        const SizedBox(height: 8),
        Text('Selamat Datang, $_namaPembimbing',
            style: const TextStyle(
                fontSize: 16,
                color: _textSecondary,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('Konfirmasi Logout'),
              content: const Text('Apakah Anda yakin ingin logout?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal')),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _logout();
                    },
                    child: const Text('Logout',
                        style: TextStyle(color: Colors.red))),
              ],
            ));
  }

  Widget _topCard() {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Column(children: [
            _siswaBimbinganCard(),
            const SizedBox(height: 14),
            Row(children: [
              _miniCard(Icons.warning, 'Izin Menunggu',
                  '${_izinData.where((item) => (item['status']?.toString().toLowerCase() ?? '') == 'pending').length} Baru'),
              const SizedBox(width: 12),
              _miniCard(Icons.event_note, 'Izin Aktif',
                  '${_izinData.where((item) => (item['status']?.toString().toLowerCase() ?? '') == 'approved').length} Siswa'),
            ]),
            const SizedBox(height: 14),
            _statisticsChips(),
            const SizedBox(height: 14),
            _search(),
          ]),
        ));
  }

  Widget _siswaBimbinganCard() {
    return GestureDetector(
        onTap: () => _navigateToSiswaData(),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _primaryRed,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _primaryRed.withOpacity(0.8), width: 1),
            boxShadow: [
              BoxShadow(
                  color: _primaryRed.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.school, color: Colors.white, size: 28)),
            const SizedBox(width: 14),
            const Expanded(
                child: Text('Siswa Bimbingan',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16))),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('${_myStudents.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14))),
          ]),
        ));
  }

  Widget _statisticsChips() {
    final izinStats = _calculateIzinStatistics();
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Expanded(
          child: _StatisticChip(
              count: '${_myStudents.length}',
              label: 'Total Siswa',
              color: _blue)),
      const SizedBox(width: 8),
      Expanded(
          child: _StatisticChip(
              count: '${izinStats['pending']}',
              label: 'Izin Menunggu',
              color: _orange)),
      const SizedBox(width: 8),
      Expanded(
          child: _StatisticChip(
              count: '${izinStats['approved']}',
              label: 'Izin Aktif',
              color: _green)),
    ]);
  }

  Widget _miniCard(IconData icon, String title, String value) {
    return Expanded(
        child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: _primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: _primaryRed.withOpacity(0.2), width: 1)),
            child: Icon(icon, color: _primaryRed, size: 20)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 11, color: _textSecondary)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: _textPrimary)),
        ]),
      ]),
    ));
  }

  Widget _search() {
    return Container(
        height: 44,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ]),
        child: Row(children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: _textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration.collapsed(
                      hintText: 'Cari siswa, izin, atau industri...',
                      hintStyle:
                          TextStyle(color: _textSecondary, fontSize: 13)),
                  onSubmitted: (value) => _performSearch())),
          if (_searchController.text.isNotEmpty)
            IconButton(
                onPressed: () => setState(() => _searchController.clear()),
                icon: const Icon(Icons.clear, color: _textSecondary, size: 18)),
        ]));
  }

  Widget _mainContainer() {
    return Container(
        margin: const EdgeInsets.only(top: 40),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: _borderColor, width: 1),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40), topRight: Radius.circular(40)),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -10))
            ]),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionTitleWithSeeAll(
                'Siswa Bimbingan', _myStudents.length, _navigateToSiswaData),
            const SizedBox(height: 16),
            _siswaList(),
            const SizedBox(height: 40),
            _sectionTitleWithSeeAll(
                'Perizinan Siswa', _izinData.length, _navigateToIzinScreen),
            const SizedBox(height: 16),
            _izinListWidget(),
            const SizedBox(height: 40),
            _sectionTitleWithSeeAll(
                'Data Industri', _industriList.length, _navigateToIndustri),
            const SizedBox(height: 16),
            _industriListWidget(),
          ]),
        ));
  }

  Widget _sectionTitleWithSeeAll(
      String title, int count, VoidCallback onSeeAll) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: _primaryRed)),
          if (count > 0)
            GestureDetector(
                onTap: onSeeAll,
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: _primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _primaryRed.withOpacity(0.2), width: 1)),
                    child: Text('Lihat Semua',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: _primaryRed)))),
        ]));
  }

  Widget _siswaList() {
    if (_myStudents.isEmpty)
      return _emptyList('Belum ada siswa bimbingan', Icons.person_outline);
    return SizedBox(
        height: 218,
        child: Column(children: [
          Expanded(
              child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _myStudents.length,
                  itemBuilder: (context, index) {
                    final siswa = _myStudents[index];
                    return Container(
                        width: MediaQuery.of(context).size.width * 0.75,
                        margin: EdgeInsets.only(
                            right: index < _myStudents.length - 1 ? 16 : 0),
                        child: _siswaCard(siswa));
                  })),
          const SizedBox(height: 8),
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                  alignment: Alignment.centerRight,
                  child: Text('Geser untuk melihat semua siswa →',
                      style: TextStyle(
                          color: _primaryRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)))),
        ]));
  }

  Widget _siswaCard(Map<String, dynamic> siswa) {
    final hariBerjalan = siswa['hari_berjalan'] ?? 0;
    final status = siswa['status'] ?? 'Tidak diketahui';
    return GestureDetector(
        onTap: () async => await _showSiswaDetail(siswa),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 6))
              ]),
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: _primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _primaryRed.withOpacity(0.3), width: 1.5)),
                  child: Icon(Icons.school, color: _primaryRed, size: 26)),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(siswa['nama'],
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.3,
                            color: _textPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _borderColor, width: 1)),
                        child: Row(children: [
                          Icon(Icons.apartment, size: 16, color: _primaryRed),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(siswa['industri'] ?? 'Industri',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _primaryRed),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)),
                        ])),
                  ])),
            ]),
            const SizedBox(height: 16),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: _green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: _green.withOpacity(0.3), width: 1)),
                child: Row(children: [
                  const Icon(Icons.calendar_today, color: _green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text('Menjalankan PKL: $hariBerjalan hari',
                          style: const TextStyle(
                              color: _green,
                              fontWeight: FontWeight.w700,
                              fontSize: 14))),
                ])),
            const SizedBox(height: 8),
            Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(status,
                    style: const TextStyle(
                        color: _green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))),
          ]),
        ));
  }

  Widget _izinListWidget() {
    if (_izinData.isEmpty)
      return _emptyList('Belum ada data perizinan', Icons.event_note);

    final pendingIzin = _izinData
        .where((item) =>
            (item['status']?.toString().toLowerCase() ?? '') == 'pending')
        .take(2)
        .toList();

    if (pendingIzin.isEmpty) {
      final recentIzin = _izinData.take(2).toList();
      return Column(
          children: recentIzin.map((izin) => _izinCard(izin)).toList());
    }

    return Column(
        children: pendingIzin.map((izin) => _izinCard(izin)).toList());
  }

  Widget _izinCard(dynamic izin) {
    final status = _translateStatus(izin['status']?.toString() ?? '');
    final jenis = izin['jenis']?.toString() ?? '';
    final tanggal = izin['tanggal']?.toString() ?? '';
    final keterangan = izin['keterangan']?.toString() ?? '';
    final siswaNama =
        izin['siswa_nama'] ?? izin['siswa_data']?['nama_lengkap'] ?? 'Siswa';
    final statusColor = _getStatusColor(status);
    final isPending =
        (izin['status']?.toString().toLowerCase() ?? '') == 'pending';

    // Format tanggal
    String formattedDate = _formatDate(tanggal);
    // Warna untuk jenis izin
    final jenisColor = jenis.toLowerCase() == 'sakit' ? _orange : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? _orange.withOpacity(0.2)
              : statusColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan nama siswa dan status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      // Ikon jenis izin
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: jenisColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          jenis.toLowerCase() == 'sakit'
                              ? Icons.healing_rounded
                              : Icons.event_note_rounded,
                          color: jenisColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Nama siswa
                      Expanded(
                        child: Text(
                          siswaNama,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        size: 12,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informasi jenis dan tanggal
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: jenisColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        jenis.toLowerCase() == 'sakit'
                            ? Icons.healing
                            : Icons.event,
                        size: 12,
                        color: jenisColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        jenis,
                        style: TextStyle(
                          color: jenisColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 13,
                      color: _textSecondary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Keterangan (jika ada)
            if (keterangan.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_outlined,
                      size: 14,
                      color: _textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        keterangan,
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Indikator pending (jika menunggu)
            if (isPending) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _orange.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_filled,
                      size: 12,
                      color: _orange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Menunggu persetujuan',
                      style: TextStyle(
                        color: _orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Icons.check_circle_outline;
      case 'ditolak':
        return Icons.highlight_off;
      case 'menunggu':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference == 0) {
        return 'Hari ini';
      } else if (difference == 1) {
        return 'Kemarin';
      } else if (difference < 7) {
        return '$difference hari lalu';
      }

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Widget _industriListWidget() {
    if (_industriList.isEmpty)
      return _emptyList('Belum ada data industri', Icons.business);
    final displayIndustri = _industriList.take(2).toList();
    return Column(
        children: displayIndustri
            .map((industri) => _industriCard(industri))
            .toList());
  }

  Widget _industriCard(Map<String, dynamic> industri) {
    return GestureDetector(
        onTap: () => _navigateToIndustriDetail(
            industri['industri_id'], industri['industri_nama']),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _borderColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ]),
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: _primaryRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(Icons.business,
                              color: _primaryRed, size: 24)),
                      const SizedBox(width: 16),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(industri['industri_nama'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: _textPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('ID: ${industri['industri_id']}',
                                style: const TextStyle(
                                    color: _textSecondary, fontSize: 13)),
                          ])),
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: _blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Row(children: [
                            const Icon(Icons.people, size: 14, color: _blue),
                            const SizedBox(width: 4),
                            Text('${industri['jumlah_siswa']} siswa',
                                style: const TextStyle(
                                    color: _blue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ])),
                    ]),
                    const SizedBox(height: 12),
                    const Divider(color: _borderColor),
                    const SizedBox(height: 12),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                              child: Text('Klik untuk melihat detail industri',
                                  style: TextStyle(
                                      color: Color(0xFF6B1B1B),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  textAlign: TextAlign.center)),
                          Icon(Icons.arrow_forward_ios,
                              size: 14, color: _primaryRed),
                        ]),
                  ])),
        ));
  }

  Widget _emptyList(String message, IconData icon) {
    return Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 6))
            ]),
        child: Center(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: _textSecondary, fontSize: 14)),
        ])));
  }

  Future<void> _showSiswaDetail(Map<String, dynamic> siswa) async {
    final siswaId = siswa['siswa_id'];
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child:
                Center(child: CircularProgressIndicator(color: _primaryRed))));
    Map<String, dynamic>? detailSiswa;
    if (siswaId != null) detailSiswa = await _fetchSiswaDetail(siswaId);
    if (context.mounted) Navigator.pop(context);
    if (context.mounted) _showSiswaDetailModal(siswa, detailSiswa);
  }

  void _showSiswaDetailModal(
      Map<String, dynamic> siswa, Map<String, dynamic>? detailSiswa) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) {
          return Container(
              padding: const EdgeInsets.all(24),
              height: MediaQuery.of(context).size.height * 0.85,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Detail Siswa',
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryRed)),
                          IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, size: 28),
                              color: Colors.black),
                        ]),
                    Expanded(
                        child: SingleChildScrollView(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                          Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: _borderColor)),
                              child: Row(children: [
                                Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                        color: _primaryRed.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                            color:
                                                _primaryRed.withOpacity(0.3))),
                                    child: Icon(Icons.school,
                                        color: _primaryRed, size: 28)),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(siswa['nama'],
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                              color: _textPrimary)),
                                      if (siswa['nis'] != null &&
                                          siswa['nis'] != '-')
                                        Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text('NIS: ${siswa['nis']}',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: _primaryRed,
                                                    fontWeight:
                                                        FontWeight.w600))),
                                      if (siswa['kelas'] != null &&
                                          siswa['kelas'] != '-')
                                        Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                                'Kelas: ${siswa['kelas']}',
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: _primaryRed,
                                                    fontWeight:
                                                        FontWeight.w600))),
                                    ])),
                              ])),
                          const SizedBox(height: 24),
                          const Text('Informasi PKL',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _textPrimary)),
                          const SizedBox(height: 12),
                          Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: _borderColor)),
                              child: Column(children: [
                                _infoRow('Status PKL',
                                    siswa['status'] ?? 'Tidak diketahui'),
                                const SizedBox(height: 12),
                                _infoRow('Industri', siswa['industri'] ?? '-'),
                                const SizedBox(height: 12),
                                _infoRow('Tanggal Mulai',
                                    siswa['tanggal_mulai'] ?? '-'),
                                const SizedBox(height: 12),
                                _infoRow('Tanggal Selesai',
                                    siswa['tanggal_selesai'] ?? '-'),
                                const SizedBox(height: 12),
                                _infoRow('Hari Berjalan',
                                    '${siswa['hari_berjalan'] ?? 0} hari'),
                              ])),
                          if (detailSiswa != null) ...[
                            const SizedBox(height: 24),
                            const Text('Informasi Pribadi',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary)),
                            const SizedBox(height: 12),
                            Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: _borderColor)),
                                child: Column(children: [
                                  if (detailSiswa['nama_lengkap'] != null)
                                    _infoRow('Nama Lengkap',
                                        detailSiswa['nama_lengkap']),
                                  if (detailSiswa['alamat'] != null) ...[
                                    const SizedBox(height: 12),
                                    _infoRow('Alamat', detailSiswa['alamat'])
                                  ],
                                  if (detailSiswa['no_telp'] != null) ...[
                                    const SizedBox(height: 12),
                                    _infoRow(
                                        'No. Telepon', detailSiswa['no_telp'])
                                  ],
                                  if (detailSiswa['tanggal_lahir'] != null) ...[
                                    const SizedBox(height: 12),
                                    _infoRow('Tanggal Lahir',
                                        detailSiswa['tanggal_lahir'])
                                  ],
                                ])),
                          ],
                          const SizedBox(height: 24),
                        ]))),
                  ]));
        });
  }

  Widget _infoRow(String label, String value) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
          width: 120,
          child: Text('$label:',
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textSecondary))),
      const SizedBox(width: 8),
      Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary))),
    ]);
  }

  void _navigateToSiswaData() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SiswaDataScreen(students: _myStudents)));
  }

  void _navigateToIzinScreen() {
    _showSnackBar('Navigasi ke halaman perizinan');
  }

  void _navigateToIndustri() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => IndustriDataScreen(industriList: _industriList)));
  }

  Widget _buildSkeletonLoading() {
    return Scaffold(
        backgroundColor: _bgColor,
        body: SingleChildScrollView(
            child: Column(children: [
          Container(
              margin: const EdgeInsets.fromLTRB(16, 40, 16, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _borderColor)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              width: 120,
                              height: 32,
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8))),
                          Row(children: [
                            Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8))),
                            const SizedBox(width: 12),
                            Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12))),
                          ]),
                        ]),
                    const SizedBox(height: 8),
                    Container(
                        width: 180,
                        height: 16,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8))),
                  ])),
          const SizedBox(height: 16),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: _borderColor)),
                  child: Column(children: [
                    Container(
                        height: 70,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(18))),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                          child: Container(
                              height: 70,
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(14)))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Container(
                              height: 70,
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(14)))),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                          child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12)))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Container(
                              height: 60,
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12)))),
                    ]),
                    const SizedBox(height: 14),
                    Container(
                        height: 44,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(30))),
                  ]))),
          Container(
              margin: const EdgeInsets.only(top: 40),
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _borderColor),
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40))),
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            width: 200,
                            height: 30,
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8))),
                        const SizedBox(height: 16),
                        Container(
                            height: 212,
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(18))),
                        const SizedBox(height: 40),
                        Container(
                            width: 200,
                            height: 30,
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8))),
                        const SizedBox(height: 16),
                        Container(
                            height: 200,
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(18))),
                        const SizedBox(height: 40),
                        Container(
                            width: 180,
                            height: 30,
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8))),
                        const SizedBox(height: 16),
                        Container(
                            height: 200,
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(18))),
                      ]))),
        ])));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _StatisticChip extends StatelessWidget {
  final String count;
  final String label;
  final Color color;
  const _StatisticChip(
      {required this.count, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4))
            ]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(count,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A1A))),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF666666))),
        ]));
  }
}

class SiswaDataScreen extends StatelessWidget {
  final List<Map<String, dynamic>> students;
  const SiswaDataScreen({super.key, required this.students});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Data Siswa Bimbingan'),
          backgroundColor: const Color(0xFF6B1B1B)),
      body: students.isEmpty
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Belum ada siswa bimbingan',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ]))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E5E5))),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(children: [
                            Text('${students.length}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6B1B1B))),
                            const Text('Total Siswa',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF666666)))
                          ]),
                          Container(
                              height: 40,
                              width: 1,
                              color: const Color(0xFFE5E5E5)),
                          Column(children: [
                            Text(
                                '${students.where((s) => s['status'] == 'Aktif').length}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.green)),
                            const Text('Siswa Aktif',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF666666)))
                          ]),
                          Container(
                              height: 40,
                              width: 1,
                              color: const Color(0xFFE5E5E5)),
                          Column(children: [
                            Text(
                                '${students.where((s) => s['status'] == 'Selesai').length}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.blue)),
                            const Text('Selesai',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF666666)))
                          ]),
                        ])),
                const SizedBox(height: 20),
                Column(
                    children: students.map((siswa) {
                  final status = siswa['status'] ?? 'Tidak diketahui';
                  Color statusColor = Colors.green;
                  if (status == 'Selesai')
                    statusColor = Colors.blue;
                  else if (status == 'Akan datang') statusColor = Colors.orange;
                  String kelasJurusan = siswa['kelas'] ?? '-';
                  if (siswa['jurusan'] != null && siswa['jurusan'] != '-')
                    kelasJurusan = '${siswa['kelas']} • ${siswa['jurusan']}';
                  return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ]),
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  CircleAvatar(
                                      radius: 24,
                                      backgroundColor: const Color(0xFF6B1B1B)
                                          .withOpacity(0.1),
                                      child: const Icon(Icons.school,
                                          color: Color(0xFF6B1B1B), size: 24)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(siswa['nama'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                                color: Color(0xFF1A1A1A))),
                                        const SizedBox(height: 4),
                                        Text('$kelasJurusan • ${siswa['nis']}',
                                            style: const TextStyle(
                                                color: Color(0xFF666666),
                                                fontSize: 13)),
                                      ])),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Text(status,
                                          style: TextStyle(
                                              color: statusColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600))),
                                ]),
                                const SizedBox(height: 12),
                                Row(children: [
                                  const Icon(Icons.apartment,
                                      size: 16, color: Color(0xFF666666)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(siswa['industri'],
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF6B1B1B)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis))
                                ]),
                                const SizedBox(height: 8),
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(children: [
                                        const Icon(Icons.calendar_today,
                                            size: 16, color: Color(0xFF666666)),
                                        const SizedBox(width: 6),
                                        Text('${siswa['hari_berjalan']} hari',
                                            style: const TextStyle(
                                                color: Color(0xFF666666),
                                                fontSize: 13))
                                      ]),
                                      Text(
                                          '${siswa['tanggal_mulai'] ?? '-'} s/d ${siswa['tanggal_selesai'] ?? '-'}',
                                          style: const TextStyle(
                                              color: Color(0xFF6B1B1B),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600)),
                                    ]),
                              ])));
                }).toList()),
              ])),
    );
  }
}

class IndustriDataScreen extends StatelessWidget {
  final List<Map<String, dynamic>> industriList;
  const IndustriDataScreen({super.key, required this.industriList});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Data Industri'),
          backgroundColor: const Color(0xFF6B1B1B)),
      body: industriList.isEmpty
          ? Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  Icon(Icons.business, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('Belum ada data industri',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                ]))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E5E5))),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(children: [
                            Text('${industriList.length}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6B1B1B))),
                            const Text('Total Industri',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF666666)))
                          ]),
                          Container(
                              height: 40,
                              width: 1,
                              color: const Color(0xFFE5E5E5)),
                          Column(children: [
                            Text(
                                '${industriList.fold(0, (sum, item) => sum + (item['jumlah_siswa'] as int))}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.green)),
                            const Text('Total Siswa',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF666666)))
                          ]),
                        ])),
                const SizedBox(height: 20),
                Column(
                    children: industriList.map((industri) {
                  final int jumlahSiswa = industri['jumlah_siswa'] ?? 0;
                  return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E5E5)),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4))
                          ]),
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  CircleAvatar(
                                      radius: 24,
                                      backgroundColor: const Color(0xFF6B1B1B)
                                          .withOpacity(0.1),
                                      child: const Icon(Icons.business,
                                          color: Color(0xFF6B1B1B), size: 24)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(industri['industri_nama'],
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 16,
                                                color: Color(0xFF1A1A1A))),
                                        const SizedBox(height: 4),
                                        Text('ID: ${industri['industri_id']}',
                                            style: const TextStyle(
                                                color: Color(0xFF666666),
                                                fontSize: 13)),
                                      ])),
                                  Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF6B1B1B)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Row(children: [
                                        const Icon(Icons.people,
                                            size: 14, color: Color(0xFF6B1B1B)),
                                        const SizedBox(width: 4),
                                        Text('$jumlahSiswa',
                                            style: const TextStyle(
                                                color: Color(0xFF6B1B1B),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600)),
                                      ])),
                                ]),
                                const SizedBox(height: 12),
                                const Divider(color: Color(0xFFE5E5E5)),
                                const SizedBox(height: 12),
                                Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Expanded(
                                          child: Text(
                                              'Klik untuk melihat detail industri',
                                              style: TextStyle(
                                                  color: Color(0xFF6B1B1B),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600),
                                              textAlign: TextAlign.center)),
                                      IconButton(
                                          onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      IndustriDetailScreen(
                                                          industriId: industri[
                                                              'industri_id'],
                                                          industriNama: industri[
                                                              'industri_nama']))),
                                          icon: const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 16,
                                              color: Color(0xFF6B1B1B))),
                                    ]),
                              ])));
                }).toList()),
              ])),
    );
  }
}
