import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login/login_screen.dart'; 

class AdminSetting extends StatelessWidget {
  const AdminSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF641E20),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              alignment: Alignment.centerLeft,
              child: const Text(
                'Pengaturan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Konten
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    // Profil Admin
                    const Column(
                      children: [
                        CircleAvatar(
                          radius: 45,
                          backgroundImage: AssetImage('assets/images/pp.png'),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Fardan Lawang',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text('Admin', style: TextStyle(color: Colors.grey)),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Tentang Aplikasi
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text('Tentang Aplikasi'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    ),

                    const SizedBox(height: 30),

                    // Tombol Logout
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          // Hapus token / session login
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();
                  

                          // Navigasi ke LoginScreen & hapus history
                          Navigator.pushAndRemoveUntil(

                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        icon: const Icon(Icons.logout, color: Colors.white),
                        label: const Text(
                          'Keluar',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB83B3B),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
