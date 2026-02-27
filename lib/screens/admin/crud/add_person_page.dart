import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AddPersonPage extends StatefulWidget {
  final String jenisData; // 'Siswa', 'Guru', 'Program Keahlian', 'Kelas', 'Industri'
  const AddPersonPage({super.key, required this.jenisData});

  @override
  State<AddPersonPage> createState() => _AddPersonPageState();
}

class _AddPersonPageState extends State<AddPersonPage> {
  final Color primaryColor = const Color(0xFF3B060A); // Warna baru
  final Color accentColor = const Color(0xFF641E20); // Warna sekunder
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Mapping jenis data untuk internal use
  late String _internalJenisData;

  // Controllers
  final TextEditingController namaController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController noTelpController = TextEditingController();
  final TextEditingController nisnController = TextEditingController();
  final TextEditingController tanggalLahirController = TextEditingController();

  final TextEditingController nipController = TextEditingController();
  final TextEditingController kodeGuruController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextEditingController kodeJurusanController = TextEditingController();
  final TextEditingController bidangController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController picController = TextEditingController();
  final TextEditingController picTelpController = TextEditingController();

  // Checkbox Guru
  bool isKaprog = false;
  bool isKoordinator = false;
  bool isPembimbing = false;
  bool isWaliKelas = false;

  // Dropdown
  List<Map<String, dynamic>> kelasList = [];
  int? selectedKelasId;

  List<Map<String, dynamic>> jurusanList = [];
  int? selectedJurusanId;

  // Untuk kaprog di jurusan
  List<Map<String, dynamic>> _kaprogList = [];
  String? _selectedKaprogId;
  bool _isLoadingKaprog = false;

  // Untuk wali kelas di kelas
  List<Map<String, dynamic>> _waliKelasList = [];
  String? _selectedWaliKelasId;
  bool _isLoadingWaliKelas = false;

  // Focus nodes untuk melacak field mana yang sedang aktif
  final FocusNode _namaFocus = FocusNode();
  final FocusNode _alamatFocus = FocusNode();
  final FocusNode _noTelpFocus = FocusNode();
  final FocusNode _nisnFocus = FocusNode();
  final FocusNode _tanggalLahirFocus = FocusNode();
  final FocusNode _nipFocus = FocusNode();
  final FocusNode _kodeGuruFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _kodeJurusanFocus = FocusNode();
  final FocusNode _bidangFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _picFocus = FocusNode();
  final FocusNode _picTelpFocus = FocusNode();

  // State untuk melacak status validasi setiap field
  final Map<String, String> _fieldErrorMessages = {};

  @override
  void initState() {
    super.initState();
    
    // Mapping jenis data: 'Program Keahlian' -> 'Jurusan' untuk internal
    _internalJenisData = widget.jenisData == 'Program Keahlian' 
        ? 'Jurusan' 
        : widget.jenisData;
    
    _fetchKelas();
    _fetchJurusan();
    _setupFocusListeners();
    _setupTextControllers();

    // Load data kaprog jika jenis data adalah Jurusan
    if (_internalJenisData == 'Jurusan') {
      _loadKaprogData();
    }
    
    // Load data wali kelas jika jenis data adalah Kelas
    if (_internalJenisData == 'Kelas') {
      _loadWaliKelasData();
    }
  }

  // Method untuk load data kaprog
  Future<void> _loadKaprogData() async {
    try {
      setState(() => _isLoadingKaprog = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List data = [];
        if (decoded['data'] != null && decoded['data']['data'] is List) {
          data = decoded['data']['data'];
        } else if (decoded['data'] is List) {
          data = decoded['data'];
        }

        // Filter hanya guru yang is_kaprog = true
        final List<Map<String, dynamic>> kaprogData = [];
        for (var guru in data) {
          if (guru['is_kaprog'] == true) {
            kaprogData.add({
              'id': guru['id']?.toString(),
              'nama': guru['nama_lengkap'] ?? guru['nama'] ?? 'Unknown',
              'kode_guru': guru['kode_guru'] ?? '',
            });
          }
        }

        setState(() {
          _kaprogList = kaprogData;
          _isLoadingKaprog = false;
        });
      } else {
        throw Exception('Failed to load kaprog data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading kaprog data: $e');
      setState(() {
        _isLoadingKaprog = false;
      });
    }
  }

  // Method untuk load data wali kelas
  Future<void> _loadWaliKelasData() async {
    try {
      setState(() => _isLoadingWaliKelas = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        List data = [];
        if (decoded['data'] != null && decoded['data']['data'] is List) {
          data = decoded['data']['data'];
        } else if (decoded['data'] is List) {
          data = decoded['data'];
        }

        // Filter hanya guru yang is_wali_kelas = true
        final List<Map<String, dynamic>> waliKelasData = [];
        for (var guru in data) {
          if (guru['is_wali_kelas'] == true) {
            waliKelasData.add({
              'id': guru['id']?.toString(),
              'nama': guru['nama_lengkap'] ?? guru['nama'] ?? 'Unknown',
              'kode_guru': guru['kode_guru'] ?? '',
            });
          }
        }

        setState(() {
          _waliKelasList = waliKelasData;
          _isLoadingWaliKelas = false;
        });
      } else {
        throw Exception('Failed to load wali kelas data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading wali kelas data: $e');
      setState(() {
        _isLoadingWaliKelas = false;
      });
    }
  }

  // Widget untuk dropdown kaprog
  Widget _buildKaprogDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kepala Program Keahlian',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          if (_isLoadingKaprog)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Memuat data kepala program...'),
                ],
              ),
            )
          else
            DropdownSearch<Map<String, dynamic>>(
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Cari kepala program...',
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                menuProps: MenuProps(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context, item, isSelected) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Text(
                      item['nama'] ?? '-',
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  );
                },
              ),
              items: [
                // Opsi "Tidak ada kaprog"
                const {'id': null, 'nama': 'Tidak ada kepala program'},
                ..._kaprogList,
              ],
              itemAsString: (item) => item['nama'] ?? '-',
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: 'Pilih Kepala Program',
                  prefixIcon: Icon(Icons.person, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
              onChanged: (selectedItem) {
                setState(() {
                  _selectedKaprogId = selectedItem?['id']?.toString();
                });
              },
              selectedItem: _selectedKaprogId != null
                  ? _kaprogList.firstWhere(
                      (kaprog) => kaprog['id'] == _selectedKaprogId,
                      orElse: () => {'id': null, 'nama': 'Tidak ada kepala program'},
                    )
                  : {'id': null, 'nama': 'Tidak ada kepala program'},
            ),
          if (!_isLoadingKaprog && _kaprogList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tidak ada guru yang terdaftar sebagai kepala program',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget untuk dropdown wali kelas
  Widget _buildWaliKelasDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wali Kelas',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          if (_isLoadingWaliKelas)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Memuat data wali kelas...'),
                ],
              ),
            )
          else
            DropdownSearch<Map<String, dynamic>>(
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Cari wali kelas...',
                    prefixIcon: Icon(Icons.search, color: primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                menuProps: MenuProps(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context, item, isSelected) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Text(
                      item['nama'] ?? '-',
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  );
                },
              ),
              items: [
                // Opsi "Tidak ada wali kelas"
                const {'id': null, 'nama': 'Tidak ada wali kelas'},
                ..._waliKelasList,
              ],
              itemAsString: (item) => item['nama'] ?? '-',
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: 'Pilih Wali Kelas',
                  prefixIcon: Icon(Icons.person, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                ),
              ),
              onChanged: (selectedItem) {
                setState(() {
                  _selectedWaliKelasId = selectedItem?['id']?.toString();
                });
              },
              selectedItem: _selectedWaliKelasId != null
                  ? _waliKelasList.firstWhere(
                      (waliKelas) => waliKelas['id'] == _selectedWaliKelasId,
                      orElse: () => {'id': null, 'nama': 'Tidak ada wali kelas'},
                    )
                  : {'id': null, 'nama': 'Tidak ada wali kelas'},
            ),
          if (!_isLoadingWaliKelas && _waliKelasList.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tidak ada guru yang terdaftar sebagai wali kelas',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _setupTextControllers() {
    // Setup listener untuk real-time validation
    namaController
        .addListener(() => _validateField('nama', namaController.text, 3));
    alamatController
        .addListener(() => _validateField('alamat', alamatController.text, 10));
    noTelpController
        .addListener(() => _validatePhone('noTelp', noTelpController.text));
    nisnController
        .addListener(() => _validateNISN('nisn', nisnController.text));
    nipController
        .addListener(() => _validateField('nip', nipController.text, 8));
    kodeGuruController.addListener(
        () => _validateField('kodeGuru', kodeGuruController.text, 3));
    passwordController.addListener(
        () => _validateField('password', passwordController.text, 6));
    kodeJurusanController.addListener(
        () => _validateField('kodeJurusan', kodeJurusanController.text, 2));
    bidangController
        .addListener(() => _validateField('bidang', bidangController.text, 3));
    emailController
        .addListener(() => _validateEmail('email', emailController.text));
    picController
        .addListener(() => _validateField('pic', picController.text, 3));
    picTelpController
        .addListener(() => _validatePhone('picTelp', picTelpController.text));
  }

  void _validateField(String fieldName, String value, int minLength) {
    final bool isValid = value.trim().length >= minLength;
    final String errorMessage =
        value.trim().isEmpty ? 'Harus diisi' : 'Minimal $minLength karakter';

    setState(() {
      _fieldErrorMessages[fieldName] = isValid ? '' : errorMessage;
    });
  }

  void _validatePhone(String fieldName, String value) {
    final bool isValid = value.trim().isNotEmpty &&
        value.trim().length >= 10 &&
        RegExp(r'^\d+$').hasMatch(value.trim());
    final String errorMessage = value.trim().isEmpty
        ? 'Harus diisi'
        : value.trim().length < 10
            ? 'Minimal 10 digit'
            : 'Harus berupa angka';

    setState(() {
      _fieldErrorMessages[fieldName] = isValid ? '' : errorMessage;
    });
  }

  void _validateNISN(String fieldName, String value) {
    final bool isValid = value.trim().isNotEmpty &&
        value.trim().length == 10 &&
        RegExp(r'^\d+$').hasMatch(value.trim());
    final String errorMessage = value.trim().isEmpty
        ? 'Harus diisi'
        : value.trim().length != 10
            ? 'Harus tepat 10 digit'
            : 'Harus berupa angka';

    setState(() {
      _fieldErrorMessages[fieldName] = isValid ? '' : errorMessage;
    });
  }

  void _validateEmail(String fieldName, String value) {
    final bool isValid = value.trim().isEmpty ||
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim());
    const String errorMessage = 'Format email tidak valid';

    setState(() {
      _fieldErrorMessages[fieldName] = isValid ? '' : errorMessage;
    });
  }

  @override
  void dispose() {
    // Dispose semua focus node
    _namaFocus.dispose();
    _alamatFocus.dispose();
    _noTelpFocus.dispose();
    _nisnFocus.dispose();
    _tanggalLahirFocus.dispose();
    _nipFocus.dispose();
    _kodeGuruFocus.dispose();
    _passwordFocus.dispose();
    _kodeJurusanFocus.dispose();
    _bidangFocus.dispose();
    _emailFocus.dispose();
    _picFocus.dispose();
    _picTelpFocus.dispose();

    // Dispose controllers
    namaController.dispose();
    alamatController.dispose();
    noTelpController.dispose();
    nisnController.dispose();
    tanggalLahirController.dispose();
    nipController.dispose();
    kodeGuruController.dispose();
    passwordController.dispose();
    kodeJurusanController.dispose();
    bidangController.dispose();
    emailController.dispose();
    picController.dispose();
    picTelpController.dispose();

    super.dispose();
  }

  void _setupFocusListeners() {
    // Setup listeners untuk trigger rebuild saat focus berubah
    final focusNodes = [
      _namaFocus,
      _alamatFocus,
      _noTelpFocus,
      _nisnFocus,
      _tanggalLahirFocus,
      _nipFocus,
      _kodeGuruFocus,
      _passwordFocus,
      _kodeJurusanFocus,
      _bidangFocus,
      _emailFocus,
      _picFocus,
      _picTelpFocus
    ];

    for (var focusNode in focusNodes) {
      focusNode.addListener(() {
        setState(() {}); // Rebuild ketika focus berubah
      });
    }
  }

  // Fetch kelas - ambil semua data
  Future<void> _fetchKelas() async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    try {
      // Gunakan limit yang besar untuk mengambil semua data
      final res = await http.get(
        Uri.parse('$baseUrl/api/kelas?limit=1000'), // Tambahkan limit besar
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(res.body);
        setState(() {
          if (jsonData['data'] != null) {
            if (jsonData['data'] is List) {
              // Jika response langsung array
              kelasList = List<Map<String, dynamic>>.from(jsonData['data']);
            } else if (jsonData['data']['data'] is List) {
              // Jika response dengan pagination
              final List<dynamic> data = jsonData['data']['data'];
              kelasList = data.cast<Map<String, dynamic>>();
            }
          }
        });
      } else {
        print('Error fetch kelas: ${res.statusCode}');
      }
    } catch (e) {
      print('Error fetch kelas: $e');
    }
  }

  // Fetch jurusan - ambil semua data
  Future<void> _fetchJurusan() async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    try {
      // Gunakan limit yang besar untuk mengambil semua data
      final res = await http.get(
        Uri.parse('$baseUrl/api/jurusan?limit=1000'), // Tambahkan limit besar
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(res.body);
        setState(() {
          if (jsonData['data'] != null) {
            if (jsonData['data'] is List) {
              // Jika response langsung array
              jurusanList = List<Map<String, dynamic>>.from(jsonData['data']);
            } else if (jsonData['data']['data'] is List) {
              // Jika response dengan pagination
              final List<dynamic> data = jsonData['data']['data'];
              jurusanList = data.cast<Map<String, dynamic>>();
            }
          }
        });
      } else {
        print('Error fetch jurusan: ${res.statusCode}');
      }
    } catch (e) {
      print('Error fetch jurusan: $e');
    }
  }

  String _convertTanggalUntukServer(String inputDate) {
    try {
      final parts = inputDate.split('-');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      }
      return inputDate;
    } catch (_) {
      return inputDate;
    }
  }

  // Fungsi untuk menampilkan popup sukses
  Future<void> _showSuccessPopup(String message) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessPopup(
        title: 'Berhasil!',
        message: message,
        onClose: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop(true); // Return true ke halaman sebelumnya
        },
      ),
    );
  }

  // Fungsi untuk menampilkan popup error
  Future<void> _showErrorPopup(String title, String message) async {
    await showDialog(
      context: context,
      builder: (context) => ErrorPopup(
        title: title,
        message: message,
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // Validasi form sebelum submit
  bool _validateForm() {
    switch (_internalJenisData) {
      case 'Siswa':
        if (namaController.text.trim().length < 3) {
          _showErrorPopup(
              'Validasi Gagal', 'Nama lengkap harus minimal 3 karakter');
          return false;
        }
        if (nisnController.text.trim().length != 10) {
          _showErrorPopup('Validasi Gagal', 'NISN harus tepat 10 digit');
          return false;
        }
        if (noTelpController.text.trim().length < 10) {
          _showErrorPopup('Validasi Gagal', 'No. Telp harus minimal 10 digit');
          return false;
        }
        if (alamatController.text.trim().length < 10) {
          _showErrorPopup('Validasi Gagal', 'Alamat harus minimal 10 karakter');
          return false;
        }
        if (tanggalLahirController.text.isEmpty) {
          _showErrorPopup('Validasi Gagal', 'Tanggal lahir harus diisi');
          return false;
        }
        if (selectedKelasId == null) {
          _showErrorPopup('Validasi Gagal', 'Kelas harus dipilih');
          return false;
        }
        break;

      case 'Guru':
        if (namaController.text.trim().length < 3) {
          _showErrorPopup(
              'Validasi Gagal', 'Nama guru harus minimal 3 karakter');
          return false;
        }
        if (nipController.text.trim().length < 8) {
          _showErrorPopup('Validasi Gagal', 'NIP harus minimal 8 digit');
          return false;
        }
        if (kodeGuruController.text.trim().length < 3) {
          _showErrorPopup(
              'Validasi Gagal', 'Kode guru harus minimal 3 karakter');
          return false;
        }
        if (noTelpController.text.trim().length < 10) {
          _showErrorPopup('Validasi Gagal', 'No. Telp harus minimal 10 digit');
          return false;
        }
        if (passwordController.text.trim().length < 6) {
          _showErrorPopup(
              'Validasi Gagal', 'Password harus minimal 6 karakter');
          return false;
        }
        break;

      case 'Jurusan':
        if (kodeJurusanController.text.trim().length < 2) {
          _showErrorPopup(
              'Validasi Gagal', 'Kode program keahlian harus minimal 2 karakter');
          return false;
        }
        if (namaController.text.trim().length < 3) {
          _showErrorPopup(
              'Validasi Gagal', 'Nama program keahlian harus minimal 3 karakter');
          return false;
        }
        break;

      case 'Kelas':
        if (namaController.text.trim().length < 2) {
          _showErrorPopup(
              'Validasi Gagal', 'Nama kelas harus minimal 2 karakter');
          return false;
        }
        if (selectedJurusanId == null) {
          _showErrorPopup('Validasi Gagal', 'Jurusan harus dipilih');
          return false;
        }
        break;

      case 'Industri':
        if (namaController.text.trim().length < 3) {
          _showErrorPopup(
              'Validasi Gagal', 'Nama industri harus minimal 3 karakter');
          return false;
        }
        if (alamatController.text.trim().length < 10) {
          _showErrorPopup('Validasi Gagal', 'Alamat harus minimal 10 karakter');
          return false;
        }
        if (bidangController.text.trim().length < 3) {
          _showErrorPopup('Validasi Gagal', 'Bidang harus minimal 3 karakter');
          return false;
        }
        if (emailController.text.trim().isNotEmpty &&
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                .hasMatch(emailController.text.trim())) {
          _showErrorPopup('Validasi Gagal', 'Format email tidak valid');
          return false;
        }
        if (noTelpController.text.trim().length < 10) {
          _showErrorPopup('Validasi Gagal', 'No. Telp harus minimal 10 digit');
          return false;
        }
        if (picController.text.trim().length < 3) {
          _showErrorPopup(
              'Validasi Gagal', 'Nama PIC harus minimal 3 karakter');
          return false;
        }
        if (picTelpController.text.trim().length < 10) {
          _showErrorPopup(
              'Validasi Gagal', 'No. Telp PIC harus minimal 10 digit');
          return false;
        }
        if (selectedJurusanId == null) {
          _showErrorPopup('Validasi Gagal', 'Jurusan harus dipilih');
          return false;
        }
        break;
    }
    return true;
  }

  Future<void> _submitData() async {
    // Validasi form sebelum submit
    if (!_validateForm()) {
      return;
    }

    String endpoint = '';
    Map<String, dynamic> payload = {};

    switch (_internalJenisData) {
      case 'Siswa':
        endpoint = '/api/siswa';
        payload = {
          'alamat': alamatController.text.trim(),
          'kelas_id': selectedKelasId ?? 0,
          'nama_lengkap': namaController.text.trim(),
          'nisn': nisnController.text.trim(),
          'no_telp': noTelpController.text.trim(),
          'tanggal_lahir': _convertTanggalUntukServer(tanggalLahirController.text),
        };
        break;
      case 'Guru':
        endpoint = '/api/guru';
        payload = {
          'is_kaprog': isKaprog,
          'is_koordinator': isKoordinator,
          'is_pembimbing': isPembimbing,
          'is_wali_kelas': isWaliKelas,
          'kode_guru': kodeGuruController.text.trim(),
          'nama': namaController.text.trim(),
          'nip': nipController.text.trim(),
          'no_telp': noTelpController.text.trim(),
          'password': passwordController.text.trim(),
        };
        break;
      case 'Jurusan':
        endpoint = '/api/jurusan';
        payload = {
          'kode': kodeJurusanController.text.trim(),
          'nama': namaController.text.trim(),
        };
        // Tambahkan kaprog_guru_id jika dipilih
        if (_selectedKaprogId != null && 
            _selectedKaprogId!.isNotEmpty && 
            _selectedKaprogId != 'null') {
          final kaprogId = int.tryParse(_selectedKaprogId!);
          if (kaprogId != null) {
            payload['kaprog_guru_id'] = kaprogId;
          }
        }
        break;
      case 'Kelas':
        endpoint = '/api/kelas';
        payload = {
          'jurusan_id': selectedJurusanId ?? 0,
          'nama': namaController.text.trim(),
        };
        // Tambahkan wali_kelas_guru_id jika dipilih
        if (_selectedWaliKelasId != null && 
            _selectedWaliKelasId!.isNotEmpty && 
            _selectedWaliKelasId != 'null') {
          final waliKelasId = int.tryParse(_selectedWaliKelasId!);
          if (waliKelasId != null) {
            payload['wali_kelas_guru_id'] = waliKelasId;
          }
        }
        break;
      case 'Industri':
        endpoint = '/api/industri';
        payload = {
          'alamat': alamatController.text.trim(),
          'bidang': bidangController.text.trim(),
          'email': emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
          'jurusan_id': selectedJurusanId ?? 0,
          'nama': namaController.text.trim(),
          'no_telp': noTelpController.text.trim(),
          'pic': picController.text.trim(),
          'pic_telp': picTelpController.text.trim(),
        };
        break;
    }

    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final url = Uri.parse('$baseUrl$endpoint');
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token') ?? '';

    // Debug: Print payload untuk memastikan tipe data benar
    print('Payload untuk ${widget.jenisData}:');
    print(jsonEncode(payload));
    print('URL: $url');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Sukses
        await _showSuccessPopup('Data ${widget.jenisData} berhasil ditambahkan!');
      } else {
        // Error dari API
        Map<String, dynamic> errorResponse;
        try {
          errorResponse = jsonDecode(response.body);
        } catch (e) {
          errorResponse = {'message': response.body};
        }
        
        String errorMessage = 'Gagal menyimpan data';
        
        if (errorResponse['message'] != null) {
          errorMessage = errorResponse['message'];
        } else if (errorResponse['error'] != null) {
          if (errorResponse['error'] is String) {
            errorMessage = errorResponse['error'];
          } else if (errorResponse['error'] is Map && errorResponse['error']['message'] != null) {
            errorMessage = errorResponse['error']['message'];
          }
        }
        
        // Parse error lebih detail jika ada
        if (errorResponse['errors'] != null) {
          final errors = errorResponse['errors'];
          if (errors is Map) {
            final errorDetails = errors.entries.map((e) => '${e.key}: ${e.value}').join('\n');
            errorMessage = '$errorMessage\n\n$errorDetails';
          } else if (errors is List) {
            errorMessage = '$errorMessage\n\n${errors.join('\n')}';
          }
        }
        
        await _showErrorPopup('Gagal Menyimpan', errorMessage);
      }
    } catch (e) {
      // Network error atau lainnya
      print('Error catch: $e');
      print('Error type: ${e.runtimeType}');
      
      String errorMessage = 'Terjadi kesalahan: $e';
      if (e is TypeError) {
        errorMessage += '\n\nError type casting: ${e.toString()}';
        // Cek kemungkinan penyebab
        errorMessage += '\n\nKemungkinan penyebab:';
        errorMessage += '\n- Data boolean dikirim sebagai string';
        errorMessage += '\n- ID yang diharapkan integer tapi dikirim string';
        errorMessage += '\n- Format payload tidak sesuai';
      }
      
      await _showErrorPopup('Kesalahan Sistem', errorMessage);
    }
  }

  Widget buildInputField(
      IconData icon, String label, TextEditingController controller,
      {bool obscure = false,
      TextInputType type = TextInputType.text,
      VoidCallback? onTap,
      bool readOnly = false,
      String? hint,
      int? minLength,
      String? additionalHint,
      required FocusNode focusNode,
      required String fieldName}) {
    final bool isFocused = focusNode.hasFocus;
    final bool hasError = _fieldErrorMessages[fieldName]?.isNotEmpty ?? false;
    final String errorMessage = _fieldErrorMessages[fieldName] ?? '';
    final bool showError = isFocused && hasError;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscure,
            keyboardType: type,
            readOnly: readOnly,
            onTap: onTap,
            onChanged: (value) {
              // Real-time validation sudah di-handle oleh listener di initState
            },
            decoration: InputDecoration(
              hintText: hint ?? 'Masukkan $label',
              prefixIcon: Container(
                width: 48,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: primaryColor, size: 22),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 30,
                      color: const Color.fromARGB(80, 128, 128, 128),
                    ),
                  ],
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: showError ? Colors.red : primaryColor,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          // Alert info di bawah box input
          if (showError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Widget untuk dropdown search
  Widget _buildDropdownSearch({
    required String label,
    required List<Map<String, dynamic>> items,
    required Function(Map<String, dynamic>?) onChanged,
    required int? selectedId,
    required IconData icon,
    required String displayKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          DropdownSearch<Map<String, dynamic>>(
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: TextFieldProps(
                decoration: InputDecoration(
                  hintText: 'Cari $label...',
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              menuProps: MenuProps(
                borderRadius: BorderRadius.circular(12),
              ),
              itemBuilder: (context, item, isSelected) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                  ),
                  child: Text(
                    item[displayKey] ?? '-',
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                );
              },
            ),
            items: items,
            itemAsString: (item) => item[displayKey] ?? '-',
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                hintText: 'Pilih $label',
                prefixIcon: Icon(icon, color: primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
            onChanged: onChanged,
            selectedItem: selectedId != null
                ? items.firstWhere(
                    (item) => item['id'] == selectedId,
                    orElse: () => {},
                  )
                : null,
          ),
        ],
      ),
    );
  }

  // Widget untuk checkbox guru
  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTanggalLahir() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
            ), dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      tanggalLahirController.text =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String displayJenis = widget.jenisData; // Untuk tampilan
    final String internalJenis = _internalJenisData; // Untuk logika

    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Header dengan gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 60, bottom: 30, left: 20, right: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withValues(alpha: 0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tambah $displayJenis',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _getIconForJenisData(displayJenis),
                        size: 40,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Input fields berdasarkan jenis data (gunakan internalJenis untuk logika)
                    if (internalJenis == 'Siswa') ...[
                      buildInputField(
                          Icons.person, 'Nama Lengkap', namaController,
                          minLength: 3,
                          focusNode: _namaFocus,
                          fieldName: 'nama'),

                      // Pilih Kelas
                      _buildDropdownSearch(
                        label: 'Kelas',
                        items: kelasList,
                        onChanged: (val) {
                          setState(() {
                            selectedKelasId = val?['id'];
                          });
                        },
                        selectedId: selectedKelasId,
                        icon: Icons.class_,
                        displayKey: 'nama',
                      ),

                      buildInputField(Icons.home, 'Alamat', alamatController,
                          minLength: 10,
                          focusNode: _alamatFocus,
                          fieldName: 'alamat'),
                      buildInputField(Icons.numbers, 'NISN', nisnController,
                          type: TextInputType.number,
                          minLength: 10,
                          additionalHint: 'Tepat 10 digit',
                          focusNode: _nisnFocus,
                          fieldName: 'nisn'),
                      buildInputField(Icons.phone, 'No. Telp', noTelpController,
                          type: TextInputType.phone,
                          minLength: 10,
                          additionalHint: 'Minimal 10 digit',
                          focusNode: _noTelpFocus,
                          fieldName: 'noTelp'),

                      // Tanggal Lahir
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tanggal Lahir',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: tanggalLahirController,
                              focusNode: _tanggalLahirFocus,
                              readOnly: true,
                              onTap: _pickTanggalLahir,
                              decoration: InputDecoration(
                                hintText: 'Pilih Tanggal',
                                prefixIcon: Icon(Icons.calendar_today_rounded,
                                    color: primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[300]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: primaryColor, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.red),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Colors.red, width: 1.5),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (internalJenis == 'Guru') ...[
                      buildInputField(Icons.person, 'Nama Guru', namaController,
                          minLength: 3,
                          focusNode: _namaFocus,
                          fieldName: 'nama'),
                      buildInputField(Icons.badge, 'NIP', nipController,
                          minLength: 8,
                          additionalHint: 'Minimal 8 digit',
                          focusNode: _nipFocus,
                          fieldName: 'nip'),
                      buildInputField(
                          Icons.code, 'Kode Guru', kodeGuruController,
                          minLength: 3,
                          focusNode: _kodeGuruFocus,
                          fieldName: 'kodeGuru'),
                      buildInputField(Icons.phone, 'No. Telp', noTelpController,
                          type: TextInputType.phone,
                          minLength: 10,
                          additionalHint: 'Minimal 10 digit',
                          focusNode: _noTelpFocus,
                          fieldName: 'noTelp'),
                      buildInputField(
                          Icons.lock, 'Password', passwordController,
                          obscure: true,
                          minLength: 6,
                          additionalHint: 'Minimal 6 karakter',
                          focusNode: _passwordFocus,
                          fieldName: 'password'),

                      // Checkbox untuk peran guru
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Peran Guru',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            _buildCheckbox('Kepala Program Keahlian', isKaprog, (value) {
                              setState(() {
                                isKaprog = value ?? false;
                              });
                            }),
                            _buildCheckbox('Koordinator', isKoordinator,
                                (value) {
                              setState(() {
                                isKoordinator = value ?? false;
                              });
                            }),
                            _buildCheckbox('Pembimbing', isPembimbing, (value) {
                              setState(() {
                                isPembimbing = value ?? false;
                              });
                            }),
                            _buildCheckbox('Wali Kelas', isWaliKelas, (value) {
                              setState(() {
                                isWaliKelas = value ?? false;
                              });
                            }),
                          ],
                        ),
                      ),
                    ] else if (internalJenis == 'Jurusan') ...[
                      buildInputField(
                          Icons.code, 'Kode Program Keahlian', kodeJurusanController,
                          minLength: 2,
                          focusNode: _kodeJurusanFocus,
                          fieldName: 'kodeJurusan'),
                      buildInputField(
                          Icons.book, 'Nama Program Keahlian', namaController,
                          minLength: 3,
                          focusNode: _namaFocus,
                          fieldName: 'nama'),
                      // Dropdown Kaprog untuk Program Keahlian
                      _buildKaprogDropdown(),
                    ] else if (internalJenis == 'Kelas') ...[
                      buildInputField(
                          Icons.class_, 'Nama Kelas', namaController,
                          minLength: 2,
                          focusNode: _namaFocus,
                          fieldName: 'nama'),
                      const SizedBox(height: 16),
                      // Dropdown Jurusan untuk Kelas
                      _buildDropdownSearch(
                        label: 'Program Keahlian',
                        items: jurusanList,
                        onChanged: (val) {
                          setState(() {
                            selectedJurusanId = val?['id'];
                          });
                        },
                        selectedId: selectedJurusanId,
                        icon: Icons.school,
                        displayKey: 'nama',
                      ),
                      const SizedBox(height: 16),
                      // Dropdown Wali Kelas untuk Kelas
                      _buildWaliKelasDropdown(),
                    ] else if (internalJenis == 'Industri') ...[
                      buildInputField(
                          Icons.business, 'Nama Industri', namaController,
                          minLength: 3,
                          focusNode: _namaFocus,
                          fieldName: 'nama'),
                      buildInputField(Icons.home, 'Alamat', alamatController,
                          minLength: 10,
                          focusNode: _alamatFocus,
                          fieldName: 'alamat'),
                      buildInputField(Icons.work, 'Bidang', bidangController,
                          minLength: 3,
                          focusNode: _bidangFocus,
                          fieldName: 'bidang'),
                      buildInputField(Icons.email, 'Email', emailController,
                          type: TextInputType.emailAddress,
                          additionalHint: 'Format email yang valid (opsional)',
                          focusNode: _emailFocus,
                          fieldName: 'email'),
                      // Dropdown Jurusan untuk Industri
                      _buildDropdownSearch(
                        label: 'Program Keahlian',
                        items: jurusanList,
                        onChanged: (val) {
                          setState(() {
                            selectedJurusanId = val?['id'];
                          });
                        },
                        selectedId: selectedJurusanId,
                        icon: Icons.school,
                        displayKey: 'nama',
                      ),
                      buildInputField(Icons.phone, 'No. Telp', noTelpController,
                          type: TextInputType.phone,
                          minLength: 10,
                          additionalHint: 'Minimal 10 digit',
                          focusNode: _noTelpFocus,
                          fieldName: 'noTelp'),
                      buildInputField(Icons.person, 'PIC', picController,
                          minLength: 3, focusNode: _picFocus, fieldName: 'pic'),
                      buildInputField(
                          Icons.phone, 'PIC Telp', picTelpController,
                          type: TextInputType.phone,
                          minLength: 10,
                          additionalHint: 'Minimal 10 digit',
                          focusNode: _picTelpFocus,
                          fieldName: 'picTelp'),
                    ],
                    const SizedBox(height: 30),

                    // Simpan Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _submitData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                          shadowColor: primaryColor.withValues(alpha: 0.3),
                        ),
                        child: const Text(
                          'Simpan Data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function untuk mendapatkan icon berdasarkan jenis data (untuk tampilan)
  IconData _getIconForJenisData(String jenis) {
    switch (jenis) {
      case 'Siswa':
        return Icons.person;
      case 'Guru':
        return Icons.school;
      case 'Program Keahlian':
        return Icons.category;
      case 'Jurusan':
        return Icons.category;
      case 'Kelas':
        return Icons.class_;
      case 'Industri':
        return Icons.business;
      default:
        return Icons.add;
    }
  }
}

// ============================================
// POPUP SUKSES ELEGAN
// ============================================

class SuccessPopup extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onClose;

  const SuccessPopup({
    super.key,
    required this.title,
    required this.message,
    required this.onClose,
  });

  @override
  State<SuccessPopup> createState() => _SuccessPopupState();
}

class _SuccessPopupState extends State<SuccessPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Auto close setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _closePopup();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closePopup() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        _closePopup();
        return false;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon dengan animasi
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Text(
                    widget.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _closePopup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B060A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
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
        ),
      ),
    );
  }
}

// ============================================
// POPUP ERROR ELEGAN
// ============================================

class ErrorPopup extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback onClose;

  const ErrorPopup({
    super.key,
    required this.title,
    required this.message,
    required this.onClose,
  });

  @override
  State<ErrorPopup> createState() => _ErrorPopupState();
}

class _ErrorPopupState extends State<ErrorPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _closePopup() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onClose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        _closePopup();
        return false;
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Error Icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.error_rounded,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Message
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _closePopup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Mengerti',
                        style: TextStyle(
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
        ),
      ),
    );
  }
}