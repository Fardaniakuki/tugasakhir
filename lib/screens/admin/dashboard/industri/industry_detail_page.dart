import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'edit_industry_page.dart';
import '../../popup_helper.dart';

class IndustryDetailPage extends StatefulWidget {
  final String industryId;

  const IndustryDetailPage({super.key, required this.industryId});

  @override
  State<IndustryDetailPage> createState() => _IndustryDetailPageState();
}

class _IndustryDetailPageState extends State<IndustryDetailPage> {
  Map<String, dynamic>? industryData;
  String? jurusanName;
  bool isLoading = true;

  final Color brown = const Color(0xFF5B1A1A);
  final Color danger = const Color(0xFF8B0000);

  @override
  void initState() {
    super.initState();
    fetchIndustryDetail();
  }

  Future<void> fetchIndustryDetail() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    print('=== START FETCH INDUSTRY DETAIL ===');
    print('Industry ID: ${widget.industryId}');
    print('Token: ${token != null ? "Ada" : "Tidak ada"}');

    try {
      final industryUrl = '${dotenv.env['API_BASE_URL']}/api/industri/${widget.industryId}';
      print('Industry URL: $industryUrl');

      final industryResponse = await http.get(
        Uri.parse(industryUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Industry Response Status: ${industryResponse.statusCode}');
      print('Industry Response Body: ${industryResponse.body}');

      if (industryResponse.statusCode == 200) {
        final decoded = json.decode(industryResponse.body);
        print('Industry Decoded: $decoded');
        
        setState(() {
          industryData = decoded['data'];
        });

        // Debug jurusan_id dari data industri
        final jurusanId = industryData!['jurusan_id'];
        print('Jurusan ID from industry: $jurusanId');
        print('Type of jurusan_id: ${jurusanId?.runtimeType}');

        if (jurusanId != null) {
          await fetchJurusanName(jurusanId);
        } else {
          setState(() {
            jurusanName = 'Tidak ada jurusan';
          });
          print('Jurusan ID is NULL');
        }
      } else {
        print('Industry fetch FAILED with status: ${industryResponse.statusCode}');
      }
      
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      print('Error fetching industry detail: $e');
    }
    print('=== END FETCH INDUSTRY DETAIL ===');
  }

  Future<void> fetchJurusanName(int jurusanId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    print('=== START FETCH JURUSAN ===');
    print('Jurusan ID to fetch: $jurusanId');

    try {
      final jurusanUrl = '${dotenv.env['API_BASE_URL']}/api/jurusan/$jurusanId';
      print('Jurusan URL: $jurusanUrl');

      final response = await http.get(
        Uri.parse(jurusanUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Jurusan Response Status: ${response.statusCode}');
      print('Jurusan Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('Jurusan Decoded: $decoded');
        
        // Coba berbagai kemungkinan struktur response
        if (decoded['nama'] != null) {
          print('Found jurusan name in decoded["nama"]: ${decoded["nama"]}');
          setState(() {
            jurusanName = decoded['nama'];
          });
        } 
        else if (decoded['data'] != null && decoded['data']['nama'] != null) {
          print('Found jurusan name in decoded["data"]["nama"]: ${decoded["data"]["nama"]}');
          setState(() {
            jurusanName = decoded['data']['nama'];
          });
        }
        else if (decoded is Map<String, dynamic> && decoded.containsKey('nama')) {
          print('Found jurusan name in root: ${decoded["nama"]}');
          setState(() {
            jurusanName = decoded['nama'];
          });
        }
        else {
          print('Jurusan name NOT FOUND in response. Available keys: ${decoded.keys}');
          setState(() {
            jurusanName = 'Struktur data tidak dikenali';
          });
        }
      } else {
        print('Jurusan fetch FAILED with status: ${response.statusCode}');
        setState(() {
          jurusanName = 'Jurusan tidak ditemukan (${response.statusCode})';
        });
      }
    } catch (e) {
      print('Error fetching jurusan: $e');
      setState(() {
        jurusanName = 'Error: $e';
      });
    }
    print('Final jurusanName: $jurusanName');
    print('=== END FETCH JURUSAN ===');
  }

  Future<void> deleteIndustry() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final response = await http.delete(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/industri/${widget.industryId}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      PopupHelper.showSuccessDialog(context, 'Industri berhasil dihapus.', onOk: () {
        Navigator.pop(context, {'deleted': true});
      });
    } else {
      PopupHelper.showErrorDialog(context, 'Gagal menghapus industri: ${response.statusCode}');
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Industri'),
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
              deleteIndustry();
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
        title: const Text('Profil Industri'),
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
          : industryData == null
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
                              child: const Icon(Icons.factory, size: 50, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              industryData!['nama'] ?? '-',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text('Industri', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildProfileItem(Icons.business, 'Nama', industryData!['nama']),
                      _buildProfileItem(Icons.location_on, 'Alamat', industryData!['alamat']),
                      _buildProfileItem(Icons.phone, 'No. Telp', industryData!['no_telp']),
                      _buildProfileItem(Icons.email, 'Email', industryData!['email']),
                      _buildProfileItem(Icons.work, 'Bidang', industryData!['bidang']),
                      _buildProfileItem(Icons.school, 'Jurusan', jurusanName ?? 'Loading...'),
                      _buildProfileItem(Icons.person, 'PIC', industryData!['pic']),
                      _buildProfileItem(Icons.phone_android, 'No. Telp PIC', industryData!['pic_telp']),
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
                                    builder: (_) => EditIndustryPage(industryData: industryData!),
                                  ),
                                );
                                if (result == true) fetchIndustryDetail();
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