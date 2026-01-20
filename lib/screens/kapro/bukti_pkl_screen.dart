// bukti_pkl_screen.dart
import 'package:flutter/material.dart';

class BuktiPklScreen extends StatefulWidget {
  final ScrollController? scrollController;
  
  const BuktiPklScreen({
    super.key,
    this.scrollController,
  });

  @override
  State<BuktiPklScreen> createState() => _BuktiPklScreenState();
}

class _BuktiPklScreenState extends State<BuktiPklScreen> with AutomaticKeepAliveClientMixin {
  final Color _primaryRed = const Color(0xFF6B1B1B);
  final Color _bgSoft = const Color(0xFFF6EEEE);
  final Color _secondaryColor = Colors.white;
  final Color _textPrimary = Colors.black;
  final Color _textSecondary = const Color(0xFF666666);
  final Color _borderColor = const Color(0xFFE0E0E0);
  final Color _green = const Color(0xFF4CAF50);
  final Color _orange = const Color(0xFFFF9800);
  final Color _red = const Color(0xFFF44336);
  
  List<Map<String, dynamic>> _buktiPklData = [];
  List<Map<String, dynamic>> _filteredData = [];
  String _filterStatus = 'Semua';
  final TextEditingController _searchController = TextEditingController();

  // Filter options
  final List<String> _statusOptions = [
    'Semua',
    'Diterima',
    'Menunggu Verifikasi',
    'Perlu Revisi',
    'Ditolak'
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadDummyData();
  }

  void _loadDummyData() {
    // Data dummy dengan format yang sama
    setState(() {
      _buktiPklData = [
        {
          'id': 'PKL001',
          'nama': 'Ahmad Rizki',
          'kelas': 'XII TKJ 1',
          'industri': 'PT. Teknologi Indonesia',
          'industri_alamat': 'Jl. Sudirman No. 123, Jakarta',
          'industri_kontak': '(021) 12345678',
          'status': 'Diterima',
          'tanggal_kirim': '15 Jan 2024 14:30',
          'tanggal_verifikasi': '16 Jan 2024 09:15',
          'verifikator': 'Dr. Budi Santoso, M.Kom.',
          'catatan': 'Dokumen lengkap dan sesuai format. Surat penerimaan dari HRD perusahaan sudah lengkap dengan tanda tangan dan stempel resmi.',
          'statusColor': _green,
          'file_url': 'https://example.com/bukti_pkl_ahmad.pdf',
          'file_type': 'pdf',
          'file_size': '2.4 MB',
          'is_approved': true,
        },
        {
          'id': 'PKL002',
          'nama': 'Siti Nurhaliza',
          'kelas': 'XII RPL 2',
          'industri': 'CV. Digital Solusi',
          'industri_alamat': 'Jl. Gatot Subroto No. 45, Bandung',
          'industri_kontak': '(022) 87654321',
          'status': 'Menunggu Verifikasi',
          'tanggal_kirim': '14 Jan 2024 10:20',
          'tanggal_verifikasi': null,
          'verifikator': null,
          'catatan': 'Menunggu konfirmasi dari pihak industri. Dokumen sudah dikirim namun belum ada balasan resmi.',
          'statusColor': _orange,
          'file_url': 'https://example.com/bukti_pkl_siti.jpg',
          'file_type': 'image',
          'file_size': '1.8 MB',
          'is_approved': false,
        },
        {
          'id': 'PKL003',
          'nama': 'Budi Santoso',
          'kelas': 'XII MM 1',
          'industri': 'PT. Media Kreatif',
          'industri_alamat': 'Jl. Merdeka No. 67, Surabaya',
          'industri_kontak': '(031) 23456789',
          'status': 'Perlu Revisi',
          'tanggal_kirim': '13 Jan 2024 09:45',
          'tanggal_verifikasi': '14 Jan 2024 11:30',
          'verifikator': 'Dr. Budi Santoso, M.Kom.',
          'catatan': 'Format surat belum sesuai standar. Mohon perbaiki kop surat dan tambahkan nomor surat resmi dari perusahaan.',
          'statusColor': _orange,
          'file_url': 'https://example.com/bukti_pkl_budi.pdf',
          'file_type': 'pdf',
          'file_size': '3.1 MB',
          'is_approved': false,
        },
        {
          'id': 'PKL004',
          'nama': 'Dewi Lestari',
          'kelas': 'XII TKJ 2',
          'industri': 'PT. Jaringan Indonesia',
          'industri_alamat': 'Jl. Pemuda No. 89, Yogyakarta',
          'industri_kontak': '(0274) 34567890',
          'status': 'Ditolak',
          'tanggal_kirim': '12 Jan 2024 16:10',
          'tanggal_verifikasi': '13 Jan 2024 14:20',
          'verifikator': 'Dr. Budi Santoso, M.Kom.',
          'catatan': 'Dokumen tidak asli/terindikasi palsu. Tanda tangan dan stempel tidak sesuai dengan database perusahaan.',
          'statusColor': _red,
          'file_url': 'https://example.com/bukti_pkl_dewi.jpg',
          'file_type': 'image',
          'file_size': '2.1 MB',
          'is_approved': false,
        },
        {
          'id': 'PKL005',
          'nama': 'Rizky Pratama',
          'kelas': 'XII RPL 1',
          'industri': 'PT. Software House',
          'industri_alamat': 'Jl. Haji Usman No. 12, Jakarta',
          'industri_kontak': '(021) 45678901',
          'status': 'Diterima',
          'tanggal_kirim': '11 Jan 2024 11:30',
          'tanggal_verifikasi': '12 Jan 2024 08:45',
          'verifikator': 'Dr. Budi Santoso, M.Kom.',
          'catatan': 'Semua dokumen valid. Surat diterima dengan lengkap dan sudah melalui verifikasi ketat.',
          'statusColor': _green,
          'file_url': 'https://example.com/bukti_pkl_rizky.pdf',
          'file_type': 'pdf',
          'file_size': '2.9 MB',
          'is_approved': true,
        },
        {
          'id': 'PKL006',
          'nama': 'Maya Sari',
          'kelas': 'XII TKJ 3',
          'industri': 'PT. Network Solution',
          'industri_alamat': 'Jl. Prof. Dr. Satrio No. 45, Jakarta',
          'industri_kontak': '(021) 98765432',
          'status': 'Menunggu Verifikasi',
          'tanggal_kirim': '10 Jan 2024 13:15',
          'tanggal_verifikasi': null,
          'verifikator': null,
          'catatan': 'Dokumen sudah dikirimkan. Menunggu proses verifikasi oleh koordinator PKL.',
          'statusColor': _orange,
          'file_url': 'https://example.com/bukti_pkl_maya.pdf',
          'file_type': 'pdf',
          'file_size': '1.5 MB',
          'is_approved': false,
        },
        {
          'id': 'PKL007',
          'nama': 'Fajar Abdullah',
          'kelas': 'XII MM 2',
          'industri': 'CV. Media Production',
          'industri_alamat': 'Jl. Cihampelas No. 78, Bandung',
          'industri_kontak': '(022) 76543210',
          'status': 'Diterima',
          'tanggal_kirim': '9 Jan 2024 09:00',
          'tanggal_verifikasi': '10 Jan 2024 14:30',
          'verifikator': 'Dr. Siti Aminah, M.Pd.',
          'catatan': 'Dokumen sudah lengkap. Surat penerimaan sudah sesuai dengan standar yang berlaku.',
          'statusColor': _green,
          'file_url': 'https://example.com/bukti_pkl_fajar.jpg',
          'file_type': 'image',
          'file_size': '2.2 MB',
          'is_approved': true,
        },
        {
          'id': 'PKL008',
          'nama': 'Kevin Maulana',
          'kelas': 'XII RPL 3',
          'industri': 'PT. Web Developer',
          'industri_alamat': 'Jl. Dipati Ukur No. 56, Bandung',
          'industri_kontak': '(022) 11223344',
          'status': 'Perlu Revisi',
          'tanggal_kirim': '8 Jan 2024 15:45',
          'tanggal_verifikasi': '9 Jan 2024 10:20',
          'verifikator': 'Dr. Siti Aminah, M.Pd.',
          'catatan': 'Tanggal surat tidak sesuai dengan periode PKL. Mohon minta surat baru dengan tanggal yang benar.',
          'statusColor': _orange,
          'file_url': 'https://example.com/bukti_pkl_kevin.pdf',
          'file_type': 'pdf',
          'file_size': '2.7 MB',
          'is_approved': false,
        },
      ];
      _filteredData = _buktiPklData;
    });
  }

  void _filterByStatus(String status) {
    setState(() {
      _filterStatus = status;
      if (status == 'Semua') {
        _filteredData = _buktiPklData;
      } else {
        _filteredData = _buktiPklData.where((item) => item['status'] == status).toList();
      }
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: isError ? _red : _green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showFileDetail(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _secondaryColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header - FIXED
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Dokumen',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _primaryRed,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 28),
                      color: _textPrimary,
                    ),
                  ],
                ),
              ),
              
              // SCROLLABLE CONTENT - FIXED
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Student Info Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _primaryRed.withValues(alpha:0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _primaryRed.withValues(alpha:0.3)),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: _primaryRed,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['nama'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        data['kelas'],
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: data['statusColor'].withValues(alpha:0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: data['statusColor'].withValues(alpha:0.3)),
                                  ),
                                  child: Text(
                                    data['status'],
                                    style: TextStyle(
                                      color: data['statusColor'],
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Industry Info
                            Row(
                              children: [
                                Icon(Icons.apartment, size: 18, color: _textSecondary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    data['industri'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            if (data['industri_alamat'] != null)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.location_on, size: 18, color: _textSecondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      data['industri_alamat'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (data['industri_kontak'] != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 18, color: _textSecondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    data['industri_kontak'],
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // File Information
                      const Text(
                        'Informasi Dokumen',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Column(
                          children: [
                            _infoRow('Jenis File', data['file_type'].toUpperCase()),
                            const SizedBox(height: 12),
                            _infoRow('Ukuran File', data['file_size']),
                            const SizedBox(height: 12),
                            _infoRow('Tanggal Kirim', data['tanggal_kirim']),
                            if (data['tanggal_verifikasi'] != null) ...[
                              const SizedBox(height: 12),
                              _infoRow('Tanggal Verifikasi', data['tanggal_verifikasi']),
                            ],
                            if (data['verifikator'] != null) ...[
                              const SizedBox(height: 12),
                              _infoRow('Verifikator', data['verifikator']),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Catatan
                      if (data['catatan'] != null && data['catatan'].isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Catatan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _borderColor),
                              ),
                              child: Text(
                                data['catatan'],
                                style: TextStyle(
                                  fontSize: 15,
                                  color: _textPrimary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              // Action Buttons - FIXED (tetap di bawah)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          _showSnackBar('Membuka file ${data['nama']}');
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryRed,
                          side: BorderSide(color: _primaryRed),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: Icon(
                          data['file_type'] == 'pdf' 
                            ? Icons.picture_as_pdf
                            : Icons.image,
                          size: 20,
                        ),
                        label: const Text(
                          'BUKA FILE',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _verifyDocument(data),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: data['is_approved'] ? Colors.grey[400] : _green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        icon: const Icon(Icons.verified, size: 20),
                        label: Text(
                          data['is_approved'] ? 'TELAH DIVERIFIKASI' : 'VERIFIKASI',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
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
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _verifyDocument(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController catatanController = TextEditingController();
        final FocusNode catatanFocusNode = FocusNode();
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.verified,
                          color: _green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VERIFIKASI DOKUMEN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6B1B1B),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Konfirmasi verifikasi bukti PKL',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Info Siswa
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detail Siswa',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6B1B1B),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data['nama'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.apartment,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                data['industri'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Status Pilihan
                  const Text(
                    'Status Verifikasi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B1B1B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusOption(
                          'Setujui',
                          _green,
                          Icons.check_circle,
                          data['status'] == 'Diterima',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusOption(
                          'Tolak',
                          _red,
                          Icons.cancel,
                          data['status'] == 'Ditolak',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusOption(
                          'Revisi',
                          _orange,
                          Icons.edit,
                          data['status'] == 'Perlu Revisi',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Catatan
                  const Text(
                    'Catatan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B1B1B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: catatanController,
                      focusNode: catatanFocusNode,
                      maxLines: 4,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Masukkan catatan verifikasi...',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryRed,
                            side: const BorderSide(color: Color(0xFF6B1B1B)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'BATAL',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final catatan = catatanController.text.trim();
                            String status = 'Diterima';
                            Color statusColor = _green;
                            
                            // Pilih status berdasarkan tombol yang aktif
                            if (data['status'] == 'Ditolak') {
                              status = 'Ditolak';
                              statusColor = _red;
                            } else if (data['status'] == 'Perlu Revisi') {
                              status = 'Perlu Revisi';
                              statusColor = _orange;
                            }
                            
                            _showSnackBar('Dokumen ${data['nama']} berhasil $status${catatan.isNotEmpty ? ' dengan catatan: $catatan' : ''}');
                            
                            // Update status di data dummy
                            setState(() {
                              final index = _buktiPklData.indexWhere((item) => item['id'] == data['id']);
                              if (index != -1) {
                                _buktiPklData[index]['status'] = status;
                                _buktiPklData[index]['statusColor'] = statusColor;
                                _buktiPklData[index]['is_approved'] = status == 'Diterima';
                                _buktiPklData[index]['tanggal_verifikasi'] = '${DateTime.now().day} ${_getMonthName(DateTime.now().month)} ${DateTime.now().year} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
                                _buktiPklData[index]['verifikator'] = 'Kaprog';
                                if (catatan.isNotEmpty) {
                                  _buktiPklData[index]['catatan'] = catatan;
                                }
                              }
                            });
                            
                            Navigator.pop(context);
                            _filterByStatus(_filterStatus); // Refresh filter
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            data['status'] == 'Ditolak' ? 'TOLAK' : 
                            data['status'] == 'Perlu Revisi' ? 'MINT REVISI' : 'VERIFIKASI',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusOption(String text, Color color, IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha:0.2) : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? color : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: isSelected ? color : Colors.grey[600]),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return months[month - 1];
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      setState(() {
        _filteredData = _buktiPklData.where((item) {
          return item['nama'].toLowerCase().contains(query) ||
                 item['kelas'].toLowerCase().contains(query) ||
                 item['industri'].toLowerCase().contains(query);
        }).toList();
      });
    } else {
      _filterByStatus(_filterStatus);
    }
  }

  Future<void> _refreshData() async {
    // Simulasi loading
    await Future.delayed(const Duration(seconds: 1));
    _loadDummyData();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: _bgSoft,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        backgroundColor: Colors.white,
        color: _primaryRed,
        child: SingleChildScrollView(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _headerCard(),
              const SizedBox(height: 16),
              _filterSection(),
              const SizedBox(height: 20),
              _statisticsSection(),
              const SizedBox(height: 20),
              _documentList(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bukti PKL',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B1B1B),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Verifikasi bukti penerimaan PKL siswa',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Verifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B1B1B),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusOptions.map((status) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    text: status,
                    isSelected: _filterStatus == status,
                    onTap: () => _filterByStatus(status),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          _searchField(),
        ],
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget _FilterChip({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _primaryRed),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : _primaryRed,
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration.collapsed(
                hintText: 'Cari nama siswa, kelas, atau industri...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              onChanged: (value) => _performSearch(),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _performSearch();
                });
              },
              icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _statisticsSection() {
    final diterimaCount = _buktiPklData.where((item) => item['status'] == 'Diterima').length;
    final menungguCount = _buktiPklData.where((item) => item['status'] == 'Menunggu Verifikasi').length;
    final revisiCount = _buktiPklData.where((item) => item['status'] == 'Perlu Revisi').length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem('Total', _buktiPklData.length.toString(), Icons.list_alt, _primaryRed),
          _StatItem('Diterima', diterimaCount.toString(), Icons.check_circle, _green),
          _StatItem('Menunggu', menungguCount.toString(), Icons.access_time, _orange),
          _StatItem('Revisi', revisiCount.toString(), Icons.edit, _orange),
        ],
      ),
    );
  }

  // ignore: non_constant_identifier_names
  Widget _StatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha:0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _documentList() {
    if (_filteredData.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada data bukti PKL',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filterStatus == 'Semua' 
                ? 'Belum ada bukti PKL yang dikirim siswa'
                : 'Tidak ada bukti PKL dengan status "$_filterStatus"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daftar Dokumen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _primaryRed,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryRed.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primaryRed.withValues(alpha:0.2)),
                ),
                child: Text(
                  '${_filteredData.length} dokumen',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primaryRed,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._filteredData.map((data) => _DocumentCard(
            data: data,
            onTap: () => _showFileDetail(data),
          )),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _DocumentCard({
    required this.data,
    required this.onTap,
  });

  static const Color _primaryRed = Color(0xFF6B1B1B);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _primaryRed.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _primaryRed.withValues(alpha:0.3)),
                      ),
                      child: Icon(
                        data['file_type'] == 'pdf' 
                          ? Icons.picture_as_pdf
                          : Icons.image,
                        color: _primaryRed,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['nama'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              data['kelas'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: data['statusColor'].withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: data['statusColor'].withValues(alpha:0.3)),
                      ),
                      child: Text(
                        data['status'],
                        style: TextStyle(
                          color: data['statusColor'],
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Industry Info
                Row(
                  children: [
                    Icon(Icons.apartment, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['industri'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // File Info
                Row(
                  children: [
                    Icon(
                      data['file_type'] == 'pdf' 
                        ? Icons.description
                        : Icons.photo,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${data['file_type'].toUpperCase()} • ${data['file_size']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Text(
                      data['tanggal_kirim'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                
                // Verifikator Info
                if (data['verifikator'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.verified_user, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verifikator: ${data['verifikator']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Catatan Preview
                if (data['catatan'] != null && data['catatan'].isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['catatan'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                // Action Button
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryRed,
                      side: const BorderSide(color: _primaryRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text(
                      'LIHAT DETAIL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}