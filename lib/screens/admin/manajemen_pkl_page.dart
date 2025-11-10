import 'package:flutter/material.dart';

class ManajemenPklPage extends StatefulWidget {
  const ManajemenPklPage({super.key});

  @override
  State<ManajemenPklPage> createState() => _ManajemenPklPageState();
}

class _ManajemenPklPageState extends State<ManajemenPklPage> {
  int _currentPklTab = 0;
  final List<Map<String, dynamic>> _penempatanList = [
    {
      'nama': 'Ahmad Rizki',
      'kelas': 'XII TKJ 1',
      'industri': 'PT. Teknologi Indonesia',
      'tanggal': '12 Jan 2024',
      'status': 'Aktif',
      'pembimbing': 'Bapak Santoso',
    },
    {
      'nama': 'Siti Aminah',
      'kelas': 'XII MM 2',
      'industri': 'CV. Digital Creative',
      'tanggal': '15 Jan 2024',
      'status': 'Aktif',
      'pembimbing': 'Ibu Dewi',
    },
    {
      'nama': 'Budi Santoso',
      'kelas': 'XII RPL 1',
      'industri': 'PT. Software Solution',
      'tanggal': '18 Jan 2024',
      'status': 'Selesai',
      'pembimbing': 'Bapak Wijaya',
    },
    {
      'nama': 'Maya Sari',
      'kelas': 'XII TKJ 2',
      'industri': 'PT. Network System',
      'tanggal': '20 Jan 2024',
      'status': 'Aktif',
      'pembimbing': 'Bapak Rahman',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Manajemen PKL',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF641E20),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Stats
          _buildHeaderStats(),
          
          // Tab Bar untuk navigasi PKL
          _buildTabBar(),
          
          // Content berdasarkan tab
          Expanded(
            child: _buildPklContent(),
          ),
        ],
      ),
      floatingActionButton: _currentPklTab == 0 
          ? FloatingActionButton(
              onPressed: _tambahPenempatan,
              backgroundColor: const Color(0xFF641E20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  Widget _buildHeaderStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF641E20),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('45', 'Siswa PKL', Icons.people),
          _buildStatItem('12', 'Industri', Icons.business),
          _buildStatItem('38', 'Aktif', Icons.check_circle),
          _buildStatItem('7', 'Selesai', Icons.assignment_turned_in),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFE0E0E0), // Mengganti withOpacity dengan color langsung
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildPklTab('Penempatan', Icons.assignment, 0),
            _buildPklTab('Monitoring', Icons.monitor_heart, 1),
            _buildPklTab('Pembimbing', Icons.supervisor_account, 2),
            _buildPklTab('Penilaian', Icons.grading, 3),
            _buildPklTab('Laporan', Icons.assignment, 4),
          ],
        ),
      ),
    );
  }

  Widget _buildPklTab(String title, IconData icon, int index) {
    final isSelected = _currentPklTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _currentPklTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF641E20) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF641E20) : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF641E20) : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPklContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _getCurrentContent(),
    );
  }

  Widget _getCurrentContent() {
    switch (_currentPklTab) {
      case 0:
        return _buildPenempatanContent();
      case 1:
        return _buildMonitoringContent();
      case 2:
        return _buildPembimbingContent();
      case 3:
        return _buildPenilaianContent();
      case 4:
        return _buildLaporanContent();
      default:
        return _buildPenempatanContent();
    }
  }

  Widget _buildPenempatanContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari siswa...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune, color: Color(0xFF641E20)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _penempatanList.length,
            itemBuilder: (context, index) {
              final data = _penempatanList[index];
              return _buildPenempatanCard(data, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPenempatanCard(Map<String, dynamic> data, int index) {
    final isAktif = data['status'] == 'Aktif';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0x1A641E20), // Mengganti withOpacity dengan hex alpha
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person,
                color: Color(0xFF641E20),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        data['nama'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAktif ? const Color(0xFFE8F5E8) : const Color(0xFFE8F4FD),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isAktif ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          data['status'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isAktif ? const Color(0xFF4CAF50) : const Color(0xFF2196F3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['kelas'],
                    style: const TextStyle(color: Color(0xFF757575)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.business, size: 14, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data['industri'],
                          style: const TextStyle(
                            color: Color(0xFF757575),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Color(0xFF9E9E9E)),
                      const SizedBox(width: 4),
                      Text(
                        data['pembimbing'],
                        style: const TextStyle(color: Color(0xFF757575), fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        data['tanggal'],
                        style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonitoringContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_heart, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Monitoring PKL',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Fitur dalam pengembangan',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPembimbingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.supervisor_account, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Data Pembimbing',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Fitur dalam pengembangan',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPenilaianContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grading, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Penilaian PKL',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Fitur dalam pengembangan',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildLaporanContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Laporan PKL',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Fitur dalam pengembangan',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _tambahPenempatan() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tambah Penempatan PKL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF641E20),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildFormField('Nama Siswa', Icons.person),
                const SizedBox(height: 12),
                _buildFormField('Kelas', Icons.class_),
                const SizedBox(height: 12),
                _buildFormField('Industri', Icons.business),
                const SizedBox(height: 12),
                _buildFormField('Tanggal Mulai', Icons.calendar_today),
                const SizedBox(height: 12),
                _buildFormField('Pembimbing', Icons.supervisor_account),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSuccessDialog();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF641E20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simpan Penempatan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormField(String label, IconData icon) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF641E20)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF641E20)),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
        content: const Text(
          'Penempatan PKL berhasil ditambahkan!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        actions: [
          Center(
            child: SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF641E20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('OK'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}