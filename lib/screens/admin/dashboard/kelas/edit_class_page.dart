import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../popup_helper.dart';

class EditClassPage extends StatefulWidget {
  final Map<String, dynamic> classData;

  const EditClassPage({super.key, required this.classData});

  @override
  State<EditClassPage> createState() => _EditClassPageState();
}

class _EditClassPageState extends State<EditClassPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  
  // PERBAIKAN: Gunakan Map untuk selected jurusan seperti di industry
  Map<String, dynamic>? _selectedJurusan;
  bool _isLoadingJurusan = true;
  bool _hasJurusanError = false;

  final Color brown = const Color(0xFF5B1A1A);
  List<Map<String, dynamic>> _jurusanList = []; // PERBAIKAN: Tambah underscore untuk konsistensi

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.classData['nama']);
    
    // PERBAIKAN: Load data jurusan dulu, baru set selected jurusan
    _fetchJurusan();
  }

  Future<void> _fetchJurusan() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/jurusan?limit=1000'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          if (data['data'] is List) {
            _jurusanList = List<Map<String, dynamic>>.from(data['data']);
          } else if (data['data']['data'] is List) {
            _jurusanList = List<Map<String, dynamic>>.from(data['data']['data']);
          }
          _isLoadingJurusan = false;
        });

        // PERBAIKAN: Set selected jurusan setelah data loaded
        _setSelectedJurusan();
      } else {
        print('Gagal fetch jurusan: ${res.statusCode}');
        setState(() {
          _isLoadingJurusan = false;
          _hasJurusanError = true;
        });
      }
    } catch (e) {
      print('Error fetch jurusan: $e');
      setState(() {
        _isLoadingJurusan = false;
        _hasJurusanError = true;
      });
    }
  }

  void _setSelectedJurusan() {
    final currentJurusanId = widget.classData['jurusan']?['id'] ?? widget.classData['jurusan_id'];
    if (currentJurusanId != null) {
      final foundJurusan = _jurusanList.firstWhere(
        (jurusan) => jurusan['id'] == currentJurusanId,
        orElse: () => <String, dynamic>{},
      );
      
      if (foundJurusan.isNotEmpty) {
        setState(() {
          _selectedJurusan = foundJurusan;
        });
      }
    }
  }

  Future<void> _updateClass() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    // PERBAIKAN: Struktur data yang benar
    final Map<String, dynamic> updateData = {
      'nama': _namaController.text.trim(),
    };

    // PERBAIKAN: Tambahkan jurusan_id jika dipilih
    if (_selectedJurusan != null) {
      updateData['jurusan_id'] = _selectedJurusan!['id'];
    } else {
      // Jika tidak ada jurusan yang dipilih, set ke null
      updateData['jurusan_id'] = null;
    }

    print('=== START UPDATE CLASS ===');
    print('Update URL: ${dotenv.env['API_BASE_URL']}/api/kelas/${widget.classData['id']}');
    print('Update Data: $updateData');

    try {
      final response = await http.put(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/kelas/${widget.classData['id']}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(updateData),
      );

      print('Update Response Status: ${response.statusCode}');
      print('Update Response Body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        // PERBAIKAN: Handle error response dengan lebih baik
        String errorMessage = 'Gagal memperbarui kelas.';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          } else if (errorData['errors'] != null) {
            errorMessage = errorData['errors'].values.first[0];
          }
        } catch (e) {
          errorMessage = 'Error: ${response.statusCode}';
        }
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      print('Error during update: $e');
      _showErrorDialog('Terjadi kesalahan jaringan: $e');
    }
    print('=== END UPDATE CLASS ===');
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        titlePadding: const EdgeInsets.only(top: 24),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
            SizedBox(height: 16),
            Text(
              'Berhasil!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('Data kelas berhasil diperbarui.',
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true); // kembali ke detail page dengan refresh
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: brown,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Kembali'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    PopupHelper.showErrorDialog(context, message);
  }

  Widget _buildTextField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nama Kelas', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _namaController,
            validator: (value) => value == null || value.isEmpty
                ? 'Nama kelas wajib diisi'
                : null,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.class_, color: brown),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: brown, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJurusanDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Jurusan', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          _isLoadingJurusan
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school, color: brown),
                      const SizedBox(width: 12),
                      const Text('Loading jurusan...'),
                    ],
                  ),
                )
              : _hasJurusanError
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Error loading jurusan'),
                        ],
                      ),
                    )
                  : DropdownSearch<Map<String, dynamic>>(
                      popupProps: PopupProps.menu(
                        showSearchBox: true,
                        searchFieldProps: const TextFieldProps(
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Cari jurusan...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        menuProps: MenuProps(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _jurusanList,
                      itemAsString: (item) => item['nama']?.toString() ?? '-',
                      dropdownDecoratorProps: DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          hintText: 'Pilih Jurusan (Opsional)',
                          prefixIcon: Icon(Icons.school, color: brown),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: brown, width: 1.5),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _selectedJurusan = val;
                        });
                      },
                      selectedItem: _selectedJurusan,
                    ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
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
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'Ubah Kelas',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.class_, size: 50, color: Color(0xFF5B1A1A)),
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
            // Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(),
                    _buildJurusanDropdown(),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateClass,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Simpan Perubahan'),
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

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }
}