import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../admin/admin_main.dart';
import '../guru/guru_dashboard.dart';
import '../siswa/siswa_dashboard.dart';
import '../koordinator/koordinator_dashboard.dart';
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

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final role = prefs.getString('user_role');

    // kasih delay dikit biar smooth
    await Future.delayed(const Duration(seconds: 1));

    // cek apakah widget masih mounted setelah async
    if (!mounted) return;

    if (token != null && role != null) {
      Widget targetPage;
      if (role == 'Siswa') {
        targetPage = const SiswaDashboard();
      } else if (role == 'Guru') {
        targetPage = const GuruDashboard();
      } else if (role == 'Koordinator') {
        targetPage = const KoordinatorDashboard();
      } else {
        targetPage = const AdminMain();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetPage),
      );
    } else {
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
        child: CircularProgressIndicator(color: Colors.orange),
      ),
    );
  }
}
