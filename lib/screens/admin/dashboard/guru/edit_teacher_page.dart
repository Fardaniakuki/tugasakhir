import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditTeacherPage extends StatefulWidget {
  final Map<String, dynamic> teacherData;

  const EditTeacherPage({super.key, required this.teacherData});

  @override
  State<EditTeacherPage> createState() => _EditTeacherPageState();
}

class _EditTeacherPageState extends State<EditTeacherPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _nipController;
  late TextEditingController _telpController;

  bool isKoordinator = false;
  bool isPembimbing = false;
  bool isWaliKelas = false;
  bool isKaprog = false;
  bool isActive = false;

  final Color brown = const Color(0xFF5B1A1A);
  final Color background = const Color.fromARGB(255, 255, 255, 255);

  @override
  void initState() {
    super.initState();
    final data = widget.teacherData;

    _namaController = TextEditingController(text: data['nama']);
    _nipController = TextEditingController(text: data['nip']);
    _telpController = TextEditingController(text: data['no_telp']);

    isKoordinator = data['is_koordinator'] ?? false;
    isPembimbing = data['is_pembimbing'] ?? false;
    isWaliKelas = data['is_wali_kelas'] ?? false;
    isKaprog = data['is_kaprog'] ?? false;
    isActive = data['is_active'] ?? false;
  }

  Future<void> _updateTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final response = await http.put(
      Uri.parse('$baseUrl/api/guru/${widget.teacherData['id']}'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'nama': _namaController.text,
        'nip': _nipController.text,
        'no_telp': _telpController.text,
        'is_koordinator': isKoordinator,
        'is_pembimbing': isPembimbing,
        'is_wali_kelas': isWaliKelas,
        'is_kaprog': isKaprog,
        'is_active': isActive,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      _showSuccessDialog();
    } else {
      _showErrorDialog();
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
              'Data guru berhasil diperbarui.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
                Navigator.pop(context, true); // Balik ke halaman sebelumnya
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor:
                    const Color(0xFF5B1A1A), // Ganti brown jadi Color langsung
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
            Text(
              'Gagal!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Gagal memperbarui data guru.',
              textAlign: TextAlign.center,
            ),
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
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Ubah Profil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person, size: 50, color: brown),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: brown,
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(Icons.camera_alt,
                                  size: 18, color: Colors.white),
                            ),
                          ),
                        ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Informasi Pribadi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: brown,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                        Icons.person, 'Nama Lengkap', _namaController),
                    _buildTextField(Icons.badge, 'NIP', _nipController,
                        keyboardType: TextInputType.number),
                    _buildTextField(
                        Icons.phone, 'Nomor Telepon', _telpController,
                        keyboardType: TextInputType.phone),
                    const SizedBox(height: 24),
                    Text(
                      'Status Peran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: brown,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRoleSwitch('Koordinator', isKoordinator,
                        (val) => setState(() => isKoordinator = val)),
                    _buildRoleSwitch('Pembimbing', isPembimbing,
                        (val) => setState(() => isPembimbing = val)),
                    _buildRoleSwitch('Wali Kelas', isWaliKelas,
                        (val) => setState(() => isWaliKelas = val)),
                    _buildRoleSwitch('Kaprog', isKaprog,
                        (val) => setState(() => isKaprog = val)),
                    _buildRoleSwitch('Aktif', isActive,
                        (val) => setState(() => isActive = val)),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _updateTeacher,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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

  Widget _buildTextField(
      IconData icon, String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: (value) =>
                value == null || value.isEmpty ? 'Wajib diisi' : null,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: brown),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Colors.grey), // Warna border default
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Colors.grey), // Warna saat tidak fokus
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Colors.grey, width: 1.5), // Warna saat fokus
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
}
