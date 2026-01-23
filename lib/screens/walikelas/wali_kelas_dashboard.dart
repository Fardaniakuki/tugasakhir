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

  // Data statistik SIA (Sakit/Izin/Alpha) - DIHITUNG OTOMATIS
  int get _totalSIA => _siaList.length;
  int get _siaMenunggu =>
      _siaList.where((sia) => sia['status'] == 'Menunggu').length;
  int get _siaDisetujui =>
      _siaList.where((sia) => sia['status'] == 'Disetujui').length;
  int get _siaDitolak =>
      _siaList.where((sia) => sia['status'] == 'Ditolak').length;

  // Data laporan dan progres - DUMMY DATA
  final int _laporanSelesai = 12;
  final int _laporanBelum = 5;
  final int _progresBaik = 10;
  final int _progresKurang = 7;

  // Data permasalahan - DUMMY DATA
  final int _permasalahanTotal = 6;

  // Data SIA - DUMMY DATA
  final List<Map<String, dynamic>> _siaList = [
    {
      'id': 'S001',
      'nama': 'Ahmad Rizki',
      'kelas': 'XII TKJ 1',
      'industri': 'PT. Teknologi Indonesia',
      'jenis': 'Izin',
      'tanggal': '15-20 Jan 2024',
      'alasan': 'Keperluan keluarga penting',
      'status': 'Disetujui',
      'catatan': 'Izin disetujui',
      'statusColor': const Color(0xFF4CAF50),
      'dokumen': null,
      'tanggal_diajukan': '14 Jan 2024',
    },
    {
      'id': 'S002',
      'nama': 'Siti Nurhaliza',
      'kelas': 'XII RPL 2',
      'industri': 'CV. Digital Solusi',
      'jenis': 'Izin',
      'tanggal': '18-19 Jan 2024',
      'alasan': 'Mengikuti seminar teknologi',
      'status': 'Menunggu',
      'catatan': 'Menunggu persetujuan',
      'statusColor': const Color(0xFFFF9800),
      'dokumen': 'surat_seminar.pdf',
      'tanggal_diajukan': '17 Jan 2024',
    },
    {
      'id': 'S003',
      'nama': 'Budi Santoso',
      'kelas': 'XII MM 1',
      'industri': 'PT. Media Kreatif',
      'jenis': 'Sakit',
      'tanggal': '22-24 Jan 2024',
      'alasan': 'Demam dan flu',
      'status': 'Disetujui',
      'catatan': 'Perlu istirahat',
      'statusColor': const Color(0xFF4CAF50),
      'dokumen': 'surat_dokter.pdf',
      'tanggal_diajukan': '21 Jan 2024',
    },
    {
      'id': 'S004',
      'nama': 'Dewi Lestari',
      'kelas': 'XII TKJ 2',
      'industri': 'PT. Network Indonesia',
      'jenis': 'Alpha',
      'tanggal': '17 Jan 2024',
      'alasan': 'Tidak ada keterangan',
      'status': 'Ditolak',
      'catatan': 'Harap konfirmasi',
      'statusColor': const Color(0xFFF44336),
      'dokumen': null,
      'tanggal_diajukan': '16 Jan 2024',
    },
  ];

  // Data permasalahan - DUMMY DATA DIUPDATE
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
      'tingkat': 'Sedang',
      'statusColor': const Color(0xFF4CAF50),
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
      'tingkat': 'Ringan',
      'statusColor': const Color(0xFFFF9800),
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
      'tingkat': 'Berat',
      'statusColor': const Color(0xFF4CAF50),
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
      'tingkat': 'Sedang',
      'statusColor': const Color(0xFF4CAF50),
    },
  ];

  // Warna tema
  static const Color _primaryRed = Color(0xFF6B1B1B);
  static const Color _bgSoft = Color(0xFFF6EEEE);
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
    prefs.getString('user_role');

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
            'Content-Type': 'application/json',
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
      setState(() {
        _isCheckingToken = false;
        _isLoading = false;
      });
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
        await Future.delayed(const Duration(seconds: 1));
        setState(() {});
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B1B1B),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Color(0xFF6B1B1B),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _navigateToSettings,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B1B1B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                const Color(0xFF6B1B1B).withValues(alpha: 0.3),
                            width: 1.5),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        color: Color(0xFF6B1B1B),
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Selamat Datang, $_namaWaliKelas',
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
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            _siaCard(),
            const SizedBox(height: 14),
            Row(
              children: [
                _miniCard(
                  Icons.description,
                  'Laporan',
                  '$_laporanSelesai/$_laporanBelum',
                  const Color(0xFF009688),
                ),
                const SizedBox(width: 12),
                _miniCard(
                  Icons.trending_up,
                  'Progres',
                  '$_progresBaik/$_progresKurang',
                  const Color(0xFF9C27B0),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _siaChips(),
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
            builder: (context) => const KelolaPerizinanTabScreen(),
          ),
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.healing, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('SIA (Sakit/Izin/Alpha)',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_totalSIA',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
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
            count: '$_siaMenunggu',
            label: 'Menunggu',
            color: _orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PengajuanChip(
            count: '$_siaDisetujui',
            label: 'Disetujui',
            color: _green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PengajuanChip(
            count: '$_siaDitolak',
            label: 'Ditolak',
            color: _red,
          ),
        ),
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

  Widget _mainContainer() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        color: _secondaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitleWithSeeAll('Perizinan Terkini', _siaList.length),
            const SizedBox(height: 16),
            _siaListHorizontal(),
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
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Color(0xFF6B1B1B),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _primaryRed.withValues(alpha: 0.2), width: 1),
            ),
            child: Text(
              '$count total',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Color(0xFF6B1B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _siaListHorizontal() {
    return SizedBox(
      height: 240, // DIPERKECIL dari 280
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _siaList.length,
        itemBuilder: (context, index) {
          final siaData = _siaList[index];
          return Container(
            width: 300, // Lebar tetap
            margin: EdgeInsets.only(
              right: index < _siaList.length - 1 ? 16 : 0,
            ),
            child: _siaCardHorizontal(siaData),
          );
        },
      ),
    );
  }

  Widget _siaCardHorizontal(Map<String, dynamic> siaData) {
    final siswaName = siaData['nama'];
    final jenis = siaData['jenis'];
    final tanggal = siaData['tanggal'];
    final status = siaData['status'];
    final statusColor = siaData['statusColor'] as Color;
    final kelas = siaData['kelas'];
    final industri = siaData['industri'];

    return GestureDetector(
      onTap: () {
        _showSIADetail(siaData);
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
              offset: const Offset(0, 6),
            ),
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
                    child: Icon(
                      _getSIAIcon(jenis),
                      color: _primaryRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          siswaName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (kelas.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.grey[300]!, width: 1),
                            ),
                            child: Text(
                              kelas,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.apartment, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      industri,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    tanggal,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
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
                      _getStatusIcon(status),
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$jenis - $status',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showSIADetail(siaData),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryRed,
                    side: const BorderSide(color: _primaryRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  icon: const Icon(Icons.visibility, size: 14),
                  label: const Text(
                    'LIHAT DETAIL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSIAIcon(String jenis) {
    switch (jenis.toLowerCase()) {
      case 'sakit':
        return Icons.healing;
      case 'izin':
        return Icons.person_pin_circle;
      case 'alpha':
        return Icons.warning;
      default:
        return Icons.description;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return Icons.check_circle;
      case 'ditolak':
        return Icons.cancel;
      default:
        return Icons.access_time;
    }
  }

  Widget _permasalahanListHorizontal() {
    return SizedBox(
      height: 255, // DIPERKECIL dari 240 (FIX OVERFLOW)
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _permasalahanList.length,
        itemBuilder: (context, index) {
          final masalahData = _permasalahanList[index];
          return Container(
            width: 280, // Lebar tetap
            margin: EdgeInsets.only(
              right: index < _permasalahanList.length - 1 ? 16 : 0,
            ),
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
    final tingkat = masalahData['tingkat'];

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
              offset: const Offset(0, 6),
            ),
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
                    child: const Icon(
                      Icons.warning,
                      color: _darkRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          siswaName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (kelas.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.grey[300]!, width: 1),
                            ),
                            child: Text(
                              kelas,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 11),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.apartment, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      industri,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getTingkatColor(tingkat).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: _getTingkatColor(tingkat).withValues(alpha: 0.3),
                      width: 1),
                ),
                child: Text(
                  '$tingkat • $jenis',
                  style: TextStyle(
                    color: _getTingkatColor(tingkat),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
                      status == 'Terselesaikan'
                          ? Icons.check_circle
                          : Icons.access_time,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: const Size(0, 36),
                  ),
                  icon: const Icon(Icons.visibility, size: 14),
                  label: const Text(
                    'LIHAT DETAIL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTingkatColor(String tingkat) {
    switch (tingkat.toLowerCase()) {
      case 'berat':
        return _red;
      case 'sedang':
        return _orange;
      case 'ringan':
        return _green;
      default:
        return _darkRed;
    }
  }

  void _showSIADetail(Map<String, dynamic> siaData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => _siaDetailBottomSheet(siaData),
    );
  }

  Widget _siaDetailBottomSheet(Map<String, dynamic> siaData) {
    final siswaName = siaData['nama'];
    final jenis = siaData['jenis'];
    final tanggal = siaData['tanggal'];
    final status = siaData['status'];
    final kelas = siaData['kelas'] ?? '';
    final industri = siaData['industri'] ?? '';
    final alasan = siaData['alasan'] ?? 'Tidak ada alasan';
    final catatan = siaData['catatan'] ?? 'Tidak ada catatan';
    final dokumen = siaData['dokumen'];
    final tanggalDiajukan = siaData['tanggal_diajukan'] ?? '-';

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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Detail Perizinan SIA',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B1B1B),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informasi Siswa
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryRed.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: _primaryRed.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _primaryRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _primaryRed.withValues(alpha: 0.3)),
                          ),
                          child: Icon(
                            _getSIAIcon(jenis),
                            color: _primaryRed,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                siswaName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$kelas • $industri',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                siaData['statusColor'].withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: siaData['statusColor']
                                    .withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: siaData['statusColor'],
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Informasi Pengajuan
                  const Text(
                    'Informasi Pengajuan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _detailInfoRow('Jenis Perizinan', jenis),
                        const SizedBox(height: 12),
                        _detailInfoRow('Tanggal Diajukan', tanggalDiajukan),
                        const SizedBox(height: 12),
                        _detailInfoRow('Periode Perizinan', tanggal),
                        const SizedBox(height: 12),
                        _detailInfoRow('Status', status),
                        const SizedBox(height: 12),
                        _detailInfoRow('Alasan', alasan),
                        const SizedBox(height: 12),
                        _detailInfoRow('Catatan', catatan),
                        if (dokumen != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(
                                width: 120,
                                child: Text(
                                  'Dokumen:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          _primaryRed.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: _primaryRed.withValues(
                                              alpha: 0.2)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.attach_file,
                                            color: _primaryRed, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            dokumen,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: _primaryRed,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.download,
                                            color: _primaryRed, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
                    onPressed: () => _rejectSIA(siaData),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: const BorderSide(color: _red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text(
                      'TOLAK',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveSIA(siaData),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: const Icon(Icons.check, size: 20),
                    label: const Text(
                      'SETUJUI',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'TUTUP',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _detailInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _approveSIA(Map<String, dynamic> data) {
    setState(() {
      data['status'] = 'Disetujui';
      data['statusColor'] = _green;
      data['catatan'] =
          'Disetujui oleh $_namaWaliKelas pada ${DateTime.now().toLocal().toString().split(' ')[0]}';
    });
    _showSnackBar('Pengajuan ${data['jenis']} disetujui');
    Navigator.pop(context);
  }

  void _rejectSIA(Map<String, dynamic> data) {
    final TextEditingController alasanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
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
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: _red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOLAK PENGAJUAN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6B1B1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Siswa: ${data['nama']}',
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
                  const SizedBox(height: 24),
                  const Text(
                    'Alasan Penolakan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B1B1B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: alasanController,
                      maxLines: 4,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Masukkan alasan penolakan...',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
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
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'BATAL',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (alasanController.text.trim().isEmpty) {
                              _showSnackBar('Masukkan alasan penolakan',
                                  isError: true);
                              return;
                            }

                            setState(() {
                              data['status'] = 'Ditolak';
                              data['statusColor'] = _red;
                              data['catatan'] =
                                  'Ditolak: ${alasanController.text.trim()}';
                            });

                            _showSnackBar('Pengajuan ditolak');
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'TOLAK',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
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
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError ? _red : _green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showPermasalahanDetail(Map<String, dynamic> masalahData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
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
    final tingkat = masalahData['tingkat'] ?? 'Sedang';
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Detail Permasalahan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB71C1C),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Informasi Siswa
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _darkRed.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: _darkRed.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _darkRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _darkRed.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(
                            Icons.warning,
                            color: _darkRed,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                siswaName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$kelas • $industri',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
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
                                color: statusColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Informasi Permasalahan
                  const Text(
                    'Informasi Permasalahan',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        _detailInfoRow('Jenis Permasalahan', jenis),
                        const SizedBox(height: 12),
                        _detailInfoRow('Tanggal Laporan', tanggal),
                        const SizedBox(height: 12),
                        _detailInfoRow('Tingkat', tingkat),
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
                              child: Text(
                                'Deskripsi:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                deskripsi,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(
                              width: 140,
                              child: Text(
                                'Solusi/Tindakan:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                solusi,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: status == 'Terselesaikan'
                                      ? _green
                                      : _orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _updatePermasalahanStatus(masalahData, 'Ditindaklanjuti');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _darkRed,
                    side: const BorderSide(color: Color(0xFFB71C1C)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.update, size: 20),
                  label: const Text(
                    'TINDAK LANJUT',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _markPermasalahanSolved(masalahData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text(
                    'SELESAI',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _updatePermasalahanStatus(Map<String, dynamic> data, String newStatus) {
    final TextEditingController catatanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
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
                          color: _orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.update,
                          color: _orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TINDAK LANJUT PERMASALAHAN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6B1B1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Siswa: ${data['nama']}',
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
                  const SizedBox(height: 24),
                  const Text(
                    'Catatan Tindakan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B1B1B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: catatanController,
                      maxLines: 4,
                      decoration: const InputDecoration.collapsed(
                        hintText:
                            'Masukkan catatan tindakan yang akan dilakukan...',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
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
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'BATAL',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (catatanController.text.trim().isEmpty) {
                              _showSnackBar('Masukkan catatan tindakan',
                                  isError: true);
                              return;
                            }

                            setState(() {
                              data['solusi'] = catatanController.text.trim();
                              data['status'] = 'Ditindaklanjuti';
                              data['statusColor'] = _orange;
                            });

                            _showSnackBar(
                                'Permasalahan sedang ditindaklanjuti');
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'SIMPAN',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
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

  void _markPermasalahanSolved(Map<String, dynamic> data) {
    setState(() {
      data['status'] = 'Terselesaikan';
      data['statusColor'] = _green;
      data['solusi'] =
          'Terselesaikan oleh $_namaWaliKelas pada ${DateTime.now().toLocal().toString().split(' ')[0]}';
    });
    _showSnackBar('Permasalahan ditandai sebagai terselesaikan');
    Navigator.pop(context);
  }

  // ============= SKELETON LOADING =============
  Widget _buildSkeletonLoadingScreen() {
    return Scaffold(
      backgroundColor: _bgSoft,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Skeleton Header Card
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
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 220,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Skeleton Top Card
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
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Skeleton SIA Card
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Skeleton Mini Cards
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Skeleton Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Skeleton Main Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Skeleton Section Title 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 150,
                          height: 25,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 25,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Skeleton Horizontal List 1
                    SizedBox(
                      height: 210,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 300,
                            margin: EdgeInsets.only(
                              right: index < 2 ? 16 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(18),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Skeleton Section Title 2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 150,
                          height: 25,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 25,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Skeleton Horizontal List 2
                    SizedBox(
                      height: 195,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 280,
                            margin: EdgeInsets.only(
                              right: index < 2 ? 16 : 0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(18),
                            ),
                          );
                        },
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

class _PengajuanChip extends StatelessWidget {
  final String count;
  final String label;
  final Color color;

  const _PengajuanChip({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black,
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
}
