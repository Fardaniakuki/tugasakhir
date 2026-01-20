import 'package:flutter/material.dart';

class KelolaPerizinanTabScreen extends StatefulWidget {
  final ScrollController? scrollController;
  
  const KelolaPerizinanTabScreen({
    super.key,
    this.scrollController,
  });

  @override
  State<KelolaPerizinanTabScreen> createState() => _KelolaPerizinanTabScreenState();
}

class _KelolaPerizinanTabScreenState extends State<KelolaPerizinanTabScreen> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  final Color _primaryRed = const Color(0xFF6B1B1B);
  final Color _bgSoft = const Color(0xFFF6EEEE);
  final Color _secondaryColor = Colors.white;
  final Color _textPrimary = Colors.black;
  final Color _textSecondary = const Color(0xFF666666);
  final Color _borderColor = const Color(0xFFE0E0E0);
  final Color _green = const Color(0xFF4CAF50);
  final Color _orange = const Color(0xFFFF9800);
  final Color _red = const Color(0xFFF44336);
  final Color _blue = const Color(0xFF2196F3);
  
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
                expandedHeight: 180.0,
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
                        Tab(text: 'SIA (Sakit/Izin/Alpha)'),
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
              // TAB 1: Kelola SIA (Sakit/Izin/Alpha)
              KelolaSiaContent(
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
              
              // TAB 2: Kelola Pengajuan PKL
              KelolaPengajuanPklContent(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kelola Perizinan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B1B1B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _selectedTabIndex == 0 
              ? 'Kelola Sakit, Izin, dan Alpha siswa PKL'
              : 'Kelola pengajuan dan pindah PKL siswa',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================================
// TAB 1: KELOLA SIA (Sakit/Izin/Alpha)
// ==============================================

class KelolaSiaContent extends StatefulWidget {
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

  const KelolaSiaContent({
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
  State<KelolaSiaContent> createState() => _KelolaSiaContentState();
}

class _KelolaSiaContentState extends State<KelolaSiaContent> 
    with SingleTickerProviderStateMixin {
  
  late TabController _siaTabController;
  int _selectedSiaTabIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'Semua';

  @override
  void initState() {
    super.initState();
    _siaTabController = TabController(length: 3, vsync: this);
    _siaTabController.addListener(() {
      setState(() {
        _selectedSiaTabIndex = _siaTabController.index;
      });
    });
  }

  @override
  void dispose() {
    _siaTabController.dispose();
    _searchController.dispose();
    super.dispose();
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
        backgroundColor: isError ? widget.red : widget.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _approveSia(Map<String, dynamic> data) {
    setState(() {
      // In a real app, you would update the data source
    });
    _showSnackBar('Pengajuan ${data['status']} disetujui');
  }

  void _rejectSia(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController alasanController = TextEditingController();
        
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
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: widget.red.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.close,
                          color: widget.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOLAK PENGAJUAN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6B1B1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Siswa: ${data['nama']}',
                              style: const TextStyle(
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

                  const Text(
                    'Alasan Penolakan',
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
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: alasanController,
                      maxLines: 4,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Masukkan alasan penolakan...',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: widget.primaryRed,
                            side: BorderSide(color: widget.primaryRed),
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
                            if (alasanController.text.trim().isEmpty) {
                              _showSnackBar('Masukkan alasan penolakan', isError: true);
                              return;
                            }
                            _showSnackBar('Pengajuan ditolak');
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'TOLAK',
                            style: TextStyle(
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _filterSection(),
          const SizedBox(height: 20),
          _statisticsSection(),
          const SizedBox(height: 20),
          _tabSection(),
          const SizedBox(height: 40),
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
            'Status Perizinan',
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
              children: ['Semua', 'Disetujui', 'Menunggu', 'Ditolak'].map((status) {
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
          const SizedBox(height: 16),
          Container(
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
                      hintText: 'Cari nama siswa atau industri...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                      });
                    },
                    icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statisticsSection() {
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
          _buildStatItem('Total', '12', Icons.list_alt, widget.primaryRed),
          _buildStatItem('Izin', '8', Icons.person_pin_circle, widget.blue),
          _buildStatItem('Sakit', '4', Icons.healing, widget.orange),
          _buildStatItem('Alpha', '0', Icons.warning, widget.red),
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

  Widget _tabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
              ),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                _buildTabButton('Izin', 0),
                const SizedBox(width: 12),
                _buildTabButton('Sakit', 1),
                const SizedBox(width: 12),
                _buildTabButton('Alpha', 2),
              ],
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(
              minHeight: 400,
            ),
            child: IndexedStack(
              index: _selectedSiaTabIndex,
              children: [
                _buildIzinList(),
                _buildSakitList(),
                _buildAlphaList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final bool isSelected = _selectedSiaTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _siaTabController.animateTo(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? widget.primaryRed : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? widget.primaryRed : Colors.transparent,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIzinList() {
    final List<Map<String, dynamic>> izinData = [
      {
        'nama': 'Ahmad Rizki',
        'kelas': 'XII TKJ 1',
        'industri': 'PT. Teknologi Indonesia',
        'tanggal': '15-20 Jan 2024',
        'alasan': 'Keperluan keluarga penting',
        'status': 'Disetujui',
        'statusColor': widget.green,
      },
      {
        'nama': 'Siti Nurhaliza',
        'kelas': 'XII RPL 2',
        'industri': 'CV. Digital Solusi',
        'tanggal': '18-19 Jan 2024',
        'alasan': 'Mengikuti seminar teknologi',
        'status': 'Menunggu',
        'statusColor': widget.orange,
      },
    ];

    return _buildListContent('Izin', izinData);
  }

  Widget _buildSakitList() {
    final List<Map<String, dynamic>> sakitData = [
      {
        'nama': 'Budi Santoso',
        'kelas': 'XII MM 1',
        'industri': 'PT. Media Kreatif',
        'tanggal': '22-24 Jan 2024',
        'alasan': 'Demam dan flu',
        'status': 'Disetujui',
        'statusColor': widget.green,
      },
    ];

    return _buildListContent('Sakit', sakitData);
  }

  Widget _buildAlphaList() {
    final List<Map<String, dynamic>> alphaData = [
      {
        'nama': 'Dewi Lestari',
        'kelas': 'XII TKJ 2',
        'industri': 'PT. Network Indonesia',
        'tanggal': '17 Jan 2024',
        'alasan': 'Tidak ada keterangan',
        'status': 'Alpha',
        'statusColor': widget.red,
      },
    ];

    return _buildListContent('Alpha', alphaData);
  }

  Widget _buildListContent(String title, List<Map<String, dynamic>> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daftar $title',
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
                border: Border.all(color: widget.primaryRed.withValues(alpha:0.2)),
              ),
              child: Text(
                '${data.length} $title',
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
        ...data.map((item) => _buildSiaCard(item)),
        if (data.isEmpty)
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
                  title == 'Izin' ? Icons.person_pin_circle :
                  title == 'Sakit' ? Icons.healing : Icons.warning,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Tidak ada data $title',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSiaCard(Map<String, dynamic> data) {
    
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
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.primaryRed.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: widget.primaryRed.withValues(alpha:0.3)),
                  ),
                  child: Icon(
                    data['status'] == 'Alpha' ? Icons.warning :
                    data['status'] == 'Sakit' ? Icons.healing : Icons.person_pin_circle,
                    color: widget.primaryRed,
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
            
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tanggal: ${data['tanggal']}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            if (data['alasan'] != null && data['alasan'].isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Keterangan: ${data['alasan']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            
            const SizedBox(height: 16),
            if (data['status'] == 'Menunggu')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectSia(data),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.red,
                        side: BorderSide(color: widget.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'TOLAK',
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
                      onPressed: () => _approveSia(data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'SETUJUI',
                        style: TextStyle(
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
    );
  }
}

// ==============================================
// TAB 2: KELOLA PENGAJUAN PKL
// ==============================================

class KelolaPengajuanPklContent extends StatefulWidget {
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

  const KelolaPengajuanPklContent({
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
  State<KelolaPengajuanPklContent> createState() => _KelolaPengajuanPklContentState();
}

class _KelolaPengajuanPklContentState extends State<KelolaPengajuanPklContent> 
    with AutomaticKeepAliveClientMixin {
  
  final List<Map<String, dynamic>> _pengajuanPklData = [
    {
      'id': 'P001',
      'nama': 'Ahmad Rizki',
      'kelas': 'XII TKJ 1',
      'industri': 'PT. Teknologi Indonesia',
      'tanggal_diajukan': '15 Jan 2024',
      'status': 'Menunggu',
      'statusColor': Colors.orange,
      'tipe': 'Pengajuan PKL Baru',
      'is_ditolak': false,
      'is_diterima': false,
    },
    {
      'id': 'P002',
      'nama': 'Siti Nurhaliza',
      'kelas': 'XII RPL 2',
      'industri': 'CV. Digital Solusi',
      'tanggal_diajukan': '14 Jan 2024',
      'status': 'Ditolak',
      'statusColor': Colors.red,
      'tipe': 'Pengajuan PKL Baru',
      'is_ditolak': true,
      'is_diterima': false,
      'alasan_tolak': 'Kuota industri sudah penuh',
    },
    {
      'id': 'P003',
      'nama': 'Budi Santoso',
      'kelas': 'XII MM 1',
      'industri': 'PT. Media Kreatif',
      'tanggal_diajukan': '13 Jan 2024',
      'status': 'Disetujui',
      'statusColor': Colors.green,
      'tipe': 'Pengajuan PKL Baru',
      'is_ditolak': false,
      'is_diterima': true,
      'guru_pembimbing': 'Dr. Budi Santoso, M.Kom.',
    },
    {
      'id': 'P004',
      'nama': 'Dewi Lestari',
      'kelas': 'XII TKJ 2',
      'industri': 'PT. Network Indonesia',
      'tanggal_diajukan': '12 Jan 2024',
      'status': 'Menunggu',
      'statusColor': Colors.orange,
      'tipe': 'Pindah PKL',
      'is_ditolak': false,
      'is_diterima': false,
      'industri_asal': 'PT. Jaringan Nusantara',
    },
    {
      'id': 'P005',
      'nama': 'Rizky Pratama',
      'kelas': 'XII RPL 1',
      'industri': 'PT. Software House',
      'tanggal_diajukan': '11 Jan 2024',
      'status': 'Ditolak',
      'statusColor': Colors.red,
      'tipe': 'Pindah PKL',
      'is_ditolak': true,
      'is_diterima': false,
      'alasan_tolak': 'Tidak ada alasan yang jelas',
      'industri_asal': 'CV. Tech Solution',
    },
  ];

  List<Map<String, dynamic>> _filteredData = [];
  String _filterStatus = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  final List<String> _statusOptions = ['Semua', 'Menunggu', 'Disetujui', 'Ditolak'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _filteredData = _pengajuanPklData;
  }

  void _filterByStatus(String status) {
    setState(() {
      _filterStatus = status;
      if (status == 'Semua') {
        _filteredData = _pengajuanPklData;
      } else {
        _filteredData = _pengajuanPklData.where((item) => item['status'] == status).toList();
      }
    });
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      setState(() {
        _filteredData = _pengajuanPklData.where((item) {
          return item['nama'].toLowerCase().contains(query) ||
                 item['kelas'].toLowerCase().contains(query) ||
                 item['industri'].toLowerCase().contains(query) ||
                 item['tipe'].toLowerCase().contains(query);
        }).toList();
      });
    } else {
      _filterByStatus(_filterStatus);
    }
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
        backgroundColor: isError ? widget.red : widget.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.secondaryColor,
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
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail Pengajuan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: widget.primaryRed,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 28),
                      color: widget.textPrimary,
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: widget.borderColor),
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
                                    color: widget.primaryRed.withValues(alpha:0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: widget.primaryRed.withValues(alpha:0.3)),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: widget.primaryRed,
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
                                          color: widget.textSecondary,
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Informasi Pengajuan',
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
                          border: Border.all(color: widget.borderColor),
                        ),
                        child: Column(
                          children: [
                            _infoRow('Jenis Pengajuan', data['tipe']),
                            const SizedBox(height: 12),
                            _infoRow('Industri', data['industri']),
                            const SizedBox(height: 12),
                            _infoRow('Tanggal Diajukan', data['tanggal_diajukan']),
                            if (data['tipe'] == 'Pindah PKL' && data['industri_asal'] != null) ...[
                              const SizedBox(height: 12),
                              _infoRow('Industri Asal', data['industri_asal']),
                            ],
                            if (data['is_diterima'] && data['guru_pembimbing'] != null) ...[
                              const SizedBox(height: 12),
                              _infoRow('Guru Pembimbing', data['guru_pembimbing']),
                            ],
                            if (data['is_ditolak'] && data['alasan_tolak'] != null) ...[
                              const SizedBox(height: 12),
                              _infoRow('Alasan Penolakan', data['alasan_tolak']),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: data['status'] == 'Menunggu' 
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _rejectApplication(data),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: widget.red,
                              side: BorderSide(color: widget.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.close, size: 20),
                            label: const Text(
                              'TOLAK',
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
                            onPressed: () => _approveApplication(data),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: widget.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            icon: const Icon(Icons.check, size: 20),
                            label: const Text(
                              'SETUJUI',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(),
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
              color: widget.textSecondary,
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

  void _rejectApplication(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController alasanController = TextEditingController();
        
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
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: widget.red.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.close,
                          color: widget.red,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOLAK PENGAJUAN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6B1B1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Siswa: ${data['nama']}',
                              style: const TextStyle(
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

                  const Text(
                    'Alasan Penolakan',
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
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: alasanController,
                      maxLines: 4,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Masukkan alasan penolakan...',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: widget.primaryRed,
                            side: BorderSide(color: widget.primaryRed),
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
                            if (alasanController.text.trim().isEmpty) {
                              _showSnackBar('Masukkan alasan penolakan', isError: true);
                              return;
                            }

                            setState(() {
                              final index = _pengajuanPklData.indexWhere((item) => item['id'] == data['id']);
                              if (index != -1) {
                                _pengajuanPklData[index]['status'] = 'Ditolak';
                                _pengajuanPklData[index]['statusColor'] = widget.red;
                                _pengajuanPklData[index]['is_ditolak'] = true;
                                _pengajuanPklData[index]['alasan_tolak'] = alasanController.text.trim();
                              }
                            });

                            _showSnackBar('Pengajuan berhasil ditolak');
                            Navigator.pop(context);
                            _filterByStatus(_filterStatus);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'TOLAK',
                            style: TextStyle(
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

  void _approveApplication(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController catatanController = TextEditingController();
        String? selectedGuruId;
        final List<Map<String, dynamic>> guruList = [
          {'id': '1', 'nama': 'Dr. Budi Santoso, M.Kom.'},
          {'id': '2', 'nama': 'Dr. Siti Aminah, M.Pd.'},
          {'id': '3', 'nama': 'Ir. Joko Susilo, M.T.'},
        ];
        
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
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: widget.green.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.check,
                          color: widget.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SETUJUI PENGAJUAN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6B1B1B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Siswa: ${data['nama']}',
                              style: const TextStyle(
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

                  const Text(
                    'Guru Pembimbing',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B1B1B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedGuruId,
                        hint: const Text(
                          'Pilih guru pembimbing',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        isExpanded: true,
                        items: guruList.map((guru) {
                          return DropdownMenuItem<String>(
                            value: guru['id'],
                            child: Text(guru['nama']),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          selectedGuruId = newValue;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Catatan (Opsional)',
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
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: catatanController,
                      maxLines: 3,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Masukkan catatan...',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: widget.primaryRed,
                            side: BorderSide(color: widget.primaryRed),
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
                            if (selectedGuruId == null) {
                              _showSnackBar('Pilih guru pembimbing terlebih dahulu', isError: true);
                              return;
                            }

                            final guruNama = guruList.firstWhere(
                              (g) => g['id'] == selectedGuruId,
                              orElse: () => {'nama': 'Guru'},
                            )['nama'];

                            setState(() {
                              final index = _pengajuanPklData.indexWhere((item) => item['id'] == data['id']);
                              if (index != -1) {
                                _pengajuanPklData[index]['status'] = 'Disetujui';
                                _pengajuanPklData[index]['statusColor'] = widget.green;
                                _pengajuanPklData[index]['is_diterima'] = true;
                                _pengajuanPklData[index]['guru_pembimbing'] = guruNama;
                              }
                            });

                            _showSnackBar('Pengajuan berhasil disetujui');
                            Navigator.pop(context);
                            _filterByStatus(_filterStatus);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'SETUJUI',
                            style: TextStyle(
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

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return RefreshIndicator(
      onRefresh: _refreshData,
      backgroundColor: Colors.white,
      color: widget.primaryRed,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
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
            'Status Pengajuan',
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
                    primaryRed: widget.primaryRed,
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
    final menungguCount = _pengajuanPklData.where((item) => item['status'] == 'Menunggu').length;
    final disetujuiCount = _pengajuanPklData.where((item) => item['status'] == 'Disetujui').length;
    final ditolakCount = _pengajuanPklData.where((item) => item['status'] == 'Ditolak').length;

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
          _StatItem('Total', _pengajuanPklData.length.toString(), Icons.list_alt, widget.primaryRed),
          _StatItem('Menunggu', menungguCount.toString(), Icons.access_time, widget.orange),
          _StatItem('Disetujui', disetujuiCount.toString(), Icons.check_circle, widget.green),
          _StatItem('Ditolak', ditolakCount.toString(), Icons.close, widget.red),
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
              'Tidak ada data pengajuan',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _filterStatus == 'Semua' 
                ? 'Belum ada pengajuan PKL dari siswa'
                : 'Tidak ada pengajuan dengan status "$_filterStatus"',
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
                'Daftar Pengajuan',
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
                  border: Border.all(color: widget.primaryRed.withValues(alpha:0.2)),
                ),
                child: Text(
                  '${_filteredData.length} pengajuan',
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
          ..._filteredData.map((data) => _DocumentCard(
            data: data,
            onTap: () => _showDetailDialog(data),
            primaryRed: widget.primaryRed,
          )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryRed;

  const _FilterChip({
    required this.text,
    required this.isSelected,
    required this.onTap,
    required this.primaryRed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryRed),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : primaryRed,
          ),
        ),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;
  final Color primaryRed;

  const _DocumentCard({
    required this.data,
    required this.onTap,
    required this.primaryRed,
  });

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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: primaryRed.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryRed.withValues(alpha:0.3)),
                      ),
                      child: Icon(
                        data['tipe'] == 'Pindah PKL' 
                          ? Icons.swap_horiz
                          : Icons.assignment,
                        color: primaryRed,
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
                
                Row(
                  children: [
                    Icon(
                      data['tipe'] == 'Pindah PKL' 
                        ? Icons.swap_horiz
                        : Icons.description,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${data['tipe']} • ${data['tanggal_diajukan']}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    if (data['tipe'] == 'Pindah PKL' && data['industri_asal'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.withValues(alpha:0.2)),
                        ),
                        child: const Text(
                          'PINDAH',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: onTap,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryRed,
                      side: BorderSide(color: primaryRed),
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