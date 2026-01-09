import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tes_flutter/screens/koordinator/koordinator_main.dart';

import 'package:tes_flutter/screens/login/login_screen.dart';
import 'package:tes_flutter/screens/admin/admin_main.dart';
import 'package:tes_flutter/screens/guru/guru_dashboard.dart';
import 'package:tes_flutter/screens/siswa/siswa_main.dart';
import 'package:tes_flutter/screens/pembimbing/pembimbing_dashboard.dart';
import 'package:tes_flutter/screens/walikelas/wali_kelas_main.dart';
import 'package:tes_flutter/screens/kapro/kaprog_dashboard.dart';

class SplashScreen1 extends StatefulWidget {
  const SplashScreen1({super.key});

  @override
  State<SplashScreen1> createState() => _SplashScreen1State();
}

class _SplashScreen1State extends State<SplashScreen1>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(seconds: 3));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final role = prefs.getString('user_role');

    print('🔑 Splash Screen Check:');
    print('   Token: ${token != null ? "ADA" : "TIDAK ADA"}');
    print('   Role: $role');

    Widget nextPage;

    if (token != null && role != null) {
      // 🎯 PERBAIKAN: Handle semua role yang mungkin
      switch (role) {
        case 'Siswa':
          nextPage = const SiswaMain();
          break;
        case 'Guru':
          nextPage = const GuruDashboard();
          break;
        case 'Pembimbing':
          nextPage = const PembimbingDashboard();
          break;
        case 'Wali Kelas':
          nextPage = const WaliKelasMain();
          break;
        case 'Kaprog':
          nextPage = const KaprogDashboard();
          break;
        case 'Koordinator':
          nextPage = const KoordinatorMain();
          break;
        case 'Admin':
          nextPage = const AdminMain();
          break;
        default:
          // 🚨 JIKA ROLE TIDAK DIKENAL, KE LOGIN LAGI
          print('❌ Role tidak dikenali: $role, redirect ke login');
          nextPage = const LoginScreen();
      }
    } else {
      // Kalau belum login
      nextPage = const LoginScreen();
    }

    print('🎯 Redirect ke: ${nextPage.runtimeType}');

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.translate(
                  offset: const Offset(-20, 0),
                  child: Lottie.asset(
                    'assets/animations/book.json',
                    controller: _controller,
                    width: 295,
                    onLoaded: (composition) {
                      _controller
                        ..duration = composition.duration * 0.8
                        ..repeat();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}