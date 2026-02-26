import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:image_picker/image_picker.dart';
import 'dashboard_service.dart';
import 'stat_grid.dart';
import '../crud/add_person_page.dart';
import 'tahun_ajaran_page.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  final Function(String)? onNavigateToData;

  const AdminDashboard({super.key, this.onNavigateToData});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final DashboardService _service = DashboardService();

  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _sekolahData;
  bool _isLoading = true;
  bool _isAppPaused = false;
  bool _isLoadingSekolah = false;
  File? _selectedLogoFile;

  // WARNA UTAMA
  final Color _primaryColor = const Color(0xFF3B060A);

  // Gradasi untuk tombol dan aksen
  static const LinearGradient _primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF3B060A), // Maroon gelap
      Color(0xFF5B1A1A), // Maroon sedang
    ],
  );

  // Warna untuk setiap jenis data
  final Map<String, Color> _typeColors = {
    'Murid': const Color(0xFF3B060A),
    'Guru': const Color(0xFF5B1A1A),
    'Program Keahlian': const Color(0xFF8B2A2D),
    'Industri': const Color(0xFFCD5C5C),
    'Kelas': const Color(0xFFF08080),
    'Tahun Ajaran': const Color(0xFF9C27B0),
  };

  // Icon untuk setiap jenis data
  final Map<String, IconData> _typeIcons = {
    'Murid': Icons.person,
    'Guru': Icons.school,
    'Program Keahlian': Icons.category,
    'Industri': Icons.business,
    'Kelas': Icons.class_,
    'Tahun Ajaran': Icons.calendar_today,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboard();
    _loadSekolahData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _isAppPaused = true;
    } else if (state == AppLifecycleState.resumed && _isAppPaused) {
      _isAppPaused = false;
      _refreshSilently();
    }
  }

  Future<void> _loadDashboard() async {
    if (_dashboardData != null) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final cachedData = _service.getCachedData('dashboard');
      if (cachedData != null && mounted) {
        setState(() {
          _dashboardData = cachedData;
          _isLoading = false;
        });
        _fetchDashboardData(silent: true);
        return;
      }

      await _fetchDashboardData();
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchDashboardData({bool silent = false}) async {
    try {
      final data = await _service.fetchDashboardData();
      if (mounted) {
        setState(() {
          _dashboardData = data;
          if (!silent) {
            _isLoading = false;
          }
        });
      }

      _service.setCacheData('dashboard', data);
    } catch (e) {
      debugPrint('Error fetching dashboard: $e');
      if (mounted && !silent) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSekolahData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoadingSekolah = true;
        });
      }

      print('📥 LOADING DATA SEKOLAH...'); // PRINT

      final response = await ApiService.get('/sekolah');

      print('📥 RESPONSE STATUS: ${response.statusCode}'); // PRINT
      print('📥 RESPONSE BODY: ${response.body}'); // PRINT

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ DATA SEKOLAH: $data'); // PRINT

        if (mounted) {
          setState(() {
            _sekolahData = data['data'];
            _isLoadingSekolah = false;
          });
          print('✅ STATE DATA SEKOLAH DIPERBARUI'); // PRINT
        }
      } else {
        print('❌ GAGAL LOAD DATA SEKOLAH: ${response.statusCode}'); // PRINT
        if (mounted) {
          setState(() {
            _isLoadingSekolah = false;
          });
        }
      }
    } catch (e) {
      print('❌ ERROR LOADING SEKOLAH DATA: $e'); // PRINT
      print('❌ STACK TRACE: ${StackTrace.current}'); // PRINT
      if (mounted) {
        setState(() {
          _isLoadingSekolah = false;
        });
      }
    }
  }

  Future<void> _updateSekolahData(Map<String, dynamic> updatedData) async {
    if (_sekolahData == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      print('📝 TOKEN: $token');
      print('📝 DATA YANG AKAN DIKIRIM: $updatedData');

      if (token == null) {
        print('❌ TOKEN TIDAK DITEMUKAN');
        if (!mounted) return;
        _showErrorSnackbar('Token tidak ditemukan. Silakan login kembali.');
        return;
      }

      final sekolahId = _sekolahData!['id'];
      print('📝 SEKOLAH ID: $sekolahId');

      // Hapus field yang tidak perlu dikirim
      final Map<String, dynamic> dataToSend = Map.from(updatedData);
      dataToSend.remove('id');
      dataToSend.remove('created_at');
      dataToSend.remove('updated_at');

      // Pastikan logo adalah string (URL)
      if (dataToSend['logo'] != null && dataToSend['logo'] is! String) {
        dataToSend['logo'] = dataToSend['logo'].toString();
      }

      print('📝 DATA AFTER CLEANUP: $dataToSend');

      print('📝 MENGIRIM REQUEST KE: /sekolah/$sekolahId');

      final response = await ApiService.put(
        '/sekolah/$sekolahId',
        dataToSend,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📝 RESPONSE STATUS CODE: ${response.statusCode}');
      print('📝 RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ UPDATE SUKSES!');

        try {
          final responseData = jsonDecode(response.body);
          print('✅ RESPONSE JSON: $responseData');

          if (mounted) {
            setState(() {
              _sekolahData = responseData['data'] ?? responseData;
              _selectedLogoFile = null;
            });
            print('✅ STATE DIPERBARUI');
          }

          if (mounted) {
            _showSuccessDialog(
                responseData['message'] ?? 'Data sekolah berhasil diperbarui');
          }
        } catch (e) {
          print('⚠️ RESPONSE BUKAN JSON TAPI STATUS SUKSES');
          print('⚠️ ERROR PARSING JSON: $e');

          if (mounted) {
            _showSuccessDialog('Data sekolah berhasil diperbarui');
            _loadSekolahData();
          }
        }
      } else {
        print('❌ GAGAL UPDATE! STATUS CODE: ${response.statusCode}');
        print('❌ RESPONSE BODY: ${response.body}');

        String errorMessage = 'Gagal memperbarui data sekolah';

        try {
          final errorData = jsonDecode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (e) {
          errorMessage =
              'Gagal memperbarui data sekolah (Kode: ${response.statusCode})';
        }

        if (!mounted) return;
        _showErrorSnackbar(errorMessage);
      }
    } catch (e) {
      print('❌ EXCEPTION: $e');
      if (!mounted) return;
      _showErrorSnackbar('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<void> _pickLogo() async {
    print('📸 MEMILIH LOGO...');

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        print('✅ GAMBAR DIPILIH: ${image.path}');

        setState(() {
          _selectedLogoFile = File(image.path);
        });

        print('✅ STATE DIPERBARUI DENGAN LOGO BARU');

        // Tampilkan dialog untuk memasukkan URL logo
        _showLogoUrlDialog();
      } else {
        print('⚠️ TIDAK ADA GAMBAR DIPILIH');
      }
    } catch (e) {
      print('❌ ERROR PICKING IMAGE: $e');
      if (!mounted) return;
      _showErrorSnackbar('Gagal memilih gambar: ${e.toString()}');
    }
  }

// Dialog untuk memasukkan URL logo
  void _showLogoUrlDialog() {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('URL Logo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Masukkan URL logo (dari hosting atau penyimpanan cloud)'),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  hintText: 'https://example.com/logo.png',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (urlController.text.isNotEmpty) {
                  // Update editedData dengan URL logo
                  // Anda perlu mengkomunikasikan ini ke dialog edit
                  // Misalnya dengan callback atau mengupdate state

                  print('✅ URL LOGO: ${urlController.text}');

                  // Tutup dialog
                  Navigator.pop(context);

                  // Tampilkan pesan sukses
                  _showSuccessDialog('URL logo berhasil ditambahkan');
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

// Method untuk upload logo ke server dan mendapatkan URL

// Method untuk upload logo ke server dan mendapatkan URL

  Future<void> _showSuccessDialog(String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  const Color(0xFF3B060A).withValues(alpha: 0.03),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF34A853),
                        Color(0xFF2E8B57),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF34A853).withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Berhasil!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: _primaryColor.withValues(alpha: 0.3),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Diperbarui: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red[700],
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _refreshSilently() async {
    try {
      final data = await _service.fetchDashboardData(forceRefresh: true);
      if (mounted && data != null) {
        setState(() {
          _dashboardData = data;
        });
      }
      await _loadSekolahData();
    } catch (e) {
      debugPrint('Error silent refresh: $e');
    }
  }

  Future<void> _refreshData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    await _fetchDashboardData();
    await _loadSekolahData();
  }

  void _handleStatBoxTap(String type) {
    widget.onNavigateToData?.call(type);
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text(
                  'Tambah Data Baru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B060A),
                  ),
                ),
              ),
              _buildAddTile(
                Icons.calendar_today,
                'Tambah Tahun Ajaran',
                'TahunAjaran',
                const Color(0xFF3B060A),
              ),
              _buildAddTile(
                Icons.school,
                'Tambah Murid',
                'Siswa',
                const Color(0xFF3B060A),
              ),
              _buildAddTile(
                Icons.person,
                'Tambah Guru',
                'Guru',
                const Color(0xFF3B060A),
              ),
              _buildAddTile(
                Icons.category,
                'Tambah Program Keahlian',
                'Program Keahlian',
                const Color(0xFF3B060A),
              ),
              _buildAddTile(
                Icons.business,
                'Tambah Industri',
                'Industri',
                const Color(0xFF3B060A),
              ),
              _buildAddTile(
                Icons.class_,
                'Tambah Kelas',
                'Kelas',
                const Color(0xFF3B060A),
              ),
              const Divider(height: 20),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B060A).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_add, color: Color(0xFF3B060A)),
                ),
                title: const Text(
                  'Tambah Siswa via Excel',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Import data dari file Excel'),
                trailing: const Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.pop(context);
                  _showExcelImportOption();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showExcelImportOption() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text(
                  'Tambah Siswa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3B060A),
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B060A).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.person_add, color: Color(0xFF3B060A)),
                ),
                title: const Text(
                  'Tambah Manual',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Tambah data siswa satu per satu'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddPersonPage('Siswa');
                },
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B060A).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      const Icon(Icons.upload_file, color: Color(0xFF3B060A)),
                ),
                title: const Text(
                  'Import Excel',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text('Upload file Excel untuk import data'),
                onTap: () {
                  Navigator.pop(context);
                  _showExcelImportDialog();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  ListTile _buildAddTile(
      IconData icon, String title, String type, Color color) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        Navigator.pop(context);
        _navigateToAddPersonPage(type);
      },
    );
  }

  void _showExcelImportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Excel'),
        content: const Text('Fitur import Excel akan segera tersedia.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddPersonPage(String jenisData) {
    if (jenisData == 'TahunAjaran') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TahunAjaranPage(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddPersonPage(jenisData: jenisData),
        ),
      );
    }
  }

  // Widget untuk menampilkan dan mengedit data sekolah
  Widget _buildSekolahInfo() {
    if (_isLoadingSekolah) {
      return _buildSekolahSkeleton();
    }

    if (_sekolahData == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _primaryColor.withValues(alpha: 0.1),
                    _primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.school_outlined,
                size: 30,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Data sekolah tidak tersedia',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: _primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Profil Sekolah',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_rounded, color: _primaryColor),
                onPressed: _showEditSekolahDialog,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Logo sekolah
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _sekolahData!['logo_url'] != null &&
                            _sekolahData!['logo_url'].isNotEmpty
                        ? Image.network(
                            _sekolahData!['logo_url'],
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.school,
                                  size: 40,
                                  color: _primaryColor.withValues(alpha: 0.5),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.school,
                              size: 40,
                              color: _primaryColor.withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Info sekolah
          _buildInfoRow('NPSN', _sekolahData!['npsn'] ?? '-'),
          _buildInfoRow('Nama Sekolah', _sekolahData!['nama_sekolah'] ?? '-'),
          _buildInfoRow('Jenis Sekolah', _sekolahData!['jenis_sekolah'] ?? '-'),
          _buildInfoRow('Akreditasi', _sekolahData!['akreditasi'] ?? '-'),

          const SizedBox(height: 8),
          const Divider(height: 20),

          // Alamat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_rounded, size: 20, color: _primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alamat',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sekolahData!['jalan'] ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${_sekolahData!['kelurahan'] ?? ''}, ${_sekolahData!['kecamatan'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '${_sekolahData!['kabupaten_kota'] ?? ''}, ${_sekolahData!['provinsi'] ?? ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'Kode Pos: ${_sekolahData!['kode_pos'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Kontak
          _buildContactRow(
              Icons.phone_rounded, _sekolahData!['nomor_telepon'] ?? '-'),
          _buildContactRow(Icons.email_rounded, _sekolahData!['email'] ?? '-'),
          _buildContactRow(
              Icons.language_rounded, _sekolahData!['website'] ?? '-'),

          const SizedBox(height: 12),
          const Divider(height: 20),

          // Kepala Sekolah
          Row(
            children: [
              Icon(Icons.person_rounded, size: 20, color: _primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kepala Sekolah',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sekolahData!['kepala_sekolah'] ?? '-',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      'NIP: ${_sekolahData!['nip_kepala_sekolah'] ?? '-'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSekolahSkeleton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: _primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 12),
              _buildSkeletonLine(width: 120, height: 20),
              const Spacer(),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.grey[300]!,
                      Colors.grey[200]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey[300]!,
                    Colors.grey[200]!,
                  ],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          for (int i = 0; i < 4; i++) ...[
            _buildSkeletonLine(width: double.infinity, height: 16),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          const Divider(height: 20),
          for (int i = 0; i < 2; i++) ...[
            _buildSkeletonLine(width: double.infinity, height: 16),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditSekolahDialog() {
    if (_sekolahData == null) return;

    final formKey = GlobalKey<FormState>();
    final Map<String, dynamic> editedData = Map.from(_sekolahData!);
    _selectedLogoFile = null;

    final List<Map<String, dynamic>> fieldGroups = [
      {
        'title': 'Informasi Umum',
        'fields': [
          // Tambahkan di fieldGroups bagian Informasi Umum
          {
            'key': 'logo',
            'label': 'URL Logo',
            'icon': Icons.image,
            'required': false,
          },
          {
            'key': 'npsn',
            'label': 'NPSN',
            'icon': Icons.numbers,
            'required': true,
          },
          {
            'key': 'nama_sekolah',
            'label': 'Nama Sekolah',
            'icon': Icons.school,
            'required': true,
          },
          {
            'key': 'jenis_sekolah',
            'label': 'Jenis Sekolah',
            'icon': Icons.category,
            'required': false,
          },
          {
            'key': 'akreditasi',
            'label': 'Akreditasi',
            'icon': Icons.grade,
            'required': false,
          },
        ]
      },
      {
        'title': 'Alamat',
        'fields': [
          {
            'key': 'jalan',
            'label': 'Jalan',
            'icon': Icons.location_on,
            'required': false,
          },
          {
            'key': 'kelurahan',
            'label': 'Kelurahan',
            'icon': Icons.location_city,
            'required': false,
          },
          {
            'key': 'kecamatan',
            'label': 'Kecamatan',
            'icon': Icons.map,
            'required': false,
          },
          {
            'key': 'kabupaten_kota',
            'label': 'Kabupaten/Kota',
            'icon': Icons.location_city,
            'required': false,
          },
          {
            'key': 'provinsi',
            'label': 'Provinsi',
            'icon': Icons.public,
            'required': false,
          },
          {
            'key': 'kode_pos',
            'label': 'Kode Pos',
            'icon': Icons.numbers,
            'required': false,
          },
        ]
      },
      {
        'title': 'Kontak & Kepala Sekolah',
        'fields': [
          {
            'key': 'nomor_telepon',
            'label': 'Nomor Telepon',
            'icon': Icons.phone,
            'required': false,
          },
          {
            'key': 'email',
            'label': 'Email',
            'icon': Icons.email,
            'required': false,
          },
          {
            'key': 'website',
            'label': 'Website',
            'icon': Icons.language,
            'required': false,
          },
          {
            'key': 'kepala_sekolah',
            'label': 'Kepala Sekolah',
            'icon': Icons.person,
            'required': false,
          },
          {
            'key': 'nip_kepala_sekolah',
            'label': 'NIP Kepala Sekolah',
            'icon': Icons.badge,
            'required': false,
          },
        ]
      },
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.9,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                color: Colors.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.edit, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Edit Profil Sekolah',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              _selectedLogoFile = null;
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Logo Upload Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[50],
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _primaryColor.withAlpha(50),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _selectedLogoFile != null
                                      ? Image.file(
                                          _selectedLogoFile!,
                                          fit: BoxFit.cover,
                                          width: 120,
                                          height: 120,
                                        )
                                      : (_sekolahData!['logo_url'] != null &&
                                              _sekolahData!['logo_url']
                                                  .isNotEmpty)
                                          ? Image.network(
                                              _sekolahData!['logo_url'],
                                              fit: BoxFit.cover,
                                              width: 120,
                                              height: 120,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Container(
                                                  color: Colors.grey[200],
                                                  child: Icon(
                                                    Icons.school,
                                                    size: 50,
                                                    color: _primaryColor
                                                        .withAlpha(100),
                                                  ),
                                                );
                                              },
                                            )
                                          : Container(
                                              color: Colors.grey[200],
                                              child: Icon(
                                                Icons.school,
                                                size: 50,
                                                color: _primaryColor
                                                    .withAlpha(100),
                                              ),
                                            ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: InkWell(
                                    onTap: () async {
                                      await _pickLogo();
                                      setState(() {});
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                         
                          if (_selectedLogoFile != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.green[200]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle,
                                        size: 14, color: Colors.green[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Logo baru dipilih',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.green[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Form Fields
                    Expanded(
                      child: Container(
                        color: Colors.white,
                        child: Form(
                          key: formKey,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (var group in fieldGroups) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 12, top: 8),
                                    child: Text(
                                      group['title'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  for (var field in group['fields']) ...[
                                    _buildEditTextField(
                                      label: field['label'],
                                      initialValue: _sekolahData![field['key']]
                                              ?.toString() ??
                                          '',
                                      icon: field['icon'],
                                      isRequired: field['required'],
                                      onChanged: (value) =>
                                          editedData[field['key']] = value,
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Footer Buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                _selectedLogoFile = null;
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                side: BorderSide(color: Colors.grey[400]!),
                              ),
                              child: Text(
                                'Batal',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (formKey.currentState!.validate()) {
                                  Navigator.pop(context);

                                  // Tampilkan loading
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );

                                  await _updateSekolahData(editedData);

                                  if (mounted) {
                                    Navigator.pop(context); // Tutup loading
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                              child: const Text('Simpan'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEditTextField({
    required String label,
    required String initialValue,
    required IconData icon,
    required bool isRequired,
    required Function(String) onChanged,
  }) {
    final controller = TextEditingController(text: initialValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Masukkan $label',
            prefixIcon: Icon(icon, size: 18, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            filled: true,
            fillColor: Colors.white,
          ),
          style: const TextStyle(fontSize: 14),
          onChanged: onChanged,
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return '$label wajib diisi';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSkeletonLine({
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[300]!,
            Colors.grey[200]!,
          ],
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  // CHART SEDERHANA - Distribusi Data
  Widget _buildSimpleDistributionChart() {
    if (_dashboardData == null) return const SizedBox();

    final siswaCount = _dashboardData!['total_siswa'] ?? 0;
    final guruCount = _dashboardData!['total_guru'] ?? 0;
    final kelasCount = _dashboardData!['total_kelas'] ?? 0;
    final jurusanCount = _dashboardData!['total_jurusan'] ?? 0;
    final industriCount = _dashboardData!['total_industri'] ?? 0;

    final maxValue = [
      siswaCount,
      guruCount,
      kelasCount,
      jurusanCount,
      industriCount
    ].reduce((a, b) => a > b ? a : b).toDouble();

    final List<ChartData> chartData = [
      ChartData(
        'Murid',
        siswaCount.toDouble(),
        _typeIcons['Murid']!,
        _typeColors['Murid']!,
      ),
      ChartData(
        'Guru',
        guruCount.toDouble(),
        _typeIcons['Guru']!,
        _typeColors['Guru']!,
      ),
      ChartData(
        'Kelas',
        kelasCount.toDouble(),
        _typeIcons['Kelas']!,
        _typeColors['Kelas']!,
      ),
      ChartData(
        'Program Keahlian',
        jurusanCount.toDouble(),
        _typeIcons['Program Keahlian']!,
        _typeColors['Program Keahlian']!,
      ),
      ChartData(
        'Industri',
        industriCount.toDouble(),
        _typeIcons['Industri']!,
        _typeColors['Industri']!,
      ),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: _primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Distribusi Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children:
                  chartData.map((data) => _buildChartLegend(data)).toList(),
            ),
          ),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue * 1.2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: _primaryColor,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final data = chartData[groupIndex];
                      return BarTooltipItem(
                        '${data.label}\n${rod.toY.toInt()}',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < chartData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              chartData[value.toInt()].label,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: chartData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.value,
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            data.color,
                            data.color.withValues(alpha: 0.7),
                          ],
                        ),
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(ChartData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: data.color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [data.color, data.color.withValues(alpha: 0.8)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 12, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 12,
              color: data.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // STATISTIK RINGKAS
  Widget _buildQuickStats() {
    if (_dashboardData == null) return const SizedBox();

    final siswaCount = _dashboardData!['total_siswa'] ?? 0;
    final guruCount = _dashboardData!['total_guru'] ?? 0;
    final kelasCount = _dashboardData!['total_kelas'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: _primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.trending_up_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Statistik Ringkas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _buildStatItem(
                'Rata Murid/Kelas',
                _calculateAverageStudentsPerClass(),
                Icons.people_rounded,
                _typeColors['Murid']!,
              )),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildStatItem(
                'Rasio Guru:Murid',
                _calculateTeacherStudentRatio(),
                Icons.balance_rounded,
                _typeColors['Guru']!,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryColor.withValues(alpha: 0.1),
                  _primaryColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _primaryColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('Murid', siswaCount, Icons.school_rounded,
                    _typeColors['Murid']!),
                _buildMiniStat('Guru', guruCount, Icons.person_rounded,
                    _typeColors['Guru']!),
                _buildMiniStat('Kelas', kelasCount, Icons.class_rounded,
                    _typeColors['Kelas']!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, color.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, int value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, color.withValues(alpha: 0.8)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            color: color.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _calculateAverageStudentsPerClass() {
    if (_dashboardData == null) return '-';
    final siswaCount = _dashboardData!['total_siswa'] ?? 0;
    final kelasCount = _dashboardData!['total_kelas'] ?? 0;

    if (kelasCount == 0) return '0';
    final average = (siswaCount / kelasCount).round();
    return average.toString();
  }

  String _calculateTeacherStudentRatio() {
    if (_dashboardData == null) return '-';
    final siswaCount = _dashboardData!['total_siswa'] ?? 0;
    final guruCount = _dashboardData!['total_guru'] ?? 0;

    if (guruCount == 0) return '-';
    final ratio = (siswaCount / guruCount).round();
    return '1:$ratio';
  }

  Widget _buildLoading() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 24),
        _buildSkeletonContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSkeletonLine(width: 150, height: 20),
                      const SizedBox(height: 8),
                      _buildSkeletonLine(width: 200, height: 14),
                    ],
                  ),
                  _buildSkeletonLine(width: 120, height: 40, borderRadius: 20),
                ],
              ),
              const SizedBox(height: 20),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: List.generate(6, (index) => _buildGridItemSkeleton()),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSekolahSkeleton(),
        const SizedBox(height: 16),
        _buildSkeletonContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: _primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildSkeletonLine(width: 120, height: 20),
                ],
              ),
              const SizedBox(height: 20),
              _buildSkeletonLine(
                  width: double.infinity, height: 200, borderRadius: 8),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildSkeletonContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: _primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildSkeletonLine(width: 120, height: 20),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildStatItemSkeleton()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatItemSkeleton()),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _primaryColor.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children:
                      List.generate(3, (index) => _buildMiniStatSkeleton()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSkeletonContainer({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildGridItemSkeleton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: _primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 12),
          _buildSkeletonLine(width: 80, height: 16),
          const SizedBox(height: 8),
          _buildSkeletonLine(width: 60, height: 20),
          const SizedBox(height: 4),
          _buildSkeletonLine(width: 100, height: 12),
        ],
      ),
    );
  }

  Widget _buildStatItemSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: _primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          _buildSkeletonLine(width: 60, height: 20),
          const SizedBox(height: 4),
          _buildSkeletonLine(width: 80, height: 14),
        ],
      ),
    );
  }

  Widget _buildMiniStatSkeleton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            gradient: _primaryGradient,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        _buildSkeletonLine(width: 30, height: 16),
        const SizedBox(height: 2),
        _buildSkeletonLine(width: 40, height: 12),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _primaryColor.withValues(alpha: 0.1),
                  _primaryColor.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gagal memuat dashboard',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan coba lagi beberapa saat',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _refreshData,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _primaryColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: _primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverAppBar(
                backgroundColor: _primaryColor,
                expandedHeight: 63,
                floating: false,
                pinned: true,
                flexibleSpace: const FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: EdgeInsets.only(left: 16, bottom: 16),
                  expandedTitleScale: 1.0,
                  title: Text(
                    'Beranda',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.white.withValues(alpha: 0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                      onPressed: _refreshData,
                    ),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: _isLoading && _dashboardData == null
                      ? _buildLoading()
                      : Padding(
                          padding: const EdgeInsets.only(
                            top: 24,
                            bottom: 20,
                            left: 16,
                            right: 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_dashboardData != null) ...[
                                StatGrid(
                                  data: _dashboardData!,
                                  onAddPressed: _showAddOptions,
                                  onBoxTap: _handleStatBoxTap,
                                  typeColors: const {},
                                ),
                                const SizedBox(height: 16),
                                _buildSekolahInfo(),
                                const SizedBox(height: 16),
                                _buildSimpleDistributionChart(),
                                _buildQuickStats(),
                                const SizedBox(height: 20),
                              ] else
                                _buildError(),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Class helper untuk data chart
class ChartData {
  final String label;
  final double value;
  final IconData icon;
  final Color color;

  ChartData(this.label, this.value, this.icon, this.color);
}
