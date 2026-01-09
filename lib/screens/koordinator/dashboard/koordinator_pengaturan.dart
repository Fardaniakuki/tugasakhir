import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../login/login_screen.dart';

class KoordinatorPengaturan extends StatefulWidget {
  const KoordinatorPengaturan({super.key});

  @override
  State<KoordinatorPengaturan> createState() => _KoordinatorPengaturanState();
}

class _KoordinatorPengaturanState extends State<KoordinatorPengaturan> {
  String _namaKoordinator = 'Nama Koordinator';
  bool _isLoading = true;

  // Warna tema Neo Brutalism
  final Color _primaryColor = const Color(0xFF1D3557);
  final Color _borderColor = const Color(0xFF000000);
  
  // Atur ketebalan border di sini
  final double _borderThickness = 3.0;
  
  // 👇 KHUSUS UNTUK SHADOW LINGKARAN (profile, loading, dialog)
  final double _circleShadowOffset = 4.0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _namaKoordinator = prefs.getString('user_name') ?? 'Koordinator PKL';
      _isLoading = false;
    });
  }

  // ========== VOID LOGOUT YANG DIPERBAIKI ==========
  Future<void> _logout(BuildContext context) async {
    print('🚪 Logout initiated');
    
    // 1. Tampilkan dialog konfirmasi
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => _buildLogoutConfirmationDialog(),
    );

    // 2. Jika user memilih KELUAR
    if (shouldLogout == true) {
      print('✅ User confirmed logout');
      
      // 3. Tampilkan loading dialog
      _showLogoutLoadingDialog(context);
      
      // 4. Delay untuk animasi
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 5. Proses logout
      await _processLogout();
      
      // 6. Tutup loading dialog
      if (context.mounted) {
        Navigator.pop(context);
        
        // 7. Navigasi ke login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } else {
      print('❌ User cancelled logout');
    }
  }

  Widget _buildLogoutConfirmationDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _borderColor, width: _borderThickness),
          boxShadow: [
            BoxShadow(
              color: _borderColor,
              offset: Offset(_circleShadowOffset, _circleShadowOffset),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    border: Border(bottom: BorderSide(color: _borderColor, width: _borderThickness)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _borderColor, width: _borderThickness),
                          boxShadow: [
                            BoxShadow(
                              color: _borderColor,
                              offset: Offset(_circleShadowOffset / 2, _circleShadowOffset / 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.logout_rounded, 
                            color: _primaryColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KONFIRMASI LOGOUT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _namaKoordinator,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // CONTENT
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: _borderColor, width: _borderThickness),
                          boxShadow: [
                            BoxShadow(
                              color: _borderColor,
                              offset: Offset(_circleShadowOffset / 2, _circleShadowOffset / 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.exit_to_app_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'YAKIN INGIN KELUAR?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Anda perlu login kembali untuk masuk',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // BUTTONS
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryColor,
                            side: BorderSide(color: _primaryColor, width: _borderThickness),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: const Text(
                            'BATAL',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: _borderColor, width: _borderThickness),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'KELUAR',
                            style: TextStyle(fontWeight: FontWeight.w900),
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
  }

  void _showLogoutLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColor, width: _borderThickness),
            boxShadow: [
              BoxShadow(
                color: _borderColor,
                offset: Offset(_circleShadowOffset / 2, _circleShadowOffset / 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor,
                  border: Border.all(color: _borderColor, width: _borderThickness),
                  boxShadow: [
                    BoxShadow(
                      color: _borderColor,
                      offset: Offset(_circleShadowOffset / 2, _circleShadowOffset / 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.hourglass_bottom_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'MEMPROSES...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Menyelesaikan sesi anda',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== PROSES LOGOUT YANG AMAN ==========
  Future<void> _processLogout() async {
    print('🔄 Processing logout...');
    
    final prefs = await SharedPreferences.getInstance();
    final currentUsername = prefs.getString('user_name');
    
    print('👤 Current username: $currentUsername');
    
    // ========== STRATEGI AMAN ==========
    // 1. JANGAN SET 'should_clear_cache' - ini penyebab masalah!
    // 2. Hanya hapus data login saja
    // 3. BIARKAN notifikasi tetap ada di SharedPreferences
    
    // Simpan username untuk logging
    final usernameForLog = currentUsername ?? 'unknown_user';
    
    // Hapus data login saja
    print('🗑️ Removing login data...');
    await prefs.remove('access_token');
    await prefs.remove('kelas_id');
    await prefs.remove('kelas_nama');
    await prefs.remove('user_kelas_id');
    await prefs.remove('user_kelas');
    await prefs.remove('user_id');
    
    // Hapus username TERAKHIR
    await prefs.remove('user_name');
    
    // JANGAN hapus notifikasi! Biarkan sebagai history
    print('💾 Preserving notifications for user: $usernameForLog');
    print('   - Key: notifications_$usernameForLog (NOT REMOVED)');
    print('   - User can see notifications when login again');
    
    // Logging detail
    print('✅ Logout completed successfully');
    print('   - User: $usernameForLog');
    print('   - Login data: REMOVED');
    print('   - Notifications: PRESERVED');
    
    // Optional: Jika ingin hapus notifikasi saat logout (tidak disarankan)
    // await prefs.remove('notifications_$usernameForLog');
    // print('🗑️ Notifications also removed');
  }
  // ==============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PENGATURAN KOORDINATOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Konten Utama
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                  border: Border.all(color: _borderColor, width: _borderThickness),
                  boxShadow: [
                    BoxShadow(
                      color: _borderColor,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      // Profile Section
                      Container(
                        margin: const EdgeInsets.only(top: 20, bottom: 30),
                        child: Column(
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _primaryColor,
                                border: Border.all(color: _borderColor, width: _borderThickness),
                                boxShadow: [
                                  BoxShadow(
                                    color: _borderColor,
                                    blurRadius: 0,
                                    offset: Offset(_circleShadowOffset, _circleShadowOffset),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _isLoading
                                ? _buildProfileSkeleton()
                                : Column(
                                    children: [
                                      Text(
                                        _namaKoordinator.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                          letterSpacing: 1,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: _primaryColor,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: _borderColor, width: _borderThickness),
                                        ),
                                        child: const Text(
                                          'KOORDINATOR PKL',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),

                      // Menu Section
                      _buildMenuSection(
                        title: '',
                        items: [
                          _buildMenuCard(
                            icon: Icons.help_outline_rounded,
                            title: 'BANTUAN & PANDUAN',
                            subtitle: 'Cara menggunakan aplikasi',
                            iconColor: const Color(0xFF795548),
                            onTap: () {},
                          ),
                          _buildMenuCard(
                            icon: Icons.info_outline_rounded,
                            title: 'TENTANG APLIKASI',
                            subtitle: 'Versi & informasi aplikasi',
                            iconColor: const Color(0xFF607D8B),
                            onTap: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Logout Button
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: _borderColor,
                              offset: Offset(_circleShadowOffset, _circleShadowOffset),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => _logout(context),
                          icon: const Icon(Icons.logout_rounded, size: 22),
                          label: const Text(
                            'KELUAR DARI APLIKASI',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE63946), // Warna merah untuk logout
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: _borderColor, width: _borderThickness),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: _primaryColor,
              letterSpacing: 1,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _borderColor,
                width: _borderThickness,
              ),
              boxShadow: [
                BoxShadow(
                  color: _borderColor,
                  blurRadius: 0,
                  offset: Offset(_circleShadowOffset, _circleShadowOffset),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor, width: _borderThickness),
                    boxShadow: [
                      BoxShadow(
                        color: _borderColor,
                        offset: Offset(_circleShadowOffset, _circleShadowOffset),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: _borderColor, width: _borderThickness),
                    boxShadow: [
                      BoxShadow(
                        color: _borderColor,
                        offset: Offset(_circleShadowOffset, _circleShadowOffset),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
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
            color: _borderColor.withValues(alpha: 0.1),
            border: Border.all(color: _borderColor, width: _borderThickness),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 18,
          decoration: BoxDecoration(
            color: _borderColor.withValues(alpha: 0.1),
            border: Border.all(color: _borderColor, width: _borderThickness),
          ),
        ),
      ],
    );
  }
}