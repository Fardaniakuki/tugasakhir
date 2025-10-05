import 'package:flutter/material.dart';

class PengajuanPKLScreen extends StatefulWidget {
  const PengajuanPKLScreen({super.key});

  @override
  State<PengajuanPKLScreen> createState() => _PengajuanPKLScreenState();
}

class _PengajuanPKLScreenState extends State<PengajuanPKLScreen> {
  final TextEditingController _namaPerusahaan = TextEditingController();
  final TextEditingController _alamatPerusahaan = TextEditingController();
  final TextEditingController _keterangan = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String? _file;

  Future<void> _pickDate(bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() {
    if (_namaPerusahaan.text.isEmpty ||
        _alamatPerusahaan.text.isEmpty ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua data wajib!')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengajuan PKL berhasil dikirim ✅')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengajuan PKL'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nama perusahaan
            const Text('Nama Perusahaan'),
            const SizedBox(height: 6),
            TextField(
              controller: _namaPerusahaan,
              decoration: InputDecoration(
                hintText: 'Masukkan nama perusahaan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Alamat
            const Text('Alamat Perusahaan'),
            const SizedBox(height: 6),
            TextField(
              controller: _alamatPerusahaan,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Masukkan alamat perusahaan',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dari & Sampai
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal Mulai'),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _pickDate(true),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _startDate == null
                                ? 'Pilih tanggal'
                                : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal Selesai'),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _pickDate(false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _endDate == null
                                ? 'Pilih tanggal'
                                : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lampiran
            const Text('Lampiran (Opsional)'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(_file ?? 'file'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: () => setState(() => _file = 'surat_pengantar.pdf'),
                ),
                if (_file != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => setState(() => _file = null),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Keterangan tambahan
            const Text('Keterangan'),
            const SizedBox(height: 6),
            TextField(
              controller: _keterangan,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tambahkan keterangan tambahan (opsional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Kirim
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Kirim Pengajuan',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
