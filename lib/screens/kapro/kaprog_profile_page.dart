import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_screen.dart';

class KaprogProfilePage extends StatefulWidget {
  const KaprogProfilePage({super.key});

  @override
  State<KaprogProfilePage> createState() => _KaprogProfilePageState();
}

class _KaprogProfilePageState extends State<KaprogProfilePage> {
  String _namaKaprog = 'Nama Kaprog';
  String _kodeGuru = '-';
  String _nip = '-';
  bool _isLoading = true;

  // Warna tema Neo Brutalism
  final Color _primaryColor = const Color(0xFF8B0000);
  final Color _borderColor = const Color(0xFF000000);
  final Color _redColor = const Color(0xFF8B0000);
  
  // Atur ketebalan border di sini
  final double _borderThickness = 2.0;
  
  // 👇 KHUSUS UNTUK SHADOW LINGKARAN (profile, loading, dialog)
  final double _circleShadowOffset = 1.0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // ========== DEBUG DETAIL ==========
    print('══════════════════════════════════════════════════════');
    print('🔍 [DEBUG] SHAREDPREFERENCES ISI LENGKAP:');
    print('══════════════════════════════════════════════════════');
    
    final allKeys = prefs.getKeys().toList()..sort();
    
    for (var key in allKeys) {
      final value = prefs.get(key);
      final valueType = value.runtimeType;
      print('📌 $key = $value (tipe: $valueType)');
    }
    
    print('══════════════════════════════════════════════════════');
    print('🔍 [DEBUG] MENCARI DATA PROFILE:');
    print('══════════════════════════════════════════════════════');
    
    // Cari semua key yang mengandung kata "nip"
    final nipKeys = allKeys.where((key) => 
      key.toLowerCase().contains('nip') ||
      key.toLowerCase().contains('user') ||
      key.toLowerCase().contains('guru')
    ).toList();
    
    print('Keys yang mungkin berisi NIP:');
    for (var key in nipKeys) {
      print('  - $key: ${prefs.get(key)}');
    }
    
    print('══════════════════════════════════════════════════════');
    print('🔍 [DEBUG] MENGAMBIL DATA:');
    print('══════════════════════════════════════════════════════');
    
    // Ambil data dengan mencoba berbagai kemungkinan
    final userName = prefs.getString('user_name');
    final name = prefs.getString('nama');
    final guruName = prefs.getString('guru_nama');
    
    final userNip = prefs.getString('user_nip');
    final nip1 = prefs.getString('nip');
    final nip2 = prefs.getString('guru_nip');
    final nip3 = prefs.getString('teacher_nip');
    
    final kodeGuru1 = prefs.getString('kode_guru');
    final kodeGuru2 = prefs.getString('guru_kode');
    final kodeGuru3 = prefs.getString('teacher_code');
    
    print('Nama dari berbagai key:');
    print('  - user_name: $userName');
    print('  - nama: $name');
    print('  - guru_nama: $guruName');
    
    print('NIP dari berbagai key:');
    print('  - user_nip: $userNip');
    print('  - nip: $nip1');
    print('  - guru_nip: $nip2');
    print('  - teacher_nip: $nip3');
    
    print('Kode Guru dari berbagai key:');
    print('  - kode_guru: $kodeGuru1');
    print('  - guru_kode: $kodeGuru2');
    print('  - teacher_code: $kodeGuru3');
    
    // Pilih yang ada datanya
    final String namaTerpilih = userName ?? name ?? guruName ?? 'Kaprog';
    
    final String nipTerpilih = userNip ?? 
                       nip1 ?? 
                       nip2 ?? 
                       nip3 ?? 
                       '-';
    
    final String kodeGuruTerpilih = kodeGuru1 ?? 
                            kodeGuru2 ?? 
                            kodeGuru3 ?? 
                            '-';
    
    print('══════════════════════════════════════════════════════');
    print('✅ [DEBUG] DATA YANG AKAN DITAMPILKAN:');
    print('══════════════════════════════════════════════════════');
    print('Nama: $namaTerpilih');
    print('NIP: $nipTerpilih');
    print('Kode Guru: $kodeGuruTerpilih');
    print('══════════════════════════════════════════════════════');
    
    setState(() {
      _namaKaprog = namaTerpilih;
      _nip = nipTerpilih;
      _kodeGuru = kodeGuruTerpilih;
      _isLoading = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => Dialog(
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
                                color: Colors.black,
                                offset: Offset(_circleShadowOffset, _circleShadowOffset),
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
                                _namaKaprog,
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
                                color: Colors.black,
                                offset: Offset(_circleShadowOffset, _circleShadowOffset),
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
      ),
    );

    if (shouldLogout == true) {
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
                  offset: Offset(_circleShadowOffset, _circleShadowOffset),
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
                        offset: Offset(_circleShadowOffset, _circleShadowOffset),
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

      await Future.delayed(const Duration(milliseconds: 800));

      final prefs = await SharedPreferences.getInstance();
      
      // HAPUS SEMUA DATA YANG MUNGKIN ADA
      await prefs.clear(); // Ini akan hapus SEMUA data di SharedPreferences
      
      // Atau hapus spesifik satu per satu:
      // await prefs.remove('access_token');
      // await prefs.remove('refresh_token');
      // await prefs.remove('user_role');
      // await prefs.remove('user_name');
      // await prefs.remove('user_id');
      // await prefs.remove('kode_guru');
      // await prefs.remove('user_nip');
      // await prefs.remove('nip');
      // await prefs.remove('guru_nip');

      if (!context.mounted) return;
      Navigator.pop(context);
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          color: Colors.black,
                          offset: Offset(_circleShadowOffset, _circleShadowOffset),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.pop(context),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    ),
                  ),        
                  const SizedBox(width: 12),
                  const Text(
                    'PROFIL KAPROG',
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
                                        _namaKaprog.toUpperCase(),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: _primaryColor,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: _borderColor, width: _borderThickness),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black,
                                              offset: Offset(_circleShadowOffset, _circleShadowOffset),
                                            ),
                                          ],
                                        ),
                                        child: const Text(
                                          'KOORDINATOR PROGRAM KEAHLIAN',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),

                      // KOTAK INFORMASI PRIBADI - SEMUA WARNA MERAH
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _borderColor,
                            width: _borderThickness,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _borderColor,
                              offset: Offset(_circleShadowOffset, _circleShadowOffset),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // HEADER INFORMASI PRIBADI
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _redColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _borderColor, width: _borderThickness),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black,
                                        offset: Offset(_circleShadowOffset, _circleShadowOffset),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.info_outline_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'INFORMASI PRIBADI',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // INFORMASI NIP - WARNA MERAH
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _redColor,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: _borderColor, width: _borderThickness),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _borderColor,
                                          offset: Offset(_circleShadowOffset, _circleShadowOffset),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.badge_outlined,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'NIP',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.black,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _nip.isNotEmpty && _nip != '-' 
                                              ? _nip 
                                              : 'NIP tidak ditemukan',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // INFORMASI KODE GURU - WARNA MERAH
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _redColor,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: _borderColor, width: _borderThickness),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _borderColor,
                                        offset: Offset(_circleShadowOffset, _circleShadowOffset),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.code_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'KODE GURU',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _kodeGuru,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      _buildMenuSection(
                        title: '',
                        items: [
                          _buildMenuCard(
                            icon: Icons.help_outline_rounded,
                            title: 'BANTUAN & PANDUAN',
                            subtitle: 'Cara menggunakan aplikasi',
                            iconColor: _redColor,
                            onTap: () {},
                          ),
                          _buildMenuCard(
                            icon: Icons.info_outline_rounded,
                            title: 'TENTANG APLIKASI',
                            subtitle: 'Informasi aplikasi',
                            iconColor: _redColor,
                            onTap: () {},
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

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
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: _borderColor, width: _borderThickness),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),
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
        if (title.isNotEmpty)
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
                    color: _redColor,
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