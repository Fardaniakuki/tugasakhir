import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'kaprog_profile_page.dart';
import '../login/login_screen.dart';
import 'industri_detail_screen.dart';

class KaprogDashboard extends StatefulWidget {
  const KaprogDashboard({super.key, required ScrollController scrollController});

  @override
  State<KaprogDashboard> createState() => _KaprogDashboardState();
}

class _KaprogDashboardState extends State<KaprogDashboard> {
  String _namaKaprog = 'Drs. Devandra';
  bool _isLoading = true;
  bool _isCheckingToken = true;
  final TextEditingController _searchController = TextEditingController();

  // Data dari API
  List<dynamic> _pendingApplications = [];
  List<dynamic> _approvedApplications = [];
  List<dynamic> _industries = [];
  List<dynamic> _teachers = [];

  // Warna tema
  final Color _primaryRed = const Color(0xFF6B1B1B);
  final Color _bgColor = Colors.white;
  static const Color _borderColor = Color(0xFFE5E5E5);
  static const Color _orange = Color(0xFFFF9800);
  static const Color _green = Color(0xFF4CAF50);
  static const Color _red = Color(0xFFF44336);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF666666);
  final Color _cardColor = Colors.white;

  // Controller untuk dialog
  final TextEditingController _catatanController = TextEditingController();
  final TextEditingController _alasanTolakController = TextEditingController();

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
      print('Error loading data: $e');
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        _redirectToLogin();
      }
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
      } else if (response.statusCode == 401) {
        _redirectToLogin();
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
      } else if (response.statusCode == 401) {
        _redirectToLogin();
        return [];
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
        final previewIndustries = data['data'] ?? [];

        final List<Map<String, dynamic>> completeIndustries = [];

        for (var previewData in previewIndustries) {
          final industriId = previewData['industri_id'];

          try {
            final detailResponse = await http.get(
              Uri.parse(
                  '${dotenv.env['API_BASE_URL']}/api/industri/$industriId'),
              headers: {'Authorization': 'Bearer $token'},
            );

            final Map<String, dynamic> completeData =
                Map<String, dynamic>.from(previewData);

            if (detailResponse.statusCode == 200) {
              final detailData = jsonDecode(detailResponse.body);
              if (detailData['success'] == true && detailData['data'] != null) {
                completeData
                    .addAll(Map<String, dynamic>.from(detailData['data']));
              }
            }

            completeIndustries.add(completeData);
          } catch (e) {
            print('Error fetching detail for industri $industriId: $e');
            completeIndustries.add(Map<String, dynamic>.from(previewData));
          }
        }

        setState(() => _industries = completeIndustries);
      } else if (response.statusCode == 401) {
        _redirectToLogin();
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
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> teachersList = [];

        if (data['success'] == true && data['data'] != null) {
          if (data['data']['data'] is List) {
            teachersList = data['data']['data'];
          } else if (data['data'] is List) {
            teachersList = data['data'];
          }
        }

        final List<dynamic> pembimbingList = teachersList.where((teacher) {
          return teacher['is_pembimbing'] == true;
        }).toList();

        final appsResponse = await http.get(
          Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/applications'),
          headers: {'Authorization': 'Bearer $token'},
        );

        List<dynamic> applications = [];
        if (appsResponse.statusCode == 200) {
          final appsData = jsonDecode(appsResponse.body);
          applications = appsData['data'] ?? [];
        } else if (appsResponse.statusCode == 401) {
          _redirectToLogin();
          return;
        }

        final List<Map<String, dynamic>> teachersWithStats = [];

        for (var teacher in pembimbingList) {
          final teacherId = teacher['id'];
          final List<Map<String, dynamic>> studentsList = [];
          int approvedStudentsCount = 0;

          for (var app in applications) {
            final appData = app['application'] ?? {};
            final pembimbingId = appData['pembimbing_guru_id'];
            final status = appData['status'] ?? '';

            if (pembimbingId != null && pembimbingId == teacherId) {
              studentsList.add({
                'nama': app['siswa_username'] ?? 'Siswa',
                'kelas': app['kelas_nama'] ?? '-',
                'industri': app['industri_nama'] ?? 'Industri',
                'status': status,
              });

              if (status == 'Approved' || status == 'Active') {
                approvedStudentsCount++;
              }
            }
          }

          final Map<String, dynamic> teacherWithStats =
              Map<String, dynamic>.from(teacher);
          teacherWithStats['jumlah_siswa'] = approvedStudentsCount;
          teacherWithStats['students'] = studentsList;
          teacherWithStats['student_count'] = studentsList.length;

          teachersWithStats.add(teacherWithStats);

          print(
              'Pembimbing: ${teacher['nama']} - Kode: ${teacher['kode_guru']} - Siswa: $approvedStudentsCount');
        }

        teachersWithStats.sort((a, b) {
          final countA = a['jumlah_siswa'] ?? 0;
          final countB = b['jumlah_siswa'] ?? 0;
          return countB.compareTo(countA);
        });

        setState(() => _teachers = teachersWithStats);
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      }
    } catch (e) {
      print('Error fetching teachers: $e');
    }
  }

  Future<void> _approveApplication(Map<String, dynamic> appData, String guruId,
      String catatan, DateTime tanggalMulai, DateTime tanggalSelesai) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final application = appData['application'] ?? {};
      final applicationId = application['id'];

      if (applicationId == null) {
        _showSnackBar('ID aplikasi tidak valid', isError: true);
        return;
      }

      final formattedMulai =
          "${tanggalMulai.year}-${tanggalMulai.month.toString().padLeft(2, '0')}-${tanggalMulai.day.toString().padLeft(2, '0')}";
      final formattedSelesai =
          "${tanggalSelesai.year}-${tanggalSelesai.month.toString().padLeft(2, '0')}-${tanggalSelesai.day.toString().padLeft(2, '0')}";

      final response = await http.put(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/pkl/applications/$applicationId/approve'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'catatan': catatan,
          'pembimbing_guru_id': int.parse(guruId),
          'tanggal_mulai': formattedMulai,
          'tanggal_selesai': formattedSelesai,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        _showSnackBar('Pengajuan berhasil disetujui');
        await _loadAllData();
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        final errorData = jsonDecode(response.body);
        _showSnackBar('Gagal menyetujui pengajuan: ${errorData['message']}',
            isError: true);
      }
    } catch (e) {
      print('Error approve application: $e');
      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _rejectApplication(
      Map<String, dynamic> appData, String alasan) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final application = appData['application'] ?? {};
      final applicationId = application['id'];

      if (applicationId == null) {
        _showSnackBar('ID aplikasi tidak valid', isError: true);
        return;
      }

      final response = await http.put(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/pkl/applications/$applicationId/reject'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({'catatan': alasan}),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Pengajuan berhasil ditolak');
        await _loadAllData();
      } else if (response.statusCode == 401) {
        _redirectToLogin();
      } else {
        _showSnackBar('Gagal menolak pengajuan', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Colors.white,
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

  // ============= SKELETON LOADING =============
  Widget _buildSkeletonLoading() {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header skeleton
            Container(
              margin: const EdgeInsets.fromLTRB(16, 40, 16, 0),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _borderColor),
              ),
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
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
                  const SizedBox(height: 8),
                  Container(
                    width: 180,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Top card skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Main content skeleton
            Container(
              margin: const EdgeInsets.only(top: 40),
              decoration: BoxDecoration(
                color: _cardColor,
                border: Border.all(color: _borderColor),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 150,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 185,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) => Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 120,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) => Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 140,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        Container(
                          width: 60,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 190,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) => Container(
                          width: MediaQuery.of(context).size.width * 0.75,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(18),
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

  // ============= DIALOG SETUJUI YANG DIPERBAIKI =============
  void _showApproveDialog(Map<String, dynamic> appData) {
    String? selectedGuruId;
    final TextEditingController catatanController = TextEditingController();
    DateTime? selectedTanggalMulai;
    DateTime? selectedTanggalSelesai;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: _green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SETUJUI PENGAJUAN',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: _textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Lengkapi data untuk menyetujui',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Detail Siswa
                    _buildDetailCard(
                      title: 'Detail Pengajuan',
                      items: [
                        _buildDetailItem(
                          icon: Icons.person,
                          label: 'Siswa',
                          value: appData['siswa_username'] ?? 'Siswa',
                        ),
                        _buildDetailItem(
                          icon: Icons.school,
                          label: 'Kelas',
                          value: appData['kelas_nama'] ?? '-',
                        ),
                        _buildDetailItem(
                          icon: Icons.apartment,
                          label: 'Industri',
                          value: appData['industri_nama'] ?? 'Industri',
                        ),
                        _buildDetailItem(
                          icon: Icons.calendar_today,
                          label: 'Tanggal Pengajuan',
                          value: appData['application']?['tanggal_permohonan'] ?? '-',
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Pilih Guru Pembimbing
                    const Text(
                      'Guru Pembimbing *',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedGuruId,
                          hint: const Text(
                            'Pilih guru pembimbing',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: _textPrimary),
                          items: _teachers.map((teacher) {
                            final nama = teacher['nama'] ?? 'Guru';
                            final nip = teacher['nip'] ?? '';
                            return DropdownMenuItem<String>(
                              value: teacher['id']?.toString() ??
                                  teacher['user_id']?.toString() ??
                                  teacher['guru_id']?.toString(),
                              child: Text(
                                nip.isNotEmpty ? '$nama (NIP: $nip)' : nama,
                                style: const TextStyle(fontSize: 14, color: _textPrimary),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedGuruId = newValue;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tanggal Mulai
                    const Text(
                      'Tanggal Mulai PKL *',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(DateTime.now().year + 2, 12, 31),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: _primaryRed,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTanggalMulai = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedTanggalMulai != null
                                  ? '${selectedTanggalMulai!.day}/${selectedTanggalMulai!.month}/${selectedTanggalMulai!.year}'
                                  : 'Pilih tanggal mulai',
                              style: TextStyle(
                                color: selectedTanggalMulai != null
                                    ? _textPrimary
                                    : _textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: _primaryRed,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tanggal Selesai
                    const Text(
                      'Tanggal Selesai PKL *',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedTanggalMulai ?? DateTime.now(),
                          firstDate: selectedTanggalMulai ?? DateTime.now(),
                          lastDate: DateTime(DateTime.now().year + 2, 12, 31),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: _primaryRed,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTanggalSelesai = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedTanggalSelesai != null
                                  ? '${selectedTanggalSelesai!.day}/${selectedTanggalSelesai!.month}/${selectedTanggalSelesai!.year}'
                                  : 'Pilih tanggal selesai',
                              style: TextStyle(
                                color: selectedTanggalSelesai != null
                                    ? _textPrimary
                                    : _textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              color: _primaryRed,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Catatan
                    const Text(
                      'Catatan (Opsional)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: TextField(
                        controller: catatanController,
                        maxLines: 3,
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Masukkan catatan untuk siswa...',
                          hintStyle: TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        style: const TextStyle(fontSize: 14, color: _textPrimary),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Validasi
                    if (selectedTanggalMulai != null &&
                        selectedTanggalSelesai != null &&
                        selectedTanggalSelesai!.isBefore(selectedTanggalMulai!))
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _red.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning, color: _red, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tanggal selesai harus setelah tanggal mulai',
                                style: TextStyle(
                                  color: _red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (selectedTanggalMulai != null &&
                        selectedTanggalSelesai != null &&
                        selectedTanggalSelesai!.isBefore(selectedTanggalMulai!))
                      const SizedBox(height: 12),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _textPrimary,
                              side: const BorderSide(color: _borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.white,
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
                              if (selectedGuruId == null) {
                                _showSnackBar(
                                    'Pilih guru pembimbing terlebih dahulu',
                                    isError: true);
                                return;
                              }
                              if (selectedTanggalMulai == null) {
                                _showSnackBar(
                                    'Pilih tanggal mulai PKL terlebih dahulu',
                                    isError: true);
                                return;
                              }
                              if (selectedTanggalSelesai == null) {
                                _showSnackBar(
                                    'Pilih tanggal selesai PKL terlebih dahulu',
                                    isError: true);
                                return;
                              }
                              if (selectedTanggalSelesai!
                                  .isBefore(selectedTanggalMulai!)) {
                                _showSnackBar(
                                    'Tanggal selesai harus setelah tanggal mulai',
                                    isError: true);
                                return;
                              }

                              _approveApplication(
                                appData,
                                selectedGuruId!,
                                catatanController.text.trim(),
                                selectedTanggalMulai!,
                                selectedTanggalSelesai!,
                              );

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                            ),
                            child: const Text(
                              'SETUJUI',
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
      ),
    );
  }

  // ============= DIALOG TOLAK YANG DIPERBAIKI =============
  void _showRejectDialog(Map<String, dynamic> appData) {
    final TextEditingController alasanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                        Icons.cancel,
                        color: _red,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOLAK PENGAJUAN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Berikan alasan penolakan',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Detail Siswa
                _buildDetailCard(
                  title: 'Detail Pengajuan',
                  items: [
                    _buildDetailItem(
                      icon: Icons.person,
                      label: 'Siswa',
                      value: appData['siswa_username'] ?? 'Siswa',
                    ),
                    _buildDetailItem(
                      icon: Icons.school,
                      label: 'Kelas',
                      value: appData['kelas_nama'] ?? '-',
                    ),
                    _buildDetailItem(
                      icon: Icons.apartment,
                      label: 'Industri',
                      value: appData['industri_nama'] ?? 'Industri',
                    ),
                    _buildDetailItem(
                      icon: Icons.calendar_today,
                      label: 'Tanggal Pengajuan',
                      value: appData['application']?['tanggal_permohonan'] ?? '-',
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Alasan Penolakan
                const Text(
                  'Alasan Penolakan *',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor),
                  ),
                  child: TextField(
                    controller: alasanController,
                    maxLines: 4,
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Masukkan alasan penolakan...',
                      hintStyle: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14, color: _textPrimary),
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _textPrimary,
                          side: const BorderSide(color: _borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.white,
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

                          _rejectApplication(
                            appData,
                            alasanController.text.trim(),
                          );

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
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
      ),
    );
  }

  // ============= WIDGET PEMBANTU =============
  Widget _buildDetailCard({
    required String title,
    required List<Widget> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: items,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: _textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============= BOTTOM SHEET DETAIL PENGAJUAN =============
  Widget _detailBottomSheet(Map<String, dynamic> appData) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _borderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Detail Pengajuan',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          
          // Detail Card
          _buildDetailCard(
            title: 'Informasi Pengajuan',
            items: [
              _buildDetailItem(
                icon: Icons.person,
                label: 'Siswa',
                value: appData['siswa_username'] ?? 'Siswa',
              ),
              _buildDetailItem(
                icon: Icons.school,
                label: 'Kelas',
                value: appData['kelas_nama'] ?? '-',
              ),
              _buildDetailItem(
                icon: Icons.apartment,
                label: 'Industri',
                value: appData['industri_nama'] ?? 'Industri',
              ),
              _buildDetailItem(
                icon: Icons.calendar_today,
                label: 'Tanggal Pengajuan',
                value: appData['application']?['tanggal_permohonan'] ?? '-',
              ),
              if (appData['application']?['catatan'] != null)
                _buildDetailItem(
                  icon: Icons.note,
                  label: 'Catatan',
                  value: appData['application']?['catatan'] ?? '',
                ),
            ],
          ),

          const SizedBox(height: 30),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showRejectDialog(appData);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _red,
                    side: const BorderSide(color: _red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.white,
                  ),
                  child: const Text(
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
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showApproveDialog(appData);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text(
                    'SETUJUI',
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

  // ============= FUNGSI NAVIGASI =============
  void _navigateToPengaturan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const KaprogProfilePage(),
      ),
    );
  }

  void _navigateToPengajuanMenunggu() {
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => PengajuanMenungguScreen(
    //       pendingApplications: _pendingApplications,
    //     ),
    //   ),
    // );
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      print('Mencari: $query');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _catatanController.dispose();
    _alasanTolakController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingToken) {
      return Scaffold(
        backgroundColor: _bgColor,
        body: Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryRed, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              color: _primaryRed,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: _isLoading ? _buildSkeletonLoading() : _content(),
    );
  }

  Widget _content() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
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
        border: Border.all(color: _borderColor),
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
                'Dashboard\nKepala Konsentrasi Keahlian',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.notifications_none,
                      color: _textPrimary,
                      size: 26,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _navigateToPengaturan,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _primaryRed.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: _primaryRed,
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
            'Selamat Datang, $_namaKaprog',
            style: const TextStyle(
              fontSize: 16,
              color: _textSecondary,
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
          border: Border.all(color: _borderColor),
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
            _pengajuanRed(),
            const SizedBox(height: 14),
            Row(
              children: [
                _miniCard(
                    Icons.person, 'Pembimbing', '${_teachers.length} Aktif'),
                const SizedBox(width: 12),
                _miniCard(Icons.apartment, 'Industri',
                    '${_industries.length} Tersedia'),
              ],
            ),
            const SizedBox(height: 14),
            _pengajuanChips(),
            const SizedBox(height: 14),
            _search(),
          ],
        ),
      ),
    );
  }

  Widget _pengajuanRed() {
    return GestureDetector(
      onTap: _navigateToPengajuanMenunggu,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _primaryRed,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _primaryRed.withValues(alpha: 0.8), width: 1),
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
              child:
                  const Icon(Icons.people_alt, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text('Pengajuan PKL',
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
                '${_pendingApplications.length}',
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

  Widget _pengajuanChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _PengajuanChip(
            count: '${_pendingApplications.length}',
            label: 'Menunggu',
            color: _orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PengajuanChip(
            count: '${_approvedApplications.length}',
            label: 'Disetujui',
            color: _green,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: _PengajuanChip(
            count: '0',
            label: 'Ditolak',
            color: _red,
          ),
        ),
      ],
    );
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
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _primaryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: _primaryRed.withValues(alpha: 0.2), width: 1),
              ),
              child: Icon(icon, color: _primaryRed, size: 20),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 11, color: _textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13, color: _textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
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
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: _textSecondary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Cari pengajuan PKL, Pembimbing, atau Industri',
                hintStyle: TextStyle(color: _textSecondary, fontSize: 13),
              ),
              onSubmitted: (value) => _performSearch(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                });
              },
              icon: const Icon(Icons.clear, color: _textSecondary, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _mainContainer() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderColor, width: 1),
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
            _sectionTitleWithSeeAll('Daftar Pengajuan PKL', _pendingApplications.length),
            const SizedBox(height: 16),
            _pengajuanList(),
            const SizedBox(height: 40),

            _sectionTitleWithSeeAll('Daftar Industri', _industries.length),
            const SizedBox(height: 16),
            _industriList(),
            const SizedBox(height: 40),

            _sectionTitleWithSeeAll('Daftar Pembimbing', _teachers.length),
            const SizedBox(height: 16),
            _pembimbingList(),
            const SizedBox(height: 0),
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
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: _primaryRed,
            ),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: _primaryRed.withValues(alpha: 0.2), width: 1),
              ),
              child: Text(
                '$count total',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _primaryRed,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pengajuanList() {
    if (_pendingApplications.isEmpty) {
      return _emptyPengajuanList();
    }

    return SizedBox(
      height: 185,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pendingApplications.length,
              itemBuilder: (context, index) {
                final appData = _pendingApplications[index];
                final siswaName = appData['siswa_username'] ?? 'Siswa';
                final industriName = appData['industri_nama'] ?? 'Industri';
                final kelasName = appData['kelas_nama'] ?? '-';

                return Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  margin: EdgeInsets.only(
                    right: index < _pendingApplications.length - 1 ? 16 : 0,
                    left: index == 0 ? 0 : 0,
                  ),
                  child: _pengajuanCardHorizontal(
                    siswaName,
                    industriName,
                    kelasName,
                    'MENUNGGU',
                    Colors.orange,
                    appData,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_pendingApplications.length > 1)
            const Padding(
              padding: EdgeInsets.only(top: 8, right: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Geser untuk melihat lebih banyak →',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pengajuanCardHorizontal(
    String siswaName,
    String industriName,
    String kelasName,
    String status,
    Color statusColor,
    Map<String, dynamic> appData,
  ) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          builder: (context) => _detailBottomSheet(appData),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _primaryRed.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Icon(
                    Icons.person,
                    color: _primaryRed,
                    size: 26,
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
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.3,
                          color: _textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: _borderColor, width: 1),
                        ),
                        child: Text(
                          kelasName,
                          style:
                              const TextStyle(color: _textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              industriName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _primaryRed,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyPengajuanList() {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada pengajuan menunggu',
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _industriList() {
    if (_industries.isEmpty) {
      return _emptyIndustriList();
    }

    return SizedBox(
      height: 190,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _industries.length,
              itemBuilder: (context, index) {
                final industry = _industries[index];
                final kuota =
                    '${industry['remaining_slots'] ?? 0}/${industry['kuota_siswa'] ?? 0} Kuota';
                return Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  margin: EdgeInsets.only(
                    right: index < _industries.length - 1 ? 16 : 0,
                    left: index == 0 ? 0 : 0,
                  ),
                  child: _industriCard(
                    industry['nama'] ?? 'Industri',
                    industry['bidang'] ?? 'Tidak tersedia',
                    kuota,
                    Icons.apartment,
                    industry,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_industries.length > 2)
            const Padding(
              padding: EdgeInsets.only(top: 8, right: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Geser untuk melihat lebih banyak →',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _industriCard(String nama, String bidang, String kuota, IconData icon,
      dynamic industryData) {
    final bidangText =
        industryData['bidang'] ?? industryData['nama'] ?? 'Industri';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IndustriDetailScreen(
              industriId: industryData['industri_id'],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _primaryRed.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Icon(
                    icon,
                    color: _primaryRed,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.3,
                          color: _textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: _borderColor, width: 1),
                        ),
                        child: Text(
                          bidangText,
                          style:
                              const TextStyle(color: _textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryRed.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _primaryRed.withValues(alpha: 0.1), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    color: _primaryRed,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    kuota,
                    style: TextStyle(
                      color: _primaryRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyIndustriList() {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.factory, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'Belum ada data industri',
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pembimbingList() {
    if (_teachers.isEmpty) {
      return _emptyPembimbingList();
    }

    return SizedBox(
      height: 190,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _teachers.length,
              itemBuilder: (context, index) {
                final teacher = _teachers[index];

                return Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  margin: EdgeInsets.only(
                    right: index < _teachers.length - 1 ? 16 : 0,
                    left: index == 0 ? 0 : 0,
                  ),
                  child: _pembimbingCard(
                    teacherData: teacher,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_teachers.length > 2)
            const Padding(
              padding: EdgeInsets.only(top: 8, right: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Geser untuk melihat lebih banyak →',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pembimbingCard({
    required dynamic teacherData,
  }) {
    final nama = teacherData['nama'] ?? 'Guru';
    final kodeGuru = teacherData['kode_guru'] ?? 'Tanpa Kode';
    final jumlahSiswa = teacherData['jumlah_siswa'] ?? 0;
    final displaySiswa = '$jumlahSiswa siswa';

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => _PembimbingDetailDialog(
            nama: nama,
            teacherData: teacherData,
            mapel: teacherData['mapel'] ?? 'Mata Pelajaran',
            kuota: '',
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _primaryRed.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Icon(
                    Icons.people,
                    color: _primaryRed,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.3,
                          color: _textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: _borderColor, width: 1),
                        ),
                        child: Text(
                          kodeGuru,
                          style:
                              const TextStyle(color: _textSecondary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _primaryRed.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: _primaryRed.withValues(alpha: 0.1), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    color: _primaryRed,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    displaySiswa,
                    style: TextStyle(
                      color: _primaryRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyPembimbingList() {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'Belum ada data pembimbing',
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
  
  // ignore: non_constant_identifier_names
  void PengajuanMenungguScreen({required List pendingApplications}) {}
}

// ============= POPUP DETAIL PEMBIMBING =============
class _PembimbingDetailDialog extends StatelessWidget {
  final String nama;
  final String mapel;
  final dynamic teacherData;

  const _PembimbingDetailDialog({
    required this.nama,
    required this.mapel,
    required this.teacherData,
    required String kuota,
  });

  static const Color _primaryRed = Color(0xFF6B1B1B);
  static const Color _bgColor = Colors.white;
  static const Color _borderColor = Color(0xFFE5E5E5);
  static const Color _textPrimary = Color(0xFF1A1A1A);
  static const Color _textSecondary = Color(0xFF666666);
  static const Color _green = Color(0xFF4CAF50);

  @override
  Widget build(BuildContext context) {
    final students = teacherData?['students'] ?? [];

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: _primaryRed,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Detail Pembimbing',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Card
                    _buildHeaderCard(),
                    const SizedBox(height: 20),

                    // Informasi Guru
                    const Text(
                      'Informasi Guru',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildInfoItem('NIP', teacherData?['nip'] ?? '-'),
                    _buildInfoItem('No. HP', teacherData?['no_telp'] ?? '-'),
                    _buildInfoItem('Email', teacherData?['email'] ?? '-'),
                    _buildInfoItem('Mata Pelajaran', teacherData?['mapel'] ?? '-'),

                    const SizedBox(height: 20),

                    // Daftar Siswa
                    const Text(
                      'Daftar Siswa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (students.isNotEmpty) ...[
                      ..._buildStudentList(students),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum ada siswa yang dibimbing',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            offset: Offset(0, 6),
            color: Colors.black12,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: _primaryRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _primaryRed.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.person,
              color: _primaryRed,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mapel,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (teacherData?['kode_guru'] != null)
                  Text(
                    'Kode: ${teacherData?['kode_guru']}',
                    style: const TextStyle(
                      color: _primaryRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textSecondary,
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
                color: _textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStudentList(List<dynamic> students) {
    return students.map<Widget>((student) {
      final namaSiswa = student['nama'] ?? 'Siswa';
      final kelas = student['kelas'] ?? '-';
      final industri = student['industri'] ?? 'Industri';
      final status = student['status'] ?? 'Pending';

      Color statusColor;
      String statusText;

      switch (status) {
        case 'Approved':
        case 'Active':
          statusColor = _green;
          statusText = 'Aktif';
          break;
        case 'Completed':
          statusColor = Colors.blue;
          statusText = 'Selesai';
          break;
        case 'Rejected':
          statusColor = Colors.red;
          statusText = 'Ditolak';
          break;
        default:
          statusColor = Colors.orange;
          statusText = 'Menunggu';
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _primaryRed.withValues(alpha: 0.1),
              radius: 22,
              child: Text(
                namaSiswa.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: _primaryRed,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaSiswa,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$kelas • $industri',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
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
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }
}