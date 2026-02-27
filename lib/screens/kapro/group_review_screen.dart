// lib/screens/kaprog/group_review_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroupReviewScreen extends StatefulWidget {
  final ScrollController? scrollController;

  const GroupReviewScreen({
    super.key,
    this.scrollController,
  });

  @override
  State<GroupReviewScreen> createState() => _GroupReviewScreenState();
}

class _GroupReviewScreenState extends State<GroupReviewScreen>
    with AutomaticKeepAliveClientMixin {
  final Color _primaryRed = const Color(0xFF6B1B1B);
  final Color _bgSoft = const Color(0xFFF6EEEE);
  final Color _textPrimary = Colors.black;
  final Color _textSecondary = const Color(0xFF666666);
  final Color _borderColor = const Color(0xFFE0E0E0);
  final Color _green = const Color(0xFF4CAF50);
  final Color _orange = const Color(0xFFFF9800);
  final Color _red = const Color(0xFFF44336);

  List<dynamic> _groups = [];
  List<dynamic> _filteredGroups = [];
  List<dynamic> _pembimbingList = [];
  String _filterStatus = 'Semua';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _rejectReasonController = TextEditingController();
  final TextEditingController _approveNoteController = TextEditingController();
  int? _selectedPembimbingId;

  String? _accessToken;
  bool _isLoading = true;
  bool _isError = false;
  String _errorMessage = '';

  // Filter options
  final List<String> _statusOptions = ['Semua', 'Menunggu'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rejectReasonController.dispose();
    _approveNoteController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    await _getAccessToken();

    if (_accessToken != null) {
      await Future.wait([
        _fetchGroups(),
        _fetchPembimbingList(),
      ]);
    } else {
      setState(() {
        _isError = true;
        _errorMessage = 'Token tidak ditemukan. Silakan login ulang.';
        _isLoading = false;
      });
    }
  }

  Future<void> _getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _accessToken = prefs.getString('access_token');
      });
    } catch (e) {
      print('Error getting access token: $e');
    }
  }

  Future<void> _fetchGroups() async {
    if (_accessToken == null || _accessToken!.isEmpty) {
      setState(() {
        _isError = true;
        _errorMessage = 'Token tidak valid. Silakan login ulang.';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/group/review'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _groups = data;
          _filteredGroups = data;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isError = true;
          _errorMessage = 'Sesi telah berakhir. Silakan login ulang.';
          _isLoading = false;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _isError = true;
          _errorMessage = 'Anda tidak memiliki akses ke halaman ini.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isError = true;
          _errorMessage = 'Gagal memuat data: ${response.statusCode}';
          _isLoading = false;
        });
        _loadDummyData();
      }
    } catch (e) {
      print('Error fetching groups: $e');
      setState(() {
        _isError = true;
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
      _loadDummyData();
    }
  }

  Future<void> _fetchPembimbingList() async {
    if (_accessToken == null) return;

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/guru'),
        headers: {'Authorization': 'Bearer $_accessToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> teachersList = [];

        if (data['success'] == true && data['data'] != null) {
          if (data['data']['data'] is List) {
            teachersList = data['data']['data'];
          } else if (data['data'] is List) {
            teachersList = data['data'];
          }
        }

        // Filter hanya guru pembimbing
        final pembimbingList = teachersList.where((teacher) {
          return teacher['is_pembimbing'] == true;
        }).toList();

        setState(() {
          _pembimbingList = pembimbingList;
        });
      }
    } catch (e) {
      print('Error loading pembimbing: $e');
    }
  }

  void _loadDummyData() {
    setState(() {
      _groups = [
        {
          'id': 1,
          'leader': {
            'id': 101,
            'nama': 'Ahmad Fauzi',
            'kelas': 'XII TKJ 2',
            'nisn': '1234567890'
          },
          'industri': {
            'id': 201,
            'nama': 'PT. Teknologi Indonesia',
            'alamat': 'Jl. Sudirman No. 123, Jakarta'
          },
          'member_count': 5,
          'members': [
            {'invitation_status': 'accepted', 'siswa': {'nama': 'Budi'}},
            {'invitation_status': 'accepted', 'siswa': {'nama': 'Cici'}},
            {'invitation_status': 'accepted', 'siswa': {'nama': 'Dedi'}},
            {'invitation_status': 'pending', 'siswa': {'nama': 'Eka'}},
            {'invitation_status': 'pending', 'siswa': {'nama': 'Fani'}}
          ],
          'submitted_at': '2026-02-25T10:30:00Z',
          'status': 'submitted',
          'catatan': 'Kelompok sudah lengkap, siap untuk PKL'
        },
        {
          'id': 2,
          'leader': {
            'id': 102,
            'nama': 'Siti Nurhaliza',
            'kelas': 'XII AKL 1',
            'nisn': '1234567891'
          },
          'industri': {
            'id': 202,
            'nama': 'PT. Finansial Sejahtera',
            'alamat': 'Jl. Gatot Subroto No. 45, Jakarta'
          },
          'member_count': 4,
          'members': [
            {'invitation_status': 'accepted', 'siswa': {'nama': 'Gita'}},
            {'invitation_status': 'accepted', 'siswa': {'nama': 'Hadi'}},
            {'invitation_status': 'accepted', 'siswa': {'nama': 'Indra'}},
            {'invitation_status': 'accepted', 'siswa': {'nama': 'Joko'}}
          ],
          'submitted_at': '2026-02-26T09:15:00Z',
          'status': 'submitted',
          'catatan': 'Semua anggota sudah menerima undangan'
        }
      ];
      _filteredGroups = _groups;
      _isLoading = false;
    });
  }

  Future<void> _approveGroup(int groupId) async {
    if (_selectedPembimbingId == null) {
      _showSnackBar('Pilih guru pembimbing terlebih dahulu', isError: true);
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/group/review/$groupId/approve'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'pembimbing_guru_id': _selectedPembimbingId,
        }),
      );

      if (response.statusCode == 200) {
        _showSnackBar('Grup berhasil disetujui');
        Navigator.pop(context); // Tutup dialog
        _fetchGroups(); // Refresh data
        _approveNoteController.clear();
        _selectedPembimbingId = null;
      } else if (response.statusCode == 404) {
        _showSnackBar('Grup tidak ditemukan', isError: true);
      } else if (response.statusCode == 409) {
        final error = json.decode(response.body);
        _showSnackBar(error['message'] ?? 'Grup sudah diproses', isError: true);
      } else {
        _showSnackBar('Gagal menyetujui grup', isError: true);
      }
    } catch (e) {
      print('Error approve group: $e');
      _showSnackBar('Terjadi kesalahan', isError: true);
    }
  }

  Future<void> _rejectGroup(int groupId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_BASE_URL']}/api/pkl/group/review/$groupId/reject'),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'reason': reason,
        }),
      );

      if (response.statusCode == 204) {
        _showSnackBar('Grup berhasil ditolak');
        Navigator.pop(context); // Tutup dialog
        _fetchGroups(); // Refresh data
        _rejectReasonController.clear();
      } else if (response.statusCode == 400) {
        _showSnackBar('Alasan penolakan harus diisi', isError: true);
      } else if (response.statusCode == 404) {
        _showSnackBar('Grup tidak ditemukan', isError: true);
      } else if (response.statusCode == 409) {
        _showSnackBar('Grup sudah diproses sebelumnya', isError: true);
      } else {
        _showSnackBar('Gagal menolak grup', isError: true);
      }
    } catch (e) {
      print('Error reject group: $e');
      _showSnackBar('Terjadi kesalahan', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? _red : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _filterByStatus(String status) {
    setState(() {
      _filterStatus = status;
      if (status == 'Semua') {
        _filteredGroups = _groups;
      } else {
        // Untuk demo, semua grup dianggap menunggu
        _filteredGroups = _groups;
      }
    });
  }

  void _performSearch() {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isNotEmpty) {
      setState(() {
        _filteredGroups = _groups.where((group) {
          final leader = group['leader'] ?? {};
          final industri = group['industri'] ?? {};
          return leader['nama']?.toLowerCase().contains(query) == true ||
              leader['kelas']?.toLowerCase().contains(query) == true ||
              industri['nama']?.toLowerCase().contains(query) == true;
        }).toList();
      });
    } else {
      _filterByStatus(_filterStatus);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day} ${_getMonthName(date.month)} ${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return months[month - 1];
  }

  int _getAcceptedMemberCount(List? members) {
    if (members == null) return 0;
    return members.where((m) => m['invitation_status'] == 'accepted').length;
  }

  void _showApproveDialog(Map<String, dynamic> group) {
    _selectedPembimbingId = null;
    _approveNoteController.clear();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.check_circle, color: _green, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Setujui Grup',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Pilih guru pembimbing',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Detail Grup
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Info Card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: _borderColor),
                            ),
                            child: Column(
                              children: [
                                _infoRow('Ketua', group['leader']?['nama'] ?? '-'),
                                const SizedBox(height: 12),
                                _infoRow('Kelas', group['leader']?['kelas'] ?? '-'),
                                const SizedBox(height: 12),
                                _infoRow('Industri', group['industri']?['nama'] ?? '-'),
                                const SizedBox(height: 12),
                                _infoRow(
                                  'Anggota',
                                  '${_getAcceptedMemberCount(group['members'])}/${group['member_count'] ?? 0}',
                                ),
                                if (group['catatan'] != null) ...[
                                  const SizedBox(height: 12),
                                  _infoRow('Catatan', group['catatan']),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Pilih Guru
                          const Text(
                            'Guru Pembimbing',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _borderColor),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _selectedPembimbingId,
                                hint: const Text(
                                  'Pilih guru pembimbing',
                                  style: TextStyle(color: Colors.grey, fontSize: 14),
                                ),
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down),
                                items: _pembimbingList.map((teacher) {
                                  return DropdownMenuItem<int>(
                                    value: teacher['id'],
                                    child: Text(
                                      teacher['nama'] ?? 'Guru',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    _selectedPembimbingId = newValue;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Catatan (Opsional)
                          const Text(
                            'Catatan (Opsional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _borderColor),
                            ),
                            child: TextField(
                              controller: _approveNoteController,
                              maxLines: 3,
                              decoration: const InputDecoration.collapsed(
                                hintText: 'Masukkan catatan...',
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _textPrimary,
                            side: BorderSide(color: _borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_selectedPembimbingId == null) {
                              _showSnackBar('Pilih guru pembimbing', isError: true);
                              return;
                            }
                            _approveGroup(group['id']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Setujui'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> group) {
    _rejectReasonController.clear();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.cancel, color: _red, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tolak Grup',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Berikan alasan penolakan',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Detail Grup
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _borderColor),
                ),
                child: Column(
                  children: [
                    _infoRow('Ketua', group['leader']?['nama'] ?? '-'),
                    const SizedBox(height: 12),
                    _infoRow('Kelas', group['leader']?['kelas'] ?? '-'),
                    const SizedBox(height: 12),
                    _infoRow('Industri', group['industri']?['nama'] ?? '-'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Alasan Penolakan
              const Text(
                'Alasan Penolakan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _borderColor),
                ),
                child: TextField(
                  controller: _rejectReasonController,
                  maxLines: 4,
                  decoration: const InputDecoration.collapsed(
                    hintText: 'Masukkan alasan penolakan...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textPrimary,
                        side: BorderSide(color: _borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_rejectReasonController.text.trim().isEmpty) {
                          _showSnackBar('Masukkan alasan penolakan', isError: true);
                          return;
                        }
                        _rejectGroup(group['id'], _rejectReasonController.text.trim());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Tolak'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: _textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _refreshData() async {
    await _fetchGroups();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: _bgSoft,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryRed),
                  const SizedBox(height: 16),
                  Text(
                    'Memuat data...',
                    style: TextStyle(color: _textSecondary),
                  ),
                ],
              ),
            )
          : _isError
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: _red),
                        const SizedBox(height: 16),
                        const Text(
                          'Terjadi Kesalahan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _textSecondary),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _initializeData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryRed,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('COBA LAGI'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshData,
                  color: _primaryRed,
                  backgroundColor: Colors.white,
                  child: CustomScrollView(
                    controller: widget.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // Header
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(16, 60, 16, 0),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: _borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _primaryRed.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.group_work,
                                  color: _primaryRed,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Tinjau Grup PKL',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${_groups.length} grup menunggu persetujuan',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _groups.isNotEmpty
                                            ? _orange
                                            : _textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 16)),

                      // Filter Section
                      SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: _borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Filter',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
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
                                        primaryColor: _primaryRed,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _searchField(),
                            ],
                          ),
                        ),
                      ),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      // Group List
                      if (_filteredGroups.isEmpty)
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off,
                                    size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                const Text(
                                  'Tidak Ada Grup Menunggu',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Semua grup telah diproses',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final group = _filteredGroups[index];
                                return _GroupCard(
                                  group: group,
                                  primaryRed: _primaryRed,
                                  borderColor: _borderColor,
                                  green: _green,
                                  orange: _orange,
                                  red: _red,
                                  textSecondary: _textSecondary,
                                  onApprove: () => _showApproveDialog(group),
                                  onReject: () => _showRejectDialog(group),
                                  formatDate: _formatDate,
                                  getAcceptedMemberCount: _getAcceptedMemberCount,
                                );
                              },
                              childCount: _filteredGroups.length,
                            ),
                          ),
                        ),
                    ],
                  ),
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
                hintText: 'Cari ketua kelompok, kelas, atau industri...',
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
}

// Filter Chip Widget
class _FilterChip extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;
  final Color primaryColor;

  const _FilterChip({
    required this.text,
    required this.isSelected,
    required this.onTap,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : primaryColor,
          ),
        ),
      ),
    );
  }
}

// Group Card Widget
class _GroupCard extends StatelessWidget {
  final Map<String, dynamic> group;
  final Color primaryRed;
  final Color borderColor;
  final Color green;
  final Color orange;
  final Color red;
  final Color textSecondary;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final String Function(String?) formatDate;
  final int Function(List?) getAcceptedMemberCount;

  const _GroupCard({
    required this.group,
    required this.primaryRed,
    required this.borderColor,
    required this.green,
    required this.orange,
    required this.red,
    required this.textSecondary,
    required this.onApprove,
    required this.onReject,
    required this.formatDate,
    required this.getAcceptedMemberCount,
  });

  @override
  Widget build(BuildContext context) {
    final leader = group['leader'] ?? {};
    final industri = group['industri'] ?? {};
    final acceptedCount = getAcceptedMemberCount(group['members']);
    final totalMembers = group['member_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryRed.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.group, color: primaryRed, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        leader['nama'] ?? 'Ketua Kelompok',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        industri['nama'] ?? 'Industri',
                        style: TextStyle(
                          fontSize: 13,
                          color: primaryRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: orange.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'MENUNGGU',
                    style: TextStyle(
                      color: orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _infoChip(
                        Icons.people,
                        'Anggota',
                        '$acceptedCount/$totalMembers',
                        textSecondary,
                        borderColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _infoChip(
                        Icons.school,
                        'Kelas',
                        leader['kelas'] ?? '-',
                        textSecondary,
                        borderColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _infoChip(
                        Icons.calendar_today,
                        'Diajukan',
                        formatDate(group['submitted_at']),
                        textSecondary,
                        borderColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _infoChip(
                        Icons.person,
                        'Ketua',
                        leader['nisn'] ?? '-',
                        textSecondary,
                        borderColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: red,
                      side: BorderSide(color: red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('TOLAK'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('SETUJUI'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value, Color textSecondary, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textSecondary),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 9, color: textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}