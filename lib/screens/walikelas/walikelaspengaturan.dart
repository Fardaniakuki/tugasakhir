import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_screen.dart';

class WaliKelasProfilePage extends StatefulWidget {
  const WaliKelasProfilePage({super.key, required String namaWaliKelas, required String kelasWali});

  @override
  State<WaliKelasProfilePage> createState() => _WaliKelasProfilePageState();
}

class _WaliKelasProfilePageState extends State<WaliKelasProfilePage> {
  // Warna-warna sama persis dengan KaprogProfilePage
  static const Color _primaryColor = Color(0xFF6B1B1B); // Merah marun
  static const Color _accentColor = Color(0xFF9F0712); // Merah
  static const Color _lightColor = Color(0xFFF5F5F5); // Abu-abu muda
  static const Color _textColor = Color(0xFF333333); // Teks gelap
  static const Color _borderColor = Color(0xFFE0E0E0); // Border abu-abu muda

  Map<String, String> _profileData = {
    'nama': 'FARDAN', // Nama default
    'nip': '199001012024001', // NIP default
  };
  
  bool _isLoading = true;
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      print('📥 Loading profile data for Wali Kelas...');
      
      // Ambil dari SharedPreferences atau gunakan data dummy
      final String? userName = prefs.getString('user_name');
      final String? nama = prefs.getString('nama');
      final String? nip = prefs.getString('nip');
      
      // Jika ada data di SharedPreferences, gunakan itu
      // Jika tidak, gunakan data dummy
      final String finalNama = (userName ?? nama ?? 'FARDAN').toUpperCase();
      final String finalNip = nip ?? '199001012024001';
      
      print('   Loaded name: $finalNama');
      print('   Loaded NIP: $finalNip');
      
      setState(() {
        _profileData = {
          'nama': finalNama,
          'nip': finalNip,
        };
        _isLoading = false;
      });
      
      print('✅ Profile loaded: ${_profileData['nama']}');
      
    } catch (e) {
      print('❌ Error loading profile: $e');
      
      // Fallback ke data dummy
      setState(() {
        _profileData = {
          'nama': 'FARDAN',
          'nip': '199001012024001',
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Simpan data ke SharedPreferences
      await prefs.setString('nama', _profileData['nama']!);
      await prefs.setString('user_name', _profileData['nama']!);
      await prefs.setString('nip', _profileData['nip']!);
      
      print('💾 Profile saved: ${_profileData['nama']}');
      
    } catch (e) {
      print('❌ Error saving profile: $e');
    }
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _nameController.text = _profileData['nama']!;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _nameController.clear();
    });
  }

  void _saveEditing() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _profileData['nama'] = _nameController.text.toUpperCase();
        _isEditing = false;
      });
      _saveProfileData(); // Simpan ke SharedPreferences
    }
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
                    color: Colors.grey.withOpacity(0.1),
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
                    'Profil Wali Kelas',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  children: [
                    // Profile Section dengan Edit Button
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          Stack(
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
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _startEditing,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: _accentColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (_isEditing)
                            // Form Edit Nama
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: TextFormField(
                                      controller: _nameController,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: _textColor,
                                      ),
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        hintText: 'Masukkan nama',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                        ),
                                        border: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: _primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        focusedBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: _primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Nama tidak boleh kosong';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ElevatedButton(
                                        onPressed: _saveEditing,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: _primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: const Text('Simpan'),
                                      ),
                                      const SizedBox(width: 12),
                                      TextButton(
                                        onPressed: _cancelEditing,
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.grey,
                                        ),
                                        child: const Text('Batal'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                          else
                            // Tampilan Normal
                            _isLoading
                                ? _buildProfileSkeleton()
                                : Column(
                                    children: [
                                      Text(
                                        _profileData['nama']!,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: _textColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _primaryColor.withOpacity(0.3),
                                          ),
                                        ),
                                        child: const Text(
                                          'WALI KELAS',
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

                    // Informasi Pribadi Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _borderColor,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                color: _primaryColor,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Informasi Pribadi',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: _textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(color: _borderColor),
                          const SizedBox(height: 16),

                          // NIP
                          _buildInfoItem(
                            icon: Icons.badge_outlined,
                            label: 'NIP',
                            value: _isLoading 
                                ? 'Memuat...'
                                : (_profileData['nip']!.isNotEmpty 
                                    ? _profileData['nip']! 
                                    : 'NIP tidak ditemukan'),
                          ),
                          const SizedBox(height: 16),

                          // Keterangan Data Dummy
                          _buildInfoItem(
                            icon: Icons.info_outline,
                            label: 'Kelas',
                            value: 'XII RPL 1',
                          ),
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
                            color: Colors.grey.withOpacity(0.05),
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
                            onTap: () => _showUnderDevelopment('Bantuan & Panduan', context),
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

                    // Logout Button
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
                            side: const BorderSide(color: _accentColor, width: 1.5),
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

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: _primaryColor,
          size: 22,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
            ],
          ),
        ),
      ],
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
                  color: _primaryColor.withOpacity(0.1),
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
              'SISFO PKL - WALI KELAS',
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
              'Aplikasi untuk pengelolaan dan monitoring siswa PKL bagi Wali Kelas',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _primaryColor.withOpacity(0.1),
                ),
              ),
              child: const Text(
                '⚠️ Mode Data Dummy: Data nama dapat diedit dan akan tersimpan di perangkat Anda',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
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
    final prefs = await SharedPreferences.getInstance();

    // Hapus data login (kecuali data dummy jika ingin dipertahankan)
    await prefs.remove('access_token');
    await prefs.remove('user_name');
    // Tidak menghapus 'nama' dan 'nip' agar data dummy tetap ada saat login lagi
  }
}