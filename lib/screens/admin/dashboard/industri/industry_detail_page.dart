import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'edit_industry_page.dart';

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

  final Color _primaryColor = const Color(0xFF3B060A);
  final Color _accentColor = const Color(0xFF5B1A1A);
  final Color _dangerColor = const Color(0xFF8B0000);

  @override
  void initState() {
    super.initState();
    fetchIndustryDetail();
  }

  Future<void> fetchIndustryDetail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      print('=== START FETCH INDUSTRY DETAIL ===');
      print('Industry ID: ${widget.industryId}');

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

      if (industryResponse.statusCode == 200) {
        final decoded = json.decode(industryResponse.body);
        print('Industry Decoded: $decoded');
        
        setState(() {
          industryData = decoded['data'];
        });

        final jurusanId = industryData!['jurusan_id'];
        print('Jurusan ID from industry: $jurusanId');

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
        setState(() => isLoading = false);
        _showErrorDialog('Gagal mengambil data industri');
      }
      
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      print('Error fetching industry detail: $e');
      _showErrorDialog('Terjadi kesalahan saat mengambil data');
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

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('Jurusan Decoded: $decoded');
        
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
          jurusanName = 'Jurusan tidak ditemukan';
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final role = prefs.getString('user_role');

      if (role?.toLowerCase() != 'admin') {
        _showErrorDialog('Kamu tidak memiliki izin untuk menghapus data');
        return;
      }

      final int? industryId = industryData?['id'];
      if (industryId == null) {
        _showErrorDialog('ID industri tidak ditemukan');
        return;
      }

      final response = await http.delete(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/industri/$industryId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        if (!mounted) return;
        _showSuccessDialog(
          'Data industri berhasil dihapus',
          onOk: () {
            Navigator.pop(context, {'deleted': true});
          },
        );
      } else {
        if (!mounted) return;
        _showErrorDialog('Gagal menghapus data: ${response.statusCode}');
      }
    } catch (_) {
      if (!mounted) return;
      _showErrorDialog('Terjadi kesalahan jaringan');
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha:0.5),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _primaryColor,
                      _accentColor,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.warning_amber_rounded, 
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Konfirmasi Hapus',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            industryData?['nama'] ?? 'Industri',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha:0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.delete_outline_rounded,
                      size: 60,
                      color: Color(0xFF8B0000),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Yakin ingin menghapus data ini?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tindakan ini tidak dapat dibatalkan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: BorderSide(color: _primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          deleteIndustry();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _dangerColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: _dangerColor.withValues(alpha:0.3),
                        ),
                        child: const Text('Hapus'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String message, {VoidCallback? onOk}) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha:0.5),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2E7D32),
                      Color(0xFF4CAF50),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.check_circle_rounded, 
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Berhasil!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 60,
                      color: Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onOk?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: const Color(0xFF4CAF50).withValues(alpha:0.3),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha:0.5),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFC62828),
                      Color(0xFFEF5350),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.error_outline_rounded, 
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Terjadi Kesalahan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: Color(0xFFEF5350),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Silakan coba lagi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF5350),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: const Color(0xFFEF5350).withValues(alpha:0.3),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // APPBAR CUSTOM
            Container(
              height: 60,
              color: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Profil Industri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            
            // SATU CONTAINER PUTIH UTUH
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  border: Border.all(
                    color: const Color(0xFFBEBEBE),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha:0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF3B060A),
                        ),
                      )
                    : industryData == null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.factory_rounded,
                                  size: 80,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Data tidak ditemukan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: fetchIndustryDetail,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Coba Lagi'),
                                ),
                              ],
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: IntrinsicHeight(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // ICON PROFILE UKURAN 110 (TETAP)
                                          Container(
                                            margin: const EdgeInsets.only(top: 30, bottom: 30),
                                            child: Container(
                                              width: 110,
                                              height: 110,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Colors.white,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha:0.1),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      _primaryColor,
                                                      _accentColor,
                                                    ],
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.factory_rounded,
                                                  size: 60,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          
                                          // DATA INDUSTRI
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10),
                                            child: Column(
                                              children: [
                                                _buildProfileItem(
                                                  icon: Icons.business_rounded,
                                                  title: 'Nama Industri',
                                                  value: industryData!['nama'] ?? '-',
                                                ),
                                                const SizedBox(height: 16),
                                                
                                                _buildProfileItem(
                                                  icon: Icons.location_on_rounded,
                                                  title: 'Alamat',
                                                  value: industryData!['alamat'] ?? '-',
                                                ),
                                                const SizedBox(height: 16),
                                                
                                                _buildProfileItem(
                                                  icon: Icons.phone_rounded,
                                                  title: 'No. Telp',
                                                  value: industryData!['no_telp'] ?? '-',
                                                ),
                                                const SizedBox(height: 16),
                                                
                                                _buildProfileItem(
                                                  icon: Icons.email_rounded,
                                                  title: 'Email',
                                                  value: industryData!['email'] ?? '-',
                                                ),
                                                const SizedBox(height: 16),
                                                
                                                _buildProfileItem(
                                                  icon: Icons.work_rounded,
                                                  title: 'Bidang',
                                                  value: industryData!['bidang'] ?? '-',
                                                ),
                                                const SizedBox(height: 16),
                                                
                                                _buildProfileItem(
                                                  icon: Icons.school_rounded,
                                                  title: 'Jurusan',
                                                  value: jurusanName ?? 'Loading...',
                                                ),
                                                const SizedBox(height: 16),
                                                
                                                _buildProfileItem(
                                                  icon: Icons.person_rounded,
                                                  title: 'PIC',
                                                  value: industryData!['pic'] ?? '-',
                                                ),
                                                const SizedBox(height: 16),
                                                
                                                _buildProfileItem(
                                                  icon: Icons.phone_android_rounded,
                                                  title: 'No. Telp PIC',
                                                  value: industryData!['pic_telp'] ?? '-',
                                                ),
                                                const SizedBox(height: 50),
                                              ],
                                            ),
                                          ),
                                          
                                          // TOMBOL DI BAWAH
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 30, left: 10, right: 10),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: _dangerColor.withValues(alpha:0.2),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: () => _confirmDelete(context),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: _dangerColor,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      ),
                                                      child: const Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.delete_rounded, size: 18),
                                                          SizedBox(width: 6),
                                                          Text(
                                                            'Hapus',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(12),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: _primaryColor.withValues(alpha:0.2),
                                                          blurRadius: 4,
                                                          offset: const Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: () async {
                                                        final result = await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (_) => EditIndustryPage(
                                                                industryData: industryData!),
                                                          ),
                                                        );
                                                        if (result == true) fetchIndustryDetail();
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: _primaryColor,
                                                        foregroundColor: Colors.white,
                                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                      ),
                                                      child: const Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.edit_rounded, size: 18),
                                                          SizedBox(width: 6),
                                                          Text(
                                                            'Edit',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w600,
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
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk item profil yang konsisten dengan StudentDetailPage
  Widget _buildProfileItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
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
              color: _primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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
}