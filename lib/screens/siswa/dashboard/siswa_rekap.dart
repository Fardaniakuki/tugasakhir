import 'package:flutter/material.dart';

class SiswaRekap extends StatefulWidget {
  const SiswaRekap({super.key, required void Function() onQuickActionPressed, required Future<void> Function() onAjukanIjin});

  @override
  State<SiswaRekap> createState() => _SiswaRekapState();
}

class _SiswaRekapState extends State<SiswaRekap> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // Warna tema siswa yang serius
  final Color _primaryRed = const Color(0xFF9f0712); // Merah siswa
  final Color _bgSoft = const Color(0xFFF5F5F5); // Background soft
  final Color _secondaryColor = Colors.white;
  final Color _textPrimary = const Color(0xFF333333); // Teks gelap
  final Color _textSecondary = const Color(0xFF666666); // Teks abu-abu
  final Color _borderColor = const Color(0xFFE0E0E0);
  final Color _green = const Color(0xFF4CAF50); // Hijau untuk disetujui
  final Color _orange = const Color(0xFFFF9800); // Oranye untuk menunggu
  final Color _red = const Color(0xFFF44336); // Merah untuk ditolak
  final Color _blue = const Color(0xFF2196F3); // Biru untuk info
  
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bgSoft,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 160.0,
                backgroundColor: _bgSoft,
                pinned: true,
                floating: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _headerCard(),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48.0),
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: _primaryRed,
                      labelColor: _primaryRed,
                      unselectedLabelColor: Colors.grey,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'Izin SIA'),
                        Tab(text: 'Pengajuan PKL'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              // TAB 1: Izin SIA (Sakit/Izin/Alpha)
              SiswaSiaContent(
                primaryRed: _primaryRed,
                bgSoft: _bgSoft,
                secondaryColor: _secondaryColor,
                textPrimary: _textPrimary,
                textSecondary: _textSecondary,
                borderColor: _borderColor,
                green: _green,
                orange: _orange,
                red: _red,
                blue: _blue,
              ),
              
              // TAB 2: Pengajuan PKL
              SiswaPengajuanPklContent(
                primaryRed: _primaryRed,
                bgSoft: _bgSoft,
                secondaryColor: _secondaryColor,
                textPrimary: _textPrimary,
                textSecondary: _textSecondary,
                borderColor: _borderColor,
                green: _green,
                orange: _orange,
                red: _red,
                blue: _blue,
              ),
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rekap & Izin',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: _primaryRed,
                ),
              ),
           
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _selectedTabIndex == 0 
              ? 'Kelola izin sakit, izin, dan alpha'
              : 'Kelola pengajuan dan pindah PKL',
            style: TextStyle(
              fontSize: 16,
              color: _textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================
// TAB 1: IZIN SIA (Siswa)
// ==============================================

class SiswaSiaContent extends StatefulWidget {
  final Color primaryRed;
  final Color bgSoft;
  final Color secondaryColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color green;
  final Color orange;
  final Color red;
  final Color blue;

  const SiswaSiaContent({
    super.key,
    required this.primaryRed,
    required this.bgSoft,
    required this.secondaryColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.green,
    required this.orange,
    required this.red,
    required this.blue,
  });

  @override
  State<SiswaSiaContent> createState() => _SiswaSiaContentState();
}

class _SiswaSiaContentState extends State<SiswaSiaContent> {
  final List<Map<String, dynamic>> _siaData = [
    {
      'id': 'SIA001',
      'jenis': 'Izin',
      'tanggal': '24 Jan 2024',
      'durasi': '1 hari',
      'alasan': 'Keperluan keluarga penting',
      'status': 'Disetujui',
      'statusColor': Colors.green,
      'tanggal_ajukan': '22 Jan 2024',
      'dokumen': 'Surat Keterangan.pdf',
      'is_ditolak': false,
      'alasan_tolak': null,
    },
    {
      'id': 'SIA002',
      'jenis': 'Sakit',
      'tanggal': '18-19 Jan 2024',
      'durasi': '2 hari',
      'alasan': 'Demam dan flu berat',
      'status': 'Disetujui',
      'statusColor': Colors.green,
      'tanggal_ajukan': '17 Jan 2024',
      'dokumen': 'Surat Dokter.pdf',
      'is_ditolak': false,
      'alasan_tolak': null,
    },
    {
      'id': 'SIA003',
      'jenis': 'Izin',
      'tanggal': '15 Jan 2024',
      'durasi': '1 hari',
      'alasan': 'Mengikuti seminar',
      'status': 'Menunggu',
      'statusColor': Colors.orange,
      'tanggal_ajukan': '14 Jan 2024',
      'dokumen': 'Undangan Seminar.pdf',
      'is_ditolak': false,
      'alasan_tolak': null,
    },
    {
      'id': 'SIA004',
      'jenis': 'Alpha',
      'tanggal': '10 Jan 2024',
      'durasi': '1 hari',
      'alasan': 'Tidak ada keterangan',
      'status': 'Ditolak',
      'statusColor': Colors.red,
      'tanggal_ajukan': '11 Jan 2024',
      'dokumen': null,
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

    final totalIzin = _siaData.where((item) => item['jenis'] == 'Izin').length;
    final totalSakit = _siaData.where((item) => item['jenis'] == 'Sakit').length;
    final totalAlpha = _siaData.where((item) => item['jenis'] == 'Alpha').length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          
          // Statistik
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Total', _siaData.length.toString(), Icons.list_alt, widget.primaryRed),
                _buildStatItem('Izin', totalIzin.toString(), Icons.person_pin_circle, widget.blue),
                _buildStatItem('Sakit', totalSakit.toString(), Icons.healing, widget.orange),
                _buildStatItem('Alpha', totalAlpha.toString(), Icons.warning, widget.red),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Filter Status
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Izin',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusOptions.map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _filterStatus = status;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _filterStatus == status ? widget.primaryRed : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: widget.primaryRed),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _filterStatus == status ? Colors.white : widget.primaryRed,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Daftar Izin
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Izin',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: widget.primaryRed,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.primaryRed.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.primaryRed.withValues(alpha:0.3)),
                      ),
                      child: Text(
                        '${filteredData.length} izin',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryRed,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                if (filteredData.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filterStatus == 'Semua'
                            ? 'Belum ada riwayat izin'
                            : 'Tidak ada izin dengan status "$_filterStatus"',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredData.map((data) => _buildIzinCard(data)),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
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

  Widget _buildIzinCard(Map<String, dynamic> data) {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: data['statusColor'].withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: data['statusColor'].withValues(alpha:0.3)),
                  ),
                  child: Icon(
                    data['jenis'] == 'Sakit' ? Icons.healing :
                    data['jenis'] == 'Alpha' ? Icons.warning : Icons.person_pin_circle,
                    color: data['statusColor'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['jenis'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tanggal: ${data['tanggal']} • ${data['durasi']}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
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
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.note, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alasan: ${data['alasan']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Diajukan: ${data['tanggal_ajukan']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            
            if (data['is_ditolak'] && data['alasan_tolak'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.close, size: 16, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Alasan ditolak: ${data['alasan_tolak']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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
  final Color primaryRed;
  final Color bgSoft;
  final Color secondaryColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color borderColor;
  final Color green;
  final Color orange;
  final Color red;
  final Color blue;

  const SiswaPengajuanPklContent({
    super.key,
    required this.primaryRed,
    required this.bgSoft,
    required this.secondaryColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.borderColor,
    required this.green,
    required this.orange,
    required this.red,
    required this.blue,
  });

  @override
  State<SiswaPengajuanPklContent> createState() => _SiswaPengajuanPklContentState();
}

class _SiswaPengajuanPklContentState extends State<SiswaPengajuanPklContent> {
  final List<Map<String, dynamic>> _pengajuanData = [
    {
      'id': 'PKL001',
      'jenis': 'Pengajuan Baru',
      'industri': 'PT. Teknologi Indonesia',
      'alamat': 'Jl. Sudirman No. 123, Jakarta',
      'tanggal_ajukan': '15 Jan 2024',
      'status': 'Disetujui',
      'statusColor': Colors.green,
      'guru_pembimbing': 'Dr. Budi Santoso, M.Kom.',
      'tanggal_mulai': '1 Feb 2024',
      'durasi': '3 bulan',
      'is_ditolak': false,
      'alasan_tolak': null,
    },
    {
      'id': 'PKL002',
      'jenis': 'Pindah PKL',
      'industri': 'CV. Digital Solusi',
      'alamat': 'Jl. Thamrin No. 45, Jakarta',
      'industri_asal': 'PT. Jaringan Nusantara',
      'tanggal_ajukan': '14 Jan 2024',
      'status': 'Menunggu',
      'statusColor': Colors.orange,
      'guru_pembimbing': null,
      'tanggal_mulai': null,
      'durasi': null,
      'is_ditolak': false,
      'alasan_tolak': null,
      'alasan_pindah': 'Lebih sesuai dengan jurusan',
    },
    {
      'id': 'PKL003',
      'jenis': 'Pengajuan Baru',
      'industri': 'PT. Media Kreatif',
      'alamat': 'Jl. Gatot Subroto No. 67, Jakarta',
      'tanggal_ajukan': '13 Jan 2024',
      'status': 'Ditolak',
      'statusColor': Colors.red,
      'guru_pembimbing': null,
      'tanggal_mulai': null,
      'durasi': null,
      'is_ditolak': true,
      'alasan_tolak': 'Kuota industri sudah penuh',
    },
  ];

  String _filterStatus = 'Semua';
  final List<String> _statusOptions = ['Semua', 'Disetujui', 'Menunggu', 'Ditolak'];



  @override
  Widget build(BuildContext context) {
    final filteredData = _pengajuanData.where((item) {
      if (_filterStatus == 'Semua') return true;
      return item['status'] == _filterStatus;
    }).toList();

    final totalDisetujui = _pengajuanData.where((item) => item['status'] == 'Disetujui').length;
    final totalMenunggu = _pengajuanData.where((item) => item['status'] == 'Menunggu').length;
    final totalDitolak = _pengajuanData.where((item) => item['status'] == 'Ditolak').length;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          
          const SizedBox(height: 20),
          
          // Statistik
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem('Total', _pengajuanData.length.toString(), Icons.list_alt, widget.primaryRed),
                _buildStatItem('Disetujui', totalDisetujui.toString(), Icons.check_circle, widget.green),
                _buildStatItem('Menunggu', totalMenunggu.toString(), Icons.access_time, widget.orange),
                _buildStatItem('Ditolak', totalDitolak.toString(), Icons.close, widget.red),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Filter Status
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Pengajuan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _statusOptions.map((status) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _filterStatus = status;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _filterStatus == status ? widget.primaryRed : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: widget.primaryRed),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _filterStatus == status ? Colors.white : widget.primaryRed,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Daftar Pengajuan
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Pengajuan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: widget.primaryRed,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: widget.primaryRed.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.primaryRed.withValues(alpha:0.3)),
                      ),
                      child: Text(
                        '${filteredData.length} pengajuan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.primaryRed,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                if (filteredData.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _filterStatus == 'Semua'
                            ? 'Belum ada riwayat pengajuan'
                            : 'Tidak ada pengajuan dengan status "$_filterStatus"',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredData.map((data) => _buildPengajuanCard(data)),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
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

  Widget _buildPengajuanCard(Map<String, dynamic> data) {
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: data['statusColor'].withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: data['statusColor'].withValues(alpha:0.3)),
                  ),
                  child: Icon(
                    data['jenis'] == 'Pindah PKL' ? Icons.swap_horiz : Icons.apartment,
                    color: data['statusColor'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['jenis'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['industri'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data['alamat'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Diajukan: ${data['tanggal_ajukan']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            
            if (data['guru_pembimbing'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Pembimbing: ${data['guru_pembimbing']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            
            if (data['tanggal_mulai'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Mulai: ${data['tanggal_mulai']} • ${data['durasi']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            
            if (data['is_ditolak'] && data['alasan_tolak'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.close, size: 16, color: Colors.red[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Alasan ditolak: ${data['alasan_tolak']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}