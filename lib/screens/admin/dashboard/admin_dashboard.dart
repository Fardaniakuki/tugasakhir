import 'dart:async';
import 'package:flutter/material.dart';
import '../crud/add_person_page.dart';
import 'murid/student_detail_page.dart';
import 'guru/teacher_detail_page.dart';
import 'jurusan/major_detail_page.dart';
import 'industri/industry_detail_page.dart';
import 'kelas/class_detail_page.dart';
import 'dashboard_service.dart';
import 'stat_grid.dart';
import 'person_tile.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final DashboardService _service = DashboardService();
  String selectedStatus = 'Murid';
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  final List<Map<String, dynamic>> muridList = [];
  final List<Map<String, dynamic>> guruList = [];
  final List<Map<String, dynamic>> jurusanDataList = [];
  final List<Map<String, dynamic>> industriList = [];
  final List<Map<String, dynamic>> kelasDataList = [];
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initAll();

    searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        final q = searchController.text.trim().toLowerCase();
        if (q != searchQuery) {
          setState(() => searchQuery = q);
          fetchDataBasedOnSelection();
        }
      });
    });
  }

  Future<void> _initAll() async {
    await Future.wait([
      fetchDashboardData(),
    ]);
    await fetchDataBasedOnSelection();
  }

  Future<void> refreshData() async {
    setState(() => isLoading = true);
    await _initAll();
    setState(() => isLoading = false);
  }

  Future<void> fetchDashboardData() async {
    try {
      final data = await _service.fetchDashboardData();
      setState(() {
        dashboardData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('Exception fetchDashboardData: $e');
    }
  }

  Future<void> fetchDataBasedOnSelection() async {
    switch (selectedStatus) {
      case 'Murid':
        await fetchSiswaData();
        break;
      case 'Guru':
        await fetchGuruData();
        break;
      case 'Jurusan':
        await fetchJurusanData();
        break;
      case 'Industri':
        await fetchIndustriData();
        break;
      case 'Kelas':
        await fetchKelasData();
        break;
      default:
        await fetchSiswaData();
    }
  }

  Future<void> fetchSiswaData() async {
    try {
      final data = await _service.fetchSiswaData(
        searchQuery: searchQuery,
      );
      setState(() {
        muridList.clear();
        muridList.addAll(data);
      });
    } catch (e) {
      debugPrint('Exception fetchSiswaData: $e');
    }
  }

  Future<void> fetchGuruData() async {
    try {
      final data = await _service.fetchGuruData(searchQuery: searchQuery);
      setState(() {
        guruList.clear();
        guruList.addAll(data);
      });
    } catch (e) {
      debugPrint('Exception fetchGuruData: $e');
    }
  }

  Future<void> fetchJurusanData() async {
    try {
      final data = await _service.fetchJurusanData(searchQuery: searchQuery);
      setState(() {
        jurusanDataList.clear();
        jurusanDataList.addAll(data);
      });
    } catch (e) {
      debugPrint('Exception fetchJurusanData: $e');
    }
  }

  Future<void> fetchIndustriData() async {
    try {
      final data = await _service.fetchIndustriData(searchQuery: searchQuery);
      setState(() {
        industriList.clear();
        industriList.addAll(data);
      });
    } catch (e) {
      debugPrint('Exception fetchIndustriData: $e');
    }
  }

  Future<void> fetchKelasData() async {
    try {
      final data = await _service.fetchKelasData(searchQuery: searchQuery);
      setState(() {
        kelasDataList.clear();
        kelasDataList.addAll(data);
      });
    } catch (e) {
      debugPrint('Exception fetchKelasData: $e');
    }
  }

  void _handleItemTap(Map<String, dynamic> item) async {
    switch (item['type']) {
      case 'siswa':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentDetailPage(studentId: item['id']!),
          ),
        );
        if (!mounted) return;
        if (result != null && result['deleted'] == true) {
          setState(() {
            muridList.remove(item);
          });
          // snackbar dihapus
        }
        break;

      case 'guru':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherDetailPage(teacherId: item['id']!),
          ),
        );
        if (!mounted) return;
        if (result != null && result['deleted'] == true) {
          setState(() {
            guruList.remove(item);
          });
          // snackbar dihapus
        }
        break;

      case 'jurusan':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MajorDetailPage(majorId: item['id']!),
          ),
        );
        if (!mounted) return;
        if (result != null && result['deleted'] == true) {
          setState(() {
            jurusanDataList.remove(item);
          });
          // snackbar dihapus
        }
        break;

      case 'industri':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => IndustryDetailPage(industryId: item['id']!),
          ),
        );
        if (!mounted) return;
        if (result != null && result['deleted'] == true) {
          setState(() {
            industriList.remove(item);
          });
          // snackbar dihapus
        }
        break;

      case 'kelas':
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClassDetailPage(classId: item['id']!),
          ),
        );
        if (!mounted) return;
        if (result != null && result['deleted'] == true) {
          setState(() {
            kelasDataList.remove(item);
          });
          // snackbar dihapus
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> currentList = [];
    switch (selectedStatus) {
      case 'Murid':
        currentList = muridList.where((m) {
          return m['name']!.toLowerCase().contains(searchQuery);
        }).toList();
        break;
      case 'Guru':
        currentList = guruList
            .where((g) => g['name']!.toLowerCase().contains(searchQuery))
            .toList();
        break;
      case 'Jurusan':
        currentList = jurusanDataList
            .where((j) => j['name']!.toLowerCase().contains(searchQuery))
            .toList();
        break;
      case 'Industri':
        currentList = industriList
            .where((i) => i['name']!.toLowerCase().contains(searchQuery))
            .toList();
        break;
      case 'Kelas':
        currentList = kelasDataList
            .where((k) => k['name']!.toLowerCase().contains(searchQuery))
            .toList();
        break;
    }

    currentList.sort((a, b) => a['name']!.compareTo(b['name']!));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5B1A1A),
        title: const Text('Dashboard', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: refreshData,
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      StatGrid(
                          data: dashboardData, onAddPressed: _showAddOptions),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: TextField(
                                controller: searchController,
                                decoration: InputDecoration(
                                  icon: const Icon(Icons.search),
                                  hintText:
                                      'Cari ${selectedStatus.toLowerCase()}',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                                // Hapus border supaya tidak ada garis
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedStatus,
                                  icon: const Icon(Icons.keyboard_arrow_down,
                                      color:
                                          Color.fromARGB(255, 112, 112, 112)),
                                  isExpanded: true,
                                  dropdownColor: Colors.grey[100],
                                  style: const TextStyle(
                                      color: Color.fromARGB(255, 112, 112, 112),
                                      fontWeight: FontWeight.w600),
                                  items: const [
                                    'Murid',
                                    'Guru',
                                    'Jurusan',
                                    'Industri',
                                    'Kelas'
                                  ]
                                      .map((item) => DropdownMenuItem(
                                            value: item,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                              child: Text(item),
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedStatus = value ?? 'Murid';
                                    });
                                    fetchDataBasedOnSelection();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ListView.builder(
                        itemCount: currentList.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          final item = currentList[index];
                          return PersonTile(
                            name: item['name']!,
                            role: item['role']!,
                            jurusan: item['jurusan'],
                            kelas: item['kelas'],
                            onTap: () => _handleItemTap(item),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAddTile(
                  Icons.menu_book, 'Tambah Murid', 'Siswa', muridList),
              _buildAddTile(Icons.person, 'Tambah Guru', 'Guru', guruList),
              _buildAddTile(
                  Icons.school, 'Tambah Jurusan', 'Jurusan', jurusanDataList),
              _buildAddTile(
                  Icons.class_, 'Tambah Kelas', 'Kelas', kelasDataList),
              _buildAddTile(
                  Icons.factory, 'Tambah Industri', 'Industri', industriList),
            ],
          ),
        );
      },
    );
  }

  ListTile _buildAddTile(IconData icon, String title, String jenis,
      List<Map<String, dynamic>> targetList) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () async {
        Navigator.pop(context);
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddPersonPage(jenisData: jenis)),
        );
        if (!mounted) return;
        if (result != null) {
          setState(() => targetList.add(result));
        }
      },
    );
  }
}
