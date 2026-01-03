import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'kaprog_profile_page.dart';
import 'kaprog_dashboard_skeleton.dart';
import '../login/login_screen.dart'; // IMPORT HALAMAN LOGIN

class KaprogDashboard extends StatefulWidget {
  const KaprogDashboard({super.key});

  @override
  State<KaprogDashboard> createState() => _KaprogDashboardState();
}

class _KaprogDashboardState extends State<KaprogDashboard> {
  String _namaKaprog = 'Loading...';
  bool _isLoading = true;
  bool _hasError = false;
  bool _isCheckingToken = true; // Tambah state untuk checking token

  // Data dari API
  List<dynamic> _pendingApplications = [];
  List<dynamic> _approvedApplications = [];
  List<dynamic> _industries = [];
  List<dynamic> _teachers = []; // Tetap dipertahankan untuk kode lain
  Map<String, dynamic>? _currentTeacher;

  @override
  void initState() {
    super.initState();
    _checkTokenAndLoadData();
  }

  // PERUBAHAN: Fungsi untuk cek token terlebih dahulu
  Future<void> _checkTokenAndLoadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    // Jika tidak ada token, redirect ke login
    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
    }

    // Jika ada token, lanjut load data
    await _loadAllData();
  }

  // PERUBAHAN: Fungsi untuk redirect ke halaman login
  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    });
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isCheckingToken = false; // Sudah selesai cek token
      _isLoading = true;
      _hasError = false;
    });

    try {
      await Future.wait([
        _loadProfileData(),
        _fetchApplications('Pending')
            .then((value) => _pendingApplications = value),
        _fetchApplications('Approved')
            .then((value) => _approvedApplications = value),
        _fetchIndustries(),
        _fetchTeachers(), // Tetap dijalankan untuk kebutuhan lain
      ]);
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
Future<void> _loadProfileData() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  
  if (token == null) {
    _redirectToLogin();
    return;
  }

  // DEBUG: Print data dari SharedPreferences
  print('=== DATA DARI SHAREDPREFERENCES ===');
  final userId = prefs.getInt('user_id');
  final kodeGuru = prefs.getString('kode_guru');
  final userName = prefs.getString('user_name');
  print('User ID: $userId');
  print('Kode Guru: $kodeGuru');
  print('User Name: $userName');

  // Coba ambil dari SharedPreferences dulu
  if (userName != null) {
    print('=== MENGAMBIL NAMA DARI SHAREDPREFERENCES ===');
    setState(() {
      _namaKaprog = userName;
    });
  }

  try {
    final response = await http.get(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/pembimbing'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('=== RESPONSE API PEMBIMBING ===');
      print('Response type: ${data.runtimeType}');
      
      List<dynamic> guruList;
      
      // Handle struktur response yang berbeda
      if (data is List) {
        // Response langsung berupa List
        print('Response is direct List');
        guruList = data;
      } else if (data is Map && data.containsKey('data')) {
        // Response berupa Map dengan key 'data'
        print('Response is Map with data key');
        if (data['data'] is List) {
          guruList = data['data'];
        } else if (data['data'] is Map && data['data']['data'] is List) {
          // Nested structure
          guruList = data['data']['data'];
        } else {
          print('Unexpected data structure: $data');
          return;
        }
      } else {
        print('Unexpected response format: $data');
        return;
      }

      if (guruList.isEmpty) {
        print('=== LIST GURU KOSONG ===');
        return;
      }

      print('=== SEMUA DATA GURU DARI API ===');
      for (var i = 0; i < guruList.length; i++) {
        final guru = guruList[i];
        print('Guru $i: ${guru['nama']} - ID: ${guru['id']}');
      }

      // CARI GURU YANG SESUAI DENGAN USER YANG LOGIN
      Map<String, dynamic>? myProfile;
      
      // Cari berdasarkan user_id (yang seharusnya ada di SharedPreferences)
      if (userId != null) {
        print('=== MENCARI BERDASARKAN USER_ID: $userId ===');
        for (var guru in guruList) {
          // Periksa berbagai kemungkinan field ID
          final guruId = guru['id'] ?? guru['user_id'] ?? guru['guru_id'];
          if (guruId == userId) {
            myProfile = guru;
            print('=== DITEMUKAN BERDASARKAN USER_ID ===');
            print('Nama: ${guru['nama']}');
            print('ID: $guruId');
            break;
          }
        }
      }
      
      // Jika tidak ditemukan dengan user_id, coba dengan nama
      if (myProfile == null && userName != null) {
        print('=== MENCARI BERDASARKAN NAMA: $userName ===');
        for (var guru in guruList) {
          if (guru['nama']?.toString().toLowerCase() == userName.toLowerCase()) {
            myProfile = guru;
            print('=== DITEMUKAN BERDASARKAN NAMA ===');
            print('Nama: ${guru['nama']}');
            break;
          }
        }
      }
      
      // Jika ditemukan, update data
      if (myProfile != null) {
        final namaLengkap = myProfile['nama'] ?? userName ?? 'Kaprodi';
        setState(() {
          _currentTeacher = myProfile;
          _namaKaprog = namaLengkap;
        });
        
        print('=== DATA GURU YANG DIGUNAKAN ===');
        print('Nama: $namaLengkap');
        print('NIP: ${myProfile['nip']}');
        
      } else {
        print('=== TIDAK DITEMUKAN, AMBIL DATA PERTAMA ===');
        // Fallback ke data pertama
        if (guruList.isNotEmpty) {
          final firstGuru = guruList.first;
          final namaLengkap = firstGuru['nama'] ?? 'Kaprodi';
          setState(() {
            _currentTeacher = firstGuru;
            _namaKaprog = namaLengkap;
          });
          print('Mengambil data pertama: $namaLengkap');
        }
      }
    } else {
      print('=== ERROR RESPONSE API ===');
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (e) {
    print('Error loading profile: $e');
    // Tetap gunakan data dari SharedPreferences jika ada error
  }
}
  Future<List<dynamic>> _fetchApplications(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/pkl/applications?status=$status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      }
    } catch (e) {
      print('Error fetching $status applications: $e');
    }
    return [];
  }

  Future<void> _fetchIndustries() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/industri/preview'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _industries = data['data'] ?? []);
      }
    } catch (e) {
      print('Error fetching industries: $e');
    }
  }

  Future<void> _fetchTeachers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/pembimbing'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _teachers = data is List ? data : []);
      }
    } catch (e) {
      print('Error fetching teachers: $e');
    }
  }

  Future<void> _approveApplication(
      int applicationId, Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.put(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/pkl/applications/$applicationId/approve'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Pengajuan berhasil disetujui', Colors.green);
        _loadAllData();
      } else {
        _showSnackBar('Pengajuan diproses', Colors.orange);
        _loadAllData();
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _rejectApplication(int applicationId, String catatan) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.put(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/pkl/applications/$applicationId/reject'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({'catatan': catatan}),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Pengajuan berhasil ditolak', Colors.green);
        _loadAllData();
      } else {
        _showSnackBar('Gagal menolak pengajuan', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _updateIndustryQuota(int industriId, int newQuota) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.put(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/pkl/industri/$industriId/quota'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({'kuota_siswa': newQuota}),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Kuota berhasil diupdate', Colors.green);
        _fetchIndustries();
      } else {
        _showSnackBar('Gagal mengupdate kuota', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.orange;
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

  // Navigate to Profile Page
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KaprogProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // PERUBAHAN: Tampilkan loading screen saat cek token
    if (_isCheckingToken) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: _navigateToProfile,
            tooltip: 'Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const KaprogDashboardSkeleton() // Menggunakan komponen skeleton terpisah
          : _hasError
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      backgroundColor: Colors.white,
      color: Colors.black,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Profile - Background Putih
            _buildProfileCard(),
            const SizedBox(height: 20),

            // Statistics Grid - Kecil dan Rapi
            _buildCompactStatisticsGrid(),
            const SizedBox(height: 20),

            // Pengajuan Menunggu
            _buildPendingApplicationsSection(),
            const SizedBox(height: 20),

            // Data Industri
            _buildIndustriesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _namaKaprog,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Koordinator Program Keahlian',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                if (_currentTeacher != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'NIP: ${_currentTeacher!['nip']}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
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

  Widget _buildCompactStatisticsGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Data',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCompactStatItem(
                value: _pendingApplications.length.toString(),
                label: 'Menunggu',
                icon: Icons.pending_actions,
              ),
              _buildCompactStatItem(
                value: _approvedApplications.length.toString(),
                label: 'Disetujui',
                icon: Icons.check_circle,
              ),
              _buildCompactStatItem(
                value: _industries.length.toString(),
                label: 'Industri',
                icon: Icons.business,
              ),
              _buildCompactStatItem(
                value: _teachers.length.toString(),
                label: 'Guru',
                icon: Icons.people,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: Colors.black),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingApplicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pengajuan Menunggu Persetujuan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              '${_pendingApplications.length} items',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _pendingApplications.isEmpty
            ? _buildEmptyState(
                'Tidak ada pengajuan menunggu',
                Icons.check_circle_outline,
                'Semua pengajuan sudah diproses',
              )
            : Column(
                children: _pendingApplications.map((appData) {
                  final application = appData['application'] ?? {};
                  return _buildApplicationCard(appData, application);
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildIndustriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Data Industri',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              '${_industries.length} industri',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _industries.isEmpty
            ? _buildEmptyState(
                'Tidak ada data industri',
                Icons.business,
                'Belum ada industri terdaftar',
              )
            : Column(
                children: _industries.map((industry) {
                  return _buildIndustryCard(industry);
                }).toList(),
              ),
      ],
    );
  }

  Widget _buildApplicationCard(
      Map<String, dynamic> appData, Map<String, dynamic> application) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appData['siswa_username'] ?? 'Siswa',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      appData['industri_nama'] ?? 'Industri',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(application['status'])
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  application['status'] ?? 'Pending',
                  style: TextStyle(
                    color: _statusColor(application['status']),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Details
          Row(
            children: [
              _buildCompactDetailItem('Kelas', appData['kelas_nama']),
              const SizedBox(width: 12),
              if (application['tanggal_permohonan'] != null)
                _buildCompactDetailItem('Tanggal',
                    _formatTanggal(application['tanggal_permohonan'])),
            ],
          ),
          if (application['catatan'] != null) ...[
            const SizedBox(height: 6),
            Text(
              'Catatan: ${application['catatan']}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Actions for pending applications
          if (application['status'] == 'Pending') ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  icon: Icons.check,
                  label: 'Setujui',
                  color: Colors.black,
                  onPressed: () => _showApproveDialog(application, appData),
                ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.close,
                  label: 'Tolak',
                  color: Colors.red,
                  onPressed: () => _showRejectDialog(application, appData),
                  isOutlined: true,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndustryCard(Map<String, dynamic> industry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  industry['nama'] ?? 'Industri',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 18, color: Colors.black),
                onPressed: () => _showUpdateQuotaDialog(industry),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildIndustryInfoItem(
                  'Kuota', '${industry['kuota_siswa'] ?? '0'}'),
              _buildIndustryInfoItem(
                  'Sisa', '${industry['remaining_slots'] ?? '0'}'),
              _buildIndustryInfoItem(
                  'Siswa', '${industry['active_students'] ?? '0'}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndustryInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDetailItem(String label, dynamic value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value?.toString() ?? '-',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      );
    }
  }

  Widget _buildEmptyState(String title, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gagal memuat data dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(
      Map<String, dynamic> application, Map<String, dynamic> appData) {
    final catatanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        // State variables untuk dialog
        DateTime? selectedStartDate;
        DateTime? selectedEndDate;
        int? selectedTeacherId;
        String? selectedTeacherName;

        // State untuk dropdown custom
        bool showTeacherPopup = false;
        final TextEditingController searchTeacherController =
            TextEditingController();
        final FocusNode searchTeacherFocusNode = FocusNode();
        final GlobalKey teacherFieldKey = GlobalKey();
        OverlayEntry? teacherOverlayEntry;
        List<dynamic> filteredTeachers = [];

        // Fungsi untuk filter teacher - dideklarasikan dulu
        void filterTeacherList() {
          final query = searchTeacherController.text.toLowerCase();
          filteredTeachers = _teachers.where((teacher) {
            return teacher['nama']?.toLowerCase().contains(query) ??
                false || teacher['nip']?.toLowerCase().contains(query) ??
                false;
          }).toList();

          if (teacherOverlayEntry != null && teacherOverlayEntry!.mounted) {
            teacherOverlayEntry!.markNeedsBuild();
          }
        }

        // Fungsi untuk menghapus overlay
        void removeTeacherOverlay() {
          if (teacherOverlayEntry != null) {
            teacherOverlayEntry!.remove();
            teacherOverlayEntry = null;
          }
          showTeacherPopup = false;
          searchTeacherController.clear();
          searchTeacherFocusNode.unfocus();
        }

        // Widget untuk list guru
        Widget buildTeacherList() {
          if (_teachers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Tidak ada data guru',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          if (filteredTeachers.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'Tidak ditemukan',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: filteredTeachers.length,
            itemBuilder: (context, index) {
              final teacher = filteredTeachers[index];
              final isSelected = selectedTeacherId == teacher['id'];

              return InkWell(
                onTap: () {
                  selectedTeacherId = teacher['id'];
                  selectedTeacherName = teacher['nama'];
                  removeTeacherOverlay();
                  (context as Element).markNeedsBuild();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: index == 0
                        ? null
                        : Border(top: BorderSide(color: Colors.grey.shade100)),
                    color:
                        isSelected ? Colors.blue.shade50 : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacher['nama'] ?? 'Guru',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (teacher['nip'] != null)
                              Text(
                                'NIP: ${teacher['nip']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check, color: Colors.blue, size: 20),
                    ],
                  ),
                ),
              );
            },
          );
        }

        // Fungsi untuk menampilkan overlay teacher
        void showTeacherPopupOverlay(BuildContext context) {
          if (teacherOverlayEntry != null) {
            removeTeacherOverlay();
            return;
          }

          final RenderBox renderBox =
              teacherFieldKey.currentContext!.findRenderObject() as RenderBox;
          final fieldOffset = renderBox.localToGlobal(Offset.zero);
          final fieldSize = renderBox.size;
          final screenSize = MediaQuery.of(context).size;
          final popupWidth = fieldSize.width;
          final maxHeight = screenSize.height * 0.4;

          // Hitung posisi popup
          double top = fieldOffset.dy + fieldSize.height;
          double left = fieldOffset.dx;

          // Pastikan tidak keluar layar
          if (top + maxHeight > screenSize.height) {
            top = fieldOffset.dy - maxHeight;
          }
          if (left + popupWidth > screenSize.width) {
            left = screenSize.width - popupWidth;
          }

          teacherOverlayEntry = OverlayEntry(
            builder: (context) {
              return Positioned(
                left: left,
                top: top,
                width: popupWidth,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        // Search Bar
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.search,
                                          color: Colors.grey, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: searchTeacherController,
                                          focusNode: searchTeacherFocusNode,
                                          onChanged: (value) =>
                                              filterTeacherList(),
                                          decoration: const InputDecoration(
                                            hintText: 'Cari guru...',
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                          ),
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                      if (searchTeacherController
                                          .text.isNotEmpty)
                                        GestureDetector(
                                          onTap: () {
                                            searchTeacherController.clear();
                                            filterTeacherList();
                                          },
                                          child: const Icon(Icons.clear,
                                              size: 16, color: Colors.grey),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: removeTeacherOverlay,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.close, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // List Guru
                        Expanded(
                          child: buildTeacherList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );

          Overlay.of(context).insert(teacherOverlayEntry!);
          showTeacherPopup = true;
          filteredTeachers = List.from(_teachers);
          (context as Element).markNeedsBuild();
        }

        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 20, color: Colors.black),
                          SizedBox(width: 8),
                          Text(
                            'Setujui Pengajuan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Catatan
                      const Text(
                        'Catatan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: catatanController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan catatan (opsional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          hintStyle: const TextStyle(fontSize: 12),
                        ),
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      // Tanggal Mulai
                      const Text(
                        'Tanggal Mulai',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(DateTime.now().year + 5, 12, 31),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Colors.black,
                                    onPrimary: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              selectedStartDate = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 18, color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedStartDate != null
                                      ? '${selectedStartDate!.day.toString().padLeft(2, '0')}/${selectedStartDate!.month.toString().padLeft(2, '0')}/${selectedStartDate!.year}'
                                      : 'Pilih tanggal mulai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selectedStartDate != null
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tanggal Selesai
                      const Text(
                        'Tanggal Selesai',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedStartDate ?? DateTime.now(),
                            firstDate: selectedStartDate ?? DateTime.now(),
                            lastDate: DateTime(DateTime.now().year + 5, 12, 31),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.light(
                                    primary: Colors.black,
                                    onPrimary: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              selectedEndDate = picked;
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 18, color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedEndDate != null
                                      ? '${selectedEndDate!.day.toString().padLeft(2, '0')}/${selectedEndDate!.month.toString().padLeft(2, '0')}/${selectedEndDate!.year}'
                                      : 'Pilih tanggal selesai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selectedEndDate != null
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Guru Pembimbing - Custom Dropdown
                      const Text(
                        'Guru Pembimbing',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () => showTeacherPopupOverlay(context),
                        child: Container(
                          key: teacherFieldKey,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: selectedTeacherId == null
                                    ? Text(
                                        'Pilih guru pembimbing',
                                        style: TextStyle(
                                          color: Colors.black
                                              .withValues(alpha: 0.6),
                                          fontSize: 14,
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedTeacherName ?? 'Guru',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'ID: $selectedTeacherId',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              Icon(
                                showTeacherPopup
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Aksi
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                removeTeacherOverlay();
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side: const BorderSide(color: Colors.black),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Batal',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Validasi
                                if (selectedStartDate == null) {
                                  _showSnackBar(
                                      'Pilih tanggal mulai', Colors.red);
                                  return;
                                }
                                if (selectedEndDate == null) {
                                  _showSnackBar(
                                      'Pilih tanggal selesai', Colors.red);
                                  return;
                                }
                                if (selectedTeacherId == null) {
                                  _showSnackBar(
                                      'Pilih guru pembimbing', Colors.red);
                                  return;
                                }

                                if (selectedEndDate!
                                    .isBefore(selectedStartDate!)) {
                                  _showSnackBar(
                                      'Tanggal selesai harus setelah tanggal mulai',
                                      Colors.red);
                                  return;
                                }

                                final data = {
                                  'catatan': catatanController.text.isNotEmpty
                                      ? catatanController.text
                                      : '-',
                                  'pembimbing_guru_id': selectedTeacherId,
                                  'tanggal_mulai':
                                      '${selectedStartDate!.year}-${selectedStartDate!.month.toString().padLeft(2, '0')}-${selectedStartDate!.day.toString().padLeft(2, '0')}',
                                  'tanggal_selesai':
                                      '${selectedEndDate!.year}-${selectedEndDate!.month.toString().padLeft(2, '0')}-${selectedEndDate!.day.toString().padLeft(2, '0')}',
                                };

                                _approveApplication(application['id'], data);
                                removeTeacherOverlay();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Setujui',
                                  style: TextStyle(fontSize: 12)),
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
      },
    );
  }

  void _showRejectDialog(
      Map<String, dynamic> application, Map<String, dynamic> appData) {
    final catatanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tolak Pengajuan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Siswa: ${appData['siswa_username']}',
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                'Industri: ${appData['industri_nama']}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: catatanController,
                decoration: const InputDecoration(
                  labelText: 'Alasan Penolakan',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(fontSize: 12),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          const Text('Batal', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _rejectApplication(
                            application['id'], catatanController.text);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          const Text('Tolak', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateQuotaDialog(Map<String, dynamic> industry) {
    final quotaController =
        TextEditingController(text: (industry['kuota_siswa'] ?? '').toString());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Update Kuota - ${industry['nama']}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quotaController,
                decoration: const InputDecoration(
                  labelText: 'Kuota Siswa',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                style: const TextStyle(fontSize: 12),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          const Text('Batal', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final newQuota =
                            int.tryParse(quotaController.text) ?? 0;
                        _updateIndustryQuota(industry['industri_id'], newQuota);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          const Text('Update', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
