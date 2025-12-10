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
  String? selectedRole;
  bool isPasswordVisible = false;
  bool isAdminMode = false;
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
      } else if (selectedRole == 'Guru' && isAdminMode) {
        _isNameValid = value.isNotEmpty;
      } else {
        _isGuruCodeValid = value.isNotEmpty;
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

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final role = prefs.getString('user_role');

    if (token != null && role != null && mounted) {
      Widget targetPage;

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
          return;
      }

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
                    size: 60, color: Colors.black87),
                const SizedBox(height: 12),
                Text(
                  'Halo, $userName',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Silakan masuk sebagai:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Column(
                  children: rolesAvailable.map((role) {
                    IconData icon;

                    switch (role) {
                      case 'Pembimbing':
                        icon = Icons.supervisor_account;
                        break;
                      case 'Wali Kelas':
                        icon = Icons.class_;
                        break;
                      case 'Kaprog':
                        icon = Icons.engineering;
                        break;
                      case 'Admin':
                        icon = Icons.admin_panel_settings;
                        break;
                      default:
                        icon = Icons.school;
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: Colors.black54),
                          ),
                          minimumSize: const Size(double.infinity, 50),
                        ),
                        icon: Icon(icon, size: 24, color: Colors.black87),
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
                            case 'Admin':
                              targetPage = const AdminMain();
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
        if (selectedRole == 'Siswa') {
          return 'Nama lengkap atau NISN salah';
        } else if (isAdminMode) {
          return 'Username atau password salah';
        } else {
          return 'Kode guru atau password salah';
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

        if (selectedRole == 'Siswa') {
          await prefs.setString('user_role', 'Siswa');
          await _saveSiswaData(prefs, user);
        } else if (isAdminMode) {
          await prefs.setString('user_role', 'Admin');
        } else {
          await prefs.setString('user_role', 'Guru');
        }

        if (endpoint == '/auth/guru/login' && !isAdminMode) {
          final List<String> rolesAvailable = ['Guru'];
          if (user['is_pembimbing'] == true) rolesAvailable.add('Pembimbing');
          if (user['is_wali_kelas'] == true) rolesAvailable.add('Wali Kelas');
          if (user['is_kaprog'] == true) rolesAvailable.add('Kaprog');
          if (user['is_admin'] == true) rolesAvailable.add('Admin');

          await _showRoleSelectionDialog(
            context,
            rolesAvailable,
            prefs,
            capitalize(user['nama']),
          );
        } else {
          Widget targetPage;
          if (selectedRole == 'Siswa') {
            targetPage = const SiswaMain();
          } else if (isAdminMode) {
            targetPage = const AdminMain();
          } else {
            targetPage = const GuruDashboard();
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
            backgroundColor: Colors.black87,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.black87,
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

      if (kelasId.isNotEmpty) {
        await _fetchAndSaveKelasDetail(prefs, kelasId);
      } else {
        await prefs.setString('user_kelas', 'Kelas Tidak Diketahui');
      }
    } catch (e) {
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
      } else if (isAdminMode) {
        loginToAPI('/auth/login', {
          'username': nameController.text.trim(),
          'password': passwordController.text.trim(),
        });
      } else {
        loginToAPI('/auth/guru/login', {
          'kode_guru': guruController.text.trim(),
          'password': passwordController.text.trim(),
        });
      }
    }
  }

  Widget _buildRoleSelectionScreen() {
    // Ambil ukuran layar
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND PUTIH SELURUH LAYAR (paling bawah)
          Positioned.fill(
            child: Container(
              color: Colors.white,
            ),
          ),

          // 2. CONTAINER PUTIH BESAR (di atas background putih)
          Positioned(
            top: screenHeight * 0.4, // 390dp dari atas
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                border: Border.all(
                  color: const Color(0xFFBEBEBE),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // TEKS "LOGIN SEBAGAI" - DI DALAM CONTAINER PUTIH
                  Container(
                    height: screenHeight * 0.10, // Atur tinggi
                    alignment: Alignment.center,
                    child: Text(
                      'LOGIN SEBAGAI',
                      style: TextStyle(
                        fontSize: screenWidth * 0.065, // Atur ukuran font
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B060A),
                      ),
                    ),
                  ),

                  // Sisanya kosong, card akan ditempatkan di layer lain
                  Expanded(child: Container()),
                ],
              ),
            ),
          ),

          // 3. BACKGROUND GAMBAR (di ATAS container putih)
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.webp',
              fit: BoxFit.cover,
            ),
          ),

          // 4. LOGO SEKOLAH (di atas background gambar)
          Positioned(
            top: screenHeight * 0.15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: screenWidth * 0.38,
                height: screenWidth * 0.38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(screenWidth * 0.19), // 0.38 / 2
                  child: Image.asset(
                    'assets/images/smkn2.webp',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.school,
                          size: screenWidth * 0.3,
                          color: const Color(0xFF3B060A),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // 5. CARD SISWA & GURU (di ATAS background gambar, di luar container)
          Positioned(
            top: screenHeight * 0.53, // Atur posisi card
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Card Siswa (kiri) - 152dp x 184dp
                Container(
                  width: screenWidth * 0.38,
                  height: screenHeight * 0.24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 3,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedRole = 'Siswa';
                          isAdminMode = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(25),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Gambar murid.webp
                          SizedBox(
                            width: screenWidth * 0.25,
                            height: screenWidth * 0.25,
                            child: Image.asset(
                              'assets/images/murid.webp',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  size: screenWidth * 0.2,
                                  color: const Color(0xFF3B060A),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Siswa',
                            style: TextStyle(
                              fontSize: screenWidth * 0.055,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3B060A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Card Guru (kanan) - 152dp x 184dp
                Container(
                  width: screenWidth * 0.38,
                  height: screenHeight * 0.24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 3,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          selectedRole = 'Guru';
                          isAdminMode = false;
                        });
                      },
                      borderRadius: BorderRadius.circular(25),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Gambar guru.webp
                          SizedBox(
                            width: screenWidth * 0.25,
                            height: screenWidth * 0.25,
                            child: Image.asset(
                              'assets/images/guru.webp',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.school,
                                  size: screenWidth * 0.2,
                                  color: const Color(0xFF3B060A),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Guru',
                            style: TextStyle(
                              fontSize: screenWidth * 0.055,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3B060A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
// Widget untuk halaman login (Siswa merah, Guru coklat)
Widget _buildLoginScreen() {
  final isSiswa = selectedRole == 'Siswa';
  final isGuru = selectedRole == 'Guru';

  // Warna yang berbeda untuk Siswa (merah) dan Guru (coklat)
  final backgroundColor = isSiswa ? const Color(0xFF8A0000) : const Color(0xFF3B060A);
  final accentColor = isSiswa ? const Color(0xFF8A0000) : const Color(0xFF3B060A);
  const containerRadius = 40.0;

  return Scaffold(
    backgroundColor: backgroundColor,
    body: Stack(
      children: [
        // Container putih yang menutupi 90% layar
        Positioned(
          top: MediaQuery.of(context).size.height * 0.1,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(containerRadius),
                topRight: Radius.circular(containerRadius),
              ),
            ),
          ),
        ),

        SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),

                          // Logo sekolah
                          Container(
                            width: 140,
                            height: 140,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: Image.asset(
                                'assets/images/smkn2.webp',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isSiswa ? Icons.person : Icons.school,
                                        size: 50,
                                        color: accentColor,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // CONTAINER UTAMA UNTUK SEMUA ELEMEN FORM DAN TOMBOL
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 25,
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  // FORM SISWA
                                  if (isSiswa) ...[
                                    _buildInputField(
                                      label: 'Nama Lengkap',
                                      hint: 'Masukkan Nama Lengkap',
                                      controller: nameController,
                                      isValid: _isNameValid,
                                      accentColor: accentColor,
                                    ),
                                    const SizedBox(height: 15),
                                    _buildInputField(
                                      label: 'NISN',
                                      hint: 'Masukkan NISN (10 digit)',
                                      controller: nisnController,
                                      isValid: _isNisnValid,
                                      isNisn: true,
                                      accentColor: accentColor,
                                    ),
                                  ]

                                  // FORM GURU
                                  else if (isGuru && !isAdminMode) ...[
                                    _buildInputField(
                                      label: 'Kode Guru',
                                      hint: 'Masukkan Kode Guru',
                                      controller: guruController,
                                      isValid: _isGuruCodeValid,
                                      accentColor: accentColor,
                                    ),
                                    const SizedBox(height: 15),
                                    _buildInputField(
                                      label: 'Password',
                                      hint: 'Masukkan Password',
                                      controller: passwordController,
                                      isValid: _isPasswordValid,
                                      isPassword: true,
                                      accentColor: accentColor,
                                    ),
                                    const SizedBox(height: 12),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          isAdminMode = true;
                                          guruController.clear();
                                          nameController.clear();
                                          passwordController.clear();
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Masuk sebagai Admin',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: accentColor,
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]

                                  // FORM ADMIN
                                  else if (isAdminMode) ...[
                                    _buildInputField(
                                      label: 'Username',
                                      hint: 'Masukkan Username',
                                      controller: nameController,
                                      isValid: _isNameValid,
                                      accentColor: accentColor,
                                    ),
                                    const SizedBox(height: 15),
                                    _buildInputField(
                                      label: 'Password',
                                      hint: 'Masukkan Password',
                                      controller: passwordController,
                                      isValid: _isPasswordValid,
                                      isPassword: true,
                                      accentColor: accentColor,
                                    ),
                                  ],

                                  const SizedBox(height: 20),

                                  // Tombol Masuk
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentColor,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        isAdminMode
                                            ? 'Masuk sebagai Admin'
                                            : 'Masuk',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Tombol Ganti Role
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: accentColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          selectedRole = null;
                                          isAdminMode = false;
                                          nameController.clear();
                                          passwordController.clear();
                                          nisnController.clear();
                                          guruController.clear();
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Ganti Role?',
                                        style: TextStyle(
                                          color: accentColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    ),
  );
}

// Widget _buildInputField tetap sama seperti sebelumnya
Widget _buildInputField({
  required String label,
  required String hint,
  required TextEditingController controller,
  required bool isValid,
  required Color accentColor,
  bool isPassword = false,
  bool isNisn = false,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: accentColor,
              width: 2,
            ),
          ),
          counterText: isNisn ? '10 digit angka' : null,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: accentColor,
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
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return selectedRole == null
        ? _buildRoleSelectionScreen()
        : _buildLoginScreen();
  }
}
