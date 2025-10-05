import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'edit_teacher_page.dart';
import '../../popup_helper.dart';

class TeacherDetailPage extends StatefulWidget {
  final String teacherId;

  const TeacherDetailPage({super.key, required this.teacherId});

  @override
  State<TeacherDetailPage> createState() => _TeacherDetailPageState();
}

class _TeacherDetailPageState extends State<TeacherDetailPage> {
  Map<String, dynamic>? teacherData;
  bool isLoading = true;

  final Color brown = const Color(0xFF5B1A1A);
  final Color danger = const Color(0xFF8B0000);

  @override
  void initState() {
    super.initState();
    fetchTeacherDetail();
  }

  Future<void> fetchTeacherDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru/${widget.teacherId}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      setState(() {
        teacherData = decoded['data'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      // ignore: use_build_context_synchronously
      PopupHelper.showErrorDialog(context, 'Gagal mengambil data guru');
    }
  }

  Future<void> deleteTeacher() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.delete(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru/${widget.teacherId}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      PopupHelper.showSuccessDialog(context, 'Data guru berhasil dihapus', onOk: () {
        Navigator.pop(context, {'deleted': true});
      });
    } else {
      if (!mounted) return;
      PopupHelper.showErrorDialog(context, 'Gagal menghapus data guru');
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
        title: const Text('Hapus Guru'),
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
              deleteTeacher();
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
        title: const Text('Profil Guru'),
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
          : teacherData == null
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
                              child: const Icon(Icons.person, size: 50, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              teacherData!['nama'] ?? '-',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text('Guru', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _buildProfileItem(Icons.code, 'Kode Guru', teacherData!['kode_guru']),
                      _buildProfileItem(Icons.badge, 'NIP', teacherData!['nip']),
                      _buildProfileItem(Icons.phone, 'No. Telp', teacherData!['no_telp']),
                      _buildProfileItem(Icons.person, 'User ID', teacherData!['user_id']?.toString()),

                      const SizedBox(height: 24),
                      const Text('Status Peran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 12),

                      _buildRoleStatus('Koordinator', teacherData?['is_koordinator']),
                      _buildRoleStatus('Pembimbing', teacherData?['is_pembimbing']),
                      _buildRoleStatus('Wali Kelas', teacherData?['is_wali_kelas']),
                      _buildRoleStatus('Kaprog', teacherData?['is_kaprog']),

                      const SizedBox(height: 30),
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
                                    builder: (_) => EditTeacherPage(teacherData: teacherData!),
                                  ),
                                );
                                if (result == true) fetchTeacherDetail();
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

  Widget _buildRoleStatus(String label, bool? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            value == true ? Icons.check_circle : Icons.cancel,
            color: value == true ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
