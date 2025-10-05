import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AddPersonPage extends StatefulWidget {
  final String jenisData; // 'Siswa', 'Guru', 'Jurusan', 'Kelas', 'Industri'
  const AddPersonPage({super.key, required this.jenisData});

  @override
  State<AddPersonPage> createState() => _AddPersonPageState();
}

class _AddPersonPageState extends State<AddPersonPage> {
  final Color brown = const Color(0xFF641E20);
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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

  @override
  void initState() {
    super.initState();
    _fetchKelas();
    _fetchJurusan();
    _setupFocusListeners();
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
    super.dispose();
  }

  void _setupFocusListeners() {
    // Setup listeners untuk trigger rebuild saat focus berubah
    final focusNodes = [
      _namaFocus, _alamatFocus, _noTelpFocus, _nisnFocus, _tanggalLahirFocus,
      _nipFocus, _kodeGuruFocus, _passwordFocus, _kodeJurusanFocus, _bidangFocus,
      _emailFocus, _picFocus, _picTelpFocus
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

  // Fungsi untuk menampilkan alert/warning
  void _showValidationAlert(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Peringatan'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],

      ),
    );
  }
  

  // Validasi form sebelum submit
  bool _validateForm() {
    switch (widget.jenisData) {
      case 'Siswa':
        if (namaController.text.trim().length < 3) {
          _showValidationAlert('Nama lengkap harus minimal 3 karakter');
          return false;
        }
        if (nisnController.text.trim().length != 10) {
          _showValidationAlert('NISN harus tepat 10 digit');
          return false;
        }
        if (noTelpController.text.trim().length < 10) {
          _showValidationAlert('No. Telp harus minimal 10 digit');
          return false;
        }
        if (alamatController.text.trim().length < 10) {
          _showValidationAlert('Alamat harus minimal 10 karakter');
          return false;
        }
        if (tanggalLahirController.text.isEmpty) {
          _showValidationAlert('Tanggal lahir harus diisi');
          return false;
        }
        if (selectedKelasId == null) {
          _showValidationAlert('Kelas harus dipilih');
          return false;
        }
        break;

      case 'Guru':
        if (namaController.text.trim().length < 3) {
          _showValidationAlert('Nama guru harus minimal 3 karakter');
          return false;
        }
        if (nipController.text.trim().length < 8) {
          _showValidationAlert('NIP harus minimal 8 digit');
          return false;
        }
        if (kodeGuruController.text.trim().length < 3) {
          _showValidationAlert('Kode guru harus minimal 3 karakter');
          return false;
        }
        if (noTelpController.text.trim().length < 10) {
          _showValidationAlert('No. Telp harus minimal 10 digit');
          return false;
        }
        if (passwordController.text.trim().length < 6) {
          _showValidationAlert('Password harus minimal 6 karakter');
          return false;
        }
        break;

      case 'Jurusan':
        if (kodeJurusanController.text.trim().length < 2) {
          _showValidationAlert('Kode jurusan harus minimal 2 karakter');
          return false;
        }
        if (namaController.text.trim().length < 3) {
          _showValidationAlert('Nama jurusan harus minimal 3 karakter');
          return false;
        }
        break;

      case 'Kelas':
        if (namaController.text.trim().length < 2) {
          _showValidationAlert('Nama kelas harus minimal 2 karakter');
          return false;
        }
        if (selectedJurusanId == null) {
          _showValidationAlert('Jurusan harus dipilih');
          return false;
        }
        break;

      case 'Industri':
        if (namaController.text.trim().length < 3) {
          _showValidationAlert('Nama industri harus minimal 3 karakter');
          return false;
        }
        if (alamatController.text.trim().length < 10) {
          _showValidationAlert('Alamat harus minimal 10 karakter');
          return false;
        }
        if (bidangController.text.trim().length < 3) {
          _showValidationAlert('Bidang harus minimal 3 karakter');
          return false;
        }
        if (emailController.text.trim().isNotEmpty && 
            !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailController.text.trim())) {
          _showValidationAlert('Format email tidak valid');
          return false;
        }
        if (noTelpController.text.trim().length < 10) {
          _showValidationAlert('No. Telp harus minimal 10 digit');
          return false;
        }
        if (picController.text.trim().length < 3) {
          _showValidationAlert('Nama PIC harus minimal 3 karakter');
          return false;
        }
        if (picTelpController.text.trim().length < 10) {
          _showValidationAlert('No. Telp PIC harus minimal 10 digit');
          return false;
        }
        if (selectedJurusanId == null) {
          _showValidationAlert('Jurusan harus dipilih');
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

    switch (widget.jenisData) {
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
        break;
      case 'Kelas':
        endpoint = '/api/kelas';
        payload = {
          'jurusan_id': selectedJurusanId ?? 0,
          'nama': namaController.text.trim(),
        };
        break;
      case 'Industri':
        endpoint = '/api/industri';
        payload = {
          'alamat': alamatController.text.trim(),
          'bidang': bidangController.text.trim(),
          'email': emailController.text.trim(),
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

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Berhasil'),
              ],
            ),
            content: const Text('Data berhasil ditambahkan!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        if (!mounted) return;
        // Tampilkan error dari API
        final errorResponse = jsonDecode(response.body);
        final errorMessage = errorResponse['message'] ?? 'Gagal menyimpan data';
        _showValidationAlert(errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      _showValidationAlert('Terjadi kesalahan: $e');
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
      required FocusNode focusNode}) {
    
    final bool isFocused = focusNode.hasFocus;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label tanpa bintang
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscure,
            keyboardType: type,
            readOnly: readOnly,
            onTap: onTap,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '$label harus diisi';
              }
              if (minLength != null && value.trim().length < minLength) {
                return 'Minimal $minLength karakter';
              }
              if (additionalHint != null && value.trim().isNotEmpty) {
                if (additionalHint.contains('digit') && !RegExp(r'^\d+$').hasMatch(value.trim())) {
                  return 'Harus berupa angka';
                }
                if (additionalHint.contains('email') && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                  return 'Format email tidak valid';
                }
                if (additionalHint.contains('tepat') && minLength != null && value.trim().length != minLength) {
                  return 'Harus tepat $minLength digit';
                }
              }
              return null;
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
                    Icon(icon, color: brown, size: 22),
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
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          // Alert info di bawah box input - HANYA muncul saat focused
          if (isFocused && (minLength != null || additionalHint != null))
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8),
              child: Text(
                additionalHint ?? 'Minimal $minLength karakter',
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
                  prefixIcon: Icon(Icons.search, color: brown),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              menuProps: MenuProps(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: items,
            itemAsString: (item) => item[displayKey] ?? '-',
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                hintText: 'Pilih $label',
                prefixIcon: Icon(icon, color: brown),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      activeColor: brown,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<void> _pickTanggalLahir() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      tanggalLahirController.text =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final jenis = widget.jenisData;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(top: 60, bottom: 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B0000), Color(0xFFB22222)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(30)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Tambah $jenis',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person_add, size: 50, color: brown),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 50,
                    left: 16,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (jenis == 'Siswa') ...[
                      buildInputField(
                          Icons.person, 'Nama Lengkap', namaController,
                          minLength: 3,
                          focusNode: _namaFocus),
                      
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
                          focusNode: _alamatFocus),
                      buildInputField(Icons.numbers, 'NISN', nisnController,
                          type: TextInputType.number, 
                          minLength: 10,
                          additionalHint: 'Tepat 10 digit',
                          focusNode: _nisnFocus),
                      buildInputField(Icons.phone, 'No. Telp', noTelpController,
                          type: TextInputType.phone, 
                          minLength: 10,
                          additionalHint: 'Minimal 10 digit',
                          focusNode: _noTelpFocus),

                      // Tanggal Lahir
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tanggal Lahir', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: tanggalLahirController,
                              focusNode: _tanggalLahirFocus,
                              readOnly: true,
                              onTap: _pickTanggalLahir,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Tanggal lahir harus diisi';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                hintText: 'Pilih Tanggal',
                                prefixIcon: Icon(Icons.calendar_today, color: brown),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.grey),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.orange),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Colors.orange, width: 1.5),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                    vertical: 20, horizontal: 12),
                              ),
                            ),
                            // Alert info untuk tanggal lahir - HANYA muncul saat focused
                            if (_tanggalLahirFocus.hasFocus)
                              const Padding(
                                padding: EdgeInsets.only(top: 4, left: 8),
                                child: Text(
                                  'Harus diisi',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ] else if (jenis == 'Guru') ...[
                      buildInputField(Icons.person, 'Nama Guru', namaController,
                          minLength: 3,
                          focusNode: _namaFocus),
                      buildInputField(Icons.badge, 'NIP', nipController,
                          minLength: 8,
                          additionalHint: 'Minimal 8 digit',
                          focusNode: _nipFocus),
                      buildInputField(
                          Icons.code, 'Kode Guru', kodeGuruController,
                          minLength: 3,
                          focusNode: _kodeGuruFocus),
                      buildInputField(Icons.phone, 'No. Telp', noTelpController,
                          type: TextInputType.phone, 
                          minLength: 10,
                          additionalHint: 'Minimal 10 digit',
                          focusNode: _noTelpFocus),
                      buildInputField(Icons.lock, 'Password', passwordController,
                          obscure: true, 
                          minLength: 6,
                          additionalHint: 'Minimal 6 karakter',
                          focusNode: _passwordFocus),

                      // Checkbox untuk peran guru
                      const SizedBox(height: 16),
                      const Text('Peran Guru', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                      const SizedBox(height: 8),
                      _buildCheckbox('Kaprog', isKaprog, (value) {
                        setState(() {
                          isKaprog = value ?? false;
                        });
                      }),
                      _buildCheckbox('Koordinator', isKoordinator, (value) {
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
                    ] else if (jenis == 'Jurusan') ...[
                      buildInputField(
                          Icons.code, 'Kode Jurusan', kodeJurusanController,
                          minLength: 2,
                          focusNode: _kodeJurusanFocus),
                      buildInputField(Icons.book, 'Nama Jurusan', namaController,
                          minLength: 3,
                          focusNode: _namaFocus),
                    ] else if (jenis == 'Kelas') ...[
                      buildInputField(Icons.class_, 'Nama Kelas', namaController,
                          minLength: 2,
                          focusNode: _namaFocus),
                      const SizedBox(height: 16),
                      // Dropdown Jurusan untuk Kelas
                      _buildDropdownSearch(
                        label: 'Jurusan',
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
                    ] else if (jenis == 'Industri') ...[
                      buildInputField(
                          Icons.business, 'Nama Industri', namaController,
                          minLength: 3,
                          focusNode: _namaFocus),
                      buildInputField(Icons.home, 'Alamat', alamatController,
                          minLength: 10,
                          focusNode: _alamatFocus),
                      buildInputField(Icons.work, 'Bidang', bidangController,
                          minLength: 3,
                          focusNode: _bidangFocus),
                      buildInputField(Icons.email, 'Email', emailController,
                          type: TextInputType.emailAddress, 
                          additionalHint: 'Format email yang valid (opsional)',
                          focusNode: _emailFocus),
                      // Dropdown Jurusan untuk Industri
                      _buildDropdownSearch(
                        label: 'Jurusan',
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
                          focusNode: _noTelpFocus),
                      buildInputField(Icons.person, 'PIC', picController,
                          minLength: 3,
                          focusNode: _picFocus),
                      buildInputField(Icons.phone, 'PIC Telp', picTelpController,
                          type: TextInputType.phone, 
                          minLength: 10,
                          additionalHint: 'Minimal 10 digit',
                          focusNode: _picTelpFocus),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _submitData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brown,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text('Simpan',
                            style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}