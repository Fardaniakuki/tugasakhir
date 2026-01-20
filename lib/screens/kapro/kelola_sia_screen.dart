// kelola_sia_screen.dart (PAGE 2 - Sakit/Izin/Alpha)
import 'package:flutter/material.dart';

class KelolaSiaScreen extends StatefulWidget {
  final ScrollController? scrollController;
  
  const KelolaSiaScreen({
    super.key,
    this.scrollController,
  });

  @override
  State<KelolaSiaScreen> createState() => _KelolaSiaScreenState();
}

class _KelolaSiaScreenState extends State<KelolaSiaScreen> 
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  final Color _primaryRed = const Color(0xFF6B1B1B);
  final Color _bgSoft = const Color(0xFFF6EEEE);
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
    _tabController = TabController(length: 3, vsync: this);
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
    
    return Scaffold(
      backgroundColor: _bgSoft,
      body: SingleChildScrollView(
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
            _tabSection(),
            const SizedBox(height: 40),
          ],
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
              const Text(
                'Kelola SIA',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B1B1B),
                ),
              ),
              IconButton(
                onPressed: () {
                },
                icon: const Icon(
                  Icons.filter_list,
                  color: Color(0xFF6B1B1B),
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Kelola Sakit, Izin, dan Alpha siswa PKL',
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
            color: Colors.black.withValues(alpha: 0.08),
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
          Row(
            children: [
              _buildFilterChip('Semua', 0),
              const SizedBox(width: 8),
              _buildFilterChip('Disetujui', 1),
              const SizedBox(width: 8),
              _buildFilterChip('Menunggu', 2),
              const SizedBox(width: 8),
              _buildFilterChip('Ditolak', 3),
            ],
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
                  color: Colors.grey.withValues(alpha: 0.1),
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
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration.collapsed(
                      hintText: 'Cari nama siswa atau industri...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String text, int index) {
    final bool isSelected = index == 0;
    return GestureDetector(
      onTap: () {},
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('Total', '12', Icons.list_alt, _primaryRed),
          _buildStatItem('Izin', '8', Icons.person_pin_circle, _blue),
          _buildStatItem('Sakit', '4', Icons.healing, _orange),
          _buildStatItem('Alpha', '0', Icons.warning, _red),
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
            color: color.withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab Bar
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
          
          // Tab Content
          Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(
              minHeight: 400,
            ),
            child: IndexedStack(
              index: _selectedTabIndex,
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
    final bool isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _primaryRed : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _primaryRed : Colors.transparent,
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
        'statusColor': _green,
      },
      {
        'nama': 'Siti Nurhaliza',
        'kelas': 'XII RPL 2',
        'industri': 'CV. Digital Solusi',
        'tanggal': '18-19 Jan 2024',
        'alasan': 'Mengikuti seminar teknologi',
        'status': 'Menunggu',
        'statusColor': _orange,
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
        'statusColor': _green,
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
        'statusColor': _red,
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
                color: _primaryRed,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _primaryRed.withValues(alpha: 0.2)),
              ),
              child: Text(
                '${data.length} $title',
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
            color: Colors.black.withValues(alpha: 0.08),
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
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _primaryRed.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    data['status'] == 'Alpha' ? Icons.warning :
                    data['status'] == 'Sakit' ? Icons.healing : Icons.person_pin_circle,
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
                    color: data['statusColor'].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: data['statusColor'].withValues(alpha: 0.3)),
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
            
            // Date Info
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
            
            // Reason
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
            
            // Action Buttons (hanya untuk yang menunggu)
            const SizedBox(height: 16),
            if (data['status'] == 'Menunggu')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _red,
                        side: BorderSide(color: _red),
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
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
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