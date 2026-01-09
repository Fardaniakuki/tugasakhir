import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../admin/admin_main.dart';
import '../guru/guru_dashboard.dart';
import '../siswa/dashboard/siswa_dashboard.dart';
import '../koordinator/koordinator_main.dart';
import 'login_screen.dart';

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // ADD THIS FUNCTION untuk clear data login
  Future<void> _clearLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_role');
    // Clear semua data user lainnya jika ada
    await prefs.remove('user_data');
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final role = prefs.getString('user_role');

    // DEBUG: Print stored data
    print('🔐 Stored Token: $token');
    print('🔐 Stored Role: $role');

    // Kasih delay dikit biar smooth
    await Future.delayed(const Duration(seconds: 1));

    // Cek apakah widget masih mounted setelah async
    if (!mounted) return;

    if (token != null && role != null) {
      Widget targetPage;
      switch (role) {
        case 'Siswa':
          targetPage = const SiswaDashboard();
          break;
        case 'Guru':
          targetPage = const GuruDashboard();
          break;
        case 'Koordinator':
          targetPage = const KoordinatorMain();
          break;
        case 'Pembimbing':
        case 'Wali Kelas':
        case 'Kaprog':
          targetPage = const GuruDashboard();
          break;
        default:
          targetPage = const AdminMain();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetPage),
      );
    } else {
      // Jika tidak ada token atau role, pastikan data dibersihkan
      await _clearLoginData();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF641E20),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Memeriksa login...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}