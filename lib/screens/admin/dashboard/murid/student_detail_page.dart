
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'edit_student_page.dart';
import '../../popup_helper.dart';

class StudentDetailPage extends StatefulWidget {
  final String studentId;

  const StudentDetailPage({super.key, required this.studentId});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  Map<String, dynamic>? studentData;
  bool isLoading = true;

  final Color brown = const Color(0xFF5B1A1A);
  final Color danger = const Color(0xFF8B0000);

  @override
  void initState() {
    super.initState();
    fetchStudentDetail();
  }

  Future<String> getClassName(int kelasId, String token) async {
    final response = await http.get(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas/$kelasId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('DEBUG getClassName: status=${response.statusCode}, body=${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('DEBUG parsed kelas data: $data');
      // Pastikan sesuai struktur JSON dari API
      return data['data']?['nama'] ?? '-';
    } else {
      return '-';
    }
  }

  Future<void> fetchStudentDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/siswa/${widget.studentId}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('DEBUG fetchStudentDetail: status=${response.statusCode}, body=${response.body}');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final siswa = decoded['data'];

      // Ambil nama kelas
      String kelasNama = '-';
      if (siswa['kelas_id'] != null) {
        kelasNama = await getClassName(siswa['kelas_id'], token!);
      }

      setState(() {
        studentData = {...siswa, 'kelas_nama': kelasNama};
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      PopupHelper.showErrorDialog(context, 'Gagal mengambil data siswa');
    }
  }

  Future<void> deleteStudent() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final role = prefs.getString('user_role');

    if (role?.toLowerCase() != 'adm') {
      PopupHelper.showErrorDialog(context, 'Kamu tidak memiliki izin untuk menghapus');
      return;
    }

    final int? studentId = studentData?['id'];
    if (studentId == null) {
      PopupHelper.showErrorDialog(context, 'ID siswa tidak ditemukan');
      return;
    }

    final response = await http.delete(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/siswa/$studentId'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      PopupHelper.showSuccessDialog(context, 'Data siswa berhasil dihapus', onOk: () {
        Navigator.pop(context, {'deleted': true});
      });
    } else {
      if (!mounted) return;
      PopupHelper.showErrorDialog(
        context,
        'Gagal menghapus data: ${response.statusCode}\n${response.body}',
      );
    }
  }

  String formatDate(String? rawDate) {
    if (rawDate == null) return '-';
    try {
      final date = DateTime.parse(rawDate);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (_) {
      return rawDate;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Siswa'),
        content: const Text('Yakin ingin menghapus data ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Navigator.pop(context);
              deleteStudent();
            },
            child: const Text('Hapus'),
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
        title: const Text('Profil Murid'),
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
          : studentData == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : Container(
                  color: Colors.white,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Bagian profil
                      Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: brown,
                              child: const Icon(Icons.person, size: 50, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              studentData!['nama_lengkap'] ?? '-',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Murid', 
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            _buildProfileItem(Icons.badge, 'Nama Panjang', studentData!['nama_lengkap']),
                            _buildProfileItem(Icons.numbers, 'NIS', studentData!['nisn']),
                            _buildProfileItem(Icons.class_, 'Kelas', studentData!['kelas_nama']),
                            _buildProfileItem(Icons.home, 'Alamat Rumah', studentData!['alamat']),
                            _buildProfileItem(Icons.cake, 'Tanggal Lahir', formatDate(studentData!['tanggal_lahir'])),
                            
                            // TOMBOL DIPINDAH KE SINI - lebih dekat dengan item terakhir
                            const SizedBox(height: 10), // Dikurangi dari 32 menjadi 24
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _confirmDelete(context),
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
                                          builder: (_) => EditStudentPage(studentData: studentData!),
                                        ),
                                      );
                                      if (result == true) fetchStudentDetail();
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
                    ],
                  ),
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
}