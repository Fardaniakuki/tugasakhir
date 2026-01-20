import 'package:flutter/material.dart';

class DataPesertaDidikScreen extends StatefulWidget {
  final int kelasId;
  final String namaKelas;

  const DataPesertaDidikScreen({
    super.key,
    required this.kelasId,
    required this.namaKelas,
  });

  @override
  State<DataPesertaDidikScreen> createState() => _DataPesertaDidikScreenState();
}

class _DataPesertaDidikScreenState extends State<DataPesertaDidikScreen> {
  List<dynamic> _siswaList = [];
  bool _isLoading = false; // Ubah jadi false karena langsung pakai data dummy
  String _searchQuery = '';
  
  // Warna sesuai permintaan (sama dengan Wali Kelas Dashboard)
  static const Color _primaryColor = Color(0xFF9F0712); // Merah
  static const Color _secondaryColor = Color(0xFFE6E3E3); // Abu-abu muda
// Merah (sama dengan primary)
  static const Color _darkColor = Color(0xFF641E20); // Merah tua
  static const Color _yellowColor = Color(0xFFFFB703); // Kuning
  static const Color _blackColor = Colors.black;
  
  // Neo Brutalism Shadows
  static const BoxShadow _heavyShadow = BoxShadow(
    color: Colors.black,
    offset: Offset(6, 6),
    blurRadius: 0,
  );
  
  final BoxShadow _lightShadow = BoxShadow(
    color: Colors.black.withValues(alpha:0.2),
    offset: const Offset(4, 4),
    blurRadius: 0,
  );

  @override
  void initState() {
    super.initState();
    // Langsung gunakan data dummy tanpa loading
    _useDummyData();
  }

  void _useDummyData() {
    // Data dummy peserta didik
    final dummyData = [
      {
        'id': 1,
        'nama_lengkap': 'Ahmad Rizki Pratama',
        'nis': '20230001',
        'jenis_kelamin': 'Laki-laki',
        'tempat_lahir': 'Jakarta',
        'tanggal_lahir': '2007-05-15',
        'alamat': 'Jl. Merdeka No. 123, Jakarta Pusat',
        'nomor_telepon': '081234567890',
        'email': 'ahmad@example.com',
        'nama_ortu': 'Budi Santoso',
        'telepon_ortu': '081234567891',
        'pkl_status': 'approved',
        'status_akademik': 'Aktif'
      },
      {
        'id': 2,
        'nama_lengkap': 'Siti Nurhaliza',
        'nis': '20230002',
        'jenis_kelamin': 'Perempuan',
        'tempat_lahir': 'Bandung',
        'tanggal_lahir': '2007-08-20',
        'alamat': 'Jl. Asia Afrika No. 456, Bandung',
        'nomor_telepon': '082345678901',
        'email': 'siti@example.com',
        'nama_ortu': 'Dewi Lestari',
        'telepon_ortu': '082345678902',
        'pkl_status': 'pending',
        'status_akademik': 'Aktif'
      },
      {
        'id': 3,
        'nama_lengkap': 'Muhammad Fajar',
        'nis': '20230003',
        'jenis_kelamin': 'Laki-laki',
        'tempat_lahir': 'Surabaya',
        'tanggal_lahir': '2007-02-10',
        'alamat': 'Jl. Diponegoro No. 789, Surabaya',
        'nomor_telepon': '083456789012',
        'email': 'fajar@example.com',
        'nama_ortu': 'Joko Susilo',
        'telepon_ortu': '083456789013',
        'pkl_status': 'rejected',
        'status_akademik': 'Aktif'
      },
      {
        'id': 4,
        'nama_lengkap': 'Rina Anggraini',
        'nis': '20230004',
        'jenis_kelamin': 'Perempuan',
        'tempat_lahir': 'Semarang',
        'tanggal_lahir': '2007-11-30',
        'alamat': 'Jl. Pemuda No. 101, Semarang',
        'nomor_telepon': '084567890123',
        'email': 'rina@example.com',
        'nama_ortu': 'Sari Wati',
        'telepon_ortu': '084567890124',
        'pkl_status': 'none',
        'status_akademik': 'Aktif'
      },
      {
        'id': 5,
        'nama_lengkap': 'Dewi Sartika',
        'nis': '20230005',
        'jenis_kelamin': 'Perempuan',
        'tempat_lahir': 'Yogyakarta',
        'tanggal_lahir': '2007-03-25',
        'alamat': 'Jl. Malioboro No. 55, Yogyakarta',
        'nomor_telepon': '085678901234',
        'email': 'dewi@example.com',
        'nama_ortu': 'Rini Hartati',
        'telepon_ortu': '085678901235',
        'pkl_status': 'approved',
        'status_akademik': 'Aktif'
      },
      {
        'id': 6,
        'nama_lengkap': 'Budi Setiawan',
        'nis': '20230006',
        'jenis_kelamin': 'Laki-laki',
        'tempat_lahir': 'Medan',
        'tanggal_lahir': '2007-07-12',
        'alamat': 'Jl. Gatot Subroto No. 78, Medan',
        'nomor_telepon': '086789012345',
        'email': 'budi@example.com',
        'nama_ortu': 'Surya Wijaya',
        'telepon_ortu': '086789012346',
        'pkl_status': 'pending',
        'status_akademik': 'Aktif'
      },
      {
        'id': 7,
        'nama_lengkap': 'Ani Lestari',
        'nis': '20230007',
        'jenis_kelamin': 'Perempuan',
        'tempat_lahir': 'Makassar',
        'tanggal_lahir': '2007-09-05',
        'alamat': 'Jl. Perintis Kemerdekaan No. 33, Makassar',
        'nomor_telepon': '087890123456',
        'email': 'ani@example.com',
        'nama_ortu': 'Linda Sari',
        'telepon_ortu': '087890123457',
        'pkl_status': 'approved',
        'status_akademik': 'Aktif'
      },
      {
        'id': 8,
        'nama_lengkap': 'Agus Supriyanto',
        'nis': '20230008',
        'jenis_kelamin': 'Laki-laki',
        'tempat_lahir': 'Denpasar',
        'tanggal_lahir': '2007-12-18',
        'alamat': 'Jl. Hayam Wuruk No. 99, Denpasar',
        'nomor_telepon': '088901234567',
        'email': 'agus@example.com',
        'nama_ortu': 'Agung Prabowo',
        'telepon_ortu': '088901234568',
        'pkl_status': 'approved',
        'status_akademik': 'Aktif'
      },
      {
        'id': 9,
        'nama_lengkap': 'Maya Sari',
        'nis': '20230009',
        'jenis_kelamin': 'Perempuan',
        'tempat_lahir': 'Palembang',
        'tanggal_lahir': '2007-04-22',
        'alamat': 'Jl. Jenderal Sudirman No. 44, Palembang',
        'nomor_telepon': '089012345678',
        'email': 'maya@example.com',
        'nama_ortu': 'Ratna Dewi',
        'telepon_ortu': '089012345679',
        'pkl_status': 'pending',
        'status_akademik': 'Aktif'
      },
      {
        'id': 10,
        'nama_lengkap': 'Hendra Kurniawan',
        'nis': '20230010',
        'jenis_kelamin': 'Laki-laki',
        'tempat_lahir': 'Bogor',
        'tanggal_lahir': '2007-06-08',
        'alamat': 'Jl. Pajajaran No. 77, Bogor',
        'nomor_telepon': '089123456789',
        'email': 'hendra@example.com',
        'nama_ortu': 'Kurnia Wibowo',
        'telepon_ortu': '089123456780',
        'pkl_status': 'none',
        'status_akademik': 'Aktif'
      },
    ];

    setState(() {
      _siswaList = dummyData;
      _isLoading = false;
    });
  }

  List<dynamic> _getFilteredSiswa() {
    if (_searchQuery.isEmpty) return _siswaList;
    
    return _siswaList.where((siswa) {
      final nama = siswa['nama_lengkap']?.toString().toLowerCase() ?? '';
      final nis = siswa['nis']?.toString().toLowerCase() ?? '';
      return nama.contains(_searchQuery.toLowerCase()) ||
            nis.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSiswa = _getFilteredSiswa();

    return Scaffold(
      backgroundColor: _darkColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _primaryColor,
                border: Border.all(color: _blackColor, width: 3),
                boxShadow: const [_heavyShadow],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _yellowColor,
                        border: Border.all(color: _blackColor, width: 3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DATA PESERTA DIDIK',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Kelas ${widget.namaKelas}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha:0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _secondaryColor,
                      border: Border.all(color: _blackColor, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_siswaList.length} SISWA',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _blackColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _secondaryColor,
                border: Border.all(color: _blackColor, width: 3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [_heavyShadow],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _yellowColor,
                      border: Border.all(color: _blackColor, width: 2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.search,
                      color: _blackColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Cari nama atau NIS peserta didik...',
                        hintStyle: TextStyle(
                          color: _darkColor.withValues(alpha:0.6),
                          fontWeight: FontWeight.w600,
                        ),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(
                        color: _blackColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Container utama - PERBAIKAN: Gunakan Expanded dengan SingleChildScrollView
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 24),
                decoration: BoxDecoration(
                  color: _secondaryColor,
                  border: Border.all(color: _blackColor, width: 4),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  boxShadow: const [_heavyShadow],
                ),
                child: SingleChildScrollView( // PERBAIKAN: Tambahkan SingleChildScrollView
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Menu
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              border: Border.all(color: _blackColor, width: 3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: _yellowColor,
                                    border: Border.all(color: _blackColor, width: 2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.people_alt,
                                    size: 20,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'DAFTAR PESERTA DIDIK',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Daftar siswa
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _isLoading
                              ? _buildLoadingSkeleton()
                              : filteredSiswa.isEmpty
                                  ? _buildEmptyState()
                                  : Column(
                                      children: List.generate(filteredSiswa.length, (index) {
                                        final siswa = filteredSiswa[index];
                                        return _buildSiswaCard(siswa);
                                      }),
                                    ),
                        ),
                        const SizedBox(height: 30), // Tambahkan spacing di bawah
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiswaCard(Map<String, dynamic> siswa) {
    final pklStatus = siswa['pkl_status']?.toString().toLowerCase() ?? 'none';
    final statusColor = _getPKLStatusColor(pklStatus);
    final statusText = _getPKLStatusText(pklStatus);
    final jenisKelamin = siswa['jenis_kelamin'] ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _secondaryColor,
        border: Border.all(color: _blackColor, width: 4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [_heavyShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header dengan status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor,
              border: const Border(
                bottom: BorderSide(color: _blackColor, width: 4),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                // Avatar berdasarkan jenis kelamin
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _blackColor, width: 3),
                    shape: BoxShape.circle,
                    boxShadow: [_lightShadow],
                  ),
                  child: Icon(
                    jenisKelamin == 'Perempuan' ? Icons.female : Icons.male,
                    color: _primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Nama dan NIS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siswa['nama_lengkap'] ?? 'Nama Tidak Tersedia',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'NIS: ${siswa['nis'] ?? '-'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha:0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: jenisKelamin == 'Perempuan' 
                                  ? const Color(0xFFE91E63)
                                  : const Color(0xFF2196F3),
                              border: Border.all(color: _blackColor, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              jenisKelamin == 'Perempuan' ? 'P' : 'L',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Detail informasi
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Tempat & Tanggal Lahir
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha:0.1),
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.place,
                          label: 'TEMPAT LAHIR',
                          value: siswa['tempat_lahir'] ?? '-',
                          color: const Color(0xFF118AB2),
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 40,
                        color: _blackColor,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.cake,
                          label: 'TANGGAL LAHIR',
                          value: siswa['tanggal_lahir'] ?? '-',
                          color: const Color(0xFF06D6A0),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Kontak
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha:0.1),
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.phone,
                          label: 'TELEPON',
                          value: siswa['nomor_telepon'] ?? '-',
                          color: _primaryColor,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 40,
                        color: _blackColor,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.email,
                          label: 'EMAIL',
                          value: siswa['email'] ?? '-',
                          color: const Color(0xFF06D6A0),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Orang Tua
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha:0.1),
                    border: Border.all(color: _blackColor, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.family_restroom,
                          label: 'ORANG TUA',
                          value: siswa['nama_ortu'] ?? '-',
                          color: const Color(0xFFFFB703),
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 40,
                        color: _blackColor,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.phone_android,
                          label: 'TELP. ORANG TUA',
                          value: siswa['telepon_ortu'] ?? '-',
                          color: const Color(0xFF118AB2),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Alamat
                if (siswa['alamat'] != null && siswa['alamat'].toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: _blackColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB703),
                            border: Border.all(color: _blackColor, width: 2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on,
                            size: 18,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ALAMAT',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: _darkColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                siswa['alamat'].toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _blackColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Container(
                  decoration: BoxDecoration(
                    color: _primaryColor,
                    border: Border.all(color: _blackColor, width: 3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () {
                      _showSiswaDetail(siswa);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'LIHAT DETAIL LENGKAP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
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
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _darkColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _blackColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color _getPKLStatusColor(String status) {
    switch (status) {
      case 'approved':
      case 'disetujui':
        return const Color(0xFF06D6A0); // Hijau
      case 'rejected':
      case 'ditolak':
        return const Color(0xFFE63946); // Merah terang
      case 'pending':
      case 'menunggu':
        return const Color(0xFFFFB703); // Kuning
      default:
        return _primaryColor; // Merah tua default
    }
  }

  String _getPKLStatusText(String status) {
    switch (status) {
      case 'approved':
      case 'disetujui':
        return 'PKL AKTIF';
      case 'rejected':
      case 'ditolak':
        return 'DITOLAK';
      case 'pending':
      case 'menunggu':
        return 'MENUNGGU';
      default:
        return 'BELUM PKL';
    }
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _secondaryColor,
            border: Border.all(color: _blackColor, width: 4),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeleton header
              Container(
                width: 200,
                height: 24,
                decoration: BoxDecoration(
                  color: _blackColor.withValues(alpha:0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 12),
              
              // Skeleton content
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _blackColor.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 150,
                          height: 16,
                          decoration: BoxDecoration(
                            color: _blackColor.withValues(alpha:0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _primaryColor.withValues(alpha:0.3),
                      border: Border.all(color: _blackColor.withValues(alpha:0.3), width: 3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _primaryColor,
              border: Border.all(color: _blackColor, width: 4),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline,
              size: 50,
              color: _secondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'TIDAK ADA DATA PESERTA DIDIK',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _blackColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Tidak ditemukan peserta didik pada kelas ini',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: _darkColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSiswaDetail(Map<String, dynamic> siswa) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _secondaryColor,
            border: Border.all(color: _blackColor, width: 4),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [_heavyShadow],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border.all(color: _blackColor, width: 3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  siswa['jenis_kelamin'] == 'Perempuan' ? Icons.female : Icons.male,
                  size: 40,
                  color: _secondaryColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'DETAIL PESERTA DIDIK',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _blackColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                siswa['nama_lengkap'] ?? 'Nama Tidak Tersedia',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  border: Border.all(color: _blackColor, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                  ),
                  child: const Text(
                    'TUTUP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}