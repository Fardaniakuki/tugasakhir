import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../login/login_screen.dart';

class KaprogProfilePage extends StatefulWidget {
  const KaprogProfilePage({super.key});

  @override
  State<KaprogProfilePage> createState() => _KaprogProfilePageState();
}

class _KaprogProfilePageState extends State<KaprogProfilePage> {
  static const Color _primaryColor = Color(0xFF6B1B1B);
  static const Color _accentColor = Color(0xFF9F0712);
  static const Color _lightColor = Color(0xFFF5F5F5);
  static const Color _textColor = Color(0xFF333333);
  static const Color _borderColor = Color(0xFFE0E0E0);

  // Data guru yang sedang login
  Map<String, dynamic> _guruData = {
    'nama': 'KAPROG',
    'kode_guru': '-',
    'nip': '-',
    'no_telp': '-',
  };

  bool _isLoading = true;
  bool _isEditing = false;

  // Controller untuk form edit
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _kodeGuruController = TextEditingController();
  final TextEditingController _nipController = TextEditingController();
  final TextEditingController _telpController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadGuruData();
  }

  Future<void> _loadGuruData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      print('📥 Loading guru data for Kaprog...');

      // Debug: print semua keys untuk melihat data apa yang tersimpan
      final allKeys = prefs.getKeys();
      print('🔑 SEMUA DATA DI SHAREDPREFERENCES:');
      for (final key in allKeys) {
        print('   $key: ${prefs.get(key)}');
      }

      // Ambil data dari berbagai kemungkinan key
      final String? userName = prefs.getString('user_name');
      final String? kodeGuru = prefs.getString('kode_guru');
      final String? userNip = prefs.getString('user_nip');
      final String? userPhone = prefs.getString('user_phone');
      final String? guruNama = prefs.getString('guru_nama');
      final String? guruKode = prefs.getString('guru_kode_guru');
      final String? guruNip = prefs.getString('guru_nip');
      final String? guruTelp = prefs.getString('guru_no_telp');

      // Prioritaskan data dari guru_* keys (lebih lengkap)
      final String nama = userName ?? guruNama ?? 'KAPROG';
      final String kode = kodeGuru ?? guruKode ?? '-';
      final String nip = userNip ?? guruNip ?? '-';
      final String telp = userPhone ?? guruTelp ?? '-';

      // Set controller untuk form edit
      _namaController.text = nama;
      _kodeGuruController.text = kode;
      _nipController.text = nip;
      _telpController.text = telp;

      setState(() {
        _guruData = {
          'nama': nama.toUpperCase(),
          'kode_guru': kode,
          'nip': nip,
          'no_telp': telp,
        };
        _isLoading = false;
      });

      print('\n✅ DATA GURU YANG DIPAKAI:');
      print('   Nama: ${_guruData['nama']}');
      print('   Kode: ${_guruData['kode_guru']}');
      print('   NIP: ${_guruData['nip']}');
      print('   Telp: ${_guruData['no_telp']}');
    } catch (e) {
      print('❌ Error loading guru data: $e');

      setState(() {
        _guruData = {
          'nama': 'KAPROG',
          'kode_guru': '-',
          'nip': '-',
          'no_telp': '-',
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _updateGuruData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await dotenv.load(fileName: '.env');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      print('🔍 DEBUG UPDATE GURU DATA:');
      print('   Token exists: ${token != null}');

      if (token == null) {
        _showErrorDialog('Token tidak ditemukan');
        return;
      }

      // Tampilkan loading
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              color: _primaryColor,
            ),
          ),
        );
      }

      // Data yang akan dikirim sesuai dengan dokumentasi API
      final Map<String, dynamic> requestData = {
        'kode_guru': _kodeGuruController.text.trim(),
        'nama': _namaController.text.trim(),
        'nip': _nipController.text.trim(),
        'no_telp': _telpController.text.trim(),
      };

      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final url = Uri.parse('$baseUrl/api/guru/me');

      print('🔄 Updating guru data...');
      print('   URL: $url');
      print('   Request data: $requestData');

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      // Tutup loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      print('📤 Response status: ${response.statusCode}');
      print('📤 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Update data lokal
          final updatedData = data['data'] as Map<String, dynamic>;

          setState(() {
            _guruData['nama'] =
                (updatedData['nama'] ?? _namaController.text.trim())
                    .toString()
                    .toUpperCase();
            _guruData['kode_guru'] =
                updatedData['kode_guru'] ?? _kodeGuruController.text.trim();
            _guruData['nip'] = updatedData['nip'] ?? _nipController.text.trim();
            _guruData['no_telp'] =
                updatedData['no_telp'] ?? _telpController.text.trim();
            _isEditing = false;
          });

          // Update SharedPreferences
          await prefs.setString('user_name', _guruData['nama']);
          await prefs.setString('kode_guru', _guruData['kode_guru']);
          await prefs.setString('user_nip', _guruData['nip']);
          await prefs.setString('user_phone', _guruData['no_telp']);
          await prefs.setString('guru_nama', _guruData['nama']);
          await prefs.setString('guru_kode_guru', _guruData['kode_guru']);
          await prefs.setString('guru_nip', _guruData['nip']);
          await prefs.setString('guru_no_telp', _guruData['no_telp']);

          _showSuccessDialog('Data berhasil diperbarui');
        } else {
          final errorMsg =
              data['message'] ?? data['error'] ?? 'Gagal memperbarui data';
          _showErrorDialog(errorMsg.toString());
        }
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMsg = errorData['message'] ??
              errorData['error'] ??
              'Terjadi kesalahan: ${response.statusCode}';
          _showErrorDialog(errorMsg.toString());
        } catch (e) {
          _showErrorDialog('Terjadi kesalahan: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
      }
      _showErrorDialog('Terjadi kesalahan: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text(
              'Sukses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
            ),
            child: const Text(
              'OK',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Edit Data Profil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textColor,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(height: 16),

          // Nama
          TextFormField(
            controller: _namaController,
            decoration: InputDecoration(
              labelText: 'Nama',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Kode Guru
          TextFormField(
            controller: _kodeGuruController,
            decoration: InputDecoration(
              labelText: 'Kode Guru',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kode guru tidak boleh kosong';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // NIP
          TextFormField(
            controller: _nipController,
            decoration: InputDecoration(
              labelText: 'NIP',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // No Telepon
          TextFormField(
            controller: _telpController,
            decoration: InputDecoration(
              labelText: 'No. Telepon',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _primaryColor, width: 2),
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 20),

          // Tombol Simpan & Batal
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                    });
                    // Reset ke data awal
                    _namaController.text = _guruData['nama'];
                    _kodeGuruController.text = _guruData['kode_guru'];
                    _nipController.text = _guruData['nip'];
                    _telpController.text = _guruData['no_telp'];
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: _textColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _updateGuruData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Simpan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: _borderColor),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightColor,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: _primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Profil Kaprog',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (!_isLoading && !_isEditing)
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      icon: const Icon(
                        Icons.edit,
                        color: _primaryColor,
                      ),
                    ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    // Profile Section
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _primaryColor,
                              border: Border.all(
                                color: _borderColor,
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _isLoading
                              ? _buildProfileSkeleton()
                              : Column(
                                  children: [
                                    Text(
                                      _guruData['nama']!,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: _textColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    // Role badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withValues(
                                            alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _primaryColor.withValues(
                                              alpha: 0.3),
                                        ),
                                      ),
                                      child: const Text(
                                        'KEPALA KONSENTRASI KEAHLIAN',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: _primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),

                    // Data Detail Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _borderColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isEditing)
                            _buildEditForm()
                          else ...[
                            const Text(
                              'Data Profil',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _textColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: _borderColor),
                            const SizedBox(height: 16),
                            _buildDetailItem(
                                'Kode Guru', _guruData['kode_guru']!),
                            const SizedBox(height: 12),
                            _buildDetailItem('NIP', _guruData['nip']!),
                            const SizedBox(height: 12),
                            _buildDetailItem(
                                'No. Telepon', _guruData['no_telp']!),
                          ],
                        ],
                      ),
                    ),

                    // Menu Section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _borderColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Menu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: _borderColor),
                          const SizedBox(height: 16),
                          _buildMenuTile(
                            icon: Icons.help_outline,
                            title: 'Bantuan & Panduan',
                            subtitle: 'Cara menggunakan aplikasi',
                            onTap: () => _showUnderDevelopment(
                                'Bantuan & Panduan', context),
                          ),
                          const SizedBox(height: 12),
                          _buildMenuTile(
                            icon: Icons.info_outline,
                            title: 'Tentang Aplikasi',
                            subtitle: 'Informasi aplikasi',
                            onTap: () => _showAboutDialog(context),
                          ),
                        ],
                      ),
                    ),

                    // Logout Button dengan jarak
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _logout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _accentColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(
                                color: _accentColor, width: 1.5),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Keluar dari Aplikasi',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // TAMBAH JARAK KE BAWAH
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: _primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSkeleton() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  void _showUnderDevelopment(String featureName, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.construction, color: _primaryColor),
            SizedBox(width: 8),
            Text(
              'Fitur dalam Pengembangan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
          ],
        ),
        content: Text(
          '$featureName sedang dalam tahap pengembangan dan akan segera hadir.',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.info, color: _primaryColor),
            SizedBox(width: 8),
            Text(
              'Tentang Aplikasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textColor,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SISFO PKL - KAPROG',
              style: TextStyle(
                fontSize: 16,
                color: _primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Versi: 1.0.0\nBuild: 2024.01',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aplikasi untuk pengelolaan dan koordinasi siswa PKL bagi Kaprog',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: _primaryColor,
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Konfirmasi Logout',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.exit_to_app,
              size: 48,
              color: _accentColor,
            ),
            SizedBox(height: 16),
            Text(
              'Yakin ingin keluar dari aplikasi?',
              style: TextStyle(
                fontSize: 16,
                color: _textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Anda perlu login kembali untuk masuk',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: _textColor,
            ),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog(
          backgroundColor: Colors.transparent,
          child: Center(
            child: CircularProgressIndicator(
              color: _primaryColor,
            ),
          ),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      await _processLogout();

      if (context.mounted) {
        Navigator.pop(context);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _processLogout() async {
    print('🔄 Processing logout for Kaprog...');

    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('user_name');

    print('👤 Current username: $currentUsername');

    // Hapus semua data login
    print('🗑️ Removing all login data...');
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      // Hapus semua kecuali notifications
      if (!key.startsWith('notifications_')) {
        await prefs.remove(key);
        print('   Removed: $key');
      }
    }

    print('✅ Logout completed successfully');
    print('   - User: ${currentUsername ?? 'unknown_user'}');
    print('   - Role: Kaprog');
    print('   - All login data: REMOVED');
    print('   - Notifications: PRESERVED');
  }
}
