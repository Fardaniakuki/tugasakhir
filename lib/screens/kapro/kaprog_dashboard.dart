import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'kaprog_profile_page.dart';
import 'kaprog_dashboard_skeleton.dart';
import '../login/login_screen.dart';

// === ANIMATED BUTTON CLASS ===
class PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final bool isPrimary;

  const PressableButton({
    required this.child,
    required this.onTap,
    this.isPrimary = false,
    super.key,
  });

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.forward().then((_) {
      widget.onTap();
    });
  }

  void _onTapCancel() {
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class KaprogDashboard extends StatefulWidget {
  const KaprogDashboard({super.key});

  @override
  State<KaprogDashboard> createState() => _KaprogDashboardState();
}

class _KaprogDashboardState extends State<KaprogDashboard> {
  String _namaKaprog = 'Loading...';
  bool _isLoading = true;
  bool _hasError = false;
  bool _isCheckingToken = true;

  // Data dari API
  List<dynamic> _pendingApplications = [];
  List<dynamic> _approvedApplications = [];
  List<dynamic> _industries = [];
  List<dynamic> _teachers = [];

  // === HANYA 3 WARNA ===
  final Color _primaryColor = const Color(0xFFE6E3E3); // Abu-abu muda
  final Color _secondaryColor = const Color(0xFF262626); // Hitam gelap
  final Color _accentColor = const Color(0xFFE71543); // Merah cerah

  // Neo Brutalism Shadows
  static const BoxShadow _heavyShadow = BoxShadow(
    color: Colors.black,
    offset: Offset(4, 4),
    blurRadius: 0,
  );

  final BoxShadow _lightShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.2),
    offset: const Offset(2, 2),
    blurRadius: 0,
  );

  @override
  void initState() {
    super.initState();
    _checkTokenAndLoadData();
  }

  Future<void> _checkTokenAndLoadData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.isEmpty) {
      _redirectToLogin();
      return;
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

  Future<void> _loadAllData() async {
    setState(() {
      _isCheckingToken = false;
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
        _fetchTeachers(),
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

    final userName = prefs.getString('user_name');
    if (userName != null) {
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

        List<dynamic> guruList;

        if (data is List) {
          guruList = data;
        } else if (data is Map && data.containsKey('data')) {
          if (data['data'] is List) {
            guruList = data['data'];
          } else if (data['data'] is Map && data['data']['data'] is List) {
            guruList = data['data']['data'];
          } else {
            return;
          }
        } else {
          return;
        }

        if (guruList.isEmpty) return;

        Map<String, dynamic>? myProfile;
        final userId = prefs.getInt('user_id');

        if (userId != null) {
          for (var guru in guruList) {
            final guruId = guru['id'] ?? guru['user_id'] ?? guru['guru_id'];
            if (guruId == userId) {
              myProfile = guru;
              break;
            }
          }
        }

        if (myProfile == null && userName != null) {
          for (var guru in guruList) {
            if (guru['nama']?.toString().toLowerCase() ==
                userName.toLowerCase()) {
              myProfile = guru;
              break;
            }
          }
        }

        if (myProfile != null) {
          final namaLengkap = myProfile['nama'] ?? userName ?? 'Kaprodi';
          setState(() {
            _namaKaprog = namaLengkap;
          });
        } else if (guruList.isNotEmpty) {
          final firstGuru = guruList.first;
          final namaLengkap = firstGuru['nama'] ?? 'Kaprodi';
          setState(() {
            _namaKaprog = namaLengkap;
          });
        }
      }
    } catch (e) {
      print('Error loading profile: $e');
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
        _showSnackBar('Pengajuan berhasil disetujui');
        _loadAllData();
      } else {
        _showSnackBar('Pengajuan diproses');
        _loadAllData();
      }
    } catch (e) {
      _showSnackBar('Error: $e');
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
        _showSnackBar('Pengajuan berhasil ditolak');
        _loadAllData();
      } else {
        _showSnackBar('Gagal menolak pengajuan');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
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
        _showSnackBar('Kuota berhasil diupdate');
        _fetchIndustries();
      } else {
        _showSnackBar('Gagal mengupdate kuota');
      }
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: _primaryColor,
            ),
          ),
          backgroundColor: _secondaryColor,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: _primaryColor, width: 2),
          ),
        ),
      );
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return _accentColor.withValues(alpha:0.8);
      case 'rejected':
        return _secondaryColor.withValues(alpha:0.8);
      case 'completed':
        return _primaryColor.withValues(alpha:0.6);
      default:
        return _primaryColor.withValues(alpha:0.4);
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

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KaprogProfilePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingToken) {
      return Scaffold(
        backgroundColor: _secondaryColor,
        body: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _primaryColor,
              border: Border.all(color: _primaryColor, width: 3),
              boxShadow: const [_heavyShadow],
            ),
            child: CircularProgressIndicator(
              color: _accentColor,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _secondaryColor,
      body: _isLoading
          ? const KaprogDashboardSkeleton()
          : _hasError
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      backgroundColor: _primaryColor,
      color: _accentColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // === HEADER TEXT (TANPA KOTAK) ===
            Container(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'KEPALA PROGRAM ',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: _primaryColor,
                                letterSpacing: -1,
                              ),
                            ),
                            Text(
                              _namaKaprog.toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _primaryColor,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          border: Border.all(color: _primaryColor, width: 2),
                          boxShadow: [_lightShadow],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.person, color: _secondaryColor),
                          onPressed: _navigateToProfile,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DASHBOARD PKL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // === STATISTICS ROW (4 KOLOM SEBARIS) ===
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryColor,
                border:
                    Border.all(color: _primaryColor.withValues(alpha:0.3), width: 2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [_heavyShadow],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    value: _pendingApplications.length.toString(),
                    label: 'MENUNGGU',
                    color: _primaryColor.withValues(alpha:0.4),
                  ),
                  _buildStatItem(
                    value: _approvedApplications.length.toString(),
                    label: 'DISETUJUI',
                    color: _primaryColor.withValues(alpha:0.3),
                  ),
                  _buildStatItem(
                    value: _industries.length.toString(),
                    label: 'INDUSTRI',
                    color: _primaryColor.withValues(alpha:0.6),
                  ),
                  _buildStatItem(
                    value: _teachers.length.toString(),
                    label: 'GURU',
                    color: _secondaryColor.withValues(alpha:0.2),
                  ),
                ],
              ),
            ),

            // === MAIN CONTENT AREA ===
            Container(
              margin: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                color: _primaryColor,
                border: Border.all(color: _primaryColor, width: 4),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: const [_heavyShadow],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // === PENGAJUAN MENUNGGU ===
                    _buildPendingApplicationsSection(),
                    const SizedBox(height: 20),

                    // === DATA INDUSTRI ===
                    _buildIndustriesSection(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _secondaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _secondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingApplicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PENGAJUAN MENUNGGU',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _secondaryColor,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_pendingApplications.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _pendingApplications.isEmpty
            ? _buildEmptyState(
                icon: Icons.inbox,
                title: 'TIDAK ADA PENGAJUAN',
                subtitle: 'Semua pengajuan telah diproses',
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
            Text(
              'DATA INDUSTRI',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _secondaryColor,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_industries.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _industries.isEmpty
            ? _buildEmptyState(
                icon: Icons.factory,
                title: 'BELUM ADA INDUSTRI',
                subtitle: 'Tambahkan industri untuk memulai',
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
    final status = application['status'] ?? 'PENDING';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _primaryColor,
        border: Border.all(color: _secondaryColor, width: 3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_heavyShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER STATUS
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _statusColor(status),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: _secondaryColor, width: 3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    border: Border.all(color: _secondaryColor, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status == 'Pending'
                        ? Icons.access_time
                        : (status == 'Approved'
                            ? Icons.check_circle
                            : Icons.cancel),
                    color: _secondaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: _secondaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        appData['siswa_username'] ?? 'Siswa',
                        style: TextStyle(
                          color: _secondaryColor.withValues(alpha:0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // KONTEN UTAMA
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // INDUSTRI
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha:0.8),
                    border: Border.all(color: _secondaryColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _accentColor,
                          border: Border.all(color: _secondaryColor, width: 2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.factory,
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
                              'LOKASI PKL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _secondaryColor,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              appData['industri_nama'] ?? 'Industri',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _secondaryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // DETAIL
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    border: Border.all(color: _secondaryColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRowCompact(
                        icon: Icons.class_,
                        title: 'KELAS',
                        value: appData['kelas_nama'] ?? '-',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRowCompact(
                        icon: Icons.calendar_today,
                        title: 'DIAJUKAN',
                        value:
                            _formatTanggal(application['tanggal_permohonan']),
                      ),
                      const SizedBox(height: 8),
                      if (appData['guru_nama'] != null)
                        _buildInfoRowCompact(
                          icon: Icons.person_outline,
                          title: 'GURU PEMBIMBING',
                          value: appData['guru_nama'],
                        ),
                    ],
                  ),
                ),

                // CATATAN JIKA ADA
                if (application['catatan'] != null &&
                    application['catatan'].isNotEmpty &&
                    application['catatan'] != '-')
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha:0.8),
                      border: Border.all(color: _secondaryColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: _accentColor,
                                border: Border.all(
                                    color: _secondaryColor, width: 1.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.note_add,
                                size: 12,
                                color: _primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'CATATAN SISWA',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: _secondaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            border:
                                Border.all(color: _secondaryColor, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            application['catatan'],
                            style: TextStyle(
                              fontSize: 12,
                              color: _secondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ACTIONS for pending status dengan animasi
                if (status == 'Pending') ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // TOMBOL TOLAK (KIRI) dengan animasi
                        Expanded(
                          child: PressableButton(
                            onTap: () =>
                                _showRejectDialog(application, appData),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: _secondaryColor, width: 3),
                                boxShadow: const [_heavyShadow],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.close,
                                    size: 22,
                                    color: _secondaryColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'TOLAK',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: _secondaryColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // TOMBOL SETUJUI (KANAN) dengan animasi
                        Expanded(
                          child: PressableButton(
                            onTap: () =>
                                _showApproveDialog(application, appData),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                color: _accentColor,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: _secondaryColor, width: 3),
                                boxShadow: const [_heavyShadow],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check,
                                    size: 22,
                                    color: _primaryColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'SETUJUI',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: _primaryColor,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildIndustryCard(Map<String, dynamic> industry) {
    final kuota = industry['kuota_siswa'] ?? 0;
    final sisa = industry['remaining_slots'] ?? 0;
    final siswa = industry['active_students'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _primaryColor,
        border: Border.all(color: _secondaryColor, width: 3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_heavyShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha:0.6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: _secondaryColor, width: 3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    industry['nama'] ?? 'INDUSTRI',
                    style: TextStyle(
                      color: _secondaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                PressableButton(
                  onTap: () => _showUpdateQuotaDialog(industry),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      border: Border.all(color: _secondaryColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.edit,
                      size: 16,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // STATISTICS
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha:0.8),
                    border: Border.all(color: _secondaryColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildIndustryStat(
                        'KUOTA',
                        kuota.toString(),
                      ),
                      _buildIndustryStat(
                        'SISA',
                        sisa.toString(),
                      ),
                      _buildIndustryStat(
                        'SISWA',
                        siswa.toString(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowCompact({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _primaryColor,
        border: Border.all(color: _secondaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _accentColor,
              border: Border.all(color: _secondaryColor, width: 1.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 14,
              color: _primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: _secondaryColor,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: _secondaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndustryStat(String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: _accentColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _secondaryColor, width: 1.5),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: _primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: _secondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _primaryColor,
        border: Border.all(color: _secondaryColor, width: 3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_heavyShadow],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _accentColor,
              border: Border.all(color: _secondaryColor, width: 2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 30,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _secondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _secondaryColor,
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
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _primaryColor,
                border: Border.all(color: _secondaryColor, width: 3),
                boxShadow: const [_heavyShadow],
              ),
              child: Icon(
                Icons.error_outline,
                size: 30,
                color: _accentColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'KESALAHAN SISTEM',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: _primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gagal memuat data dashboard',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            PressableButton(
              onTap: _loadAllData,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: _accentColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _primaryColor, width: 2),
                  boxShadow: const [_heavyShadow],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh,
                      size: 18,
                      color: _primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'COBA LAGI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _primaryColor,
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

        // Fungsi untuk filter teacher
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_outline,
                        size: 40, color: _secondaryColor),
                    const SizedBox(height: 8),
                    Text(
                      'Tidak ada data guru',
                      style: TextStyle(color: _secondaryColor),
                    ),
                  ],
                ),
              ),
            );
          }

          if (filteredTeachers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 40, color: _secondaryColor),
                    const SizedBox(height: 8),
                    Text(
                      'Tidak ditemukan',
                      style: TextStyle(color: _secondaryColor),
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
                        : Border(
                            top: BorderSide(
                                color: _primaryColor.withValues(alpha:0.3))),
                    color: isSelected
                        ? _accentColor.withValues(alpha:0.1)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _secondaryColor),
                        ),
                        child: Icon(Icons.person,
                            color: _secondaryColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacher['nama'] ?? 'Guru',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: _secondaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (teacher['nip'] != null)
                              Text(
                                'NIP: ${teacher['nip']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _secondaryColor.withValues(alpha:0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check, color: _accentColor, size: 20),
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
                      color: _primaryColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _secondaryColor),
                      boxShadow: const [_heavyShadow],
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
                                    color: _primaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _secondaryColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.search,
                                          color: _secondaryColor, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextField(
                                          controller: searchTeacherController,
                                          focusNode: searchTeacherFocusNode,
                                          onChanged: (value) =>
                                              filterTeacherList(),
                                          decoration: InputDecoration(
                                            hintText: 'Cari guru...',
                                            hintStyle: TextStyle(
                                                color: _secondaryColor
                                                    .withValues(alpha:0.6)),
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                            isDense: true,
                                          ),
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: _secondaryColor),
                                        ),
                                      ),
                                      if (searchTeacherController
                                          .text.isNotEmpty)
                                        GestureDetector(
                                          onTap: () {
                                            searchTeacherController.clear();
                                            filterTeacherList();
                                          },
                                          child: Icon(Icons.clear,
                                              size: 16, color: _secondaryColor),
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
                                    color: _secondaryColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.close,
                                      size: 18, color: _primaryColor),
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
              backgroundColor: _primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 20, color: _accentColor),
                          const SizedBox(width: 8),
                          Text(
                            'Setujui Pengajuan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _secondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // === GURU PEMBIMBING (URUTAN PERTAMA) ===
                      Text(
                        'Guru Pembimbing',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _secondaryColor,
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
                            border: Border.all(color: _secondaryColor),
                            borderRadius: BorderRadius.circular(8),
                            color: _primaryColor,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: selectedTeacherId == null
                                    ? Text(
                                        'Pilih guru pembimbing',
                                        style: TextStyle(
                                          color:
                                              _secondaryColor.withValues(alpha:0.6),
                                          fontSize: 14,
                                        ),
                                      )
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedTeacherName ?? 'Guru',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: _secondaryColor,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'ID: $selectedTeacherId',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _secondaryColor
                                                  .withValues(alpha:0.6),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              Icon(
                                showTeacherPopup
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: _secondaryColor.withValues(alpha:0.6),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // === CATATAN (URUTAN KEDUA) ===
                      Text(
                        'Catatan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _secondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: catatanController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan catatan (opsional)',
                          hintStyle: TextStyle(
                              color: _secondaryColor.withValues(alpha:0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _secondaryColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        style: TextStyle(fontSize: 12, color: _secondaryColor),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      // === TANGGAL MULAI (URUTAN KETIGA) ===
                      Text(
                        'Tanggal Mulai',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _secondaryColor,
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
                                  colorScheme: ColorScheme.light(
                                    primary: _accentColor,
                                    onPrimary: _primaryColor,
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
                            border: Border.all(color: _secondaryColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 18, color: _secondaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedStartDate != null
                                      ? '${selectedStartDate!.day.toString().padLeft(2, '0')}/${selectedStartDate!.month.toString().padLeft(2, '0')}/${selectedStartDate!.year}'
                                      : 'Pilih tanggal mulai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selectedStartDate != null
                                        ? _secondaryColor
                                        : _secondaryColor.withValues(alpha:0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // === TANGGAL SELESAI (URUTAN KEEMPAT) ===
                      Text(
                        'Tanggal Selesai',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _secondaryColor,
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
                                  colorScheme: ColorScheme.light(
                                    primary: _accentColor,
                                    onPrimary: _primaryColor,
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
                            border: Border.all(color: _secondaryColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 18, color: _secondaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  selectedEndDate != null
                                      ? '${selectedEndDate!.day.toString().padLeft(2, '0')}/${selectedEndDate!.month.toString().padLeft(2, '0')}/${selectedEndDate!.year}'
                                      : 'Pilih tanggal selesai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: selectedEndDate != null
                                        ? _secondaryColor
                                        : _secondaryColor.withValues(alpha:0.6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tombol Aksi dengan animasi
                      Row(
                        children: [
                          // Tombol Batal dengan animasi
                          Expanded(
                            child: PressableButton(
                              onTap: () {
                                removeTeacherOverlay();
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _secondaryColor, width: 2),
                                  boxShadow: const [_heavyShadow],
                                ),
                                child: Center(
                                  child: Text(
                                    'BATAL',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: _secondaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Tombol Setujui dengan animasi
                          Expanded(
                            child: PressableButton(
                              onTap: () {
                                // Validasi
                                if (selectedStartDate == null) {
                                  _showSnackBar('Pilih tanggal mulai');
                                  return;
                                }
                                if (selectedEndDate == null) {
                                  _showSnackBar('Pilih tanggal selesai');
                                  return;
                                }
                                if (selectedTeacherId == null) {
                                  _showSnackBar('Pilih guru pembimbing');
                                  return;
                                }

                                if (selectedEndDate!
                                    .isBefore(selectedStartDate!)) {
                                  _showSnackBar(
                                      'Tanggal selesai harus setelah tanggal mulai');
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
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _accentColor,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: _secondaryColor, width: 2),
                                  boxShadow: const [_heavyShadow],
                                ),
                                child: Center(
                                  child: Text(
                                    'SETUJUI',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: _primaryColor,
                                    ),
                                  ),
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
      },
    );
  }

  void _showRejectDialog(
      Map<String, dynamic> application, Map<String, dynamic> appData) {
    final catatanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.cancel_outlined,
                        size: 20, color: _accentColor),
                    const SizedBox(width: 8),
                    Text(
                      'Tolak Pengajuan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha:0.8),
                    border: Border.all(color: _secondaryColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Siswa: ${appData['siswa_username']}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _secondaryColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Industri: ${appData['industri_nama']}',
                        style: TextStyle(
                            fontSize: 12, color: _secondaryColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Alasan Penolakan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _secondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: catatanController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan alasan penolakan...',
                    hintStyle: TextStyle(
                        color: _secondaryColor.withValues(alpha: 0.6)),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: _secondaryColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  style: TextStyle(fontSize: 12, color: _secondaryColor),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Tombol Batal dengan animasi
                    Expanded(
                      child: PressableButton(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: _secondaryColor, width: 2),
                            boxShadow: const [_heavyShadow],
                          ),
                          child: Center(
                            child: Text(
                              'BATAL',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: _secondaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol Tolak dengan animasi
                    Expanded(
                      child: PressableButton(
                        onTap: () {
                          if (catatanController.text.isEmpty) {
                            _showSnackBar('Masukkan alasan penolakan');
                            return;
                          }
                          _rejectApplication(
                              application['id'], catatanController.text);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: _secondaryColor, width: 2),
                            boxShadow: const [_heavyShadow],
                          ),
                          child: Center(
                            child: Text(
                              'TOLAK',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: _primaryColor,
                              ),
                            ),
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
      ),
    );
  }

  void _showUpdateQuotaDialog(Map<String, dynamic> industry) {
    final quotaController =
        TextEditingController(text: (industry['kuota_siswa'] ?? '').toString());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: _primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.edit, size: 20, color: _accentColor),
                    const SizedBox(width: 8),
                    Text(
                      'Update Kuota',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.8),
                    border: Border.all(color: _secondaryColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    industry['nama'] ?? 'Industri',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _secondaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Kuota Siswa',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _secondaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: quotaController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan jumlah kuota...',
                    hintStyle:
                        TextStyle(color: _secondaryColor.withValues(alpha:0.6)),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: _secondaryColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  style: TextStyle(fontSize: 12, color: _secondaryColor),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // Tombol Batal dengan animasi
                    Expanded(
                      child: PressableButton(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: _secondaryColor, width: 2),
                            boxShadow: const [_heavyShadow],
                          ),
                          child: Center(
                            child: Text(
                              'BATAL',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: _secondaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol Update dengan animasi
                    Expanded(
                      child: PressableButton(
                        onTap: () {
                          final newQuota =
                              int.tryParse(quotaController.text) ?? 0;
                          if (newQuota <= 0) {
                            _showSnackBar('Masukkan kuota yang valid');
                            return;
                          }
                          _updateIndustryQuota(
                              industry['industri_id'], newQuota);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _accentColor,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: _secondaryColor, width: 2),
                            boxShadow: const [_heavyShadow],
                          ),
                          child: Center(
                            child: Text(
                              'UPDATE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: _primaryColor,
                              ),
                            ),
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
      ),
    );
  }
}