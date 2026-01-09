import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../login/login_screen.dart';

class KoordinatorDashboard extends StatefulWidget {
  const KoordinatorDashboard({super.key});

  @override
  State<KoordinatorDashboard> createState() => _KoordinatorDashboardState();
}

class _KoordinatorDashboardState extends State<KoordinatorDashboard> {
  String _namaKoordinator = 'Koordinator';
  String _kodeGuru = 'N/A';

  // Neo Brutalism Colors (Sama dengan SiswaDashboard)
  final Color _primaryColor = const Color(0xFFE71543);
  final Color _secondaryColor = const Color(0xFFE6E3E3);
  final Color _darkColor = const Color(0xFF1D3557);
  final Color _yellowColor = const Color(0xFFFFB703);
  final Color _blackColor = Colors.black;

  // Neo Brutalism Shadows (Sama dengan SiswaDashboard)
  static const BoxShadow _heavyShadow = BoxShadow(
    color: Colors.black,
    offset: Offset(6, 6),
    blurRadius: 0,
  );

  final BoxShadow _lightShadow = BoxShadow(
    color: Colors.black.withValues(alpha: 0.2),
    offset: const Offset(4, 4),
    blurRadius: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      _namaKoordinator = prefs.getString('user_name') ?? 'Koordinator';
      _kodeGuru = prefs.getString('kode_guru') ?? 'N/A';
    });
  }

  // ========== DATA ==========
  final List<Map<String, dynamic>> _statsData = [
    {'title': 'Total Siswa', 'value': '125', 'color': const Color(0xFF4CAF50), 'icon': Icons.people},
    {'title': 'Industri', 'value': '42', 'color': const Color(0xFF2196F3), 'icon': Icons.business},
    {'title': 'Pembimbing', 'value': '18', 'color': const Color(0xFFFF9800), 'icon': Icons.supervisor_account},
    {'title': 'Siswa PKL', 'value': '96', 'color': const Color(0xFF9C27B0), 'icon': Icons.work},
    {'title': 'Pending', 'value': '23', 'color': const Color(0xFFF44336), 'icon': Icons.pending},
    {'title': 'Disetujui', 'value': '58', 'color': const Color(0xFF06D6A0), 'icon': Icons.check_circle},
  ];

  // Semua aksi cepat dalam satu list untuk grid 3x2
  final List<Map<String, dynamic>> _quickActions = [
    {'title': 'Buat Jadwal', 'icon': Icons.add_circle, 'color': const Color(0xFFE71543)},
    {'title': 'Lihat Laporan', 'icon': Icons.assignment, 'color': const Color(0xFF2196F3)},
    {'title': 'Industri', 'icon': Icons.business_center, 'color': const Color(0xFF4CAF50)},
    {'title': 'Verifikasi', 'icon': Icons.verified, 'color': const Color(0xFFFF9800)},
    {'title': 'Pembimbing', 'icon': Icons.groups, 'color': const Color(0xFF9C27B0)},
    {'title': 'Keluar Akun', 'icon': Icons.exit_to_app, 'color': const Color(0xFFF44336)},
  ];

  // ========== LOGOUT FUNCTION ==========
  Future<void> _logout(BuildContext context) async {
    print('🚪 Logout Koordinator initiated');
    
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => _buildLogoutConfirmationDialog(),
    );

    if (shouldLogout == true) {
      print('✅ Koordinator confirmed logout');
      
      _showLogoutLoadingDialog(context);
      
      await Future.delayed(const Duration(milliseconds: 800));
      
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

  Widget _buildLogoutConfirmationDialog() {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _blackColor, width: 4),
          boxShadow: const [_heavyShadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER - Neo Brutalism Style
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    border: Border(bottom: BorderSide(color: _blackColor, width: 4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _blackColor, width: 3),
                          boxShadow: [_lightShadow],
                        ),
                        child: Icon(Icons.logout_rounded, 
                            color: _primaryColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'KONFIRMASI LOGOUT',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _namaKoordinator,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: _blackColor, width: 4),
                          boxShadow: const [_heavyShadow],
                        ),
                        child: const Icon(
                          Icons.exit_to_app_rounded,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'KELUAR SEBAGAI KOORDINATOR?',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Anda perlu login kembali untuk mengakses sistem',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: _yellowColor,
                          border: Border.all(color: _blackColor, width: 3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [_lightShadow],
                        ),
                        child: Text(
                          'Kode Guru: $_kodeGuru',
                          style: TextStyle(
                            fontSize: 18,
                            color: _blackColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // BUTTONS
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: _yellowColor,
                            border: Border.all(color: _blackColor, width: 3),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [_heavyShadow],
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: TextButton.styleFrom(
                              foregroundColor: _blackColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: const Text(
                              'BATAL',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            border: Border.all(color: _blackColor, width: 3),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [_heavyShadow],
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: const Text(
                              'KELUAR',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
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
  }

  void _showLogoutLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: _blackColor, width: 4),
            boxShadow: const [_heavyShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor,
                  border: Border.all(color: _blackColor, width: 4),
                  boxShadow: const [_heavyShadow],
                ),
                child: const Icon(
                  Icons.hourglass_bottom_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'MEMPROSES LOGOUT...',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Menyelesaikan sesi Koordinator',
                style: TextStyle(
                  fontSize: 16,
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

  Future<void> _processLogout() async {
    final prefs = await SharedPreferences.getInstance();
    final keysToRemove = [
      'access_token',
      'refresh_token',
      'user_role',
      'user_id',
      'user_name',
      'username',
      'user_nip',
      'kode_guru',
      'kelas_id',
      'kelas_nama',
      'user_kelas_id',
      'user_kelas',
      'last_login_time',
      'login_expiry',
    ];
    
    for (var key in keysToRemove) {
      await prefs.remove(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER SECTION - Neo Brutalism Style
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border.all(color: _blackColor, width: 4),
                  boxShadow: const [_heavyShadow],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Bagian kiri: Salam dan nama
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Halo,',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _namaKoordinator,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Selamat Datang Koordinator',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Bagian kanan: Icon profile
                    GestureDetector(
                      onTap: () {
                        _showProfileDialog(context);
                      },
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: _blackColor, width: 3),
                          boxShadow: const [_heavyShadow],
                        ),
                        child: Icon(
                          Icons.person,
                          color: _primaryColor,
                          size: 36,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // AKSI CEPAT SECTION - Grid 3 kolom x 2 baris
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: _secondaryColor,
                  border: Border.all(color: _blackColor, width: 4),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [_heavyShadow],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION TITLE
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _yellowColor,
                          border: Border.all(color: _blackColor, width: 3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [_lightShadow],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.bolt,
                              color: Colors.black,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'AKSI CEPAT',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // GRID 3x2 untuk aksi cepat
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                        itemCount: _quickActions.length,
                        itemBuilder: (context, index) {
                          final action = _quickActions[index];
                          return GestureDetector(
                            onTap: index == 5 ? () => _logout(context) : () {},
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: _blackColor, width: 3),
                                boxShadow: const [_heavyShadow],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: action['color'].withValues(alpha: 0.15),
                                        border: Border.all(color: action['color'], width: 2),
                                      ),
                                      child: Icon(action['icon'], color: action['color'], size: 24),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      action['title'],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                        letterSpacing: -0.3,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // STATISTIK SECTION
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _secondaryColor,
                  border: Border.all(color: _blackColor, width: 4),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [_heavyShadow],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SECTION TITLE
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          border: Border.all(color: _blackColor, width: 3),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [_lightShadow],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.bar_chart,
                              color: Colors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'STATISTIK SISTEM',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // STATISTIK GRID (2x3)
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 9,
                        mainAxisSpacing: 9,
                        childAspectRatio: 1.3,
                        children: _statsData.map((stat) => _buildStatCard(
                          title: stat['title'],
                          value: stat['value'],
                          icon: stat['icon'],
                          color: stat['color'],
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // BOTTOM SPACING
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _blackColor, width: 4),
            boxShadow: const [_heavyShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(26),
                    topRight: Radius.circular(26),
                  ),
                  border: Border(bottom: BorderSide(color: _blackColor, width: 4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _blackColor, width: 3),
                        boxShadow: [_lightShadow],
                      ),
                      child: Icon(Icons.person, color: _primaryColor, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'PROFIL KOORDINATOR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
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
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _primaryColor,
                        border: Border.all(color: _blackColor, width: 4),
                        boxShadow: const [_heavyShadow],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _namaKoordinator,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: _yellowColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _blackColor, width: 3),
                      ),
                      child: Text(
                        'Kode: $_kodeGuru',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      height: 60,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        border: Border.all(color: _blackColor, width: 3),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [_heavyShadow],
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _logout(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                        child: const Text(
                          'LOGOUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: -0.3,
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
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blackColor, width: 3),
        boxShadow: const [_heavyShadow],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                  border: Border.all(color: color, width: 2),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _blackColor, width: 2),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}