import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../login/login_screen.dart';
import 'progress_siswa_screen.dart';
import 'laporan_siswa_screen.dart';

class WaliKelasDashboard extends StatefulWidget {
  const WaliKelasDashboard({super.key});

  @override
  State<WaliKelasDashboard> createState() => _WaliKelasDashboardState();
}

class _WaliKelasDashboardState extends State<WaliKelasDashboard> {
  String _namaWaliKelas = 'Loading...';
  String _kelasWali = 'Loading...';
  bool _isLoading = true;
  
  // Neo Brutalism Colors - Sama dengan contoh
  final Color _primaryColor = const Color(0xFFE71543);
  final Color _secondaryColor = const Color(0xFFE6E3E3);
  final Color _darkColor = const Color(0xFF1D3557);
  final Color _yellowColor = const Color(0xFFFFB703);
  final Color _blackColor = Colors.black;
  
  // Neo Brutalism Shadows
  static const BoxShadow _heavyShadow = BoxShadow(
    color: Colors.black,
    offset: Offset(6, 6),
    blurRadius: 0,
  );
  
  final BoxShadow _lightShadow = BoxShadow(
    color: Colors.black.withValues(alpha:0.2),
    offset: const Offset(4, 4),
    blurRadius: 0,
  );

  @override
  void initState() {
    super.initState();
    print('🚀 WaliKelasDashboard initState called');
    _loadProfileData();
  }

  bool _isWaliKelasRole(String? userRole) {
    if (userRole == null) return false;
    
    // DEBUG: Print role yang diterima
    print('🔍 _isWaliKelasRole called with: "$userRole"');
    
    // Cek semua kemungkinan format role
    final roleLower = userRole.toLowerCase();
    final isWaliKelas = 
        roleLower == 'wali_kelas' ||
        roleLower == 'wali kelas' ||
        roleLower == 'walikelas' ||
        roleLower == 'guru' || // Jika role hanya "guru"
        roleLower == 'pembimbing' || // Jika role "pembimbing"
        roleLower.contains('wali') && roleLower.contains('kelas');
    
    print('   Result: $isWaliKelas');
    return isWaliKelas;
  }

  Future<void> _loadProfileData() async {
    print('\n🔍 ===== WALI KELAS DASHBOARD DEBUG START =====');
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userRole = prefs.getString('user_role');
    final userName = prefs.getString('user_name');

    // Cek token
    if (token == null || token.isEmpty) {
      print('❌ ERROR: Token is null or empty');
      print('   Redirecting to login...');
      _redirectToLogin();
      return;
    }

    // Cek role dengan logika yang lebih fleksibel
    final isValidRole = _isWaliKelasRole(userRole);
    if (!isValidRole) {
      print('❌ ERROR: Role is not Wali Kelas');
      print('   Redirecting to login...');
      _redirectToLogin();
      return;
    }

    print('✅ AUTH PASSED: Role valid, loading profile data...');

    try {
      final apiUrl = dotenv.env['API_BASE_URL'] ?? '';
      
      final response = await http.get(
        Uri.parse('$apiUrl/api/guru/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final guruData = data['data'];
          
          await Future.delayed(const Duration(milliseconds: 800)); // Simulasi loading
          
          setState(() {
            _namaWaliKelas = guruData['nama'] ?? userName ?? 'Wali Kelas';
            
            // Jika ada kelas yang diampu
            if (guruData['kelas_diampu'] != null && 
                guruData['kelas_diampu'].isNotEmpty) {
              _kelasWali = guruData['kelas_diampu'][0]['nama'] ?? 'Kelas';
              
              // Simpan kelas untuk future use
              prefs.setString('kelas_nama', _kelasWali);
            } else {
              _kelasWali = 'Tidak Ada Kelas';
            }
          });
        } else {
          _setFallbackData(prefs);
        }
      } else {
        _setFallbackData(prefs);
      }
    } catch (e) {
      print('❌ Exception loading profile: $e');
      _setFallbackData(prefs);
    } finally {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        setState(() {
          _isLoading = false;
        });
      }
    }
    
    print('===== WALI KELAS DASHBOARD DEBUG END =====\n');
  }

  void _setFallbackData(SharedPreferences prefs) {
    print('🔄 Using fallback data from SharedPreferences');
    setState(() {
      _namaWaliKelas = prefs.getString('user_name') ?? 'Wali Kelas';
      _kelasWali = prefs.getString('kelas_nama') ?? 'Kelas';
    });
  }


  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }

  Widget _buildMenuItem({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _secondaryColor,
          border: Border.all(color: _blackColor, width: 4),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [_heavyShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header dengan ikon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha:0.9),
                border: Border(
                  bottom: BorderSide(color: _blackColor, width: 4),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  // Ikon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _blackColor, width: 3),
                      shape: BoxShape.circle,
                      boxShadow: [_lightShadow],
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Judul
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  
                  // Panah
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _yellowColor,
                      border: Border.all(color: _blackColor, width: 3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            // Deskripsi
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: _darkColor,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== SKELETON LOADING WIDGETS =====

  Widget _buildSkeletonHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primaryColor,
        border: Border.all(color: _blackColor, width: 3),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_heavyShadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Skeleton untuk "Halo, ..."
                Container(
                  width: 180,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Skeleton untuk badge kelas
                Container(
                  width: 150,
                  height: 35,
                  decoration: BoxDecoration(
                    color: _yellowColor.withValues(alpha:0.7),
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                
                // Skeleton untuk subtext
                Container(
                  width: 200,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          
          // Skeleton untuk avatar dan logout
          Column(
            children: [
              // Skeleton avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _secondaryColor.withValues(alpha:0.7),
                  border: Border.all(color: _blackColor, width: 3),
                  shape: BoxShape.circle,
                ),
              ),
              
          
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonStatItem() {
    return Column(
      children: [
        // Skeleton circle icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha:0.5),
            border: Border.all(color: _blackColor.withValues(alpha:0.5), width: 2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        
        // Skeleton value
        Container(
          width: 30,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha:0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        
        // Skeleton label
        Container(
          width: 40,
          height: 10,
          decoration: BoxDecoration(
            color: _darkColor.withValues(alpha:0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _secondaryColor.withValues(alpha:0.8),
        border: Border.all(color: _blackColor, width: 4),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [_heavyShadow],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSkeletonStatItem(),
          Container(width: 4, height: 50, color: _blackColor.withValues(alpha:0.5)),
          _buildSkeletonStatItem(),
          Container(width: 4, height: 50, color: _blackColor.withValues(alpha:0.5)),
          _buildSkeletonStatItem(),
        ],
      ),
    );
  }

  Widget _buildSkeletonMenuItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _secondaryColor.withValues(alpha:0.7),
        border: Border.all(color: _blackColor, width: 4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_heavyShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Skeleton header menu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _primaryColor.withValues(alpha:0.6),
              border: const Border(
                bottom: BorderSide(color: Colors.black, width: 4),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Skeleton icon circle
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.5),
                    border: Border.all(color: _blackColor, width: 3),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Skeleton title
                Expanded(
                  child: Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.4),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                
                // Skeleton arrow button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _yellowColor.withValues(alpha:0.6),
                    border: Border.all(color: _blackColor, width: 3),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          
          // Skeleton description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _darkColor.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _darkColor.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 200,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _darkColor.withValues(alpha:0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoadingScreen() {
    return Scaffold(
      backgroundColor: _darkColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Skeleton Header
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildSkeletonHeader(),
                  const SizedBox(height: 16),
                  _buildSkeletonStats(),
                ],
              ),
            ),
            
            // Skeleton Menu
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildSkeletonMenuItem();
                },
                childCount: 4, // Jumlah menu skeleton
              ),
            ),
          ],
        ),
      ),
      
      // Skeleton FAB
      floatingActionButton: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: _yellowColor.withValues(alpha:0.7),
          border: Border.all(color: _blackColor.withValues(alpha:0.7), width: 4),
          shape: BoxShape.circle,
          boxShadow: const [_heavyShadow],
        ),
        child: Icon(
          Icons.add,
          color: _blackColor.withValues(alpha:0.7),
          size: 32,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeletonLoadingScreen();
    }

    return Scaffold(
      backgroundColor: _darkColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header dan statistik
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Header dengan profil
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _primaryColor,
                      border: Border.all(color: _blackColor, width: 3),
                      boxShadow: const [_heavyShadow],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Halo, $_namaWaliKelas!',
                                style: const TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _yellowColor,
                                  border: Border.all(color: _blackColor, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Wali Kelas',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: _blackColor,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Dashboard Monitoring & Laporan',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha:0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Avatar dan logout
                        Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: _secondaryColor,
                                border: Border.all(color: _blackColor, width: 3),
                                shape: BoxShape.circle,
                                boxShadow: [_lightShadow],
                              ),
                              child: Icon(
                                Icons.school,
                                size: 32,
                                color: _primaryColor,
                              ),
                            ),
                       
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Statistik singkat
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _secondaryColor,
                      border: Border.all(color: _blackColor, width: 4),
                      boxShadow: const [_heavyShadow],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          value: '32',
                          label: 'SISWA',
                          icon: Icons.people,
                          color: _primaryColor,
                        ),
                      
                        _buildStatItem(
                          value: '15',
                          label: 'PKL AKTIF',
                          icon: Icons.work,
                          color: const Color(0xFF06D6A0),
                        ),
                     
                        _buildStatItem(
                          value: '2',
                          label: 'ISSUES',
                          icon: Icons.warning,
                          color: const Color(0xFFFFB703),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu (scrollable)
            SliverList(
              delegate: SliverChildListDelegate([
                Container(
                  margin: const EdgeInsets.only(top: 24, bottom: 80),
                  decoration: BoxDecoration(
                    color: _secondaryColor,
                    border: Border.all(color: _blackColor, width: 4),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: const [_heavyShadow],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Judul menu
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              border: Border.all(color: _blackColor, width: 3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _yellowColor,
                                    border: Border.all(color: _blackColor, width: 2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.menu,
                                    size: 20,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'MENU WALI KELAS',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Daftar menu
                        Column(
                          children: [
                            _buildMenuItem(
                              title: 'LIHAT PROGRESS',
                              description: 'Pantau perkembangan dan kemajuan siswa dalam program PKL. Lihat status pengajuan, progress kerja, dan pencapaian siswa.',
                              icon: Icons.trending_up,
                              iconColor: const Color(0xFF06D6A0),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProgressSiswaScreen(
                                      kelasId: 1,
                                      namaKelas: _kelasWali,
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            _buildMenuItem(
                              title: 'LAPORAN SISWA',
                              description: 'Akses data lengkap siswa, termasuk informasi pribadi, akademik, dan riwayat PKL. Monitoring data siswa secara komprehensif.',
                              icon: Icons.assignment_ind,
                              iconColor: _primaryColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LaporanSiswaScreen(
                                      kelasId: 1,
                                      namaKelas: _kelasWali,
                                    ),
                                  ),
                                );
                              },
                            ),
                            
                            _buildMenuItem(
                              title: 'PERMASALAHAN SISWA',
                              description: 'Identifikasi dan catat permasalahan yang dihadapi siswa selama PKL. Berikan solusi dan monitoring masalah hingga tuntas.',
                              icon: Icons.warning_amber,
                              iconColor: const Color(0xFFFFB703),
                              onTap: () {
                                _showUnderDevelopment(context);
                              },
                            ),
                            
                            _buildMenuItem(
                              title: 'KOMUNIKASI',
                              description: 'Terhubung dengan siswa, pembimbing, dan industri. Kelola pesan, pengumuman, dan koordinasi kegiatan PKL.',
                              icon: Icons.chat_bubble,
                              iconColor: const Color(0xFFA8DADC),
                              onTap: () {
                                _showUnderDevelopment(context);
                              },
                            ),
                            
                            const SizedBox(height: 30),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
      
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: _blackColor, width: 2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: _blackColor,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _darkColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  void _showUnderDevelopment(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _secondaryColor,
            border: Border.all(color: _blackColor, width: 4),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [_heavyShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB703),
                  border: Border.all(color: _blackColor, width: 3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction,
                  color: Colors.black,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'FITUR DALAM PENGEMBANGAN',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _blackColor,
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Fitur ini sedang dalam tahap pengembangan dan akan segera hadir.',
                style: TextStyle(
                  fontSize: 14,
                  color: _darkColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border.all(color: _blackColor, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'MENGERTI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
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