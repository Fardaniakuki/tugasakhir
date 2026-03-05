import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

// Import screens
import 'package:tes_flutter/screens/kapro/kaprog_main_screen.dart';
import 'package:tes_flutter/screens/koordinator/koordinator_main.dart';
import '../admin/admin_main.dart';
import '../guru/guru_dashboard.dart';
import '../pembimbing/main_dashboard.dart';
import '../walikelas/walikelas_main_screen.dart';
import '../siswa/siswa_main.dart';

// Import dialog
import 'role_selection_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  String? selectedRole;
  bool isPasswordVisible = false;
  bool isAdminMode = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Tambahkan variabel untuk menyimpan data sekolah
  Map<String, dynamic>? _sekolahData;
  bool _isLoadingSekolah = false;

  // Animation controller untuk efek geter
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nisnController = TextEditingController();
  final TextEditingController guruController = TextEditingController();

  bool _isNameValid = false;
  bool _isPasswordValid = false;
  bool _isNisnValid = false;
  bool _isGuruCodeValid = false;

  // Untuk menampilkan pesan error di bawah field
  String? _nameErrorText;
  String? _passwordErrorText;
  String? _nisnErrorText;
  String? _guruCodeErrorText;

  @override
  void initState() {
    super.initState();

    // Inisialisasi animasi geter
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );

    _checkLoginStatus();
    _loadSekolahData(); // Panggil fungsi untuk load data sekolah

    nameController.addListener(_validateName);
    passwordController.addListener(_validatePassword);
    nisnController.addListener(_validateNisn);
    guruController.addListener(_validateGuruCode);
  }

  // Fungsi untuk mengambil data sekolah
  Future<void> _loadSekolahData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSekolah = true;
    });

    try {
      await dotenv.load(fileName: '.env');
      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';

      debugPrint(
          '🔍 Mencoba mengambil data sekolah dari: $baseUrl/api/sekolah');

      final response = await http.get(
        Uri.parse('$baseUrl/api/sekolah'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Data sekolah berhasil diambil');
        debugPrint('🏫 Nama Sekolah: ${data['data']?['nama_sekolah']}');
        debugPrint('🖼️ Logo URL: ${data['data']?['logo_url']}');

        setState(() {
          _sekolahData = data['data'];
          _isLoadingSekolah = false;
        });
      } else if (mounted) {
        debugPrint(
            '⚠️ Gagal mengambil data sekolah. Status: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          debugPrint('Response body: ${response.body}');
        }
        setState(() {
          _isLoadingSekolah = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading sekolah data: $e');
      if (mounted) {
        setState(() {
          _isLoadingSekolah = false;
        });
      }
    }
  }

  // Fungsi untuk mengaktifkan geter pada HP
  Future<void> _triggerVibration() async {
    try {
      final bool hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        Vibration.vibrate(duration: 300);
      }
    } catch (e) {
      // Abaikan error jika vibrasi tidak tersedia
    }
  }

  void _validateName() {
    final value = nameController.text.trim();
    setState(() {
      if (selectedRole == 'Siswa') {
        _isNameValid = value.length >= 3;
        _nameErrorText = !_isNameValid && value.isNotEmpty
            ? 'Nama lengkap minimal 3 karakter'
            : null;
      } else if (selectedRole == 'Guru' && isAdminMode) {
        _isNameValid = value.isNotEmpty;
        _nameErrorText = !_isNameValid && value.isNotEmpty
            ? 'Nama tidak boleh kosong'
            : null;
      } else {
        _isGuruCodeValid = value.isNotEmpty;
      }
    });
  }

  void _validatePassword() {
    final value = passwordController.text.trim();
    setState(() {
      _isPasswordValid = value.length >= 6;
      _passwordErrorText = !_isPasswordValid && value.isNotEmpty
          ? 'Kata sandi minimal 6 karakter'
          : null;
    });
  }

  void _validateNisn() {
    final value = nisnController.text.trim();
    setState(() {
      _isNisnValid = value.length == 10 && _isNumeric(value);
      _nisnErrorText = !_isNisnValid && value.isNotEmpty
          ? 'NISN harus 10 digit angka'
          : null;
    });
  }

  void _validateGuruCode() {
    final value = guruController.text.trim();
    setState(() {
      _isGuruCodeValid = value.isNotEmpty && _isNumeric(value);
      _guruCodeErrorText = !_isGuruCodeValid && value.isNotEmpty
          ? 'Kode guru harus berupa angka'
          : null;
    });
  }

  bool _isNumeric(String value) {
    if (value.isEmpty) {
      return false;
    }
    final numericRegex = RegExp(r'^[0-9]+$');
    return numericRegex.hasMatch(value);
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final role = prefs.getString('user_role');

    if (token != null && role != null && mounted) {
      Widget targetPage;
      final roleLower = role.toLowerCase();

      switch (roleLower) {
        case 'siswa':
          targetPage = const SiswaMain();
          break;
        case 'guru':
          targetPage = const GuruDashboard();
          break;
        case 'pembimbing':
          targetPage = const PembimbingMainScreen();
          break;
        case 'wali kelas':
        case 'wali_kelas':
          targetPage = const WalikelasMainScreen();
          break;
        case 'kaprog':
        case 'kepala konsentrasi keahlian':
        case 'kepala_konsentrasi_keahlian':
          targetPage = const KaprogMainScreen();
          break;
        case 'admin':
          targetPage = const AdminMain();
          break;
        case 'koordinator':
          targetPage = const KoordinatorMain();
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

    _shakeController.dispose();

    nameController.dispose();
    passwordController.dispose();
    nisnController.dispose();
    guruController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchGuruProfile(
      SharedPreferences prefs) async {
    try {
      final token = prefs.getString('access_token');
      if (token == null) return null;

      final userId = prefs.getInt('user_id');
      final kodeGuru = prefs.getString('kode_guru');

      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';

      if (userId != null) {
        final searchTerm = kodeGuru ?? '';
        final url = '$baseUrl/api/guru?search=$searchTerm&limit=10';

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success'] == true &&
              data['data'] != null &&
              data['data'] is Map) {
            final dataMap = data['data'] as Map<String, dynamic>;
            if (dataMap['data'] != null && dataMap['data'] is List) {
              final guruList = dataMap['data'] as List;
              if (guruList.isNotEmpty) {
                for (final guru in guruList) {
                  final guruUserId = guru['user_id'];
                  if (guruUserId == userId) {
                    return guru;
                  }
                }
                if (kodeGuru != null && kodeGuru.isNotEmpty) {
                  for (final guru in guruList) {
                    final guruKode = guru['kode_guru'];
                    if (guruKode == kodeGuru) {
                      return guru;
                    }
                  }
                }
                return guruList.first;
              }
            }
          }
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> _showRoleSelectionDialog(
    BuildContext context,
    Map<String, dynamic> userData,
    SharedPreferences prefs,
    String userName,
  ) async {
    if (!mounted) return;

    final guruProfile = await _fetchGuruProfile(prefs);
    final Map<String, dynamic> combinedData = Map.from(userData);
    if (guruProfile != null) {
      guruProfile.forEach((key, value) {
        if (value != null) {
          combinedData[key] = value;
        }
      });
    }

    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return RoleSelectionDialog(
          userData: combinedData,
          userName: userName,
          onRoleSelected: (role) async {
            String roleToSave = role;
            if (role == 'Kepala Konsentrasi Keahlian') {
              roleToSave = 'kaprog';
            }

            final roleLower = roleToSave.toLowerCase();
            await prefs.setString('user_role', roleLower);
            await _saveAllUserData(prefs, combinedData, roleToSave);

            if (!mounted) return;

            Widget targetPage;
            switch (roleLower) {
              case 'pembimbing':
                targetPage = const PembimbingMainScreen();
                break;
              case 'wali kelas':
              case 'wali_kelas':
                targetPage = const WalikelasMainScreen();
                break;
              case 'kaprog':
              case 'kepala konsentrasi keahlian':
                targetPage = const KaprogMainScreen();
                break;
              case 'admin':
                targetPage = const AdminMain();
                break;
              case 'koordinator':
                targetPage = const KoordinatorMain();
                break;
              case 'guru':
              default:
                targetPage = const GuruDashboard();
            }

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => targetPage),
            );
          },
        );
      },
    );
  }

  Future<void> _saveAllUserData(SharedPreferences prefs,
      Map<String, dynamic> userData, String role) async {
    try {
      await prefs.setInt('user_id', userData['id'] ?? 0);
      await prefs.setString('username', userData['username'] ?? '');
      await prefs.setString(
          'user_name', userData['nama'] ?? userData['name'] ?? 'User');

      if (userData['kode_guru'] != null) {
        await prefs.setString('kode_guru', userData['kode_guru'].toString());
      }

      if (userData['nip'] != null) {
        await prefs.setString('user_nip', userData['nip'].toString());
      }

      if (userData['no_telp'] != null) {
        await prefs.setString('user_phone', userData['no_telp'].toString());
      }

      if (userData['is_wali_kelas'] != null) {
        await prefs.setBool('is_wali_kelas', userData['is_wali_kelas'] == true);
      }
      if (userData['is_pembimbing'] != null) {
        await prefs.setBool('is_pembimbing', userData['is_pembimbing'] == true);
      }
      if (userData['is_kaprog'] != null) {
        await prefs.setBool('is_kaprog', userData['is_kaprog'] == true);
      }
      if (userData['is_koordinator'] != null) {
        await prefs.setBool(
            'is_koordinator', userData['is_koordinator'] == true);
      }
    } catch (e) {
      // Error handling
    }
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

      if (errorMessage.isNotEmpty) {
        return errorMessage;
      }

      if (endpoint == '/auth/siswa/login') {
        return 'Nama lengkap atau NISN salah';
      } else if (endpoint == '/auth/guru/login') {
        return 'Kode guru atau password salah';
      } else if (endpoint == '/auth/login') {
        return 'Username atau password salah';
      }

      return 'Login gagal';
    } catch (e) {
      if (endpoint == '/auth/siswa/login') {
        return 'Nama lengkap atau NISN salah';
      } else if (endpoint == '/auth/guru/login') {
        return 'Kode guru atau password salah';
      } else if (endpoint == '/auth/login') {
        return 'Username atau password salah';
      }
      return 'Login gagal';
    }
  }

  // Fungsi untuk menampilkan notifikasi error
  void _showErrorNotification(String message) {
    // Jalankan animasi geter
    _shakeController.forward(from: 0);

    // Jalankan geter pada HP
    _triggerVibration();

    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    final isSiswa = selectedRole == 'Siswa';
    final accentColor =
        isSiswa ? const Color(0xFF8A0000) : const Color(0xFF3B060A);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Login Gagal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: accentColor,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Tutup',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> loginToAPI(String endpoint, Map<String, dynamic> body) async {
    await dotenv.load(fileName: '.env');

    final baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
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
        await prefs.setInt('user_id', user['id'] ?? 0);
        await prefs.setString('user_name', user['nama'] ?? 'Guru');

        String kodeGuru = '';

        if (user['kode_guru'] != null) {
          kodeGuru = user['kode_guru'].toString();
          await prefs.setString('kode_guru', kodeGuru);
        } else if (user['username'] != null) {
          kodeGuru = user['username'].toString();
          await prefs.setString('kode_guru', kodeGuru);
        } else {
          if (selectedRole == 'Guru' && !isAdminMode) {
            kodeGuru = guruController.text.trim();
            await prefs.setString('kode_guru', kodeGuru);
          }
        }

        if (user['nip'] != null) {
          await prefs.setString('user_nip', user['nip'].toString());
        }

        if (selectedRole == 'Siswa') {
          await prefs.setString('user_role', 'Siswa');
          await _saveSiswaData(prefs, user);
        } else if (isAdminMode) {
          await prefs.setString('user_role', 'Admin');
        } else {
          await prefs.setString('user_role', 'Guru');
        }

        if (endpoint == '/auth/guru/login' && !isAdminMode) {
          final userName = (user['nama'] ?? 'Guru').toString();
          final capitalized = userName.isNotEmpty
              ? '${userName[0].toUpperCase()}${userName.substring(1)}'
              : 'Guru';
          await _showRoleSelectionDialog(context, user, prefs, capitalized);
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

        setState(() {
          if (selectedRole == 'Siswa') {
            _isNameValid = false;
            _isNisnValid = false;
            _nameErrorText = 'Nama lengkap atau NISN salah';
            _nisnErrorText = 'Periksa kembali NISN Anda';
          } else if (isAdminMode) {
            _isNameValid = false;
            _isPasswordValid = false;
            _nameErrorText = 'Username atau password salah';
            _passwordErrorText = 'Password yang Anda masukkan salah';
          } else {
            _isGuruCodeValid = false;
            _isPasswordValid = false;
            _guruCodeErrorText = 'Kode guru atau password salah';
            _passwordErrorText = 'Password yang Anda masukkan salah';
          }
        });

        final errorMessage =
            _getUserFriendlyError(endpoint, response.statusCode, response.body);
        _showErrorNotification(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage = 'Tidak dapat terhubung ke server';
      } else if (e.toString().contains('Timeout')) {
        errorMessage = 'Koneksi timeout, periksa jaringan Anda';
      } else {
        if (selectedRole == 'Siswa') {
          errorMessage = 'Nama lengkap atau NISN salah';
        } else if (isAdminMode) {
          errorMessage = 'Username atau password salah';
        } else {
          errorMessage = 'Kode guru atau password salah';
        }
      }

      _showErrorNotification(errorMessage);
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
      }

      final String nama =
          user['nama_lengkap'] ?? user['nama'] ?? user['full_name'] ?? 'Siswa';
      final String kelasId = (user['kelas_id'] ?? '').toString();

      await prefs.setString('user_name', nama);
      await prefs.setString('user_nisn', nisn);
      await prefs.setString('user_kelas_id', kelasId);
      await prefs.setInt('user_id', user['id'] ?? 0);
      await prefs.setString('username', user['username'] ?? '');

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
      if (token == null) return;

      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      final response = await http.get(
        Uri.parse('$baseUrl/api/kelas/$kelasId'),
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
    setState(() {
      _nameErrorText = null;
      _passwordErrorText = null;
      _nisnErrorText = null;
      _guruCodeErrorText = null;
    });

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
    } else {
      _shakeController.forward(from: 0);
      _triggerVibration();
    }
  }

  Widget _buildRoleSelectionScreen() {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: Colors.white,
            ),
          ),
          Positioned(
            top: screenHeight * 0.4,
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
                  Container(
                    height: screenHeight * 0.10,
                    alignment: Alignment.center,
                    child: Text(
                      'MASUK SEBAGAI',
                      style: TextStyle(
                        fontSize: screenWidth * 0.065,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B060A),
                      ),
                    ),
                  ),
                  Expanded(child: Container()),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_background.webp',
              fit: BoxFit.cover,
            ),
          ),
// ========== LOGO SEKOLAH + MASKOT INO ==========
          Positioned(
            top: screenHeight * 0.15,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo Sekolah (SMKN2) - dengan lingkaran putih
                  Container(
                    width: screenWidth * 0.3,
                    height: screenWidth * 0.3,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(screenWidth * 0.15),
                      child: _buildSchoolLogo(screenWidth),
                    ),
                  ),

                  // Spacer kecil antara logo dan maskot
                  const SizedBox(width: 15),

                  // Maskot INO (di kanan) - TANPA LINGKARAN PUTIH
                  SizedBox(
                    width: screenWidth * 0.4,
                    height: screenWidth * 0.4,
                    // HAPUS BoxDecoration dengan shape circle
                    // LANGSUNG ClipRRect tanpa background putih
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(15), // Sudut sedikit melengkung
                      child: Image.asset(
                        'assets/images/ino.webp', // Maskot INO
                        fit: BoxFit.contain, // contain agar tidak terpotong
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('❌ Gagal memuat maskot INO: $error');
                          return Container(
                            color:
                                const Color(0xFF3B060A).withValues(alpha: 0.1),
                            child: Center(
                              child: Icon(
                                Icons.emoji_emotions,
                                size: screenWidth * 0.15,
                                color: const Color(0xFF3B060A)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: screenHeight * 0.53,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  width: screenWidth * 0.38,
                  height: screenHeight * 0.24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
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
                Container(
                  width: screenWidth * 0.38,
                  height: screenHeight * 0.24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
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

  // Widget untuk logo di halaman pemilihan role
  Widget _buildSchoolLogo(double screenWidth) {
    if (_isLoadingSekolah) {
      debugPrint('⏳ Loading logo dari server...');
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B060A)),
          ),
        ),
      );
    }

    if (_sekolahData != null &&
        _sekolahData!['logo_url'] != null &&
        _sekolahData!['logo_url'].toString().isNotEmpty) {
      debugPrint('🖼️ Menampilkan logo dari URL: ${_sekolahData!['logo_url']}');
      debugPrint('📋 Data diambil dari API sekolah (Admin)');

      return Image.network(
        _sekolahData!['logo_url'],
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            debugPrint('✅ Logo berhasil dimuat dari server');
            return child;
          }
          debugPrint(
              '⏳ Memuat logo dari server... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
          return Container(
            color: Colors.grey[300],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF3B060A)),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Gagal memuat logo dari server: $error');
          debugPrint('⚠️ Fallback ke logo lokal assets/images/smkn2.webp');
          return Image.asset(
            'assets/images/smkn2.webp',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Gagal memuat logo lokal, fallback ke icon');
              return Center(
                child: Icon(
                  Icons.school,
                  size: screenWidth * 0.3,
                  color: const Color(0xFF3B060A),
                ),
              );
            },
          );
        },
      );
    }

    debugPrint('⚠️ Tidak ada logo_url dari server, menggunakan logo lokal');
    debugPrint('📁 Menggunakan logo dari: assets/images/smkn2.webp');

    return Image.asset(
      'assets/images/smkn2.webp',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Gagal memuat logo lokal, fallback ke icon');
        return Center(
          child: Icon(
            Icons.school,
            size: screenWidth * 0.3,
            color: const Color(0xFF3B060A),
          ),
        );
      },
    );
  }

  Widget _buildLoginScreen() {
    final isSiswa = selectedRole == 'Siswa';
    final isGuru = selectedRole == 'Guru';

    final backgroundColor =
        isSiswa ? const Color(0xFF8A0000) : const Color(0xFF3B060A);
    final accentColor =
        isSiswa ? const Color(0xFF8A0000) : const Color(0xFF3B060A);
    const containerRadius = 40.0;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: Stack(
          children: [
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: const BoxDecoration(
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
                              Container(
                                width: 140,
                                height: 140,
                                margin: const EdgeInsets.only(bottom: 20),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: _buildLoginScreenLogo(
                                      isSiswa, accentColor),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
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
                                      if (isSiswa) ...[
                                        _buildInputField(
                                          label: 'Nama Lengkap',
                                          hint: 'Masukkan Nama Lengkap',
                                          controller: nameController,
                                          isValid: _isNameValid,
                                          errorText: _nameErrorText,
                                          accentColor: accentColor,
                                        ),
                                        const SizedBox(height: 15),
                                        _buildInputField(
                                          label: 'NISN',
                                          hint: 'Masukkan NISN (10 digit)',
                                          controller: nisnController,
                                          isValid: _isNisnValid,
                                          errorText: _nisnErrorText,
                                          isNisn: true,
                                          accentColor: accentColor,
                                        ),
                                      ] else if (isGuru && !isAdminMode) ...[
                                        _buildGuruCodeField(
                                          label: 'Kode Guru',
                                          hint: 'Masukkan Kode Guru',
                                          controller: guruController,
                                          isValid: _isGuruCodeValid,
                                          errorText: _guruCodeErrorText,
                                          accentColor: accentColor,
                                        ),
                                        const SizedBox(height: 15),
                                        _buildInputField(
                                          label: 'Kata Sandi',
                                          hint: 'Masukkan Kata Sandi',
                                          controller: passwordController,
                                          isValid: _isPasswordValid,
                                          errorText: _passwordErrorText,
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
                                              _nameErrorText = null;
                                              _passwordErrorText = null;
                                              _guruCodeErrorText = null;
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
                                      ] else if (isAdminMode) ...[
                                        _buildInputField(
                                          label: 'Nama',
                                          hint: 'Masukkan Nama Anda',
                                          controller: nameController,
                                          isValid: _isNameValid,
                                          errorText: _nameErrorText,
                                          accentColor: accentColor,
                                        ),
                                        const SizedBox(height: 15),
                                        _buildInputField(
                                          label: 'Kata Sandi',
                                          hint: 'Masukkan Kata Sandi',
                                          controller: passwordController,
                                          isValid: _isPasswordValid,
                                          errorText: _passwordErrorText,
                                          isPassword: true,
                                          accentColor: accentColor,
                                        ),
                                      ],
                                      const SizedBox(height: 20),
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.15),
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
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                              _nameErrorText = null;
                                              _passwordErrorText = null;
                                              _nisnErrorText = null;
                                              _guruCodeErrorText = null;
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
                                            'Ubah Jenis Akun?',
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
      ),
    );
  }

  // Widget untuk logo di halaman login form
  Widget _buildLoginScreenLogo(bool isSiswa, Color accentColor) {
    if (_isLoadingSekolah) {
      debugPrint('⏳ Loading logo dari server (halaman login)...');
      return Container(
        color: Colors.grey[300],
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
          ),
        ),
      );
    }

    if (_sekolahData != null &&
        _sekolahData!['logo_url'] != null &&
        _sekolahData!['logo_url'].toString().isNotEmpty) {
      debugPrint(
          '🖼️ Menampilkan logo dari URL (halaman login): ${_sekolahData!['logo_url']}');
      debugPrint('📋 Data diambil dari API sekolah (Admin)');

      return Image.network(
        _sekolahData!['logo_url'],
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            debugPrint('✅ Logo berhasil dimuat dari server (halaman login)');
            return child;
          }
          debugPrint(
              '⏳ Memuat logo dari server (halaman login)... ${loadingProgress.cumulativeBytesLoaded}/${loadingProgress.expectedTotalBytes}');
          return Container(
            color: Colors.grey[300],
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Gagal memuat logo dari server (halaman login): $error');
          debugPrint('⚠️ Fallback ke logo lokal assets/images/smkn2.webp');
          return Image.asset(
            'assets/images/smkn2.webp',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('❌ Gagal memuat logo lokal, fallback ke icon');
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
          );
        },
      );
    }

    debugPrint(
        '⚠️ Tidak ada logo_url dari server, menggunakan logo lokal (halaman login)');
    debugPrint('📁 Menggunakan logo dari: assets/images/smkn2.webp');

    return Image.asset(
      'assets/images/smkn2.webp',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Gagal memuat logo lokal, fallback ke icon');
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
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isValid,
    required Color accentColor,
    String? errorText,
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
          inputFormatters:
              isNisn ? [FilteringTextInputFormatter.digitsOnly] : null,
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
              borderSide: BorderSide(
                color: errorText != null ? Colors.red[300]! : Colors.grey[300]!,
                width: errorText != null ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : accentColor,
                width: errorText != null ? 2 : 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red[300]!,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
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
                      color: errorText != null ? Colors.red : accentColor,
                    ),
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                  )
                : null,
            errorText: errorText,
            errorStyle: const TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Tidak boleh kosong';
            }
            if (!isValid && errorText == null) {
              if (isNisn) return 'NISN harus 10 digit angka';
              if (isPassword) return 'Kata sandi minimal 6 karakter';
              return 'Input tidak valid';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildGuruCodeField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool isValid,
    required Color accentColor,
    String? errorText,
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
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.black),
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
              borderSide: BorderSide(
                color: errorText != null ? Colors.red[300]! : Colors.grey[300]!,
                width: errorText != null ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : accentColor,
                width: errorText != null ? 2 : 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.red[300]!,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Tidak boleh kosong';
            }
            if (!isValid && errorText == null) {
              return 'Kode guru harus angka';
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
