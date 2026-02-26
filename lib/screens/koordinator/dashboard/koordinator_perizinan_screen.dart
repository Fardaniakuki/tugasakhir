import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tes_flutter/screens/login/login_screen.dart';

class KoordinatorPerizinanScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const KoordinatorPerizinanScreen({
    super.key,
    this.scrollController,
  });

  @override
  State<KoordinatorPerizinanScreen> createState() =>
      _KoordinatorPerizinanScreenState();
}

class _KoordinatorPerizinanScreenState extends State<KoordinatorPerizinanScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final Color _primaryRed = const Color(0xFF641E20);
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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(() {
      setState(() {});
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
      length: 1,
      child: Scaffold(
        backgroundColor: _bgSoft,
        body: NestedScrollView(
          controller: widget.scrollController,
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
                        Tab(text: 'Pengajuan Pindah'),
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
              // TAB: Kelola Pengajuan Pindah PKL untuk Koordinator
              KoordinatorPengajuanPklContent(
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
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kelola Perizinan',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF641E20),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Kelola pengajuan pindah PKL (Koordinator)',
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
}

// ==============================================
// TAB: KELOLA PENGAJUAN PKL UNTUK KOORDINATOR
// ==============================================

class KoordinatorPengajuanPklContent extends StatefulWidget {
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

  const KoordinatorPengajuanPklContent({
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
  State<KoordinatorPengajuanPklContent> createState() =>
      _KoordinatorPengajuanPklContentState();
}

class _KoordinatorPengajuanPklContentState
    extends State<KoordinatorPengajuanPklContent>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _pengajuanPklData = [];
  List<dynamic> _filteredData = [];
  String _filterStatus = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  final List<String> _statusOptions = [
    'Semua',
    'Menunggu',
    'Disetujui',
    'Ditolak'
  ];

  @override
  void initState() {
    super.initState();
    _fetchPengajuanPklData();
  }

  @override
  bool get wantKeepAlive => true;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> _fetchPengajuanPklData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await _getToken();
      if (token == null) {
        _showSnackBar('Token tidak ditemukan. Silakan login ulang.',
            isError: true);
        _redirectToLogin();
        return;
      }

      final baseUrl =
          dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';

      final response = await http.get(
        Uri.parse('$baseUrl/api/pindah-pkl/koordinator'),
        headers: {
          'accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response: $data');

        if (data['items'] != null && data['items'] is List) {
          final List<dynamic> processedData = [];

          for (var item in data['items']) {
            final processedItem = {
              'id': item['id'],
              'status':
                  _translateStatus(item['status'] ?? 'pending_pembimbing'),
              'siswa_nama': item['siswa_nama'] ?? 'Siswa Tidak Diketahui',
              'industri_lama': item['industri_lama_nama'] ?? 'Industri Lama',
              'industri_baru': item['industri_baru_nama'] ?? 'Industri Baru',
              'tanggal_diajukan': _formatDate(item['created_at']),
              'tipe': 'Pengajuan Pindah PKL',
              'status_api': item['status'],
              'created_at': item['created_at'],
            };

            processedData.add(processedItem);
          }

          setState(() {
            _pengajuanPklData = processedData;
            _filteredData = processedData;
          });

          print('Data loaded: ${processedData.length} items');
        } else {
          _showSnackBar('Format data tidak sesuai', isError: true);
        }
      } else if (response.statusCode == 401) {
        _showSnackBar('Token tidak valid atau expired. Silakan login ulang.',
            isError: true);
        _redirectToLogin();
      } else {
        _showSnackBar('Gagal mengambil data: ${response.statusCode}',
            isError: true);
      }
    } catch (e) {
      print('Error: $e');
      _showSnackBar('Error: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
Future<void> _finalDecidePindahPKL(
  BuildContext context,
  Map<String, dynamic> data,
  String status, // 'approved' atau 'rejected'
  String catatan,
  String tanggalEfektif,
) async {
  try {
    final token = await _getToken();
    if (token == null) {
      _showSnackBar('Token tidak ditemukan', isError: true);
      return;
    }

    final baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'https://api.gedanggoreng.com';

    // Tampilkan loading dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF641E20),
          ),
        ),
      ),
    );

    // Prepare request body sesuai API specification
    final requestBody = {
      'catatan': catatan,
      'status': status,
      'tanggal_efektif': tanggalEfektif,
    };

    print('Sending PATCH request to: ${data['id']}');
    print('Request body: $requestBody');

    final response = await http.patch(
      Uri.parse('$baseUrl/api/pindah-pkl/${data['id']}/koordinator'),
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );

    // Tutup loading dialog
    if (context.mounted) {
      Navigator.pop(context);
    }

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      jsonDecode(response.body);
      
      // Check if response indicates success (API might return 200 with success message)
      // Remove the item from local lists regardless since API call was successful
      setState(() {
        _pengajuanPklData.removeWhere((item) => item['id'] == data['id']);
        _filteredData.removeWhere((item) => item['id'] == data['id']);
      });

      _showSnackBar(
        status == 'approved'
            ? 'Pengajuan pindah PKL berhasil disetujui'
            : 'Pengajuan pindah PKL berhasil ditolak',
      );

      // Tutup dialog detail jika masih terbuka
      if (context.mounted) {
        Navigator.pop(context);
      }
    } else if (response.statusCode == 401) {
      _showSnackBar('Token expired, silakan login ulang', isError: true);
      _redirectToLogin();
    } else {
      String errorMessage = 'Gagal memproses pengajuan pindah PKL';
      try {
        final errorData = jsonDecode(response.body);
        errorMessage = errorData['message'] ?? errorMessage;
      } catch (e) {
        // Ignore JSON decode error
      }
      _showSnackBar(errorMessage, isError: true);
    }
  } catch (e) {
    if (context.mounted) {
      // Tutup loading dialog jika masih terbuka
      try {
        Navigator.pop(context);
      } catch (e) {
        // Dialog might already be closed
      }
    }
    print('Error in _finalDecidePindahPKL: $e');
    _showSnackBar('Terjadi kesalahan: ${e.toString()}', isError: true);
  }
}
  void _redirectToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    });
  }
void _showApproveDialog(dynamic data) {
  final TextEditingController catatanController = TextEditingController(
    text: 'Disetujui, silakan mulai di industri baru',
  );

  showDialog(
    context: context,
    builder: (context) {
      String selectedDate = DateTime.now()
          .add(const Duration(days: 1))
          .toString()
          .split(' ')[0];

      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
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
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: widget.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.check_circle,
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
                                  'SETUJUI PINDAH PKL',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF641E20),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Siswa: ${data['siswa_nama']}',
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

                      // Informasi pindah PKL
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Detail Pindah PKL',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.arrow_back,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dari: ${data['industri_lama']}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.arrow_forward,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Ke: ${data['industri_baru']}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Tanggal efektif
                      const Text(
                        'Tanggal Efektif',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF641E20),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final now = DateTime.now();
                          final initial = DateTime.tryParse(selectedDate) ??
                              now.add(const Duration(days: 1));

                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: initial,
                            firstDate: now,
                            lastDate: DateTime(2026, 12, 31),
                            builder: (context, child) {
                              return Theme(
                                data: ThemeData.light().copyWith(
                                  primaryColor: widget.primaryRed,
                                  colorScheme: ColorScheme.light(
                                      primary: widget.primaryRed),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (picked != null) {
                            setState(() {
                              selectedDate =
                                  "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  child: Text(
                                    selectedDate,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ),
                              const Icon(Icons.calendar_today,
                                  size: 18, color: Colors.grey),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Catatan
                      const Text(
                        'Catatan (Opsional)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF641E20),
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
                          minLines: 3,
                          decoration: const InputDecoration.collapsed(
                            hintText: 'Masukkan catatan untuk siswa...',
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tombol aksi
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
                              onPressed: () async {
                                final catatan = catatanController.text.trim();
                                await _finalDecidePindahPKL(
                                  context,
                                  data,
                                  'approved',
                                  catatan,
                                  selectedDate, // ✅ selectedDate is now in scope
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: widget.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
            ),
          );
        },
      );
    },
  );
}
  void _showRejectDialog(dynamic data) {
    final TextEditingController alasanController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
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
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: widget.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.cancel,
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
                                'TOLAK PINDAH PKL',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF641E20),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Siswa: ${data['siswa_nama']}',
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

                    // Informasi pindah PKL
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detail Pindah PKL',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.arrow_back,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Dari: ${data['industri_lama']}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.arrow_forward,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ke: ${data['industri_baru']}',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Alasan penolakan
                    const Text(
                      'Alasan Penolakan',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF641E20),
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
                        minLines: 3,
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

                    // Tombol aksi
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
                            onPressed: () async {
                              if (alasanController.text.trim().isEmpty) {
                                _showSnackBar('Masukkan alasan penolakan',
                                    isError: true);
                                return;
                              }

                              // Tanggal efektif bisa diisi dengan tanggal hari ini
                              final tanggalEfektif =
                                  DateTime.now().toString().split(' ')[0];
                              final catatan = alasanController.text.trim();

                              await _finalDecidePindahPKL(
                                context,
                                data,
                                'rejected',
                                catatan,
                                tanggalEfektif,
                              );
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
          ),
        );
      },
    );
  }


  String _translateStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending_pembimbing':
      case 'pending_kaprog':
      case 'pending_koordinator':
      case 'pending':
        return 'Menunggu';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';

    try {
      final date = DateTime.parse(dateString);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day-$month-$year';
    } catch (e) {
      return '-';
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? widget.red : widget.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Menunggu':
        return widget.orange;
      case 'Disetujui':
        return widget.green;
      case 'Ditolak':
        return widget.red;
      default:
        return Colors.grey;
    }
  }

  void _filterByStatus(String status) {
    setState(() {
      _filterStatus = status;
      _filteredData = status == 'Semua'
          ? _pengajuanPklData
          : _pengajuanPklData
              .where((item) => item['status'] == status)
              .toList();
    });
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredData = query.isEmpty
          ? _pengajuanPklData
          : _pengajuanPklData.where((item) {
              final siswaNama =
                  (item['siswa_nama'] ?? '').toString().toLowerCase();
              final industriLama =
                  (item['industri_lama'] ?? '').toString().toLowerCase();
              final industriBaru =
                  (item['industri_baru'] ?? '').toString().toLowerCase();

              return siswaNama.contains(query) ||
                  industriLama.contains(query) ||
                  industriBaru.contains(query);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchPengajuanPklData();
      },
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
            'Status Pengajuan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF641E20),
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
                    onTap: () => _filterByStatus(status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _filterStatus == status
                            ? widget.primaryRed
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: widget.primaryRed),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _filterStatus == status
                              ? Colors.white
                              : widget.primaryRed,
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
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _performSearch(),
                    decoration: const InputDecoration.collapsed(
                      hintText: 'Cari nama siswa atau industri...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    onPressed: () {
                      _searchController.clear();
                      _performSearch();
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
    final menungguCount =
        _pengajuanPklData.where((item) => item['status'] == 'Menunggu').length;
    final disetujuiCount =
        _pengajuanPklData.where((item) => item['status'] == 'Disetujui').length;
    final ditolakCount =
        _pengajuanPklData.where((item) => item['status'] == 'Ditolak').length;

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
          _buildStatItem(
            'Total',
            _pengajuanPklData.length.toString(),
            Icons.list_alt,
            widget.primaryRed,
          ),
          _buildStatItem(
            'Menunggu',
            menungguCount.toString(),
            Icons.access_time,
            widget.orange,
          ),
          _buildStatItem(
            'Disetujui',
            disetujuiCount.toString(),
            Icons.check_circle,
            widget.green,
          ),
          _buildStatItem(
            'Ditolak',
            ditolakCount.toString(),
            Icons.cancel,
            widget.red,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, IconData icon, Color color) {
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
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _documentList() {
    if (_isLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
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
                  ? 'Belum ada pengajuan pindah PKL dari siswa'
                  : 'Tidak ada pengajuan dengan status "$_filterStatus"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
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
              const Text(
                'Daftar Pengajuan Pindah PKL',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF641E20),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: widget.primaryRed.withValues(alpha: 0.2),
                  ),
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
          ..._filteredData.map((data) => _buildDocumentCard(data)),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> data) {
    final statusColor = _getStatusColor(data['status']);
    final isPending = data['status'] == 'Menunggu';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showDetailDialog(data),
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
                        color: widget.primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: widget.primaryRed.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.swap_horiz,
                        color: Color(0xFF641E20),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['siswa_nama'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.business,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  data['industri_lama'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.arrow_forward,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  data['industri_baru'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        data['status'],
                        style: TextStyle(
                          color: statusColor,
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
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Diajukan: ${data['tanggal_diajukan']}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (isPending)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectDialog(data),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: widget.red,
                            side: BorderSide(color: widget.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text(
                            'TOLAK',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showApproveDialog(data),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text(
                            'SETUJUI',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: () => _showDetailDialog(data),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: widget.primaryRed,
                        side: BorderSide(color: widget.primaryRed),
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

  void _showDetailDialog(Map<String, dynamic> data) {
    final isPending = data['status'] == 'Menunggu';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Detail Pengajuan Pindah PKL (Koordinator)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF641E20),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 28),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey[300]!),
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
                                    color: widget.primaryRed
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Color(0xFF641E20),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['siswa_nama'],
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(data['status'])
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: _getStatusColor(data['status'])
                                          .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    data['status'],
                                    style: TextStyle(
                                      color: _getStatusColor(data['status']),
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
                        'Informasi Pindah PKL',
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
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          children: [
                            _infoRow('Industri Asal', data['industri_lama']),
                            const SizedBox(height: 12),
                            _infoRow('Industri Tujuan', data['industri_baru']),
                            const SizedBox(height: 12),
                            _infoRow(
                                'Tanggal Diajukan', data['tanggal_diajukan']),
                            const SizedBox(height: 12),
                            _infoRow('Status', data['status']),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              if (isPending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(data),
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
                        onPressed: () => _showApproveDialog(data),
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
                ),
              ],
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
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF666666),
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
}
