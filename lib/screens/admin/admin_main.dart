  import 'package:flutter/material.dart';
  import 'dashboard/admin_dashboard.dart';
  import 'admin_setting.dart';
  import 'dashboard/admin_data.dart';
  import '../admin/crud/add_person_page.dart';
  import 'manajemen_pkl_page.dart';

  class AdminMain extends StatefulWidget {
    const AdminMain({super.key});

    @override
    State<AdminMain> createState() => _AdminMainState();
  }

  class _AdminMainState extends State<AdminMain> {
    int _selectedIndex = 0;
    final PageController _pageController = PageController();

    final GlobalKey<AdminDataState> _adminDataKey = GlobalKey<AdminDataState>();

    late final List<Widget> _pages;

    @override
    void initState() {
      super.initState();
      _pages = [
        AdminDashboard(onNavigateToData: _navigateToDataWithFilter),
        AdminData(key: _adminDataKey),
        const ManajemenPklPage(), // INDEX 2 - PKL
        const AdminSetting(), // INDEX 3 - PENGATURAN
      ];
    }

    void _onItemTapped(int index) {
      // Handle tombol tengah (index 2) yang kosong
      if (index == 2) {
        _showAddDataDialog();
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
      if (_selectedIndex == 2) return 3; // PKL di nav index 3
      if (_selectedIndex == 3) return 4; // Pengaturan di nav index 4
      return _selectedIndex; // Beranda (0), Data (1)
    }

    void _navigateToDataWithFilter(String filter) {
      setState(() {
        _selectedIndex = 1;
      });
      _pageController.jumpToPage(1);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _adminDataKey.currentState?.updateFilter(filter);
      });
    }

    void _showAddDataDialog() {
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
                    'Tambah Data Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF641E20),
                    ),
                  ),
                ),
                _buildAddTile(Icons.person, 'Tambah Murid', 'Siswa'),
                _buildAddTile(Icons.school, 'Tambah Guru', 'Guru'),
                _buildAddTile(Icons.category, 'Tambah Jurusan', 'Jurusan'),
                _buildAddTile(Icons.business, 'Tambah Industri', 'Industri'),
                _buildAddTile(Icons.class_, 'Tambah Kelas', 'Kelas'),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
    }

    ListTile _buildAddTile(IconData icon, String title, String jenis) {
      return ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF641E20).withAlpha(25),
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
          _navigateToAddPage(jenis);
        },
      );
    }

    void _navigateToAddPage(String jenisData) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddPersonPage(jenisData: jenisData),
        ),
      ).then((result) {
        if (result == true) {
          _adminDataKey.currentState?.refreshData();
        }
      });
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
                  icon: Icon(Icons.folder),
                  label: 'Data',
                ),
                BottomNavigationBarItem(
                  icon: SizedBox.shrink(),
                  label: '',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.work),
                  label: 'PKL',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Pengaturan',
                ),
              ],
            ),
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 25,
              bottom: 15,
              child: GestureDetector(
                onTap: _showAddDataDialog,
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