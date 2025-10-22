import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dropdown_search/dropdown_search.dart';

class EditStudentPage extends StatefulWidget {
  final Map<String, dynamic> studentData;

  const EditStudentPage({super.key, required this.studentData});

  @override
  State<EditStudentPage> createState() => _EditStudentPageState();
}

class _EditStudentPageState extends State<EditStudentPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController namaController;
  late TextEditingController nisnController;
  late TextEditingController alamatController;
  late TextEditingController noTelpController;
  late TextEditingController tanggalLahirController;

  final Color brown = const Color(0xFF5B1A1A);

  List<Map<String, dynamic>> kelasList = [];
  Map<String, dynamic>? selectedKelas;

  @override
  void initState() {
    super.initState();
    namaController =
        TextEditingController(text: widget.studentData['nama_lengkap']);
    nisnController = TextEditingController(text: widget.studentData['nisn']);
    alamatController =
        TextEditingController(text: widget.studentData['alamat']);
    noTelpController =
        TextEditingController(text: widget.studentData['no_telp']);
    tanggalLahirController = TextEditingController(
      text: _formatDateForDisplay(widget.studentData['tanggal_lahir']),
    );

    _fetchKelas();
  }

  Future<void> _fetchKelas() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';

    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/kelas?limit=1000'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          if (data['data'] is List) {
            kelasList = List<Map<String, dynamic>>.from(data['data']);
          } else if (data['data']['data'] is List) {
            kelasList =
                List<Map<String, dynamic>>.from(data['data']['data']);
          }
selectedKelas = kelasList.isNotEmpty
    ? kelasList.firstWhere(
        (k) => k['id'] == widget.studentData['kelas_id'],
        orElse: () => kelasList[0],
      )
    : null;

        });
      } else {
        print('Gagal fetch kelas: ${res.statusCode}');
      }
    } catch (e) {
      print('Error fetch kelas: $e');
    }
  }

  String _formatDateForDisplay(String? rawDate) {
    if (rawDate == null) return '';
    try {
      final date = DateTime.parse(rawDate);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (_) {
      return rawDate;
    }
  }

  String _convertDisplayDateToISO(String inputDate) {
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

  Future<void> _pickTanggalLahir() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(widget.studentData['tanggal_lahir'] ?? '') ??
              DateTime(2005),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        tanggalLahirController.text =
            '${pickedDate.day.toString().padLeft(2, '0')}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.year}';
      });
    }
  }

  Future<void> updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      _showErrorDialog('Token tidak ditemukan. Silakan login ulang.');
      return;
    }

    final url =
        '${dotenv.env['API_BASE_URL']}/api/siswa/${widget.studentData['id']}';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'nama_lengkap': namaController.text.trim(),
          'nisn': nisnController.text.trim(),
          'alamat': alamatController.text.trim(),
          'no_telp': noTelpController.text.trim(),
          'kelas_id': selectedKelas?['id'] ?? 0,
          'tanggal_lahir':
              _convertDisplayDateToISO(tanggalLahirController.text.trim()),
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        _showSuccessDialog();
      } else {
        String message = 'Gagal memperbarui data siswa.';
        try {
          final data = json.decode(response.body);
          if (data['message'] != null) {
            message = data['message'];
          } else if (data['errors'] != null) {
            message = data['errors'].values.first[0];
          }
        } catch (e) {
          print('Error parsing response: $e');
        }
        _showErrorDialog(message);
      }
    } catch (e) {
      print('Terjadi error saat request: $e');
      _showErrorDialog('Terjadi kesalahan jaringan: $e');
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
              'Data siswa berhasil diperbarui.',
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Tutup'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTextField(
      IconData icon, String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text,
      bool readOnly = false,
      VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            readOnly: readOnly,
            onTap: onTap,
            validator: (value) =>
                value == null || value.isEmpty ? 'Wajib diisi' : null,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: brown),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Colors.grey, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKelasDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kelas', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          DropdownSearch<Map<String, dynamic>>(
            popupProps: PopupProps.menu(
              showSearchBox: true,
              searchFieldProps: const TextFieldProps(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Cari kelas...',
                  border: OutlineInputBorder(),
                ),
              ),
              menuProps: MenuProps(borderRadius: BorderRadius.circular(12)),
            ),
            items: kelasList,
            itemAsString: (item) => item['nama'] ?? '-',
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                hintText: 'Pilih Kelas',
                prefixIcon: Icon(Icons.class_, color: brown),
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
              ),
            ),
            onChanged: (val) {
              setState(() {
                selectedKelas = val;
              });
            },
            selectedItem: selectedKelas,
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
                      const Text(
                        'Ubah Data Siswa',
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
                        child: Icon(Icons.person, size: 50, color: brown),
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
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField(Icons.person, 'Nama Lengkap', namaController),
                    _buildTextField(Icons.numbers, 'NISN', nisnController,
                        keyboard: TextInputType.number),
                    _buildTextField(Icons.home, 'Alamat', alamatController),
                    _buildTextField(Icons.phone, 'No Telepon', noTelpController,
                        keyboard: TextInputType.phone),
                    _buildKelasDropdown(),
                    _buildTextField(Icons.calendar_today,
                        'Tanggal Lahir (DD-MM-YYYY)', tanggalLahirController,
                        readOnly: true, onTap: _pickTanggalLahir),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: updateStudent,
                        icon: const Icon(Icons.save, size: 20),
                        label: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
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
