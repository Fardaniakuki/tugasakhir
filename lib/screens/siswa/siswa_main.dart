import 'package:flutter/material.dart';
import 'dart:async';
import 'dashboard/siswa_dashboard.dart';
import 'dashboard/siswa_kalender.dart';
import 'dashboard/siswa_rekap.dart';
import 'dashboard/siswa_pengaturan.dart';
import 'dashboard/ajukan_pkl_dialog.dart'; // Import dialog untuk PKL

class SiswaMain extends StatefulWidget {
  const SiswaMain({super.key});

  @override
  State<SiswaMain> createState() => _SiswaMainState();
}

class _SiswaMainState extends State<SiswaMain> {
  int _currentIndex = 0;
  
  // Cache untuk menyimpan widget halaman
  final Map<int, Widget> _pageCache = {};
  final Map<int, bool> _pageLoaded = {};

  late final List<Widget> _pageBuilders;

  // WARNA UNTUK SISWA - Menggunakan warna merah yang lebih serius
  final Color _primaryColor = const Color(0xFF9f0712); // Warna utama merah
  final Color _inactiveColor = const Color(0xFF9E9E9E); // Warna tidak aktif

  // Variabel untuk form izin
  final _izinFormKey = GlobalKey<FormState>();
  final TextEditingController _tanggalController = TextEditingController();
  final TextEditingController _jenisIzinController = TextEditingController();
  final TextEditingController _alasanController = TextEditingController();
  String? _tipeIzin = 'izin'; // Default value

  @override
  void initState() {
    super.initState();
    
    // Inisialisasi page builders
    _pageBuilders = [
      _buildDashboardPage(),
      _buildKalenderPage(),
      _buildRekapPage(),
      _buildPengaturanPage(),
    ];
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _jenisIzinController.dispose();
    _alasanController.dispose();
    super.dispose();
  }

  // Builder untuk halaman Dashboard dengan caching
  Widget _buildDashboardPage() {
    return _buildCachedPage(
      index: 0,
      builder: () => SiswaDashboard(
        key: const ValueKey('dashboard_page'),
        onAjukanPklPressed: _showAjukanPKLDialog, // Tambahkan callback
      ),
    );
  }

  // Builder untuk halaman Kalender
  Widget _buildKalenderPage() {
    return _buildCachedPage(
      index: 1,
      builder: () => const SiswaKalender(
        key: ValueKey('kalender_page'),
      ),
    );
  }

  // Builder untuk halaman Rekap
  Widget _buildRekapPage() {
    return _buildCachedPage(
      index: 2,
      builder: () => SiswaRekap(
        key: const ValueKey('rekap_page'), 
        onQuickActionPressed: _showQuickActionsDialog, 
        onAjukanIjin: () async {
          await _showAjukanIzinForm();
        }, // Mengembalikan Future<void>
      ),
    );
  }

  // Builder untuk halaman Pengaturan
  Widget _buildPengaturanPage() {
    return _buildCachedPage(
      index: 3,
      builder: () => const SiswaPengaturan(
        key: ValueKey('pengaturan_page'),
      ),
    );
  }

  // Fungsi untuk caching halaman
  Widget _buildCachedPage({
    required int index,
    required Widget Function() builder,
  }) {
    // Jika halaman belum pernah dibuat
    if (!_pageLoaded.containsKey(index) || !_pageLoaded[index]!) {
      return FutureBuilder<void>(
        future: Future.delayed(Duration.zero, () {
          _pageCache[index] = builder();
          _pageLoaded[index] = true;
        }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return _pageCache[index]!;
          }
          return Center(
            child: CircularProgressIndicator(
              color: _primaryColor,
            ),
          );
        },
      );
    }

    return _pageCache[index]!;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Fungsi untuk menampilkan dialog Ajukan PKL
  void _showAjukanPKLDialog() {
    showDialog(
      context: context,
      builder: (context) => AjukanPKLDialog(
        primaryColor: _primaryColor, token: '', kelasId: null,
      ),
    );
  }

  // Fungsi untuk menampilkan form pengajuan izin - sekarang mengembalikan Future<void>
  Future<void> _showAjukanIzinForm() async {
    // Reset form
    _tanggalController.clear();
    _jenisIzinController.clear();
    _alasanController.clear();
    _tipeIzin = 'izin';

    // Tampilkan modal bottom sheet dan tunggu hingga selesai
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20)
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Ajukan Izin / Pindah PKL',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                
                // Form
                Form(
                  key: _izinFormKey,
                  child: Column(
                    children: [
                      // Pilihan Tipe Izin/Sakit
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Jenis Pengajuan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildIzinTypeOption(
                              value: 'izin',
                              label: 'Izin',
                              icon: Icons.event_available,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildIzinTypeOption(
                              value: 'Pindah PKL',
                              label: 'Pindah PKL',
                              icon: Icons.work_outline,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Tanggal
                      TextFormField(
                        controller: _tanggalController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Tanggal Izin',
                          hintText: 'Pilih tanggal',
                          prefixIcon: const Icon(Icons.calendar_today),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: _primaryColor,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              _tanggalController.text = 
                                '${picked.day}/${picked.month}/${picked.year}';
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap pilih tanggal izin';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Jenis Izin
                      TextFormField(
                        controller: _jenisIzinController,
                        decoration: InputDecoration(
                          labelText: 'Jenis Izin',
                          hintText: 'Contoh: Izin keluarga, sakit kepala, dll.',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap isi jenis izin';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Alasan
                      TextFormField(
                        controller: _alasanController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Alasan',
                          hintText: 'Jelaskan alasan izin/sakit secara detail...',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Harap isi alasan izin';
                          }
                          if (value.length < 10) {
                            return 'Alasan terlalu singkat';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Tombol Submit
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _submitIzinForm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'AJUKAN IZIN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildIzinTypeOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _tipeIzin == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _tipeIzin = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isSelected 
            ? _primaryColor.withValues(alpha:0.1) 
            : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? _primaryColor : Colors.grey,
              size: 30,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? _primaryColor : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitIzinForm() async {
    if (_izinFormKey.currentState!.validate()) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _primaryColor),
              const SizedBox(height: 20),
              const Text('Mengajukan izin...'),
            ],
          ),
        ),
      );

      // Simulasi proses pengajuan
      await Future.delayed(const Duration(seconds: 2));

      // Tutup loading
      Navigator.pop(context);
      
      // Tutup form
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Izin berhasil diajukan!'),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      // Reset form
      _izinFormKey.currentState!.reset();
      _tanggalController.clear();
      _jenisIzinController.clear();
      _alasanController.clear();
      _tipeIzin = 'izin';

      // Refresh halaman rekap jika sedang dibuka
      refreshPage(2);
    }
  }

  void _showQuickActionsDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20)
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'AKSI CEPAT',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              _buildActionTile(Icons.assignment, 'AJUKAN PKL', 'pengajuan'),
              Divider(height: 1, color: Colors.grey.shade300),
              _buildActionTile(Icons.calendar_today, 'LIHAT JADWAL', 'jadwal'),
              Divider(height: 1, color: Colors.grey.shade300),
              _buildActionTile(Icons.assessment, 'LIHAT NILAI', 'nilai'),
              Divider(height: 1, color: Colors.grey.shade300),
              _buildActionTile(Icons.chat, 'KONSULTASI', 'konsultasi'),
              Divider(height: 1, color: Colors.grey.shade300),
              _buildActionTile(Icons.report, 'LAPORAN HARIAN', 'laporan'),
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
          shape: BoxShape.circle,
          color: _primaryColor,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Colors.black,
          fontSize: 16,
        ),
      ),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _primaryColor,
        ),
        child: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.white,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        _navigateToAction(jenis);
      },
    );
  }

  void _navigateToAction(String jenisAksi) {
    switch (jenisAksi) {
      case 'pengajuan':
        // Tampilkan dialog PKL jika di dashboard
        if (_currentIndex == 0) {
          _showAjukanPKLDialog();
        }
        break;
      case 'jadwal':
        // Navigate to jadwal
        setState(() {
          _currentIndex = 1; // Ke halaman kalender
        });
        break;
      case 'nilai':
        // Navigate to nilai - mungkin bisa ditambahkan di rekap
        setState(() {
          _currentIndex = 2; // Ke halaman rekap
        });
        break;
      case 'konsultasi':
        // Navigate to konsultasi
        break;
      case 'laporan':
        // Navigate to laporan harian
        setState(() {
          _currentIndex = 2; // Ke halaman rekap
        });
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Halaman konten - mengisi seluruh layar
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: _pageBuilders,
            ),
          ),
          
          // Floating Action Button untuk Aksi Cepat - hanya di dashboard dan rekap
          if (_currentIndex == 0 || _currentIndex == 2)
            Positioned(
              right: 20,
              bottom: 80, // Di atas bottom navigation bar
              child: FloatingActionButton(
                onPressed: () async {
                  if (_currentIndex == 0) {
                    _showAjukanPKLDialog();
                  } else if (_currentIndex == 2) {
                    await _showAjukanIzinForm();
                  }
                },
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                child: const Icon(Icons.add, size: 28),
              ),
            ),
          
          // Bottom Navigation Bar - posisi absolute di bawah
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _SiswaBottomBar(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
              primaryColor: _primaryColor,
              inactiveColor: _inactiveColor,
            ),
          ),
        ],
      ),
    );
  }

  // Method untuk refresh halaman tertentu
  void refreshPage(int pageIndex) {
    if (_pageLoaded.containsKey(pageIndex)) {
      _pageCache.remove(pageIndex);
      _pageLoaded[pageIndex] = false;
      
      if (_currentIndex == pageIndex) {
        setState(() {});
      }
    }
  }
}

// ============== BOTTOM NAVIGATION BAR ==============
class _SiswaBottomBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final Color primaryColor;
  final Color inactiveColor;

  const _SiswaBottomBar({
    required this.currentIndex,
    required this.onTabSelected,
    required this.primaryColor,
    required this.inactiveColor,
  });

  @override
  State<_SiswaBottomBar> createState() => __SiswaBottomBarState();
}

class __SiswaBottomBarState extends State<_SiswaBottomBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Menu 1: Beranda
          _buildTabItem(
            index: 0,
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Beranda',
          ),

          // Menu 2: Kalender
          _buildTabItem(
            index: 1,
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today,
            label: 'Kalender',
          ),

          // Menu 3: Rekap
          _buildTabItem(
            index: 2,
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment,
            label: 'Permohonan',
          ),

          // Menu 4: Pengaturan
          _buildTabItem(
            index: 3,
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isActive = widget.currentIndex == index;
    final activeColor = widget.primaryColor;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => widget.onTabSelected(index),
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon dengan efek animasi
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isActive 
                    ? activeColor.withValues(alpha:0.1)
                    : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? activeColor : widget.inactiveColor,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              
              // Label
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  color: isActive ? activeColor : widget.inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}