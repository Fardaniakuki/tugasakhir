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
import '../siswa/siswa_main.dart';

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

  bool _isNameValid = false;
  bool _isPasswordValid = false;
  bool _isNisnValid = false;
  bool _isGuruCodeValid = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();

    nameController.addListener(_validateName);
    passwordController.addListener(_validatePassword);
    nisnController.addListener(_validateNisn);
    guruController.addListener(_validateGuruCode);
  }

  void _validateName() {
    final value = nameController.text.trim();
    setState(() {
      if (selectedRole == 'Siswa') {
        _isNameValid = value.length >= 3;
      } else {
        _isNameValid = value.isNotEmpty;
      }
    });
  }

  void _validatePassword() {
    final value = passwordController.text.trim();
    setState(() {
      _isPasswordValid = value.length >= 6;
    });
  }

  void _validateNisn() {
    final value = nisnController.text.trim();
    setState(() {
      _isNisnValid = value.length == 10 && _isNumeric(value);
    });
  }

  void _validateGuruCode() {
    final value = guruController.text.trim();
    setState(() {
      _isGuruCodeValid = value.isNotEmpty;
    });
  }

  bool _isNumeric(String value) {
    return double.tryParse(value) != null;
  }

  // ✅ PERBAIKAN: Gunakan pengecekan role yang sama dengan SplashScreen
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final role = prefs.getString('user_role');

    print('🔑 LoginScreen - Check Login Status:');
    print('   Token: ${token != null ? "ADA" : "TIDAK ADA"}');
    print('   Role: $role');

    if (token != null && role != null && mounted) {
      Widget targetPage;
      
      // 🎯 GUNAKAN LOGIC YANG SAMA PERSIS DENGAN SPLASH SCREEN
      switch (role) {
        case 'Siswa':
          targetPage = const SiswaMain();
          break;
        case 'Guru':
          targetPage = const GuruDashboard();
          break;
        case 'Pembimbing':
          targetPage = const PembimbingDashboard();
          break;
        case 'Wali Kelas':
          targetPage = const WaliKelasDashboard();
          break;
        case 'Kaprog':
          targetPage = const KaprogDashboard();
          break;
        case 'Admin':
          targetPage = const AdminMain();
          break;
        default:
          // Jika role tidak dikenali, ke login screen
          print('❌ Role tidak dikenali: $role');
          return;
      }

      print('🎯 Redirect ke: ${targetPage.runtimeType}');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetPage),
      );
    }
  }

  @override
  void dispose() {
    nameController.removeListener(_validateName);
    passwordController.removeListener(_validatePassword);
    nisnController.removeListener(_validateNisn);
    guruController.removeListener(_validateGuruCode);

    nameController.dispose();
    passwordController.dispose();
    nisnController.dispose();
    guruController.dispose();
    super.dispose();
  }

  String capitalize(String s) =>
      s.isNotEmpty ? '${s[0].toUpperCase()}${s.substring(1)}' : '';

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
                const Icon(Icons.account_circle,
                    size: 60, color: Color(0xFF5B1A1A)),
                const SizedBox(height: 12),
                Text(
                  'Halo, $userName',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
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
                        label:
                            Text(role, style: const TextStyle(fontSize: 16)),
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

                          // ✅ SIMPAN ROLE YANG DIPILIH
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

  String _getUserFriendlyError(
      String endpoint, int statusCode, String responseBody) {
    try {
      final errorData = jsonDecode(responseBody);
      final errorCode = errorData['error']['code'] ?? '';
      final errorMessage = errorData['error']['message'] ?? '';

      if (endpoint == '/auth/siswa/login') {
        switch (errorCode) {
          case 'SISWA_INVALID_CREDENTIALS':
            return 'Nama lengkap atau NISN salah';
          case 'SISWA_NOT_FOUND':
            return 'Data siswa tidak ditemukan';
          default:
            return 'Nama lengkap atau NISN tidak valid';
        }
      } else if (endpoint == '/auth/guru/login') {
        switch (errorCode) {
          case 'GURU_INVALID_CREDENTIALS':
            return 'Kode guru atau password salah';
          case 'GURU_NOT_FOUND':
            return 'Data guru tidak ditemukan';
          default:
            return 'Kode guru atau password tidak valid';
        }
      } else if (endpoint == '/auth/login') {
        switch (errorCode) {
          case 'ADMIN_INVALID_CREDENTIALS':
            return 'Username atau password salah';
          case 'USER_NOT_FOUND':
            return 'User tidak ditemukan';
          default:
            return 'Username atau password tidak valid';
        }
      }

      if (statusCode == 401) {
        switch (selectedRole) {
          case 'Siswa':
            return 'Nama lengkap atau NISN salah';
          case 'Guru':
            return 'Kode guru atau password salah';
          default:
            return 'Username atau password salah';
        }
      } else if (statusCode == 404) {
        return 'Data tidak ditemukan';
      } else if (statusCode == 500) {
        return 'Terjadi kesalahan server';
      }

      return errorMessage.isNotEmpty ? errorMessage : 'Terjadi kesalahan';
    } catch (e) {
      return 'Terjadi kesalahan, coba lagi';
    }
  }

  Future<void> loginToAPI(String endpoint, Map<String, dynamic> body) async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final url = Uri.parse('$baseUrl$endpoint');

    print('🔐 Login Attempt:');
    print('   URL: $url');
    print('   Role: $selectedRole');
    print('   Body: $body');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('📡 Response Status: ${response.statusCode}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final refreshToken = data['refresh_token'];
        final user = data['user'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', token);
        await prefs.setString('refresh_token', refreshToken);

        // ✅ PERBAIKAN: Pastikan role disimpan dengan benar
        if (selectedRole == 'Siswa') {
          await prefs.setString('user_role', 'Siswa');
          await _saveSiswaData(prefs, user);
        } else if (selectedRole == 'Guru') {
          // Untuk guru, role akan disimpan berdasarkan pilihan di dialog
          await prefs.setString('user_role', 'Guru');
        } else {
          await prefs.setString('user_role', 'Admin');
        }

        print('💾 Data disimpan - Role: ${prefs.getString('user_role')}');

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
          // ✅ PERBAIKAN: Gunakan selectedRole bukan user['role'] dari API
          if (selectedRole == 'Siswa') {
            targetPage = const SiswaMain();
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

        final errorMessage =
            _getUserFriendlyError(endpoint, response.statusCode, response.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveSiswaData(
      SharedPreferences prefs, Map<String, dynamic> user) async {
    try {
      String nisn = '';
      if (user['nisn'] != null) {
        nisn = user['nisn'].toString();
      } else if (user['NISN'] != null) {
        nisn = user['NISN'].toString();
      } else if (user['nomor_induk'] != null) {
        nisn = user['nomor_induk'].toString();
      } else if (user['no_induk'] != null) {
        nisn = user['no_induk'].toString();
      }

      final String nama =
          user['nama_lengkap'] ?? user['nama'] ?? user['full_name'] ?? 'Siswa';
      final String kelasId = (user['kelas_id'] ?? '').toString();

      await prefs.setString('user_name', nama);
      await prefs.setString('user_nisn', nisn);
      await prefs.setString('user_kelas_id', kelasId);

      print('💾 Data siswa disimpan:');
      print('   Nama: $nama');
      print('   NISN: $nisn');
      print('   Kelas ID: $kelasId');

      if (kelasId.isNotEmpty) {
        await _fetchAndSaveKelasDetail(prefs, kelasId);
      } else {
        await prefs.setString('user_kelas', 'Kelas Tidak Diketahui');
      }

      if (user['alamat'] != null) {
        await prefs.setString('user_alamat', user['alamat'].toString());
      }
      if (user['no_telp'] != null) {
        await prefs.setString('user_no_telp', user['no_telp'].toString());
      }
      if (user['tanggal_lahir'] != null) {
        await prefs.setString(
            'user_tanggal_lahir', user['tanggal_lahir'].toString());
      }
    } catch (e) {
      print('❌ Error menyimpan data siswa: $e');
      await prefs.setString('user_kelas', 'Kelas Tidak Diketahui');
    }
  }

  Future<void> _fetchAndSaveKelasDetail(
      SharedPreferences prefs, String kelasId) async {
    try {
      final token = prefs.getString('access_token');

      if (token == null) {
        return;
      }

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas/$kelasId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final kelasData = jsonDecode(response.body);

        String kelasName = 'Kelas Tidak Diketahui';

        if (kelasData['data'] != null) {
          kelasName = kelasData['data']['nama'] ?? 'Kelas Tidak Diketahui';
        }

        await prefs.setString('user_kelas', kelasName);
        print('💾 Detail kelas disimpan: $kelasName');
      } else {
        await prefs.setString('user_kelas', 'Kelas $kelasId');
      }
    } catch (e) {
      await prefs.setString('user_kelas', 'Kelas $kelasId');
    }
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      if (selectedRole == 'Siswa') {
        loginToAPI('/auth/siswa/login', {
          'nama_lengkap': nameController.text.trim(),
          'nisn': nisnController.text.trim(),
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
                  
                  // ROLE TAB BAR - Design yang sudah konsisten
                  RoleTabBar(
                    selected: selectedRole,
                    onChanged: (val) {
                      setState(() {
                        selectedRole = val;
                        _validateName();
                        _validatePassword();
                        _validateNisn();
                        _validateGuruCode();
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // NAME FIELD
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      isSiswa ? 'Nama Lengkap' : (isGuru ? 'Kode Guru' : 'Nama'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  if (isSiswa)
                    _buildInputField(
                      hint: 'Masukkan Nama Lengkap',
                      controller: nameController,
                      isValid: _isNameValid,
                    )
                  else if (isGuru)
                    _buildInputField(
                      hint: 'Masukkan Kode Guru',
                      controller: guruController,
                      isValid: _isGuruCodeValid,
                    )
                  else
                    _buildInputField(
                      hint: 'Masukkan Username',
                      controller: nameController,
                      isValid: _isNameValid,
                    ),
                  const SizedBox(height: 16),
                  
                  // PASSWORD or NISN FIELD
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
                    _buildInputField(
                      hint: 'Masukkan NISN (10 digit)',
                      controller: nisnController,
                      isValid: _isNisnValid,
                      isNisn: true,
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
                    _buildInputField(
                      hint: 'Password',
                      controller: passwordController,
                      isValid: _isPasswordValid,
                      isPassword: true,
                    ),
                  ],
                  const SizedBox(height: 16),
                  
                  // LOGIN BUTTON
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

  // Helper method untuk input field yang konsisten
  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    required bool isValid,
    bool isPassword = false,
    bool isNisn = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNisn ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.black),
      maxLength: isNisn ? 10 : null,
      obscureText: isPassword && !isPasswordVisible,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        counterText: isNisn ? '10 digit angka' : null,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black,
                ),
                onPressed: () {
                  setState(() {
                    isPasswordVisible = !isPasswordVisible;
                  });
                },
              )
            : null,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Tidak boleh kosong';
        }
        if (!isValid) {
          if (isNisn) return 'NISN harus 10 digit angka';
          if (isPassword) return 'Password minimal 6 karakter';
          return 'Input tidak valid';
        }
        return null;
      },
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