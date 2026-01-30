import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

    print('[DEBUG] Checking login status...');
    print('[DEBUG] Token: ${token != null ? "Exists" : "Not found"}');
    print('[DEBUG] Role: $role');

    if (token != null && role != null && mounted) {
      Widget targetPage;

      // PERHATIAN: Gunakan lowercase untuk konsistensi dan handle semua kemungkinan
      final roleLower = role.toLowerCase();
      print('[DEBUG] Role in lowercase: $roleLower');

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
          print('[DEBUG] Role recognized as Kaprog, navigating to KaprogMainScreen');
          targetPage = const KaprogMainScreen();
          break;
        case 'admin':
          targetPage = const AdminMain();
          break;
        case 'koordinator':
          targetPage = const KoordinatorMain();
          break;
        default:
          print('[DEBUG] Unknown role in checkLoginStatus: $role');
          print('[DEBUG] Defaulting to GuruDashboard');
          return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => targetPage),
      );
    } else {
      print('[DEBUG] No valid token or role found');
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

  // Fungsi untuk mengambil data profil guru berdasarkan user_id atau nama
  Future<Map<String, dynamic>?> _fetchGuruProfile(
      SharedPreferences prefs) async {
    try {
      final token = prefs.getString('access_token');
      if (token == null) {
        print('Token tidak ditemukan');
        return null;
      }

      final userId = prefs.getInt('user_id');
      final kodeGuru = prefs.getString('kode_guru');
      final userName = prefs.getString('user_name');

      print('=== FETCH GURU PROFILE ===');
      print('User ID: $userId');
      print('Kode Guru: $kodeGuru');
      print('User Name: $userName');

      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
      
      // PENTING: Cari berdasarkan user_id yang didapat dari login
      if (userId != null) {
        // Gunakan endpoint dengan search untuk mencari berdasarkan nama atau kode
        final searchTerm = userName ?? kodeGuru ?? '';
        final url = '$baseUrl/api/guru?search=$searchTerm&limit=10';
        
        print('Request URL: $url');

        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          
          if (data['success'] == true) {
            // PERHATIAN: Data structure adalah {"data": {"data": [...]}}
            if (data['data'] != null && data['data'] is Map) {
              final dataMap = data['data'] as Map<String, dynamic>;
              
              if (dataMap['data'] != null && dataMap['data'] is List) {
                final guruList = dataMap['data'] as List;
                
                if (guruList.isNotEmpty) {
                  // Cari guru yang sesuai dengan user_id dari login
                  for (final guru in guruList) {
                    final guruUserId = guru['user_id'];
                    if (guruUserId == userId) {
                      print('Found matching guru by user_id: $guruUserId');
                      print('Guru data: $guru');
                      return guru;
                    }
                  }
                  
                  // Jika tidak ditemukan by user_id, coba dengan kode_guru
                  if (kodeGuru != null && kodeGuru.isNotEmpty) {
                    for (final guru in guruList) {
                      final guruKode = guru['kode_guru'];
                      if (guruKode == kodeGuru) {
                        print('Found matching guru by kode_guru: $guruKode');
                        return guru;
                      }
                    }
                  }
                  
                  // Jika masih tidak ditemukan, ambil yang pertama
                  print('Using first guru from list');
                  return guruList.first;
                }
              }
            }
          }
        }
      } else if (kodeGuru != null && kodeGuru.isNotEmpty) {
        // Fallback: cari langsung dengan kode_guru
        final url = '$baseUrl/api/guru?search=$kodeGuru&limit=1';
        print('Fallback URL: $url');
        
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
              data['data'] is Map &&
              (data['data'] as Map)['data'] is List) {
            final guruList = (data['data'] as Map)['data'] as List;
            if (guruList.isNotEmpty) {
              return guruList.first;
            }
          }
        }
      }

      return null;
    } catch (e) {
      print('Error fetching guru profile: $e');
      return null;
    }
  }

  Future<void> _showRoleSelectionDialog(
    BuildContext context,
    Map<String, dynamic> userData,
    SharedPreferences prefs,
    String userName,
  ) async {
    if (!mounted) return;

    // DEBUG: Tampilkan data user yang diterima
    print('=== SHOW ROLE SELECTION DIALOG ===');
    print('User data keys: ${userData.keys.toList()}');
    print('is_kaprog: ${userData['is_kaprog']}');
    print('is_koordinator: ${userData['is_koordinator']}');
    print('is_pembimbing: ${userData['is_pembimbing']}');
    print('is_wali_kelas: ${userData['is_wali_kelas']}');

    // Ambil data profil guru terlebih dahulu
    final guruProfile = await _fetchGuruProfile(prefs);

    // Gabungkan data dari login dengan data profil
    final Map<String, dynamic> combinedData = Map.from(userData);
    if (guruProfile != null) {
      // Prioritaskan data dari guruProfile (karena lebih lengkap)
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
            // SIMPAN KE SHAREDPREFERENCES DENGAN KEY YANG KONSISTEN
            String roleToSave = role;
            
            // DEBUG: Log role yang diterima dari dialog
            print('[DEBUG] Role received from dialog: $role');
            
            // Jika role adalah 'Kepala Konsentrasi Keahlian', simpan sebagai 'kaprog'
            if (role == 'Kepala Konsentrasi Keahlian') {
              roleToSave = 'kaprog'; // Simpan sebagai 'kaprog' untuk sistem
              print('[DEBUG] Converting role to: $roleToSave');
            }
            
            // Simpan role dengan key yang konsisten (gunakan lowercase)
            final roleLower = roleToSave.toLowerCase();
            await prefs.setString('user_role', roleLower);
            print('[DEBUG] Saved role to SharedPreferences: $roleLower');

            // Simpan semua data user
            await _saveAllUserData(prefs, combinedData, roleToSave);

            // SIMPAN DATA GURU TAMBAHAN jika ada
            if (guruProfile != null) {
              await _saveGuruProfileData(prefs, guruProfile);
            }

            if (!mounted) return;

            Widget targetPage;
            
            // GUNAKAN ROLE_TO_SAVE (yang sudah dikonversi) untuk navigasi
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
                print('[DEBUG] Navigating to KaprogMainScreen');
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
                print('[DEBUG] Defaulting to GuruDashboard for role: $roleToSave');
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
      // Simpan data dasar
      await prefs.setInt('user_id', userData['id'] ?? 0);
      await prefs.setString('username', userData['username'] ?? '');
      await prefs.setString(
          'user_name', userData['nama'] ?? userData['name'] ?? 'User');

      // Simpan data spesifik guru
      if (userData['kode_guru'] != null) {
        await prefs.setString('kode_guru', userData['kode_guru'].toString());
      }

      if (userData['nip'] != null) {
        await prefs.setString('user_nip', userData['nip'].toString());
      }

      // PERHATIAN: no_telp ada di data guru, bukan di data login awal
      if (userData['no_telp'] != null) {
        await prefs.setString('user_phone', userData['no_telp'].toString());
        print('Saved phone number: ${userData['no_telp']}');
      } else {
        print('No phone number found in userData');
        print('Available keys: ${userData.keys.toList()}');
      }

      // Simpan status role dari data guru
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
        await prefs.setBool('is_koordinator', userData['is_koordinator'] == true);
      }

      print('=== DATA DISIMPAN UNTUK ROLE: $role ===');
      print('User ID: ${userData['id']}');
      print('Username: ${userData['username']}');
      print('Nama: ${userData['nama']}');
      print('Kode Guru: ${userData['kode_guru']}');
      print('NIP: ${userData['nip']}');
      print('Telp: ${userData['no_telp']}');
      print('Wali Kelas: ${userData['is_wali_kelas']}');
      print('Pembimbing: ${userData['is_pembimbing']}');
      print('Kaprog: ${userData['is_kaprog']}');
      print('Koordinator: ${userData['is_koordinator']}');
    } catch (e) {
      print('Error saving user data: $e');
    }
  }

  Future<void> _saveGuruProfileData(
      SharedPreferences prefs, Map<String, dynamic> guruData) async {
    try {
      // Simpan semua field penting dari data guru
      final importantKeys = [
        'id', 'user_id', 'kode_guru', 'nip', 'nama', 
        'no_telp', 'is_koordinator', 'is_pembimbing', 
        'is_wali_kelas', 'is_kaprog', 'is_active'
      ];
      
      for (final key in importantKeys) {
        final value = guruData[key];
        if (value != null) {
          if (value is String) {
            await prefs.setString('guru_$key', value);
          } else if (value is int) {
            await prefs.setInt('guru_$key', value);
          } else if (value is bool) {
            await prefs.setBool('guru_$key', value);
          } else if (value is double) {
            await prefs.setDouble('guru_$key', value);
          } else {
            await prefs.setString('guru_$key', value.toString());
          }
        }
      }

      print('=== GURU PROFILE DATA SAVED ===');
      print('Phone saved to: guru_no_telp = ${guruData['no_telp']}');
    } catch (e) {
      print('Error saving guru profile: $e');
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

      return errorMessage.isNotEmpty ? errorMessage : 'Terjadi kesalahan';
    } catch (e) {
      return 'Terjadi kesalahan, coba lagi';
    }
  }

  Future<void> loginToAPI(String endpoint, Map<String, dynamic> body) async {
    await dotenv.load(fileName: '.env'); // Load .env file

    final baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';
    final url = Uri.parse('$baseUrl$endpoint');

    print('=== LOGIN REQUEST ===');
    print('Base URL: $baseUrl');
    print('Endpoint: $endpoint');
    print('Full URL: $url');
    print('Body: $body');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      print('=== LOGIN RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final refreshToken = data['refresh_token'];
        final user = data['user'];

        print('=== USER DATA FROM API ===');
        print('Full user object: $user');
        print('User keys: ${user.keys.toList()}');
        print('User id: ${user['id']}');
        print('User nama: ${user['nama']}');
        print('User kode_guru: ${user['kode_guru']}');

        final prefs = await SharedPreferences.getInstance();

        // SIMPAN SEMUA DATA TERLEBIH DAHULU
        await prefs.setString('access_token', token);
        await prefs.setString('refresh_token', refreshToken);
        await prefs.setInt('user_id', user['id'] ?? 0);
        await prefs.setString('user_name', user['nama'] ?? 'Guru');

        // SIMPAN KODE_GURU
        String kodeGuru = '';

        if (user['kode_guru'] != null) {
          kodeGuru = user['kode_guru'].toString();
          await prefs.setString('kode_guru', kodeGuru);
        } else if (user['username'] != null) {
          kodeGuru = user['username'].toString();
          await prefs.setString('kode_guru', kodeGuru);
        } else {
          // Jika tidak ada kode_guru, gunakan kode dari form login
          if (selectedRole == 'Guru' && !isAdminMode) {
            kodeGuru = guruController.text.trim();
            await prefs.setString('kode_guru', kodeGuru);
          }
        }

        // SIMPAN NIP jika ada (biasanya belum ada di login response)
        if (user['nip'] != null) {
          await prefs.setString('user_nip', user['nip'].toString());
        }

        // DEBUG: Verifikasi data yang tersimpan
        print('=== VERIFIKASI DATA TERSIMPAN ===');
        final savedId = prefs.getInt('user_id');
        final savedName = prefs.getString('user_name');
        final savedKode = prefs.getString('kode_guru');

        print('Saved User ID: $savedId');
        print('Saved User Name: $savedName');
        print('Saved Kode Guru: $savedKode');

        // Set role
        if (selectedRole == 'Siswa') {
          await prefs.setString('user_role', 'Siswa');
          await _saveSiswaData(prefs, user);
        } else if (isAdminMode) {
          await prefs.setString('user_role', 'Admin');
        } else {
          await prefs.setString('user_role', 'Guru');
        }

        if (endpoint == '/auth/guru/login' && !isAdminMode) {
          // Tampilkan dialog pemilihan role untuk guru
          await _showRoleSelectionDialog(
            context,
            user,
            prefs,
            capitalize(user['nama'] ?? 'Guru'),
          );
        } else {
          Widget targetPage;
          if (selectedRole == 'Siswa') {
            targetPage = const SiswaMain();
          } else if (isAdminMode) {
            targetPage = const AdminMain();
          } else {
            // Jika tidak memilih role khusus, default ke GuruDashboard
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

      if (token == null) {
        return;
      }

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
                      'LOGIN SEBAGAI',
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
                  borderRadius: BorderRadius.circular(screenWidth * 0.19),
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
                        color: Colors.black.withValues(alpha:0.25),
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
                        color: Colors.black.withValues(alpha:0.25),
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
      body: Stack(
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
                                    color: Colors.black.withValues(alpha:0.05),
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
                                    ] else if (isGuru && !isAdminMode) ...[
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
                                    ] else if (isAdminMode) ...[
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
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha:0.15),
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