import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'edit_class_page.dart';
import '../../popup_helper.dart';
import '../murid/student_detail_page.dart'; // Import halaman detail siswa

class ClassDetailPage extends StatefulWidget {
  final String classId;

  const ClassDetailPage({super.key, required this.classId});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  Map<String, dynamic>? classData;
  List<dynamic> students = [];
  bool isLoading = true;
  bool isLoadingStudents = true;

  final Color brown = const Color(0xFF5B1A1A);
  final Color danger = const Color(0xFF8B0000);

  @override
  void initState() {
    super.initState();
    fetchClassDetail();
    fetchStudents();
  }

  // Ambil nama jurusan
  Future<String> getJurusanName(int jurusanId, String token) async {
    final response = await http.get(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/jurusan/$jurusanId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data']?['nama'] ?? '-';
    } else {
      return '-';
    }
  }

  Future<void> fetchClassDetail() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    final response = await http.get(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas/${widget.classId}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final kelas = decoded['data'];

      // Ambil nama jurusan
      String jurusanNama = '-';
      if (kelas['jurusan_id'] != null) {
        jurusanNama = await getJurusanName(kelas['jurusan_id'], token);
      }

      setState(() {
        classData = {...kelas, 'jurusan_nama': jurusanNama};
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      PopupHelper.showErrorDialog(context, 'Gagal mengambil data kelas');
    }
  }

  Future<void> fetchStudents() async {
    setState(() => isLoadingStudents = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/siswa?kelas_id=${widget.classId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        List<dynamic> fetchedStudents = [];
        
        if (decoded['data'] != null && decoded['data']['data'] is List) {
          fetchedStudents = decoded['data']['data'];
        } else if (decoded['data'] is List) {
          fetchedStudents = decoded['data'];
        } else {
          fetchedStudents = [];
        }

        // Urutkan siswa berdasarkan nama depan
        fetchedStudents.sort((a, b) {
          final String nameA = (a['nama_lengkap'] ?? a['nama'] ?? '').toString().toLowerCase();
          final String nameB = (b['nama_lengkap'] ?? b['nama'] ?? '').toString().toLowerCase();
          
          // Ambil kata pertama (nama depan)
          final String firstNameA = nameA.split(' ').first;
          final String firstNameB = nameB.split(' ').first;
          
          return firstNameA.compareTo(firstNameB);
        });

        setState(() {
          students = fetchedStudents;
          isLoadingStudents = false;
        });
      } else {
        setState(() => isLoadingStudents = false);
        PopupHelper.showErrorDialog(context, 'Gagal mengambil data siswa');
      }
    } catch (e) {
      setState(() => isLoadingStudents = false);
      if (!mounted) return;
      PopupHelper.showErrorDialog(context, 'Error: $e');
    }
  }

  Future<void> deleteClass() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.delete(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas/${widget.classId}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      PopupHelper.showSuccessDialog(context, 'Kelas berhasil dihapus',
          onOk: () {
        Navigator.pop(context, {'deleted': true});
      });
    } else {
      PopupHelper.showErrorDialog(
        context,
        'Gagal menghapus kelas: ${response.statusCode}\n${response.body}',
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kelas'),
        content: const Text('Yakin ingin menghapus kelas ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              deleteClass();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: brown,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStudentsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: brown,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Daftar Murid',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: brown.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${students.length} siswa',
                  style: TextStyle(fontSize: 12, color: brown, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoadingStudents)
            const Center(child: CircularProgressIndicator())
          else if (students.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Tidak ada murid dalam kelas ini',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Column(
              children: students.map((student) {
                return InkWell(
                  onTap: () {
                    // Navigasi ke halaman detail siswa ketika diklik
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentDetailPage(
                          studentId: student['id'].toString(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: brown.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            color: brown,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student['nama_lengkap'] ?? student['nama'] ?? '-',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              if (student['nisn'] != null)
                                Text(
                                  'NISN: ${student['nisn']}',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              if (student['email'] != null)
                                Text(
                                  student['email'],
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Detail Kelas'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8B0000), Color(0xFFB22222)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : classData == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: brown,
                              child: const Icon(Icons.class_, size: 50, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              classData!['nama'] ?? '-',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text('Kelas', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildProfileItem(Icons.class_, 'Nama Kelas', classData!['nama']),
                      _buildProfileItem(Icons.school, 'Jurusan', classData!['jurusan_nama'] ?? '-'),

                      // Tambahkan section daftar murid di sini
                      _buildStudentsSection(),

                      const SizedBox(height: 30),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _confirmDelete,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: danger,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Hapus'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditClassPage(classData: classData!),
                                  ),
                                );

                                // **Refresh data dari server setelah edit**
                                if (result == true && mounted) {
                                  fetchClassDetail();
                                  fetchStudents(); // Refresh data siswa setelah edit
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: brown,
                                side: BorderSide(color: brown),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Edit'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}