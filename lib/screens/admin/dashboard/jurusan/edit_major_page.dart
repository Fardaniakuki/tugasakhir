import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dropdown_search/dropdown_search.dart';

class EditMajorPage extends StatefulWidget {
  final Map<String, dynamic> majorData;

  const EditMajorPage({super.key, required this.majorData});

  @override
  State<EditMajorPage> createState() => _EditMajorPageState();
}

class _EditMajorPageState extends State<EditMajorPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _kodeController;
  late TextEditingController _namaController;
  String? _selectedKaprogId;
  List<Map<String, dynamic>> _kaprogList = [];

  final Color brown = const Color(0xFF5B1A1A);
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _kodeController = TextEditingController(text: widget.majorData['kode']);
    _namaController = TextEditingController(text: widget.majorData['nama']);
    _selectedKaprogId = widget.majorData['kaprog_guru_id']?.toString();
    
    // Load data kaprog saat init
    _loadKaprogData();
  }

  Future<void> _loadKaprogData() async {
    try {
      setState(() => _isLoading = true);
      
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
          _isLoading = false; // PASTIKAN isLoading di-set ke false
        });
      } else {
        throw Exception('Failed to load kaprog data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading kaprog data: $e');
      setState(() {
        _isLoading = false; // PASTIKAN isLoading di-set ke false bahkan saat error
      });
    }
  }

  Future<void> _updateMajor() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    // Prepare data untuk update
    final Map<String, dynamic> updateData = {
      'kode': _kodeController.text,
      'nama': _namaController.text,
    };

    // Handle kaprog_guru_id dengan benar
    if (_selectedKaprogId != null && 
        _selectedKaprogId!.isNotEmpty && 
        _selectedKaprogId != 'null') {
      final kaprogId = int.tryParse(_selectedKaprogId!);
      if (kaprogId != null) {
        updateData['kaprog_guru_id'] = kaprogId;
      } else {
        updateData['kaprog_guru_id'] = null;
      }
    } else {
      updateData['kaprog_guru_id'] = null;
    }

    final response = await http.put(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/jurusan/${widget.majorData['id']}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(updateData),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      _showSuccessDialog();
    } else {
      print('Gagal update jurusan: ${response.statusCode}');
      print('Body: ${response.body}');
      
      String errorMessage = 'Gagal memperbarui jurusan.';
      try {
        final data = json.decode(response.body);
        if (data['error'] != null && data['error']['message'] != null) {
          errorMessage = data['error']['message'];
        } else if (data['message'] != null) {
          errorMessage = data['message'];
        } else if (data['errors'] != null) {
          errorMessage = data['errors'].values.first[0];
        }
      } catch (_) {
        errorMessage = 'Terjadi kesalahan tidak dikenal.';
      }
      _showErrorDialog(errorMessage);
    }
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
            Text(
              'Data jurusan berhasil diperbarui.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: brown,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        titlePadding: const EdgeInsets.only(top: 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Gagal!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tutup'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTextField(IconData icon, String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: brown),
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
                borderSide: const BorderSide(color: Colors.grey, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  // Method untuk mendapatkan selected item
  Map<String, dynamic> _getSelectedKaprogItem() {
    if (_selectedKaprogId == null || _selectedKaprogId!.isEmpty || _selectedKaprogId == 'null') {
      return {'id': null, 'nama': 'Tidak ada kaprog'};
    }
    
    try {
      return _kaprogList.firstWhere(
        (kaprog) => kaprog['id'] == _selectedKaprogId,
      );
    } catch (e) {
      print('Kaprog tidak ditemukan dengan ID: $_selectedKaprogId');
      return {'id': null, 'nama': 'Tidak ada kaprog'};
    }
  }

  Widget _buildKaprogDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kaprog',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          
          // PERBAIKAN: Gunakan kondisi yang lebih sederhana
          if (_isLoading)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
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
                  Text('Memuat data kaprog...'),
                ],
              ),
            )
          else
            DropdownSearch<Map<String, dynamic>>(
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    hintText: 'Cari kaprog...',
                    prefixIcon: Icon(Icons.search, color: brown),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                menuProps: MenuProps(
                  borderRadius: BorderRadius.circular(12),
                ),
                // PERBAIKAN: Hanya tampilkan nama saja
                itemBuilder: (context, item, isSelected) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      item['nama'] ?? '-',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  );
                },
              ),
              items: [
                // Opsi "Tidak ada kaprog"
                const {'id': null, 'nama': 'Tidak ada kaprog'},
                ..._kaprogList,
              ],
              itemAsString: (item) => item['nama'] ?? '-',
              dropdownDecoratorProps: DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  hintText: 'Pilih Kaprog',
                  prefixIcon: Icon(Icons.person, color: brown),
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
              onChanged: (selectedItem) {
                setState(() {
                  _selectedKaprogId = selectedItem?['id']?.toString();
                });
              },
              selectedItem: _getSelectedKaprogItem(),
            ),
          
          if (!_isLoading && _kaprogList.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Tidak ada guru yang terdaftar sebagai kaprog',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
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
                  child: Column(
                    children: [
                      const Text(
                        'Ubah Jurusan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.school, size: 50, color: brown),
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
                    _buildTextField(Icons.code, 'Kode Jurusan', _kodeController),
                    _buildTextField(Icons.school, 'Nama Jurusan', _namaController),
                    _buildKaprogDropdown(),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateMajor,
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
}