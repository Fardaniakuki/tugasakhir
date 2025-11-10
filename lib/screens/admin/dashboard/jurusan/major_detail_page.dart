import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_major_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../popup_helper.dart';

class MajorDetailPage extends StatefulWidget {
  final String majorId;

  const MajorDetailPage({super.key, required this.majorId});

  @override
  State<MajorDetailPage> createState() => _MajorDetailPageState();
}

class _MajorDetailPageState extends State<MajorDetailPage> {
  Map<String, dynamic>? majorData;
  List<dynamic> classes = [];
  bool isLoading = true;
  bool isLoadingClasses = true;

  final Color brown = const Color(0xFF5B1A1A);
  final Color danger = const Color(0xFF8B0000);

  @override
  void initState() {
    super.initState();
    fetchMajorDetail();
    fetchClasses();
  }

  Future<void> fetchMajorDetail() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/jurusan/${widget.majorId}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      setState(() {
        majorData = decoded['data'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      // ignore: use_build_context_synchronously
      PopupHelper.showErrorDialog(context, 'Gagal mengambil data jurusan');
    }
  }

  Future<void> fetchClasses() async {
    setState(() => isLoadingClasses = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas?jurusan_id=${widget.majorId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        setState(() {
          if (decoded['data'] != null && decoded['data']['data'] is List) {
            classes = decoded['data']['data'];
          } else if (decoded['data'] is List) {
            classes = decoded['data'];
          } else {
            classes = [];
          }
          isLoadingClasses = false;
        });
      } else {
        setState(() => isLoadingClasses = false);
        if (!mounted) return;
        PopupHelper.showErrorDialog(context, 'Gagal mengambil data kelas');
      }
    } catch (e) {
      setState(() => isLoadingClasses = false);
      if (!mounted) return;
      PopupHelper.showErrorDialog(context, 'Error: $e');
    }
  }

  Future<void> deleteMajor() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.delete(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/jurusan/${widget.majorId}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      PopupHelper.showSuccessDialog(context, 'Jurusan berhasil dihapus', onOk: () {
        Navigator.pop(context, {'deleted': true});
      });
    } else {
      if (!mounted) return;
      PopupHelper.showErrorDialog(
        context,
        'Gagal menghapus jurusan: ${response.statusCode}\n${response.body}',
      );
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Jurusan'),
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
            ),
            onPressed: () {
              Navigator.pop(context);
              deleteMajor();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String? value) {
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
                Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(value ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildClassesSection() {
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
                child: const Icon(Icons.class_, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Kelas dalam Jurusan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoadingClasses)
            const Center(child: CircularProgressIndicator())
          else if (classes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Tidak ada kelas dalam jurusan ini',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Column(
              children: classes.map((classData) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.class_, color: Colors.grey, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              classData['nama'] ?? '-',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            if (classData['tingkat'] != null)
                              Text(
                                'Tingkat ${classData['tingkat']}',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      if (classData['jumlah_siswa'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: brown.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${classData['jumlah_siswa']} siswa',
                            style: TextStyle(fontSize: 12, color: brown, fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
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
        title: const Text('Detail Jurusan'),
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
          : majorData == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: brown,
                        child: const Icon(Icons.school, size: 50, color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        majorData!['nama'] ?? '-',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text('Jurusan', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 24),

                      _buildProfileItem(Icons.code, 'Kode Jurusan', majorData!['kode']),
                      _buildProfileItem(Icons.school, 'Nama Jurusan', majorData!['nama']),

                      // Tambahkan section kelas di sini
                      _buildClassesSection(),

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
                                    builder: (_) => EditMajorPage(majorData: majorData!),
                                  ),
                                );
                                if (result == true) {
                                  fetchMajorDetail();
                                  fetchClasses(); // Refresh data kelas setelah edit
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