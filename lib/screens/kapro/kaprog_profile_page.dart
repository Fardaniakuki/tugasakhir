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
  Map<String, dynamic>? _currentTeacher;
  bool _isLoading = true;
  String? _errorMessage;
@override
void initState() {
  super.initState();
  _loadProfileData();
}

Future<void> _loadProfileData() async {
  final prefs = await SharedPreferences.getInstance();
  
  // AMBIL DATA DARI SHAREDPREFERENCES TERLEBIH DAHULU
  final userId = prefs.getInt('user_id');
  final userName = prefs.getString('user_name');
  final kodeGuru = prefs.getString('kode_guru');
  final userNip = prefs.getString('user_nip');
  
  print('=== DATA DARI SHAREDPREFERENCES ===');
  print('User ID: $userId');
  print('User Name: $userName');
  print('Kode Guru: $kodeGuru');
  print('NIP: $userNip');
  
  // BUAT DATA DARI SHAREDPREFERENCES SEBAGAI FALLBACK
  final fallbackData = {
    'nama': userName ?? 'Guru',
    'kode_guru': kodeGuru ?? '-',
    'nip': userNip ?? '-',
    'no_telp': '-',
    'is_kaprog': true,
    'is_active': true,
  };
  
  // LANGSUNG SET DATA DARI SHAREDPREFERENCES
  setState(() {
    _currentTeacher = fallbackData;
    _isLoading = false;
  });
  
  // COBA AMBIL DATA LENGKAP DARI API (OPTIONAL)
  _tryLoadFromAPI();
}

Future<void> _tryLoadFromAPI() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  
  if (token == null) return;
  
  try {
    print('Trying to load additional data from API...');
    
    // Coba endpoint yang berbeda
    final response = await http.get(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('API Response received');
      
      // Cari data yang sesuai dengan user_id
      final userId = prefs.getInt('user_id');
      final kodeGuru = prefs.getString('kode_guru');
      
      List<dynamic> guruList = [];
      
      // Parse response
      if (data is Map && data['success'] == true) {
        if (data['data'] is Map && data['data']['data'] is List) {
          guruList = data['data']['data'];
        } else if (data['data'] is List) {
          guruList = data['data'];
        }
      }
      
      if (guruList.isNotEmpty) {
        // Cari guru yang sesuai
        Map<String, dynamic>? apiData;
        
        if (userId != null) {
          for (var guru in guruList) {
            if (guru['user_id'] == userId || guru['id'] == userId) {
              apiData = guru;
              break;
            }
          }
        }
        
        if (apiData == null && kodeGuru != null) {
          for (var guru in guruList) {
            if (guru['kode_guru']?.toString() == kodeGuru) {
              apiData = guru;
              break;
            }
          }
        }
        
        // Jika ditemukan, update dengan data dari API
        if (apiData != null && mounted) {
          setState(() {
            _currentTeacher = {
              ..._currentTeacher ?? {}, // Pertahankan data fallback
              ...apiData!,               // Tambahkan data dari API
            };
          });
          print('Updated with API data');
        }
      }
    }
  } catch (e) {
    print('Error loading from API: $e');
  }
}

  // Dialog Logout yang lebih bagus
  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 190, 28, 16)
                      .withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout,
                  size: 36,
                  color: Color.fromARGB(255, 190, 28, 16),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),

              // Message
              const Text(
                'Apakah Anda yakin ingin keluar dari aplikasi?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),

              // Buttons
              Row(
                children: [
                  // Cancel Button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Logout Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 190, 28, 16),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_role');
    await prefs.remove('user_name');

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading ? _buildSkeletonLoading() : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfileData,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Background dengan lengkungan
          Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    Container(
                      height: 280,
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Konten utama
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Profile Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person,
                                size: 40, color: Colors.black),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _currentTeacher?['nama'] ?? 'Nama tidak tersedia',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currentTeacher?['is_kaprog'] == true
                                ? 'Koordinator Program Keahlian'
                                : 'Guru',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profile Details
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Pribadi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildProfileItem('NIP',
                              _currentTeacher?['nip']?.toString() ?? '-'),
                          _buildProfileItem('Kode Guru',
                              _currentTeacher?['kode_guru']?.toString() ?? '-'),
                          _buildProfileItem('No. Telepon',
                              _currentTeacher?['no_telp']?.toString() ?? '-'),
                          _buildProfileItem(
                              'Status',
                              _currentTeacher?['is_active'] == true
                                  ? 'Aktif'
                                  : 'Tidak Aktif'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Actions
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aksi',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _showLogoutDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor:
                                    const Color.fromARGB(255, 190, 28, 16),
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(
                                      color: Color.fromARGB(255, 190, 28, 16),
                                      width: 1.5),
                                ),
                              ),
                              icon: const Icon(Icons.logout, size: 20),
                              label: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            children: [
              Positioned.fill(
                child: Column(
                  children: [
                    Container(
                      height: 280,
                      color: Colors.white,
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFD9D9D9),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Skeleton Profile Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          SkeletonCircle(radius: 40),
                          SizedBox(height: 16),
                          SkeletonLine(width: 150, height: 20),
                          SizedBox(height: 8),
                          SkeletonLine(width: 120, height: 14),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Skeleton Profile Details
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 100, height: 16),
                          SizedBox(height: 16),
                          SkeletonLine(height: 14),
                          SizedBox(height: 12),
                          SkeletonLine(height: 14),
                          SizedBox(height: 12),
                          SkeletonLine(height: 14),
                          SizedBox(height: 12),
                          SkeletonLine(height: 14),
                        ],
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
}

// Skeleton Widgets untuk profile
class SkeletonLine extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonLine({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double radius;

  const SkeletonCircle({
    super.key,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}
