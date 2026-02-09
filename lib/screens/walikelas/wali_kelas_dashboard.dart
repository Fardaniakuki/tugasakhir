import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../login/login_screen.dart';
import 'kelola_perizinan_screen.dart';
import 'walikelaspengaturan.dart';

class WaliKelasDashboard extends StatefulWidget {
  const WaliKelasDashboard(
      {super.key, required ScrollController scrollController});
  @override
  State<WaliKelasDashboard> createState() => _WaliKelasDashboardState();
}

class _WaliKelasDashboardState extends State<WaliKelasDashboard> {
  String _namaWaliKelas = 'Wali Kelas';
  String _kelasWali = 'XII TKJ 1';
  bool _isLoading = true;
  bool _isCheckingToken = true;
  List<dynamic> _perizinanData = [];
  List<SiswaPKL> _siswaPKLList = [];
  final Map<int, String> _kelasCache = {};

  int get _totalSIA => _perizinanData.length;
  int get _siaMenunggu => _perizinanData
      .where((item) => item['status']?.toString().toLowerCase() == 'pending')
      .length;
  int get _siaDisetujui => _perizinanData
      .where((item) => item['status']?.toString().toLowerCase() == 'approved')
      .length;
  int get _siaDitolak => _perizinanData
      .where((item) => item['status']?.toString().toLowerCase() == 'rejected')
      .length;

  final int _laporanSelesai = 12;
  final int _laporanBelum = 5;
  final int _progresBaik = 10;
  final int _progresKurang = 7;
  final List<Map<String, dynamic>> _permasalahanList = [
    {
      'id': 'M001',
      'nama': 'Ahmad Rizki',
      'kelas': 'XII TKJ 1',
      'industri': 'PT. Teknologi Indonesia',
      'jenis': 'Konflik dengan Supervisor',
      'status': 'Terselesaikan',
      'solusi': 'Dilakukan mediasi dengan HRD',
      'tanggal': '10 Jan 2024',
      'lokasi': 'Tempat PKL',
      'statusColor': const Color(0xFF4CAF50)
    },
    {
      'id': 'M002',
      'nama': 'Siti Nurhaliza',
      'kelas': 'XII RPL 2',
      'industri': 'CV. Digital Solusi',
      'jenis': 'Teknis Pekerjaan',
      'status': 'Belum',
      'solusi': 'Menunggu jadwal pendampingan',
      'tanggal': '12 Jan 2024',
      'lokasi': 'Tempat PKL',
      'statusColor': const Color(0xFFFF9800)
    },
    {
      'id': 'M003',
      'nama': 'Budi Santoso',
      'kelas': 'XII MM 1',
      'industri': 'PT. Media Kreatif',
      'jenis': 'Transportasi',
      'status': 'Terselesaikan',
      'solusi': 'Dicarikan carpool',
      'tanggal': '8 Jan 2024',
      'lokasi': 'Perjalanan ke PKL',
      'statusColor': const Color(0xFF4CAF50)
    },
    {
      'id': 'M004',
      'nama': 'Dewi Lestari',
      'kelas': 'XII TKJ 2',
      'industri': 'PT. Network Indonesia',
      'jenis': 'Komunikasi',
      'status': 'Terselesaikan',
      'solusi': 'Bimbingan komunikasi',
      'tanggal': '15 Jan 2024',
      'lokasi': 'Tempat PKL',
      'statusColor': const Color(0xFF4CAF50)
    },
  ];

  int get _permasalahanTotal => _permasalahanList.length;
  static const Color _primaryRed = Color(0xFF6B1B1B);
  static const Color _bgSoft = Color(0xFF6B1B1B);
  static const Color _secondaryColor = Colors.white;
  static const Color _borderOrange = Color(0xFFFFB74D);
  static const Color _orange = Color(0xFFFF9800);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _red = Color(0xFFF44336);
  static const Color _darkRed = Color(0xFFB71C1C);

  @override
  void initState() {
    super.initState();
    _checkTokenAndLoadProfile();
  }

  Future<void> _checkTokenAndLoadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }
    await _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? '';
      if (apiUrl.isNotEmpty) {
        final response = await http.get(
          Uri.parse('$apiUrl/api/guru/profile'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true && data['data'] != null) {
            final guruData = data['data'];
            setState(() {
              _namaWaliKelas = guruData['nama'] ?? 'Wali Kelas';
              if (guruData['kelas_diampu'] != null &&
                  guruData['kelas_diampu'].isNotEmpty) {
                if (guruData['kelas_diampu'] is List) {
                  final kelasList = guruData['kelas_diampu'] as List;
                  if (kelasList.isNotEmpty) {
                    final kelasData = kelasList[0];
                    _kelasWali =
                        kelasData['nama'] ?? kelasData['kelas'] ?? 'Kelas';
                  }
                } else if (guruData['kelas_diampu'] is String) {
                  _kelasWali = guruData['kelas_diampu'];
                }
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
    } finally {
      await _fetchPerizinanData();
      await _fetchDashboardData();
      setState(() {
        _isCheckingToken = false;
        _isLoading = false;
      });
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> _fetchKelas(int kelasId) async {
    try {
      if (_kelasCache.containsKey(kelasId)) return _kelasCache[kelasId];
      final token = await _getToken();
      if (token == null) return null;
      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final response = await http.get(
        Uri.parse('$baseUrl/api/kelas/$kelasId'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final kelasNama = data['data']['nama'] ?? 'Tidak Diketahui';
          _kelasCache[kelasId] = kelasNama;
          return kelasNama;
        }
      }
    } catch (e) {
      print('Error fetching kelas: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchSiswaDetail(int siswaId) async {
    try {
      final token = await _getToken();
      if (token == null) return null;
      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final response = await http.get(
        Uri.parse('$baseUrl/api/siswa/$siswaId'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final siswaData = data['data'] as Map<String, dynamic>;
          final kelasId = siswaData['kelas_id'];
          if (kelasId != null) {
            final kelasNama = await _fetchKelas(kelasId);
            siswaData['kelas'] = kelasNama ?? 'Tidak Diketahui';
          }
          siswaData['nama_lengkap'] = siswaData['nama_lengkap'] ??
              siswaData['username'] ??
              'Siswa $siswaId';
          return siswaData;
        }
      }
    } catch (e) {
      print('Error fetching siswa detail: $e');
    }
    return null;
  }

  Future<void> _fetchPerizinanData() async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final response = await http.get(
        Uri.parse('$baseUrl/api/izin/wali-kelas'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> processedData = [];
        if (data is List && data.isNotEmpty) {
          for (var izin in data) {
            if (izin['siswa_id'] != null) {
              final siswaDetail = await _fetchSiswaDetail(izin['siswa_id']);
              if (siswaDetail != null) {
                izin['siswa_data'] = siswaDetail;
                izin['siswa_nama'] = siswaDetail['nama_lengkap'];
                izin['kelas'] = siswaDetail['kelas'] ?? '-';
              }
            }
            processedData.add(izin);
            if (processedData.length >= 4) break;
          }
        }
        setState(() {
          _perizinanData = processedData;
        });
      }
    } catch (e) {
      print('Error fetching perizinan data: $e');
      _setDummyData();
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final response = await http.get(
        Uri.parse('$baseUrl/api/guru/dashboard/wali-kelas?page=1&limit=10'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<SiswaPKL> siswaList = [];
        if (data['siswa_list'] is List) {
          for (var siswa in data['siswa_list']) {
            siswaList.add(SiswaPKL.fromJson(siswa));
          }
        }
        setState(() {
          _siswaPKLList = siswaList;
          if (data['kelas_info'] != null) {
            final kelasInfo = KelasInfo.fromJson(data['kelas_info']);
            _kelasWali = kelasInfo.nama;
          }
        });
      }
    } catch (e) {
      print('Error fetching dashboard data: $e');
    }
  }

  void _setDummyData() {
    setState(() {
      _perizinanData = [
        {
          'id': 1,
          'siswa_id': 78,
          'siswa_nama': 'Ahmad Rizki',
          'kelas': 'XII TKJ 1',
          'industri': 'PT. Teknologi Indonesia',
          'jenis': 'Sakit',
          'tanggal': '15-20 Jan 2024',
          'keterangan': 'Demam tinggi, ada surat dokter',
          'status': 'approved',
          'bukti_foto_urls': []
        },
        {
          'id': 2,
          'siswa_id': 190,
          'siswa_nama': 'Siti Nurhaliza',
          'kelas': 'XII RPL 2',
          'industri': 'CV. Digital Solusi',
          'jenis': 'Izin',
          'tanggal': '18-19 Jan 2024',
          'keterangan': 'Mengikuti seminar teknologi',
          'status': 'pending',
          'bukti_foto_urls': []
        },
        {
          'id': 3,
          'siswa_id': 166,
          'siswa_nama': 'Budi Santoso',
          'kelas': 'XII MM 1',
          'industri': 'PT. Media Kreatif',
          'jenis': 'Sakit',
          'tanggal': '22-24 Jan 2024',
          'keterangan': 'Pusing dan mual',
          'status': 'approved',
          'bukti_foto_urls': []
        },
        {
          'id': 4,
          'siswa_id': 200,
          'siswa_nama': 'Dewi Lestari',
          'kelas': 'XII TKJ 2',
          'industri': 'PT. Network Indonesia',
          'jenis': 'Izin',
          'tanggal': '17 Jan 2024',
          'keterangan': 'Keperluan keluarga',
          'status': 'rejected',
          'rejection_reason': 'Bukti tidak jelas',
          'bukti_foto_urls': []
        },
      ];
    });
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time;
      default:
        return Icons.help_outline;
    }
  }

  IconData _getSIAIcon(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'sakit':
        return Icons.healing;
      case 'izin':
        return Icons.person_pin_circle;
      default:
        return Icons.description;
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

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WaliKelasProfilePage(
          namaWaliKelas: _namaWaliKelas,
          kelasWali: _kelasWali,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingToken) {
      return _buildSkeletonLoadingScreen();
    }
    return Scaffold(
      backgroundColor: _bgSoft,
      body: _isLoading ? _buildSkeletonLoadingScreen() : _content(),
    );
  }

  Widget _content() {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchPerizinanData();
        await _fetchDashboardData();
      },
      backgroundColor: Colors.white,
      color: _primaryRed,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _headerCard(),
            const SizedBox(height: 16),
            _topCard(),
            _mainContainer(),
          ],
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
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Beranda',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B1B1B))),
              Row(
                children: [
                  IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none,
                          color: Color(0xFF6B1B1B), size: 26)),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _navigateToSettings,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B1B1B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF6B1B1B).withOpacity(0.3),
                            width: 1.5),
                      ),
                      child: const Icon(Icons.person_outline,
                          color: Color(0xFF6B1B1B), size: 22),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selamat Datang, $_namaWaliKelas', // Ini akan menampilkan nama dari variabel
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _topCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          children: [
            _siaCard(),
            const SizedBox(height: 14),
            Row(
              children: [
                _miniCard(Icons.description, 'Laporan',
                    '$_laporanSelesai/$_laporanBelum', const Color(0xFF009688)),
                const SizedBox(width: 12),
                _miniCard(Icons.trending_up, 'Progres',
                    '$_progresBaik/$_progresKurang', const Color(0xFF9C27B0)),
              ],
            ),
            const SizedBox(height: 14),
            _siaChips(),
            const SizedBox(height: 14),
            _pklStatsCard(),
          ],
        ),
      ),
    );
  }

  Widget _siaCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => KelolaPerizinanTabScreen(
                  scrollController: ScrollController())),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _primaryRed,
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: _primaryRed.withValues(alpha: 0.8), width: 1),
          boxShadow: [
            BoxShadow(
                color: _primaryRed.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.healing, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
                child: Text('Sakit Dan Izin',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text('$_totalSIA',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _siaChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
            child: _PengajuanChip(
                count: '$_siaMenunggu', label: 'Menunggu', color: _orange)),
        const SizedBox(width: 8),
        Expanded(
            child: _PengajuanChip(
                count: '$_siaDisetujui', label: 'Disetujui', color: _green)),
        const SizedBox(width: 8),
        Expanded(
            child: _PengajuanChip(
                count: '$_siaDitolak', label: 'Ditolak', color: _red)),
      ],
    );
  }

  Widget _miniCard(IconData icon, String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _borderOrange.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: color.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pklStatsCard() {
    final totalSiswa = _siswaPKLList.length;
    final sedangPKL =
        _siswaPKLList.where((siswa) => siswa.statusPkl == 'Sedang PKL').length;
    final belumPKL =
        _siswaPKLList.where((siswa) => siswa.statusPkl == 'Belum PKL').length;
    final selesaiPKL =
        _siswaPKLList.where((siswa) => siswa.statusPkl == 'Selesai PKL').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.business, size: 20, color: _primaryRed),
              const SizedBox(width: 8),
              const Text('Statistik PKL',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _primaryRed)),
              const Spacer(),
              Text('$totalSiswa siswa',
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pklStatChip('Sedang PKL', '$sedangPKL',
                  const Color.fromARGB(255, 0, 0, 0)),
              _pklStatChip(
                  'Belum PKL', '$belumPKL', const Color.fromARGB(255, 0, 0, 0)),
              _pklStatChip('Selesai PKL', '$selesaiPKL',
                  const Color.fromARGB(255, 0, 0, 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pklStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainContainer() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        color: _secondaryColor,
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40), topRight: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -10))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitleWithSeeAll('Perizinan Terkini', _perizinanData.length),
            const SizedBox(height: 16),
            _siaListHorizontal(),
            const SizedBox(height: 40),
            _sectionTitleWithSeeAll('Siswa PKL', _siswaPKLList.length),
            const SizedBox(height: 16),
            _siswaPklListHorizontal(),
            const SizedBox(height: 40),
            _sectionTitleWithSeeAll('Permasalahan Siswa', _permasalahanTotal),
            const SizedBox(height: 16),
            _permasalahanListHorizontal(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitleWithSeeAll(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: Color(0xFF6B1B1B))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _primaryRed.withValues(alpha: 0.2), width: 1),
            ),
            child: Text('$count total',
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF6B1B1B))),
          ),
        ],
      ),
    );
  }

  Widget _siaListHorizontal() {
    if (_perizinanData.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey[200]!)),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.healing, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('Tidak ada data perizinan',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
          ]),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _perizinanData.length,
        itemBuilder: (context, index) {
          final perizinan = _perizinanData[index];
          return Container(
            width: 300,
            margin: EdgeInsets.only(
                right: index < _perizinanData.length - 1 ? 16 : 0),
            child: _siaCardHorizontal(perizinan),
          );
        },
      ),
    );
  }

  Widget _siaCardHorizontal(dynamic perizinanData) {
    final siswaName = perizinanData['siswa_nama'] ??
        perizinanData['siswa_data']?['nama_lengkap'] ??
        'Siswa ${perizinanData['siswa_id']}';
    final jenis = perizinanData['jenis']?.toString() ?? '';
    final tanggal = perizinanData['tanggal']?.toString().split(' ')[0] ?? '';
    final status = _translateStatus(perizinanData['status']?.toString() ?? '');
    final statusColor =
        _getStatusColor(perizinanData['status']?.toString() ?? '');
    final kelas =
        perizinanData['kelas'] ?? perizinanData['siswa_data']?['kelas'] ?? '-';
    final keterangan = perizinanData['keterangan']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        _showSIADetail(perizinanData);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _primaryRed.withValues(alpha: 0.3),
                          width: 1.5),
                    ),
                    child:
                        Icon(_getSIAIcon(jenis), color: _primaryRed, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(siswaName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        if (kelas.isNotEmpty && kelas != '-')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.grey[300]!, width: 1)),
                            child: Text(kelas,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Text(tanggal,
                    style: const TextStyle(fontSize: 12, color: Colors.grey))
              ]),
              const SizedBox(height: 8),
              if (keterangan.isNotEmpty)
                Text(
                    keterangan.length > 50
                        ? '${keterangan.substring(0, 50)}...'
                        : keterangan,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: statusColor.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        _getStatusIcon(
                            perizinanData['status']?.toString() ?? ''),
                        color: statusColor,
                        size: 16),
                    const SizedBox(width: 6),
                    Text('$jenis - $status',
                        style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showSIADetail(perizinanData),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryRed,
                    side: const BorderSide(color: _primaryRed),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  icon: const Icon(Icons.visibility, size: 14),
                  label: const Text('LIHAT DETAIL',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _siswaPklListHorizontal() {
    // Filter hanya siswa yang SEDANG PKL
    final List<SiswaPKL> siswaSedangPKL = _siswaPKLList
        .where((siswa) => siswa.statusPkl == 'Sedang PKL')
        .toList();

    if (siswaSedangPKL.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_outlined, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              const Text(
                'Tidak ada siswa yang sedang PKL',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 330,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: siswaSedangPKL.length,
        itemBuilder: (context, index) {
          final siswa = siswaSedangPKL[index];
          return Container(
            width: 320,
            margin: EdgeInsets.only(
              right: index < siswaSedangPKL.length - 1 ? 16 : 0,
              left: index == 0 ? 4 : 0,
            ),
            child: _siswaPklCard(siswa),
          );
        },
      ),
    );
  }

  Widget _siswaPklCard(SiswaPKL siswa) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan avatar dan nama
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF2196F3),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siswa.nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          height: 1.2,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'NISN: ${siswa.nisn}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status PKL badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_circle_fill,
                    color: Color(0xFF2196F3),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    siswa.statusPkl,
                    style: const TextStyle(
                      color: Color(0xFF2196F3),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Info PKL
            if (siswa.industri != null && siswa.industri!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          siswa.industri!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF444444),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            if (siswa.pembimbing != null && siswa.pembimbing!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Pembimbing: ${siswa.pembimbing!}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

            if (siswa.alamatIndustri != null &&
                siswa.alamatIndustri!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        siswa.alamatIndustri!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),

            // Tombol detail
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showSiswaDetail(siswa),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                label: const Text(
                  'LIHAT DETAIL PKL',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _permasalahanListHorizontal() {
    return SizedBox(
      height: 255,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _permasalahanList.length,
        itemBuilder: (context, index) {
          final masalahData = _permasalahanList[index];
          return Container(
            width: 280,
            margin: EdgeInsets.only(
                right: index < _permasalahanList.length - 1 ? 16 : 0),
            child: _permasalahanCardHorizontal(masalahData),
          );
        },
      ),
    );
  }

  Widget _permasalahanCardHorizontal(Map<String, dynamic> masalahData) {
    final siswaName = masalahData['nama'];
    final jenis = masalahData['jenis'];
    final status = masalahData['status'];
    final statusColor = masalahData['statusColor'] as Color;
    final kelas = masalahData['kelas'];
    final industri = masalahData['industri'];

    return GestureDetector(
      onTap: () {
        _showPermasalahanDetail(masalahData);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey[200]!, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 6))
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _darkRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _darkRed.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.warning, color: _darkRed, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(siswaName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.2),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        if (kelas.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.grey[300]!, width: 1)),
                            child: Text(kelas,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.apartment, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(industri,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis))
              ]),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: _darkRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: _darkRed.withValues(alpha: 0.3), width: 1)),
                child: Text(jenis,
                    style: const TextStyle(
                        color: _darkRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.3), width: 1)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                      status == 'Terselesaikan'
                          ? Icons.check_circle
                          : Icons.access_time,
                      color: statusColor,
                      size: 16),
                  const SizedBox(width: 6),
                  Text(status,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12))
                ]),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showPermasalahanDetail(masalahData),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: _darkRed,
                      side: const BorderSide(color: _darkRed),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      minimumSize: const Size(0, 36)),
                  icon: const Icon(Icons.visibility, size: 14),
                  label: const Text('LIHAT DETAIL',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSIADetail(dynamic data) {
    final status = _translateStatus(data['status']?.toString() ?? '');
    final jenis = data['jenis']?.toString() ?? '';
    final tanggal = data['tanggal']?.toString() ?? '';
    final keterangan = data['keterangan']?.toString() ?? '';
    final siswaNama = data['siswa_nama'] ??
        data['siswa_data']?['nama_lengkap'] ??
        'Siswa ${data['siswa_id']}';
    final kelas = data['kelas'] ?? data['siswa_data']?['kelas'] ?? '-';
    final fotoUrls =
        (data['bukti_foto_urls'] as List<dynamic>?)?.cast<String>() ?? [];
    final statusColor = _getStatusColor(data['status']?.toString() ?? '');
    final rejectionReason = data['rejection_reason'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      builder: (context) => _siaDetailBottomSheet(
          data,
          siswaNama,
          jenis,
          tanggal,
          keterangan,
          kelas,
          fotoUrls,
          status,
          statusColor,
          rejectionReason),
    );
  }

  Widget _siaDetailBottomSheet(
      dynamic data,
      String siswaName,
      String jenis,
      String tanggal,
      String keterangan,
      String kelas,
      List<String> fotoUrls,
      String status,
      Color statusColor,
      String? rejectionReason) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text('Detail Perizinan SIA',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B1B1B))),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: _primaryRed.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: _primaryRed.withValues(alpha: 0.1))),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                              color: _primaryRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _primaryRed.withValues(alpha: 0.3))),
                          child: Icon(_getSIAIcon(jenis),
                              color: _primaryRed, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(siswaName,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(kelas,
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3))),
                          child: Text(status,
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Informasi Pengajuan',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!)),
                    child: Column(
                      children: [
                        _detailInfoRow('Jenis Perizinan', jenis),
                        const SizedBox(height: 12),
                        _detailInfoRow('Tanggal Pengajuan', tanggal),
                        const SizedBox(height: 12),
                        _detailInfoRow('Status', status),
                        const SizedBox(height: 12),
                        _detailInfoRow('Alasan', keterangan),
                        if (rejectionReason != null) ...[
                          const SizedBox(height: 12),
                          _detailInfoRow('Alasan Penolakan', rejectionReason),
                        ],
                        if (fotoUrls.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                    width: 120,
                                    child: Text('Bukti Foto:',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey))),
                                SizedBox(width: 8),
                              ]),
                          const SizedBox(height: 8),
                          ...fotoUrls.map((url) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: GestureDetector(
                                  onTap: () => _showImagePreview([url]),
                                  child: Container(
                                    width: double.infinity,
                                    height: 200,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey[300]!)),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        url,
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Center(
                                              child: CircularProgressIndicator(
                                                  value: loadingProgress
                                                              .expectedTotalBytes !=
                                                          null
                                                      ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                      : null));
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                    color: Colors.grey[200],
                                                    child: const Center(
                                                        child: Icon(
                                                            Icons.broken_image,
                                                            color: Colors.grey,
                                                            size: 48))),
                                      ),
                                    ),
                                  ),
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          if (status == 'Menunggu')
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectSIA(data),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: const BorderSide(color: _red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('TOLAK',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveSIA(data),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text('SETUJUI',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('TUTUP',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showImagePreview(List<String> imageUrls) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Bukti Foto',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600)),
                        IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context)),
                      ])),
              Expanded(
                child: PageView.builder(
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) => InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[800],
                        child: const Center(
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                              Icon(Icons.broken_image,
                                  color: Colors.grey, size: 48),
                              SizedBox(height: 12),
                              Text('Gagal memuat gambar',
                                  style: TextStyle(color: Colors.grey)),
                            ])),
                      ),
                    ),
                  ),
                ),
              ),
              if (imageUrls.length > 1)
                Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.black,
                    child: Text(
                        'Gambar ${imageUrls.length} - Geser untuk melihat lainnya',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white60, fontSize: 12))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
            width: 140,
            child: Text('$label:',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey))),
        const SizedBox(width: 8),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500))),
      ],
    );
  }

  void _approveSIA(dynamic data) async {
    try {
      final token = await _getToken();
      if (token == null) return;
      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final response = await http.post(
        Uri.parse('$baseUrl/api/izin/${data['id']}/approve'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          data['status'] = 'approved';
        });
        _showSnackBar('Pengajuan ${data['jenis']} disetujui');
        Navigator.pop(context);
      } else {
        _showSnackBar('Gagal menyetujui pengajuan', isError: true);
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan', isError: true);
    }
  }

  void _rejectSIA(dynamic data) {
    final TextEditingController alasanController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                              color: _red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14)),
                          child:
                              const Icon(Icons.close, color: _red, size: 24)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TOLAK PENGAJUAN',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6B1B1B))),
                            const SizedBox(height: 4),
                            Text('Siswa: ${data['siswa_nama']}',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Alasan Penolakan',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B1B1B))),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!)),
                    child: TextField(
                      controller: alasanController,
                      maxLines: 4,
                      decoration: const InputDecoration.collapsed(
                          hintText: 'Masukkan alasan penolakan...',
                          hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 14)),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: _primaryRed,
                              side: const BorderSide(color: Color(0xFF6B1B1B)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('BATAL',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (alasanController.text.trim().isEmpty) {
                              _showSnackBar('Masukkan alasan penolakan',
                                  isError: true);
                              return;
                            }
                            try {
                              final token = await _getToken();
                              if (token == null) return;
                              final baseUrl = dotenv.env['API_BASE_URL'] ??
                                  'https://api.gedanggoreng.com';
                              final response = await http.post(
                                Uri.parse(
                                    '$baseUrl/api/izin/${data['id']}/reject'),
                                headers: {
                                  'accept': 'application/json',
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json'
                                },
                                body: jsonEncode({
                                  'rejection_reason':
                                      alasanController.text.trim()
                                }),
                              );
                              if (response.statusCode == 200) {
                                setState(() {
                                  data['status'] = 'rejected';
                                  data['rejection_reason'] =
                                      alasanController.text.trim();
                                });
                                _showSnackBar('Pengajuan ditolak');
                                Navigator.pop(context);
                                Navigator.pop(context);
                              } else {
                                _showSnackBar('Gagal menolak pengajuan',
                                    isError: true);
                              }
                            } catch (e) {
                              _showSnackBar('Terjadi kesalahan', isError: true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text('TOLAK',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        backgroundColor: isError ? _red : _green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSiswaDetail(SiswaPKL siswa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      builder: (context) => _siswaDetailBottomSheet(siswa),
    );
  }

  Widget _siswaDetailBottomSheet(SiswaPKL siswa) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.help_outline;

    if (siswa.statusPkl == 'Sedang PKL') {
      statusColor = const Color(0xFF2196F3);
      statusIcon = Icons.play_circle_fill;
    } else if (siswa.statusPkl == 'Belum PKL') {
      statusColor = const Color(0xFFFF9800);
      statusIcon = Icons.access_time;
    } else if (siswa.statusPkl == 'Selesai PKL') {
      statusColor = const Color(0xFF4CAF50);
      statusIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text('Detail Siswa PKL',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6B1B1B))),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.1))),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3))),
                          child: Icon(statusIcon, color: statusColor, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(siswa.nama,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('NISN: ${siswa.nisn}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3))),
                          child: Text(siswa.statusPkl,
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Informasi PKL',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!)),
                    child: Column(
                      children: [
                        if (siswa.industri != null)
                          _detailInfoRow('Industri', siswa.industri!),
                        if (siswa.industri != null) const SizedBox(height: 12),
                        if (siswa.alamatIndustri != null)
                          _detailInfoRow(
                              'Alamat Industri', siswa.alamatIndustri!),
                        if (siswa.alamatIndustri != null)
                          const SizedBox(height: 12),
                        if (siswa.pembimbing != null)
                          _detailInfoRow(
                              'Pembimbing Sekolah', siswa.pembimbing!),
                        if (siswa.pembimbing != null)
                          const SizedBox(height: 12),
                        if (siswa.pembimbingIndustri != null)
                          _detailInfoRow(
                              'Pembimbing Industri', siswa.pembimbingIndustri!),
                        if (siswa.pembimbingIndustri != null)
                          const SizedBox(height: 12),
                        if (siswa.noTelpIndustri != null)
                          _detailInfoRow(
                              'Telp Industri', siswa.noTelpIndustri!),
                        if (siswa.noTelpIndustri != null)
                          const SizedBox(height: 12),
                        if (siswa.noTelpPembimbingSekolah != null)
                          _detailInfoRow('Telp Pembimbing',
                              siswa.noTelpPembimbingSekolah!),
                        if (siswa.noTelpPembimbingSekolah != null)
                          const SizedBox(height: 12),
                        _detailInfoRow('Status PKL', siswa.statusPkl),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('TUTUP',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showPermasalahanDetail(Map<String, dynamic> masalahData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24))),
      builder: (context) => _permasalahanDetailBottomSheet(masalahData),
    );
  }

  Widget _permasalahanDetailBottomSheet(Map<String, dynamic> masalahData) {
    final siswaName = masalahData['nama'];
    final jenis = masalahData['jenis'];
    const deskripsi =
        'Siswa mengalami kesulitan dalam hal ini. Klik tombol di bawah untuk melihat detail lengkap.';
    final status = masalahData['status'];
    final solusi = masalahData['solusi'] ?? 'Belum ada solusi';
    final kelas = masalahData['kelas'] ?? '';
    final industri = masalahData['industri'] ?? '';
    final tanggal = masalahData['tanggal'] ?? '-';
    final lokasi = masalahData['lokasi'] ?? 'Tempat PKL';
    final statusColor = masalahData['statusColor'] as Color;

    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
              child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 24),
          const Text('Detail Permasalahan',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB71C1C))),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: _darkRed.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: _darkRed.withValues(alpha: 0.1))),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                              color: _darkRed.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _darkRed.withValues(alpha: 0.3))),
                          child: const Icon(Icons.warning,
                              color: _darkRed, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(siswaName,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('$kelas • $industri',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: statusColor.withValues(alpha: 0.3))),
                          child: Text(status,
                              style: TextStyle(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Informasi Permasalahan',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!)),
                    child: Column(
                      children: [
                        _detailInfoRow('Jenis Permasalahan', jenis),
                        const SizedBox(height: 12),
                        _detailInfoRow('Tanggal Laporan', tanggal),
                        const SizedBox(height: 12),
                        _detailInfoRow('Lokasi', lokasi),
                        const SizedBox(height: 12),
                        _detailInfoRow('Status', status),
                        const SizedBox(height: 12),
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                                width: 140,
                                child: Text('Deskripsi:',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey))),
                            SizedBox(width: 8),
                            Expanded(
                                child: Text(deskripsi,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                                width: 140,
                                child: Text('Solusi/Tindakan:',
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey))),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(solusi,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: status == 'Terselesaikan'
                                            ? _green
                                            : _orange))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoadingScreen() {
    return Scaffold(
      backgroundColor: _bgSoft,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 40, 16, 0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6))
                    ]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              width: 180,
                              height: 30,
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(8))),
                          Row(children: [
                            Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(20))),
                            const SizedBox(width: 12),
                            Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12)))
                          ]),
                        ]),
                    const SizedBox(height: 16),
                    Container(
                        width: 220,
                        height: 20,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 8))
                    ]),
                child: Column(
                  children: [
                    Container(
                        height: 80,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
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
                                  borderRadius: BorderRadius.circular(14))))
                    ]),
                    const SizedBox(height: 14),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Container(
                                  height: 70,
                                  decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius:
                                          BorderRadius.circular(12)))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Container(
                                  height: 70,
                                  decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius:
                                          BorderRadius.circular(12)))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Container(
                                  height: 70,
                                  decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius:
                                          BorderRadius.circular(12)))),
                        ]),
                    const SizedBox(height: 14),
                    Container(
                        height: 100,
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(18))),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -10))
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              width: 150,
                              height: 25,
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(6))),
                          Container(
                              width: 60,
                              height: 25,
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12))),
                        ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 210,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) => Container(
                            width: 300,
                            margin: EdgeInsets.only(right: index < 2 ? 16 : 0),
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(18))),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              width: 150,
                              height: 25,
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(6))),
                          Container(
                              width: 60,
                              height: 25,
                              decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12))),
                        ]),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 195,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) => Container(
                            width: 280,
                            margin: EdgeInsets.only(right: index < 2 ? 16 : 0),
                            decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(18))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class KelasInfo {
  final int id;
  final String nama;
  final int totalSiswa;

  KelasInfo({required this.id, required this.nama, required this.totalSiswa});

  factory KelasInfo.fromJson(Map<String, dynamic> json) {
    return KelasInfo(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      totalSiswa: json['total_siswa'] ?? 0,
    );
  }
}

class SiswaPKL {
  final int id;
  final String nisn;
  final String nama;
  final String statusPkl;
  final String? industri;
  final String? pembimbing;
  final String? alamatIndustri;
  final String? pembimbingIndustri;
  final String? noTelpIndustri;
  final String? noTelpPembimbingSekolah;

  SiswaPKL({
    required this.id,
    required this.nisn,
    required this.nama,
    required this.statusPkl,
    this.industri,
    this.pembimbing,
    this.alamatIndustri,
    this.pembimbingIndustri,
    this.noTelpIndustri,
    this.noTelpPembimbingSekolah,
  });

  factory SiswaPKL.fromJson(Map<String, dynamic> json) {
    return SiswaPKL(
      id: json['id'] ?? 0,
      nisn: json['nisn'] ?? '',
      nama: json['nama'] ?? '',
      statusPkl: json['status_pkl'] ?? '',
      industri: json['industri'],
      pembimbing: json['pembimbing'],
      alamatIndustri: json['alamat_industri'],
      pembimbingIndustri: json['pembimbing_industri'],
      noTelpIndustri: json['no_telp_industri'],
      noTelpPembimbingSekolah: json['no_telp_pembimbing_sekolah'],
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;

  Pagination({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      totalItems: json['total_items'] ?? 0,
      totalPages: json['total_pages'] ?? 1,
    );
  }
}

class WaliKelasDashboardResponse {
  final KelasInfo kelasInfo;
  final List<SiswaPKL> siswaList;
  final Pagination pagination;

  WaliKelasDashboardResponse({
    required this.kelasInfo,
    required this.siswaList,
    required this.pagination,
  });

  factory WaliKelasDashboardResponse.fromJson(Map<String, dynamic> json) {
    return WaliKelasDashboardResponse(
      kelasInfo: KelasInfo.fromJson(json['kelas_info']),
      siswaList: (json['siswa_list'] as List)
          .map((e) => SiswaPKL.fromJson(e))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }
}

class _PengajuanChip extends StatelessWidget {
  final String count;
  final String label;
  final Color color;
  const _PengajuanChip(
      {required this.count, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!, width: 1)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(count,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.black)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700])),
      ]),
    );
  }
}
