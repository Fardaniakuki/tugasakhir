// lib/screens/kaprog/kaprog_add_industri_screen.dart

// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dropdown_search/dropdown_search.dart';

class KaprogAddIndustriScreen extends StatefulWidget {
  const KaprogAddIndustriScreen({super.key});

  @override
  State<KaprogAddIndustriScreen> createState() => _KaprogAddIndustriScreenState();
}

class _KaprogAddIndustriScreenState extends State<KaprogAddIndustriScreen> {
  final Color primaryColor = const Color(0xFF6B1B1B); // Warna merah dari dashboard
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController namaController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController bidangController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController noTelpController = TextEditingController();
  final TextEditingController picController = TextEditingController();
  final TextEditingController picTelpController = TextEditingController();

  // Dropdown Jurusan
  List<Map<String, dynamic>> jurusanList = [];
  int? selectedJurusanId;

  // State untuk loading
  bool _isLoading = false;
  bool _isLoadingJurusan = true;

  // Focus nodes
  final FocusNode _namaFocus = FocusNode();
  final FocusNode _alamatFocus = FocusNode();
  final FocusNode _bidangFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _noTelpFocus = FocusNode();
  final FocusNode _picFocus = FocusNode();
  final FocusNode _picTelpFocus = FocusNode();

  // State untuk validasi
  final Map<String, String> _fieldErrorMessages = {};

  @override
  void initState() {
    super.initState();
    _fetchJurusan();
    _setupFocusListeners();
    _setupTextControllers();
  }

  void _setupFocusListeners() {
    final focusNodes = [
      _namaFocus,
      _alamatFocus,
      _bidangFocus,
      _emailFocus,
      _noTelpFocus,
      _picFocus,
      _picTelpFocus,
    ];

    for (var focusNode in focusNodes) {
      focusNode.addListener(() {
        setState(() {}); // Rebuild ketika focus berubah
      });
    }
  }

  void _setupTextControllers() {
    namaController.addListener(() => _validateField('nama', namaController.text, 3));
    alamatController.addListener(() => _validateField('alamat', alamatController.text, 10));
    bidangController.addListener(() => _validateField('bidang', bidangController.text, 3));
    emailController.addListener(() => _validateEmail('email', emailController.text));
    noTelpController.addListener(() => _validatePhone('noTelp', noTelpController.text));
    picController.addListener(() => _validateField('pic', picController.text, 3));
    picTelpController.addListener(() => _validatePhone('picTelp', picTelpController.text));
  }

  void _validateField(String fieldName, String value, int minLength) {
    final bool isValid = value.trim().length >= minLength;
    final String errorMessage = value.trim().isEmpty 
        ? 'Harus diisi' 
        : 'Minimal $minLength karakter';

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
    // Dispose focus nodes
    _namaFocus.dispose();
    _alamatFocus.dispose();
    _bidangFocus.dispose();
    _emailFocus.dispose();
    _noTelpFocus.dispose();
    _picFocus.dispose();
    _picTelpFocus.dispose();

    // Dispose controllers
    namaController.dispose();
    alamatController.dispose();
    bidangController.dispose();
    emailController.dispose();
    noTelpController.dispose();
    picController.dispose();
    picTelpController.dispose();

    super.dispose();
  }

  // Fetch jurusan
  Future<void> _fetchJurusan() async {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    try {
      setState(() => _isLoadingJurusan = true);

      final response = await http.get(
        Uri.parse('$baseUrl/api/jurusan?limit=1000'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          if (jsonData['data'] != null) {
            if (jsonData['data'] is List) {
              jurusanList = List<Map<String, dynamic>>.from(jsonData['data']);
            } else if (jsonData['data']['data'] is List) {
              final List<dynamic> data = jsonData['data']['data'];
              jurusanList = data.cast<Map<String, dynamic>>();
            }
          }
          _isLoadingJurusan = false;
        });
      } else {
        print('Error fetch jurusan: ${response.statusCode}');
        setState(() => _isLoadingJurusan = false);
      }
    } catch (e) {
      print('Error fetch jurusan: $e');
      setState(() => _isLoadingJurusan = false);
    }
  }

  // Validasi form
  bool _validateForm() {
    if (namaController.text.trim().length < 3) {
      _showErrorPopup('Validasi Gagal', 'Nama industri harus minimal 3 karakter');
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
      _showErrorPopup('Validasi Gagal', 'Nama PIC harus minimal 3 karakter');
      return false;
    }
    if (picTelpController.text.trim().length < 10) {
      _showErrorPopup('Validasi Gagal', 'No. Telp PIC harus minimal 10 digit');
      return false;
    }
    if (selectedJurusanId == null) {
      _showErrorPopup('Validasi Gagal', 'Program Keahlian harus dipilih');
      return false;
    }
    return true;
  }

  // Submit data industri
  Future<void> _submitData() async {
    if (!_validateForm()) {
      return;
    }

    setState(() => _isLoading = true);

    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final url = Uri.parse('$baseUrl/api/industri');
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token') ?? '';

    final payload = {
      'alamat': alamatController.text.trim(),
      'bidang': bidangController.text.trim(),
      'email': emailController.text.trim().isNotEmpty ? emailController.text.trim() : null,
      'jurusan_id': selectedJurusanId ?? 0,
      'nama': namaController.text.trim(),
      'no_telp': noTelpController.text.trim(),
      'pic': picController.text.trim(),
      'pic_telp': picTelpController.text.trim(),
    };

    print('Payload industri:');
    print(jsonEncode(payload));

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

      setState(() => _isLoading = false);

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _showSuccessPopup('Data industri berhasil ditambahkan!');
      } else {
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
      setState(() => _isLoading = false);
      print('Error catch: $e');
      await _showErrorPopup('Kesalahan Sistem', 'Terjadi kesalahan: $e');
    }
  }

  // Widget input field dengan validasi
  Widget buildInputField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    TextInputType type = TextInputType.text,
    String? hint,
    int? minLength,
    required FocusNode focusNode,
    required String fieldName,
    bool isRequired = true,
  }) {
    final bool isFocused = focusNode.hasFocus;
    final bool hasError = _fieldErrorMessages[fieldName]?.isNotEmpty ?? false;
    final String errorMessage = _fieldErrorMessages[fieldName] ?? '';
    final bool showError = isFocused && hasError;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              if (isRequired) 
                Text(' *', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: type,
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

  // Widget dropdown jurusan
  Widget _buildJurusanDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Program Keahlian', style: TextStyle(fontWeight: FontWeight.w500)),
              Text(' *', style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          if (_isLoadingJurusan)
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
                  Text('Memuat data program keahlian...'),
                ],
              ),
            )
          else if (jurusanList.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Center(
                child: Text(
                  'Tidak ada data program keahlian',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            DropdownSearch<Map<String, dynamic>>(
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Cari program keahlian...',
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
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  );
                },
              ),
              items: jurusanList,
              itemAsString: (item) => item['nama'] ?? '-',
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: 'Pilih Program Keahlian',
                  prefixIcon: Icon(Icons.school, color: primaryColor),
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
              onChanged: (val) {
                setState(() {
                  selectedJurusanId = val?['id'];
                });
              },
              selectedItem: selectedJurusanId != null
                  ? jurusanList.firstWhere(
                      (item) => item['id'] == selectedJurusanId,
                      orElse: () => {},
                    )
                  : null,
            ),
        ],
      ),
    );
  }

  // Popup sukses
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

  // Popup error
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Header
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
                          const Expanded(
                            child: Text(
                              'Tambah Industri',
                              style: TextStyle(
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
                            Icons.business,
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
                        buildInputField(
                          icon: Icons.business,
                          label: 'Nama Industri',
                          controller: namaController,
                          minLength: 3,
                          focusNode: _namaFocus,
                          fieldName: 'nama',
                        ),
                        buildInputField(
                          icon: Icons.home,
                          label: 'Alamat',
                          controller: alamatController,
                          minLength: 10,
                          focusNode: _alamatFocus,
                          fieldName: 'alamat',
                        ),
                        buildInputField(
                          icon: Icons.work,
                          label: 'Bidang',
                          controller: bidangController,
                          minLength: 3,
                          focusNode: _bidangFocus,
                          fieldName: 'bidang',
                        ),
                        buildInputField(
                          icon: Icons.email,
                          label: 'Email',
                          controller: emailController,
                          type: TextInputType.emailAddress,
                          focusNode: _emailFocus,
                          fieldName: 'email',
                          isRequired: false,
                        ),
                        
                        // Dropdown Jurusan
                        _buildJurusanDropdown(),
                        
                        buildInputField(
                          icon: Icons.phone,
                          label: 'No. Telp',
                          controller: noTelpController,
                          type: TextInputType.phone,
                          minLength: 10,
                          focusNode: _noTelpFocus,
                          fieldName: 'noTelp',
                        ),
                        buildInputField(
                          icon: Icons.person,
                          label: 'Pembimbing Industri',
                          controller: picController,
                          minLength: 3,
                          focusNode: _picFocus,
                          fieldName: 'pic',
                        ),
                        buildInputField(
                          icon: Icons.phone,
                          label: 'Telp',
                          controller: picTelpController,
                          type: TextInputType.phone,
                          minLength: 10,
                          focusNode: _picTelpFocus,
                          fieldName: 'picTelp',
                        ),
                        
                        const SizedBox(height: 30),

                        // Simpan Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitData,
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
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Simpan Data Industri',
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

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================
// POPUP SUKSES (Copy dari AddPersonPage)
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _closePopup();
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
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _closePopup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B1B1B),
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
// POPUP ERROR (Copy dari AddPersonPage)
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
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _closePopup();
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