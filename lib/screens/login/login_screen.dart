import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tes_flutter/screens/kapro/kaprog_dashboard.dart';

import '../admin/admin_main.dart';
import '../guru/guru_dashboard.dart';
import '../pembimbing/pembimbing_dashboard.dart';
import '../walikelas/wali_kelas_dashboard.dart';
import '../siswa/siswa_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'Admin';
  bool isPasswordVisible = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nisnController = TextEditingController();
  final TextEditingController guruController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final role = prefs.getString('user_role');

    if (token != null && role != null && mounted) {
      Widget targetPage;
      switch (role) {
        case 'Siswa':
          targetPage = const SiswaDashboard();
          break;
        case 'Guru':
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
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    passwordController.dispose();
    nisnController.dispose();
    guruController.dispose();
    super.dispose();
  }

  /// Capitalize first letter
  String capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '';

  /// 🔥 POPUP pilih peran Guru (klik luar area bisa close)
  Future<void> _showRoleSelectionDialog(
    BuildContext context,
    List<String> rolesAvailable,
    SharedPreferences prefs,
    String userName,
  ) async {
    if (!mounted) return;
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Padding(
            padding: const EdgeInsets.all(35),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle, size: 60, color: Color(0xFF5B1A1A)),
                const SizedBox(height: 12),
                Text(
                  'Halo, $userName',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Silakan masuk sebagai.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Column(
                  children: rolesAvailable.map((role) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B1A1A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        label: Text(role, style: const TextStyle(fontSize: 16)),
                        onPressed: () async {
                          Navigator.pop(context);
                          Widget targetPage;
                          switch (role) {
                            case 'Pembimbing':
                              targetPage = const PembimbingDashboard();
                              break;
                            case 'Wali Kelas':
                              targetPage = const WaliKelasDashboard();
                              break;
                            case 'Kaprog':
                              targetPage = const KaprogDashboard();
                              break;
                            default:
                              targetPage = const GuruDashboard();
                          }

                          await prefs.setString('user_role', role);
                          if (!mounted) return;
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => targetPage),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> loginToAPI(String endpoint, Map<String, dynamic> body) async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final url = Uri.parse('$baseUrl$endpoint');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final refreshToken = data['refresh_token'];
        final user = data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        await prefs.setString('refresh_token', refreshToken);
        await prefs.setString('user_role', user['role']);

        if (endpoint == '/auth/guru/login') {
          final List<String> rolesAvailable = ['Guru'];
          if (user['is_pembimbing'] == true) rolesAvailable.add('Pembimbing');
          if (user['is_wali_kelas'] == true) rolesAvailable.add('Wali Kelas');
          if (user['is_kaprog'] == true) rolesAvailable.add('Kaprog');

          await _showRoleSelectionDialog(
            context,
            rolesAvailable,
            prefs,
            capitalize(user['nama']),
          );
        } else {
          Widget targetPage;
          if (selectedRole == 'Siswa') {
            targetPage = const SiswaDashboard();
          } else if (selectedRole == 'Guru') {
            targetPage = const GuruDashboard();
          } else {
            targetPage = const AdminMain();
          }

          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => targetPage),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login gagal: ${response.body}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      if (selectedRole == 'Siswa') {
        loginToAPI('/auth/login', {
          'username': nameController.text.trim(),
          'password': nisnController.text.trim(),
        });
      } else if (selectedRole == 'Guru') {
        loginToAPI('/auth/guru/login', {
          'kode_guru': guruController.text.trim(),
          'password': passwordController.text.trim(),
        });
      } else {
        loginToAPI('/auth/login', {
          'username': nameController.text.trim(),
          'password': passwordController.text.trim(),
        });
      }
    }
  }

  Widget buildInputField({
    required String hint,
    required TextEditingController controller,
    required TextInputType inputType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Tidak boleh kosong' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSiswa = selectedRole == 'Siswa';
    final isGuru = selectedRole == 'Guru';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF641E20),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24.0,
              right: 24.0,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Image.asset(
                      'assets/images/ino.webp',
                      width: 240,
                    ),
                  ),
                  const SizedBox(height: 60),
                  RoleTabBar(
                    selected: selectedRole,
                    onChanged: (val) {
                      setState(() {
                        selectedRole = val;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      isSiswa
                          ? 'Nama Lengkap'
                          : (isGuru ? 'Kode Guru' : 'Nama'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  buildInputField(
                    hint: isSiswa
                        ? 'Masukkan Nama Lengkap'
                        : (isGuru ? 'Masukkan Kode Guru' : 'Masukkan Nama'),
                    controller: isSiswa
                        ? nameController
                        : (isGuru ? guruController : nameController),
                    inputType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  if (isSiswa) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Text(
                        'NISN',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    buildInputField(
                      hint: 'Masukkan NISN',
                      controller: nisnController,
                      inputType: TextInputType.number,
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 4.0),
                      child: Text(
                        'Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: const TextStyle(color: Colors.black54),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty
                              ? 'Tidak boleh kosong'
                              : null,
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      minimumSize: const Size(double.infinity, 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Masuk',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoleTabBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const RoleTabBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final roles = ['Admin', 'Guru', 'Siswa'];
    final selectedIndex = roles.indexOf(selected);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tabWidth = constraints.maxWidth / roles.length;

        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment(
                  -1 + (2 / (roles.length - 1)) * selectedIndex,
                  0,
                ),
                child: Container(
                  width: tabWidth - 8,
                  margin:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              Row(
                children: roles.map((role) {
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onChanged(role),
                      child: Center(
                        child: Text(
                          role,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: selected == role
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
