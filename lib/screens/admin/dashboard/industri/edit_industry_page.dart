import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dropdown_search/dropdown_search.dart';

class EditIndustryPage extends StatefulWidget {
  final Map<String, dynamic> industryData;

  const EditIndustryPage({super.key, required this.industryData});

  @override
  State<EditIndustryPage> createState() => _EditIndustryPageState();
}

class _EditIndustryPageState extends State<EditIndustryPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _alamatController;
  late TextEditingController _telpController;
  late TextEditingController _emailController;
  late TextEditingController _bidangController;
  late TextEditingController _picController;
  late TextEditingController _picTelpController;
  bool isActive = false;

  // Variabel untuk dropdown jurusan
  List<Map<String, dynamic>> _jurusanList = []; // PERBAIKAN: Ubah tipe data
  Map<String, dynamic>? _selectedJurusan;
  bool _isLoadingJurusan = true;
  bool _hasJurusanError = false;
  String? _previousJurusanWarning;

  final Color brown = const Color(0xFF5B1A1A);
  final Color background = Colors.white;

  @override
  void initState() {
    super.initState();
    final data = widget.industryData;

    _namaController = TextEditingController(text: data['nama']);
    _alamatController = TextEditingController(text: data['alamat']);
    _telpController = TextEditingController(text: data['no_telp']);
    _emailController = TextEditingController(text: data['email']);
    _bidangController = TextEditingController(text: data['bidang']);
    _picController = TextEditingController(text: data['pic']);
    _picTelpController = TextEditingController(text: data['pic_telp']);
    isActive = data['is_active'] ?? false;

    // Load data jurusan
    _fetchJurusanList();
  }

  Future<void> _fetchJurusanList() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    print('=== START FETCH JURUSAN LIST FOR EDIT ===');
    
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/jurusan'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Jurusan List Response Status: ${response.statusCode}');
      print('Jurusan List Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('Jurusan List Decoded: $decoded');
        
        // PERBAIKAN: Handle nested structure dengan type conversion
        List<Map<String, dynamic>> jurusanData = [];
        
        if (decoded is List) {
          jurusanData = List<Map<String, dynamic>>.from(decoded);
        } else if (decoded['data'] != null) {
          // Jika data adalah object yang berisi data lagi
          if (decoded['data'] is List) {
            jurusanData = List<Map<String, dynamic>>.from(decoded['data']);
          } else if (decoded['data']['data'] is List) {
            jurusanData = List<Map<String, dynamic>>.from(decoded['data']['data']);
          }
        }
        
        setState(() {
          _jurusanList = jurusanData;
          _isLoadingJurusan = false;
        });
        
        print('Loaded ${_jurusanList.length} jurusan');
        
        // Cari jurusan yang sesuai dengan jurusan_id dari data industri
        final currentJurusanId = widget.industryData['jurusan_id'];
        if (currentJurusanId != null) {
          final foundJurusan = _jurusanList.firstWhere(
            (jurusan) => jurusan['id'] == currentJurusanId,
            orElse: () => <String, dynamic>{}, // Return empty map jika tidak ditemukan
          );
          
          if (foundJurusan.isNotEmpty) {
            setState(() {
              _selectedJurusan = foundJurusan;
            });
          } else {
            print('WARNING: Selected jurusan_id $currentJurusanId not found in jurusan list!');
            setState(() {
              _hasJurusanError = false;
              _previousJurusanWarning = 'Jurusan sebelumnya (ID: $currentJurusanId) tidak ditemukan. Silakan pilih jurusan baru.';
            });
          }
        }
      } else {
        print('Failed to load jurusan list: ${response.statusCode}');
        setState(() {
          _isLoadingJurusan = false;
          _hasJurusanError = true;
        });
      }
    } catch (e) {
      print('Error fetching jurusan list: $e');
      setState(() {
        _isLoadingJurusan = false;
        _hasJurusanError = true;
      });
    }
    print('=== END FETCH JURUSAN LIST FOR EDIT ===');
  }

  Future<void> _updateIndustry() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    // Prepare data untuk update
    final Map<String, dynamic> updateData = {
      'nama': _namaController.text,
      'alamat': _alamatController.text,
      'no_telp': _telpController.text,
      'email': _emailController.text,
      'bidang': _bidangController.text,
      'pic': _picController.text,
      'pic_telp': _picTelpController.text,
      'is_active': isActive,
    };

    // Tambahkan jurusan_id jika dipilih
    if (_selectedJurusan != null) {
      updateData['jurusan_id'] = _selectedJurusan!['id'];
    } else {
      // Jika jurusan_id di-set ke null, hapus dari data
      updateData['jurusan_id'] = null;
    }

    print('=== START UPDATE INDUSTRY ===');
    print('Update URL: ${dotenv.env['API_BASE_URL']}/api/industri/${widget.industryData['id']}');
    print('Update Data: $updateData');

    final response = await http.put(
      Uri.parse('${dotenv.env['API_BASE_URL']}/api/industri/${widget.industryData['id']}'),
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
      _showErrorDialog();
    }
    print('=== END UPDATE INDUSTRY ===');
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
            Text('Berhasil!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Data industri berhasil diperbarui.', textAlign: TextAlign.center),
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

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        titlePadding: const EdgeInsets.only(top: 24),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            SizedBox(height: 16),
            Text('Gagal!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text('Gagal memperbarui data industri.', textAlign: TextAlign.center),
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
                          // Hapus warning ketika user memilih jurusan baru
                          if (val != null) {
                            _previousJurusanWarning = null;
                          }
                        });
                      },
                      selectedItem: _selectedJurusan,
                    ),
          // Tampilkan warning jika jurusan sebelumnya tidak ditemukan
          if (_previousJurusanWarning != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[800], size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _previousJurusanWarning!,
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(IconData icon, String label, TextEditingController controller,
      {int maxLines = 1, TextInputType inputType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: inputType,
            maxLines: maxLines,
            validator: (value) => (value == null || value.isEmpty) ? 'Wajib diisi' : null,
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

  Widget _buildRoleSwitch(String title, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        value: value,
        activeColor: brown,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
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
                        'Edit Industri',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.factory, size: 50, color: brown),
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
                    _buildTextField(Icons.business, 'Nama Industri', _namaController),
                    _buildTextField(Icons.location_on, 'Alamat', _alamatController),
                    _buildTextField(Icons.phone, 'No. Telepon', _telpController, inputType: TextInputType.phone),
                    _buildTextField(Icons.email, 'Email', _emailController, inputType: TextInputType.emailAddress),
                    _buildTextField(Icons.work, 'Bidang', _bidangController),
                    
                    // Dropdown Jurusan dengan search
                    _buildJurusanDropdown(),
                    
                    _buildTextField(Icons.person, 'Nama PIC', _picController),
                    _buildTextField(Icons.phone_android, 'Telepon PIC', _picTelpController, inputType: TextInputType.phone),

                    const SizedBox(height: 12),
                    _buildRoleSwitch('Aktif', isActive, (val) => setState(() => isActive = val)),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateIndustry,
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
    _alamatController.dispose();
    _telpController.dispose();
    _emailController.dispose();
    _bidangController.dispose();
    _picController.dispose();
    _picTelpController.dispose();
    super.dispose();
  }
}