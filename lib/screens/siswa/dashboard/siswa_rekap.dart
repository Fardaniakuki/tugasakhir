import 'package:flutter/material.dart';

// Definisi Warna Tema Professional
class RekapTheme {
  static const Color primaryRed = Color(0xFF9f0712);
  static const Color background = Color(0xFFF8F9FA); // Putih tulang / abu sangat muda
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF2D3748);
  static const Color textGrey = Color(0xFF718096);
  static const Color border = Color(0xFFE2E8F0);
  
  static const Color green = Color(0xFF38A169);
  static const Color orange = Color(0xFFDD6B20);
  static const Color red = Color(0xFFE53E3E);
  static const Color blue = Color(0xFF3182CE);
}

class SiswaRekap extends StatefulWidget {
  const SiswaRekap({super.key, required void Function() onQuickActionPressed, required Future<void> Function() onAjukanIjin});

  @override
  State<SiswaRekap> createState() => _SiswaRekapState();
}

class _SiswaRekapState extends State<SiswaRekap> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  late TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: RekapTheme.background,
      appBar: AppBar(
        backgroundColor: RekapTheme.surface,
        elevation: 0,
        title: const Text(
          'Rekapitulasi',
          style: TextStyle(
            color: RekapTheme.textDark, 
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: RekapTheme.border)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: RekapTheme.primaryRed,
              unselectedLabelColor: RekapTheme.textGrey,
              indicatorColor: RekapTheme.primaryRed,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Riwayat Izin (SIA)'),
                Tab(text: 'Riwayat PKL'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SiswaSiaContent(),
          SiswaPengajuanPklContent(),
        ],
      ),
    );
  }
}

// ==============================================
// TAB 1: IZIN SIA (Siswa)
// ==============================================

class SiswaSiaContent extends StatefulWidget {
  const SiswaSiaContent({super.key});

  @override
  State<SiswaSiaContent> createState() => _SiswaSiaContentState();
}

class _SiswaSiaContentState extends State<SiswaSiaContent> {
  // Mock Data
  final List<Map<String, dynamic>> _siaData = [
    {
      'id': 'SIA001',
      'jenis': 'Izin',
      'tanggal': '24 Jan 2024',
      'durasi': '1 hari',
      'alasan': 'Keperluan keluarga penting',
      'status': 'Disetujui',
      'statusColor': RekapTheme.green,
      'tanggal_ajukan': '22 Jan 2024',
      'is_ditolak': false,
    },
    {
      'id': 'SIA002',
      'jenis': 'Sakit',
      'tanggal': '18-19 Jan 2024',
      'durasi': '2 hari',
      'alasan': 'Demam dan flu berat',
      'status': 'Disetujui',
      'statusColor': RekapTheme.green,
      'tanggal_ajukan': '17 Jan 2024',
      'is_ditolak': false,
    },
    {
      'id': 'SIA003',
      'jenis': 'Izin',
      'tanggal': '15 Jan 2024',
      'durasi': '1 hari',
      'alasan': 'Mengikuti seminar',
      'status': 'Menunggu',
      'statusColor': RekapTheme.orange,
      'tanggal_ajukan': '14 Jan 2024',
      'is_ditolak': false,
    },
    {
      'id': 'SIA004',
      'jenis': 'Alpha',
      'tanggal': '10 Jan 2024',
      'durasi': '1 hari',
      'alasan': 'Tidak ada keterangan',
      'status': 'Ditolak',
      'statusColor': RekapTheme.red,
      'tanggal_ajukan': '11 Jan 2024',
      'is_ditolak': true,
      'alasan_tolak': 'Tidak ada surat keterangan',
    },
  ];

  String _filterStatus = 'Semua';
  final List<String> _statusOptions = ['Semua', 'Disetujui', 'Menunggu', 'Ditolak'];

  @override
  Widget build(BuildContext context) {
    final filteredData = _siaData.where((item) {
      if (_filterStatus == 'Semua') return true;
      return item['status'] == _filterStatus;
    }).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Summary Cards
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Total Izin', _siaData.length.toString(), Icons.folder_copy_outlined, RekapTheme.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('Disetujui', _siaData.where((e) => e['status'] == 'Disetujui').length.toString(), Icons.check_circle_outline, RekapTheme.green)),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statusOptions.map((status) => _buildFilterChip(status)).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // 3. List Data
          if (filteredData.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredData.length,
              separatorBuilder: (ctx, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildSiaCard(filteredData[index]);
              },
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String status) {
    final bool isSelected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => setState(() => _filterStatus = status),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? RekapTheme.primaryRed : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? RekapTheme.primaryRed : RekapTheme.border,
            ),
            boxShadow: isSelected 
              ? [BoxShadow(color: RekapTheme.primaryRed.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
          ),
          child: Text(
            status,
            style: TextStyle(
              color: isSelected ? Colors.white : RekapTheme.textGrey,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RekapTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: RekapTheme.textDark)),
              Text(title, style: const TextStyle(fontSize: 12, color: RekapTheme.textGrey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSiaCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RekapTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: RekapTheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      data['jenis'] == 'Sakit' ? Icons.medical_services_outlined : 
                      data['jenis'] == 'Alpha' ? Icons.warning_amber_rounded : Icons.assignment_outlined,
                      size: 14,
                      color: RekapTheme.textDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      data['jenis'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: RekapTheme.textDark),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(data['status'], data['statusColor']),
            ],
          ),
          const SizedBox(height: 12),
          
          // Content
          Text(
            '${data['tanggal']} (${data['durasi']})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: RekapTheme.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            data['alasan'],
            style: const TextStyle(color: RekapTheme.textGrey, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          // Divider if rejected
          if (data['is_ditolak'] == true) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: RekapTheme.border),
            ),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: RekapTheme.red),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Alasan Ditolak: ${data['alasan_tolak']}',
                    style: const TextStyle(color: RekapTheme.red, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.filter_list_off, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Tidak ada data ditemukan',
              style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ==============================================
// TAB 2: PENGAJUAN PKL (Siswa)
// ==============================================

class SiswaPengajuanPklContent extends StatefulWidget {
  const SiswaPengajuanPklContent({super.key});

  @override
  State<SiswaPengajuanPklContent> createState() => _SiswaPengajuanPklContentState();
}

class _SiswaPengajuanPklContentState extends State<SiswaPengajuanPklContent> {
  // Mock Data
  final List<Map<String, dynamic>> _pengajuanData = [
    {
      'id': 'PKL001',
      'jenis': 'Pengajuan Baru',
      'industri': 'PT. Teknologi Indonesia',
      'alamat': 'Jl. Sudirman No. 123, Jakarta',
      'tanggal_ajukan': '15 Jan 2024',
      'status': 'Disetujui',
      'statusColor': RekapTheme.green,
      'guru_pembimbing': 'Dr. Budi Santoso',
      'tanggal_mulai': '1 Feb 2024',
      'is_ditolak': false,
    },
    {
      'id': 'PKL002',
      'jenis': 'Pindah PKL',
      'industri': 'CV. Digital Solusi',
      'alamat': 'Jl. Thamrin No. 45, Jakarta',
      'tanggal_ajukan': '14 Jan 2024',
      'status': 'Menunggu',
      'statusColor': RekapTheme.orange,
      'is_ditolak': false,
    },
    {
      'id': 'PKL003',
      'jenis': 'Pengajuan Baru',
      'industri': 'PT. Media Kreatif',
      'alamat': 'Jl. Gatot Subroto No. 67, Jakarta',
      'tanggal_ajukan': '13 Jan 2024',
      'status': 'Ditolak',
      'statusColor': RekapTheme.red,
      'is_ditolak': true,
      'alasan_tolak': 'Kuota industri sudah penuh',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // 1. Stats Row
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Total', _pengajuanData.length.toString(), Icons.assignment, RekapTheme.primaryRed)),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('Disetujui', _pengajuanData.where((e) => e['status'] == 'Disetujui').length.toString(), Icons.check_circle, RekapTheme.green)),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Section Title
          const Row(
            children: [
              Text('Riwayat Pengajuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: RekapTheme.textDark)),
            ],
          ),
          const SizedBox(height: 12),

          // 3. List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pengajuanData.length,
            separatorBuilder: (ctx, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildPklCard(_pengajuanData[index]);
            },
          ),
           const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RekapTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: RekapTheme.textDark)),
              Icon(icon, color: color.withOpacity(0.5), size: 24),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: RekapTheme.textGrey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPklCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RekapTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: RekapTheme.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business_rounded, color: RekapTheme.textDark, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['industri'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: RekapTheme.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['jenis'],
                      style: const TextStyle(color: RekapTheme.textGrey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(data['status'], data['statusColor']),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: RekapTheme.border),
          ),
          
          // Details
          _buildInfoRow(Icons.location_on_outlined, data['alamat']),
          if (data['guru_pembimbing'] != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.person_outline, 'Pembimbing: ${data['guru_pembimbing']}'),
          ],
          const SizedBox(height: 8),
          _buildInfoRow(Icons.calendar_today_outlined, 'Diajukan: ${data['tanggal_ajukan']}'),

          // Rejected Info
          if (data['is_ditolak'] == true) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: RekapTheme.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: RekapTheme.red.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: RekapTheme.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Alasan: ${data['alasan_tolak']}',
                      style: const TextStyle(color: RekapTheme.red, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: RekapTheme.textGrey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: RekapTheme.textDark),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}