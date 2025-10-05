// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_class_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../popup_helper.dart';

class ClassDetailPage extends StatefulWidget {
  final String classId;

  const ClassDetailPage({super.key, required this.classId});

  @override
  State<ClassDetailPage> createState() => _ClassDetailPageState();
}

class _ClassDetailPageState extends State<ClassDetailPage> {
  Map<String, dynamic>? classData;
  bool isLoading = true;

  final Color brown = const Color(0xFF5B1A1A);
  final Color danger = const Color(0xFF8B0000);

  @override
  void initState() {
    super.initState();
    fetchClassDetail();
  }

  Future<void> fetchClassDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.get(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas/${widget.classId}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      setState(() {
        classData = decoded['data'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      PopupHelper.showErrorDialog(context, 'Gagal mengambil data kelas');
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

    if (response.statusCode == 200) {
      if (!mounted) return;
      PopupHelper.showSuccessDialog(context, 'Kelas berhasil dihapus', onOk: () {
        Navigator.pop(context, {'deleted': true});
      });
    } else {
      if (!mounted) return;
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
                                if (result == true) fetchClassDetail();
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
