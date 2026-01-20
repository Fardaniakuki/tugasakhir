import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../login/login_screen.dart';
import 'koordinator_pengaturan.dart';
import 'industri_detail_screen.dart'; // Anda mungkin sudah punya ini

class KoordinatorDashboard extends StatefulWidget {
  const KoordinatorDashboard({super.key});

  @override
  State<KoordinatorDashboard> createState() => _KoordinatorDashboardState();
}

class _KoordinatorDashboardState extends State<KoordinatorDashboard> {
  String _namaKoordinator = 'Koordinator PKL';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // Data dari API
  List<dynamic> _pendingApplications = [];
  List<dynamic> _approvedApplications = [];
  List<dynamic> _industries = [];
  List<dynamic> _teachers = [];
  List<dynamic> _pklStudents = [];

  // Warna profesional (sama dengan kaprog)
  final Color _primaryRed = const Color(0xFF6B1B1B);
  final Color _bgSoft = const Color(0xFFF6EEEE);
  final Color _borderOrange = const Color(0xFFFFB74D);
  final Color _orange = const Color(0xFFFF9800);
  final Color _green = const Color(0xFF4CAF50);
  final Color _red = const Color(0xFFF44336);
  final Color _secondaryColor = Colors.white;
  final Color _blackColor = Colors.black;

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
        _fetchPklStudents(),
      ]);
    } catch (e) {
      print('Error loading data: $e');
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
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
        _namaKoordinator = userName;
      });
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

  Future<void> _fetchPklStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _redirectToLogin();
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['API_BASE_URL']}/api/pkl/applications?status=Approved'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> approvedApps = data['data'] ?? [];

        final List<Map<String, dynamic>> studentsData = [];

        for (var app in approvedApps) {
          final appData = app['application'] ?? {};

          // Cari data pembimbing
          String pembimbingName = 'Belum ditentukan';
          final pembimbingId = appData['pembimbing_guru_id'];

          if (pembimbingId != null) {
            for (var teacher in _teachers) {
              if (teacher['id'] == pembimbingId) {
                pembimbingName = teacher['nama'] ?? 'Pembimbing';
                break;
              }
            }
          }

          studentsData.add({
            'nama': app['siswa_username'] ?? 'Siswa',
            'kelas': app['kelas_nama'] ?? '-',
            'industri': app['industri_nama'] ?? 'Industri',
            'pembimbing': pembimbingName,
            'status': appData['status'] ?? 'Approved',
            'tanggal_mulai': appData['tanggal_mulai'] ?? '-',
            'tanggal_selesai': appData['tanggal_selesai'] ?? '-',
            'application_id': appData['id'],
            'siswa_id': app['siswa_id'],
            'industri_id': app['industri_id'],
          });
        }

        setState(() => _pklStudents = studentsData);
      }
    } catch (e) {
      print('Error fetching PKL students: $e');
    }
  }


  void _navigateToPengaturan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const KoordinatorPengaturan(),
      ),
    );
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      print('Mencari: $query');
    }
  }

  // ============= DIALOG DETAIL SISWA PKL =============
  void _showStudentDetailDialog(Map<String, dynamic> studentData) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                        color: _primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.person,
                        color: _primaryRed,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DETAIL SISWA PKL',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF6B1B1B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Informasi lengkap siswa',
                            style: TextStyle(
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

                // Info Siswa
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Siswa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B1B1B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _detailItem('Nama Siswa', studentData['nama'] ?? 'Siswa'),
                      _detailItem('Kelas', studentData['kelas'] ?? '-'),
                      _detailItem('Status', studentData['status'] ?? 'Aktif'),
                      _detailItem(
                          'Tanggal Mulai', studentData['tanggal_mulai'] ?? '-'),
                      _detailItem('Tanggal Selesai',
                          studentData['tanggal_selesai'] ?? '-'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Info Industri
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informasi Industri',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B1B1B),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _detailItem('Nama Industri',
                          studentData['industri'] ?? 'Industri'),
                      _detailItem('Pembimbing Industri',
                          studentData['pembimbing'] ?? 'Belum ditentukan'),
                      if (studentData['industri_id'] != null)
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => IndustriDetailScreen(
                                  industriId: studentData['industri_id'],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: _primaryRed.withValues(alpha:0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _primaryRed.withValues(alpha:0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: _primaryRed,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Lihat Detail Industri',
                                  style: TextStyle(
                                    color: _primaryRed,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
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
                          'TUTUP',
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

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
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
      ),
    );
  }
// ============= DIALOG DETAIL PEMBIMBING =============
void _showTeacherDetailDialog(Map<String, dynamic> teacherData) {
  final students = teacherData['students'] ?? [];

  showDialog(
    context: context,
    builder: (context) => Dialog(
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
                      color: _primaryRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.people,
                      color: _primaryRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DETAIL PEMBIMBING',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6B1B1B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Informasi lengkap pembimbing',
                          style: TextStyle(
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

              // Info Pembimbing
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Pembimbing',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B1B1B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _simpleDetailItem('Nama', teacherData['nama'] ?? 'Guru'),
                    _simpleDetailItem('NIP', teacherData['nip'] ?? '-'),
                    _simpleDetailItem('No. HP', teacherData['no_telp'] ?? '-'),
                    _simpleDetailItem('Kode Guru', teacherData['kode_guru'] ?? '-')    
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Daftar Siswa
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Daftar Siswa',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B1B1B),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primaryRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${students.length} siswa',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _primaryRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (students.isNotEmpty) ...[
                      ..._buildSimpleStudentList(students),
                      const SizedBox(height: 8),
                      if (students.length > 3)
                        Text(
                          '${students.length - 3} siswa lainnya...',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 36,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Belum ada siswa yang dibimbing',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action Button
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
                        'TUTUP',
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

Widget _simpleDetailItem(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
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
    ),
  );
}

List<Widget> _buildSimpleStudentList(List<dynamic> students) {
  // Ambil hanya 3 siswa pertama untuk tampilan
  final displayStudents = students.length > 3 ? students.sublist(0, 3) : students;
  
  return displayStudents.map<Widget>((student) {
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
        statusColor = _red;
        statusText = 'Ditolak';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Menunggu';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _primaryRed.withValues(alpha: 0.1),
            radius: 18,
            child: Text(
              namaSiswa.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: _primaryRed,
                fontWeight: FontWeight.w700,
                fontSize: 14,
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
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$kelas • $industri',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }).toList();
}



  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
      backgroundColor: _bgSoft,
      body: _isLoading ? _buildSkeleton() : _content(),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _skeletonHeaderCard(),
          const SizedBox(height: 16),
          _skeletonTopCard(),
          _skeletonMainContainer(),
        ],
      ),
    );
  }

  Widget _skeletonHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
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
                width: 120,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
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
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonTopCard() {
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
              color: Colors.black.withValues(alpha:0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[300],
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
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _skeletonChip()),
                const SizedBox(width: 8),
                Expanded(child: _skeletonChip()),
                const SizedBox(width: 8),
                Expanded(child: _skeletonChip()),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonMainContainer() {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      decoration: BoxDecoration(
        color: _secondaryColor,
        border: Border.all(color: _blackColor.withValues(alpha:0.1), width: 1),
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
            Container(
              width: 200,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 185,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 150,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              width: 180,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 190,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ],
        ),
      ),
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
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
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
                'Dashboard Koordinator',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B1B1B),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      
                    },
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Color(0xFF6B1B1B),
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
                        color: const Color(0xFF6B1B1B).withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF6B1B1B).withValues(alpha:0.3),
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
            'Selamat Datang, $_namaKoordinator',
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
              color: Colors.black.withValues(alpha:0.08),
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
                    Icons.people, 'Siswa PKL', '${_pklStudents.length} Aktif'),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryRed,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primaryRed.withValues(alpha:0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: _primaryRed.withValues(alpha:0.3),
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
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.supervisor_account,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text('Total PKL Aktif',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_approvedApplications.length}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ],
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
            label: 'Aktif',
            color: _green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PengajuanChip(
            count: '${_teachers.length}',
            label: 'Pembimbing',
            color: Colors.blue,
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
          border: Border.all(color: _borderOrange.withValues(alpha:0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha:0.1),
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
                color: _primaryRed.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: _primaryRed.withValues(alpha:0.2), width: 1),
              ),
              child: Icon(icon, color: _primaryRed, size: 20),
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

  Widget _search() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Cari siswa PKL, industri, atau pembimbing',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
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
              icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
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
        border: Border.all(color: _blackColor.withValues(alpha:0.1), width: 1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
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
            // Section 1: Daftar Siswa PKL
            _sectionTitleWithSeeAll('Siswa PKL Aktif', _pklStudents.length),
            const SizedBox(height: 16),
            _pklStudentsList(),
            const SizedBox(height: 40),

            // Section 2: Daftar Industri
            _sectionTitleWithSeeAll('Daftar Industri', _industries.length),
            const SizedBox(height: 16),
            _industriList(),
            const SizedBox(height: 40),

            // Section 3: Daftar Pembimbing
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
                color: _primaryRed.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: _primaryRed.withValues(alpha:0.2), width: 1),
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

  Widget _pklStudentsList() {
    if (_pklStudents.isEmpty) {
      return _emptyPklStudentsList();
    }

    return SizedBox(
      height: 235,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pklStudents.length,
              itemBuilder: (context, index) {
                final student = _pklStudents[index];
                return Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  margin: EdgeInsets.only(
                    right: index < _pklStudents.length - 1 ? 16 : 0,
                    left: index == 0 ? 0 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () => _showStudentDetailDialog(student),
                    child: _pklStudentCard(
                      student['nama'] ?? 'Siswa',
                      student['kelas'] ?? '-',
                      student['industri'] ?? 'Industri',
                      student['pembimbing'] ?? 'Belum ditentukan',
                      student['status'] ?? 'Aktif',
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_pklStudents.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Geser untuk melihat lebih banyak →',
                  style: TextStyle(
                    color: Colors.grey[600],
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

  Widget _pklStudentCard(
    String siswaName,
    String kelasName,
    String industriName,
    String pembimbingName,
    String status,
  ) {
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
        statusColor = _red;
        statusText = 'Ditolak';
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Menunggu';
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
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
                  color: _primaryRed.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _primaryRed.withValues(alpha:0.3), width: 1.5),
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
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Text(
                        kelasName,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
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
              color: statusColor.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor.withValues(alpha:0.3), width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.work_outline,
                  color: statusColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            pembimbingName,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _emptyPklStudentsList() {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            const Text(
              'Belum ada siswa PKL aktif',
              style: TextStyle(color: Colors.grey, fontSize: 14),
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
                final industriId = industry['industri_id'];
                final kuota =
                    '${industry['remaining_slots'] ?? 0}/${industry['kuota_siswa'] ?? 0} Kuota';
                return Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  margin: EdgeInsets.only(
                    right: index < _industries.length - 1 ? 16 : 0,
                    left: index == 0 ? 0 : 0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      if (industriId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => IndustriDetailScreen(
                              industriId: industriId,
                            ),
                          ),
                        );
                      }
                    },
                    child: _industriCard(
                      industry['nama'] ?? 'Industri',
                      industry['bidang'] ?? 'Tidak tersedia',
                      kuota,
                      Icons.apartment,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_industries.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Geser untuk melihat lebih banyak →',
                  style: TextStyle(
                    color: Colors.grey[600],
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

  Widget _industriCard(
      String nama, String bidang, String kuota, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
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
                  color: _primaryRed.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _primaryRed.withValues(alpha:0.3), width: 1.5),
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
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Text(
                        bidang,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
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
              color: _primaryRed.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryRed.withValues(alpha:0.1), width: 1),
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
    );
  }

  Widget _emptyIndustriList() {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
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
              style: TextStyle(color: Colors.grey, fontSize: 14),
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
                  child: GestureDetector(
                    onTap: () => _showTeacherDetailDialog(teacher),
                    child: _pembimbingCard(
                      teacherData: teacher,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          if (_teachers.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Geser untuk melihat lebih banyak →',
                  style: TextStyle(
                    color: Colors.grey[600],
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
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
                  color: _primaryRed.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _primaryRed.withValues(alpha:0.3), width: 1.5),
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
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: Text(
                        kodeGuru,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
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
              color: _primaryRed.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primaryRed.withValues(alpha:0.1), width: 1),
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
    );
  }

  Widget _emptyPembimbingList() {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
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
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
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
