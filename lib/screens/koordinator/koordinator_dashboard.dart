import 'package:flutter/material.dart';

class KoordinatorDashboard extends StatefulWidget {
  const KoordinatorDashboard({super.key});

  @override
  State<KoordinatorDashboard> createState() => _KoordinatorDashboardState();
}

class _KoordinatorDashboardState extends State<KoordinatorDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const Center(child: Text('Beranda Koordinator')),
    const Center(child: Text('Daftar Guru')),
    const Center(child: Text('Daftar Siswa')),
    const Center(child: Text('Pengaturan')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Koordinator'),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Guru',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Siswa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
