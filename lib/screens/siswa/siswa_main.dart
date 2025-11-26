import 'package:flutter/material.dart';
import 'dashboard/siswa_dashboard.dart';
import 'dashboard/siswa_kalender.dart';
import 'dashboard/siswa_rekap.dart';
import 'dashboard/siswa_pengaturan.dart';

class SiswaMain extends StatefulWidget {
  const SiswaMain({super.key});

  @override
  State<SiswaMain> createState() => _SiswaMainState();
}

class _SiswaMainState extends State<SiswaMain> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const SiswaDashboard(),     // INDEX 0 - BERANDA
      const SiswaKalender(),      // INDEX 1 - KALENDER  
      const SiswaRekap(),         // INDEX 2 - REKAP
      const SiswaPengaturan(),    // INDEX 3 - PENGATURAN
    ];
  }

  void _onItemTapped(int index) {
    // Handle tombol tengah (index 2) yang kosong
    if (index == 2) {
      _showQuickActionsDialog();
      return;
    }
    
    // Mapping index BottomNavigationBar ke _pages
    int pageIndex = index;
    if (index > 2) {
      pageIndex = index - 1; // Adjust untuk tombol tengah
    }

    setState(() {
      _selectedIndex = pageIndex;
    });
    _pageController.jumpToPage(pageIndex);
  }

  // Method untuk mapping _selectedIndex ke BottomNavigationBar index
  int _getCurrentNavIndex() {
    if (_selectedIndex == 2) return 3; // Rekap di nav index 3
    if (_selectedIndex == 3) return 4; // Pengaturan di nav index 4
    return _selectedIndex; // Beranda (0), Kalender (1)
  }

  void _showQuickActionsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text(
                  'Aksi Cepat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF641E20),
                  ),
                ),
              ),
              _buildActionTile(Icons.assignment, 'Ajukan PKL', 'pengajuan'),
              _buildActionTile(Icons.calendar_today, 'Lihat Jadwal', 'jadwal'),
              _buildActionTile(Icons.assessment, 'Lihat Nilai', 'nilai'),
              _buildActionTile(Icons.chat, 'Konsultasi', 'konsultasi'),
              _buildActionTile(Icons.report, 'Laporan Harian', 'laporan'),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  ListTile _buildActionTile(IconData icon, String title, String jenis) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF641E20).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF641E20)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: () {
        Navigator.pop(context);
        _navigateToAction(jenis);
      },
    );
  }

  void _navigateToAction(String jenisAksi) {
    switch (jenisAksi) {
      case 'pengajuan':
        // Navigate to pengajuan PKL
        break;
      case 'jadwal':
        // Navigate to jadwal
        break;
      case 'nilai':
        // Navigate to nilai
        break;
      case 'konsultasi':
        // Navigate to konsultasi
        break;
      case 'laporan':
        // Navigate to laporan harian
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: Stack(
        clipBehavior: Clip.none,
        children: [
          BottomNavigationBar(
            currentIndex: _getCurrentNavIndex(), // PASTIKAN pakai method mapping
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF641E20),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            elevation: 0, // Pastikan elevation 0
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Beranda',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: 'Kalender',
              ),
              BottomNavigationBarItem(
                icon: SizedBox.shrink(),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Rekap',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Pengaturan',
              ),
            ],
          ),
          // Tombol + di tengah
          Positioned(
            left: MediaQuery.of(context).size.width / 2 - 25,
            bottom: 15,
            child: GestureDetector(
              onTap: _showQuickActionsDialog,
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF641E20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF641E20).withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}