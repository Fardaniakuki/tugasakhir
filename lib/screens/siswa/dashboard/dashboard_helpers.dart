// File: lib/screens/siswa/dashboard_helpers.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ============== MODELS ==============

class SiswaInfo {
  final int id;
  final String nama;
  final String nisn;
  final String kelas;

  SiswaInfo({
    required this.id,
    required this.nama,
    required this.nisn,
    required this.kelas,
  });

  factory SiswaInfo.fromJson(Map<String, dynamic> json) {
    return SiswaInfo(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      nama: json['nama']?.toString() ?? '',
      nisn: json['nisn']?.toString() ?? '',
      kelas: json['kelas']?.toString() ?? '',
    );
  }
}
// ============== INDUSTRI MODEL ==============
class IndustriModel {
  final int id;
  final String name;
  final String address;
  final String sector;
  final int quota;
  final int remainingSlots;

  IndustriModel({
    required this.id,
    required this.name,
    required this.address,
    required this.sector,
    required this.quota,
    required this.remainingSlots,
  });

  factory IndustriModel.fromJson(Map<String, dynamic> json) {
    return IndustriModel(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String,
      sector: json['sector'] as String,
      quota: json['quota'] as int,
      remainingSlots: json['remaining_slots'] as int,
    );
  }

  bool get isAvailable => remainingSlots > 0;
  
  String get quotaInfo => '$remainingSlots/$quota tersedia';
}
// ============== AVAILABLE MEMBER MODEL ==============
class AvailableMember {
  final int id;
  final String nama;
  final String nisn;
  final String kelas;

  AvailableMember({
    required this.id,
    required this.nama,
    required this.nisn,
    required this.kelas,
  });

  factory AvailableMember.fromJson(Map<String, dynamic> json) {
    return AvailableMember(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      nama: json['nama']?.toString() ?? '',
      nisn: json['nisn']?.toString() ?? '',
      kelas: json['kelas']?.toString() ?? '',
    );
  }

  @override
  String toString() => '$nama - $kelas';
}

class GroupMember {
  final SiswaInfo siswa;
  final bool isLeader;
  final String invitationStatus;
  final String joinedAt;
  final String? respondedAt;

  GroupMember({
    required this.siswa,
    required this.isLeader,
    required this.invitationStatus,
    required this.joinedAt,
    this.respondedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      siswa: SiswaInfo.fromJson(json['siswa'] ?? {}),
      isLeader: json['is_leader'] ?? false,
      invitationStatus: json['invitation_status']?.toString() ?? 'pending',
      joinedAt: json['joined_at']?.toString() ?? '',
      respondedAt: json['responded_at']?.toString(),
    );
  }
}

class IndustriInfo {
  final int id;
  final String nama;
  final String alamat;
  final String? noTelp;
  final String? email;

  IndustriInfo({
    required this.id,
    required this.nama,
    required this.alamat,
    this.noTelp,
    this.email,
  });

  factory IndustriInfo.fromJson(Map<String, dynamic> json) {
    return IndustriInfo(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      nama: json['nama']?.toString() ?? '',
      alamat: json['alamat']?.toString() ?? '',
      noTelp: json['no_telp']?.toString(),
      email: json['email']?.toString(),
    );
  }
}

class PKLGroupModel {
  final int id;
  final SiswaInfo leader;
  final List<GroupMember> members;
  final IndustriInfo industri;
  final String status;
  final int memberCount;
  final String? catatan;
  final String? tanggalMulai;
  final String? tanggalSelesai;
  final String? pembimbing;
  final String createdAt;
  final String? submittedAt;
  final String? approvedAt;

  PKLGroupModel({
    required this.id,
    required this.leader,
    required this.members,
    required this.industri,
    required this.status,
    required this.memberCount,
    this.catatan,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.pembimbing,
    required this.createdAt,
    this.submittedAt,
    this.approvedAt,
  });

  factory PKLGroupModel.fromJson(Map<String, dynamic> json) {
    String status = json['status']?.toString() ?? 'pending';

    // Mapping semua 'draft' ke 'pending'
    if (status.toLowerCase() == 'draft') {
      status = 'pending';
    }

    return PKLGroupModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      leader: SiswaInfo.fromJson(json['leader'] ?? {}),
      members: (json['members'] as List? ?? [])
          .map((m) => GroupMember.fromJson(m))
          .toList(),
      industri: IndustriInfo.fromJson(json['industri'] ?? {}),
      status: status,
      memberCount: json['member_count'] ?? 0,
      catatan: json['catatan']?.toString(),
      tanggalMulai: json['tanggal_mulai']?.toString(),
      tanggalSelesai: json['tanggal_selesai']?.toString(),
      pembimbing: json['pembimbing']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      submittedAt: json['submitted_at']?.toString(),
      approvedAt: json['approved_at']?.toString(),
    );
  }

  bool isUserLeader(int userId) {
    return leader.id == userId;
  }

  String? getUserInvitationStatus(int userId) {
    try {
      final member = members.firstWhere((m) => m.siswa.id == userId);
      return member.invitationStatus;
    } catch (e) {
      return null;
    }
  }

  List<GroupMember> getAcceptedMembers() {
    return members.where((m) => m.invitationStatus == 'accepted').toList();
  }

  List<GroupMember> getPendingMembers() {
    return members.where((m) => m.invitationStatus == 'pending').toList();
  }
}

// ============== INVITATION MODEL ==============

class GroupInvitation {
  final int id;
  final int groupId;
  final Map<String, dynamic> leader;
  final Map<String, dynamic> industri;
  final int memberCount;
  final String invitedAt;

  GroupInvitation({
    required this.id,
    required this.groupId,
    required this.leader,
    required this.industri,
    required this.memberCount,
    required this.invitedAt,
  });

  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    return GroupInvitation(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      groupId: json['group_id'] is int
          ? json['group_id']
          : int.tryParse(json['group_id'].toString()) ?? 0,
      leader: json['leader'] ?? {},
      industri: json['industri'] ?? {},
      memberCount: json['member_count'] ?? 0,
      invitedAt: json['invited_at']?.toString() ?? '',
    );
  }

  String getLeaderName() {
    return leader['nama']?.toString() ?? 'Unknown';
  }

  String getLeaderKelas() {
    return leader['kelas']?.toString() ?? '-';
  }

  String getIndustriName() {
    return industri['nama']?.toString() ?? 'Belum dipilih';
  }
}

// ============== API HELPER ==============
class IndustriApiHelper {
  static Future<List<IndustriModel>> getAvailableIndustries({
    required String token,
    String search = '',
    int limit = 100,
  }) async {
    print('=== GET AVAILABLE INDUSTRIES ===');
    
    try {
      // Build URL dengan query parameters
      String urlString = '${dotenv.env['API_BASE_URL']}/api/pkl/industri/available';
      
      // Tambahkan query parameters jika ada
      final Map<String, String> queryParams = {};
      if (search.isNotEmpty) {
        queryParams['search'] = search;
      }
      queryParams['limit'] = limit.toString();
      
      if (queryParams.isNotEmpty) {
        final uri = Uri.parse(urlString);
        final newUri = uri.replace(queryParameters: queryParams);
        urlString = newUri.toString();
      }
      
      print('GET: $urlString');
      
      final response = await http.get(
        Uri.parse(urlString),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        
        print('Found ${data.length} industries');
        
        return data.map((item) => IndustriModel.fromJson(item)).toList();
      } else {
        print('Failed to load industries: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error getting available industries: $e');
      print('Stack trace:');
      print(StackTrace.current);
    }
    
    return [];
  }
}

// ============== DATE FORMATTER ==============
class DateFormatter {
  // Format untuk API (YYYY-MM-DD)
  static String formatForApi(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
           '${date.month.toString().padLeft(2, '0')}-'
           '${date.day.toString().padLeft(2, '0')}';
  }
  
  // Format untuk tampilan (dd MMMM yyyy)
  static String format(dynamic date) {
    if (date == null) return '-';
    
    DateTime dateTime;
    
    // Handle jika date sudah berupa DateTime
    if (date is DateTime) {
      dateTime = date;
    }
    // Handle jika date berupa String
    else if (date is String) {
      try {
        dateTime = DateTime.parse(date);
      } catch (e) {
        return date; // Return original string jika tidak bisa parse
      }
    }
    // Handle jika date berupa int (timestamp)
    else if (date is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(date);
    }
    else {
      return date.toString();
    }
    
    // Format: 15 Maret 2025
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }
  
  // Format singkat (dd/MM/yyyy)
  static String formatShort(dynamic date) {
    if (date == null) return '-';
    
    DateTime dateTime;
    
    if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      try {
        dateTime = DateTime.parse(date);
      } catch (e) {
        return date;
      }
    } else {
      return date.toString();
    }
    
    return '${dateTime.day.toString().padLeft(2, '0')}/'
           '${dateTime.month.toString().padLeft(2, '0')}/'
           '${dateTime.year}';
  }
  
  // Method untuk menampilkan waktu relatif (misal: "2 jam yang lalu", "kemarin", dll)
  static String timeAgo(dynamic date) {
    if (date == null) return '-';
    
    DateTime dateTime;
    
    // Handle berbagai tipe input
    if (date is DateTime) {
      dateTime = date;
    } else if (date is String) {
      try {
        dateTime = DateTime.parse(date);
      } catch (e) {
        return date.toString();
      }
    } else if (date is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(date);
    } else {
      return date.toString();
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    // Kurang dari 1 menit
    if (difference.inSeconds < 60) {
      return 'baru saja';
    }
    
    // Kurang dari 1 jam
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit yang lalu';
    }
    
    // Kurang dari 24 jam
    if (difference.inHours < 24) {
      return '${difference.inHours} jam yang lalu';
    }
    
    // Kurang dari 7 hari
    if (difference.inDays < 7) {
      if (difference.inDays == 1) {
        return 'kemarin';
      }
      return '${difference.inDays} hari yang lalu';
    }
    
    // Kurang dari 30 hari
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      if (weeks == 1) {
        return 'minggu lalu';
      }
      return '$weeks minggu yang lalu';
    }
    
    // Kurang dari 365 hari
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      if (months == 1) {
        return 'bulan lalu';
      }
      return '$months bulan yang lalu';
    }
    
    // Lebih dari setahun
    final years = (difference.inDays / 365).floor();
    if (years == 1) {
      return 'tahun lalu';
    }
    return '$years tahun yang lalu';
  }
  
  // Helper method untuk mendapatkan nama bulan
  static String getMonthName(int month) {
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return months[month - 1];
  }
  
  // Helper method untuk membandingkan apakah tanggal sama
  static bool isSameDay(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }
  
  // Helper method untuk mendapatkan range tanggal
  static String getDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '-';
    
    if (start.year == end.year && start.month == end.month) {
      return '${start.day} - ${end.day} ${getMonthName(end.month)} ${end.year}';
    } else if (start.year == end.year) {
      return '${start.day} ${getMonthName(start.month)} - ${end.day} ${getMonthName(end.month)} ${end.year}';
    } else {
      return '${format(start)} - ${format(end)}';
    }
  }
}

// ============== STATUS HELPER ==============
class StatusHelper {
  static Color getColor(String status) {
    switch (status.toLowerCase()) {
      case 'disetujui':
      case 'approved':
        return const Color.fromARGB(255, 46, 125, 50);
      case 'ditolak':
      case 'rejected':
        return Colors.red;
      case 'menunggu':
      case 'pending':
      case 'submitted':
      case 'draft':
        return Colors.orange;
      default:
        return Colors.orange;
    }
  }

  static String translate(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'disetujui':
        return 'DISETUJUI';
      case 'rejected':
      case 'ditolak':
        return 'DITOLAK';
      case 'pending':
      case 'menunggu':
      case 'submitted':
      case 'draft':
        return 'MENUNGGU';
      case 'completed':
      case 'selesai':
        return 'SELESAI';
      default:
        return status.toUpperCase();
    }
  }

  static String getText(String? status) {
    if (status == null) return 'Belum Mengajukan';
    switch (status.toLowerCase()) {
      case 'menunggu':
      case 'pending':
      case 'submitted':
      case 'draft':
        return 'Menunggu';
      case 'disetujui':
      case 'approved':
        return 'Menjalankan PKL';
      case 'selesai':
      case 'completed':
        return 'Selesai PKL';
      default:
        return 'Mengajukan';
    }
  }

  static int getProgress(String? status) {
    if (status == null) return 0;
    switch (status.toLowerCase()) {
      case 'menunggu':
      case 'pending':
      case 'submitted':
      case 'draft':
        return 1;
      case 'disetujui':
      case 'approved':
        return 2;
      case 'selesai':
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  // Helper untuk mengecek apakah status termasuk dalam kategori "dapat diedit"
  static bool isEditable(String status) {
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'pending' ||
        lowerStatus == 'menunggu' ||
        lowerStatus == 'submitted' ||
        lowerStatus == 'draft';
  }
}

// ============== EDIT MEMBERS DROPDOWN DIALOG ==============
class EditMembersDropdownDialog extends StatefulWidget {
  final PKLGroupModel group;
  final int currentUserId;
  final Future<List<AvailableMember>> Function({String query})
      onGetAvailableMembers;

  const EditMembersDropdownDialog({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.onGetAvailableMembers,
  });

  @override
  State<EditMembersDropdownDialog> createState() =>
      _EditMembersDropdownDialogState();
}

class _EditMembersDropdownDialogState extends State<EditMembersDropdownDialog> {
  final List<AvailableMember> _selectedMembers = [];
  final List<AvailableMember> _availableMembers = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadAvailableMembers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadAvailableMembers(query: _searchController.text);
    });
  }

  Future<void> _loadAvailableMembers({String query = ''}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final members = await widget.onGetAvailableMembers(query: query);

      // Filter out current user (ketua) and existing members
      final existingMemberIds = widget.group.members
          .where((m) => m.siswa.id != widget.currentUserId)
          .map((m) => m.siswa.id)
          .toSet();

      final filteredMembers = members
          .where((m) =>
              m.id != widget.currentUserId && !existingMemberIds.contains(m.id))
          .toList();

      setState(() {
        _availableMembers.clear();
        _availableMembers.addAll(filteredMembers);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat daftar anggota';
        _isLoading = false;
      });
    }
  }

  void _addMember(AvailableMember? member) {
    if (member != null && !_selectedMembers.contains(member)) {
      setState(() {
        _selectedMembers.add(member);
      });
    }
  }

  void _removeMember(AvailableMember member) {
    setState(() {
      _selectedMembers.remove(member);
    });
  }

  @override
  Widget build(BuildContext context) {
    final existingMembers = widget.group.members
        .where((m) => m.siswa.id != widget.currentUserId)
        .toList();

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.group, color: Colors.blue[700]),
          const SizedBox(width: 8),
          const Text('Edit Anggota Kelompok'),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current members section
              if (existingMembers.isNotEmpty) ...[
                const Text(
                  'Anggota Saat Ini:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...existingMembers.map((member) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.siswa.nama,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  member.siswa.kelas,
                                  style: TextStyle(
                                      fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: member.invitationStatus == 'accepted'
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              member.invitationStatus == 'accepted'
                                  ? 'DITERIMA'
                                  : 'MENUNGGU',
                              style: TextStyle(
                                fontSize: 9,
                                color: member.invitationStatus == 'accepted'
                                    ? Colors.green
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 24),
              ],

              // New members selection
              const Text(
                'Tambah Anggota Baru:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),

              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NISN...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(height: 12),

              // Selected members chips
              if (_selectedMembers.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedMembers
                      .map((member) => Chip(
                            label: Text(member.nama),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removeMember(member),
                            backgroundColor: Colors.blue.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(fontSize: 12),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Available members dropdown
              if (_isLoading)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ))
              else if (_errorMessage != null)
                Center(
                    child: Text(_errorMessage!,
                        style: const TextStyle(color: Colors.red)))
              else if (_availableMembers.isEmpty)
                const Center(child: Text('Tidak ada anggota tersedia'))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pilih anggota:',
                        style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AvailableMember>(
                          isExpanded: true,
                          hint: const Text('-- Pilih anggota --'),
                          value: null,
                          items: _availableMembers.map((member) {
                            return DropdownMenuItem(
                              value: member,
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline,
                                      size: 16, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member.nama,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          '${member.kelas} • NISN: ${member.nisn}',
                                          style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: _addMember,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _selectedMembers.isEmpty
              ? null
              : () {
                  // Convert selected members to list of usernames
                  final usernames =
                      _selectedMembers.map((m) => m.nama).toList();
                  Navigator.pop(context, usernames);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
          child: const Text('Simpan Perubahan'),
        ),
      ],
    );
  }
}

// ============== SKELETON WIDGETS ==============

class SkeletonTimeSection extends StatelessWidget {
  const SkeletonTimeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTimeItemSkeleton(),
            Container(
              width: 2,
              height: 40,
              color: Colors.grey[300],
            ),
            _buildTimeItemSkeleton(),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 27,
          color: Colors.grey[200],
        ),
      ],
    );
  }

  Widget _buildTimeItemSkeleton() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 12,
          color: Colors.grey[300],
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 18,
          color: Colors.grey[300],
        ),
      ],
    );
  }
}

class SkeletonQuickActions extends StatelessWidget {
  const SkeletonQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140,
      color: Colors.grey[200],
      child: Stack(
        children: [
          Positioned(
            left: 140,
            top: 22,
            bottom: 22,
            child: Container(
              width: 2,
              color: Colors.grey[300],
            ),
          ),
          Positioned(
            left: 158,
            right: 22,
            top: 70,
            child: Container(
              height: 2,
              color: Colors.grey[300],
            ),
          ),
          Positioned(
            left: 45,
            top: 40,
            child: _buildMenuSkeleton(),
          ),
          Positioned(
            right: 85,
            top: 20,
            child: _buildMenuSkeletonKanan(),
          ),
          Positioned(
            right: 85,
            bottom: 20,
            child: _buildMenuSkeletonKanan(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSkeleton() {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 12,
          color: Colors.grey[300],
        ),
      ],
    );
  }

  Widget _buildMenuSkeletonKanan() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 50,
          height: 12,
          color: Colors.grey[300],
        ),
      ],
    );
  }
}

class SkeletonTitle extends StatelessWidget {
  const SkeletonTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          width: 150,
          height: 20,
          color: Colors.grey[300],
        ),
        Container(
          width: 80,
          height: 12,
          color: Colors.grey[300],
        ),
      ],
    );
  }
}

class SkeletonPKLCard extends StatelessWidget {
  const SkeletonPKLCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 24,
            color: Colors.grey[200],
          ),
          const SizedBox(height: 12),
          Container(
            width: 150,
            height: 20,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 8),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Container(
                width: double.infinity,
                height: 14,
                color: Colors.grey[200],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 12,
                  color: Colors.grey[200],
                ),
                const SizedBox(height: 4),
                Container(
                  height: 14,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============== NOTIFICATION WIDGETS ==============

class NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final bool isRead;
  final bool isDisetujui;
  final bool isDitolak;
  final VoidCallback? onTap;
  final VoidCallback? onReapply;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.isRead,
    required this.isDisetujui,
    required this.isDitolak,
    this.onTap,
    this.onReapply,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = DateTime.parse(
        notification['timestamp'] ?? DateTime.now().toIso8601String());
    final catatan = notification['catatan'] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.grey[50] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isRead
                ? Colors.grey[200]!
                : const Color.fromARGB(255, 180, 16, 4),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isDitolak
                        ? Colors.red
                        : (isDisetujui ? Colors.green : Colors.orange),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification['title']?.toString() ?? 'Notifikasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notification['message']?.toString() ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            if (catatan.isNotEmpty && catatan != 'Tidak ada alasan diberikan')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  catatan,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormatter.timeAgo(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (isDitolak)
                  TextButton(
                    onPressed: onReapply,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                    ),
                    child: const Text(
                      'Ajukan Ulang',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 180, 16, 4),
                        fontWeight: FontWeight.bold,
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

// ============== INVITATION WIDGETS ==============

class InvitationCard extends StatelessWidget {
  final GroupInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final bool isProcessing;

  const InvitationCard({
    super.key,
    required this.invitation,
    required this.onAccept,
    required this.onReject,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.mail,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'UNDANGAN GROUP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'MENUNGGU',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ketua Kelompok',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      invitation.getLeaderName(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  invitation.getLeaderKelas(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.factory, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Industri',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      invitation.getIndustriName(),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.people, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                '${invitation.memberCount} anggota',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: isProcessing ? null : onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('TERIMA'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isProcessing ? null : onReject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('TOLAK'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class EmptyInvitationsCard extends StatelessWidget {
  const EmptyInvitationsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.mail_outline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada undangan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kamu tidak memiliki undangan group yang menunggu',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

// ============== DASHBOARD WIDGETS ==============

class DashboardHeader extends StatelessWidget {
  final String namaSiswa;
  final bool isLoading;
  final int unreadCount;
  final VoidCallback onNotificationTap;

  const DashboardHeader({
    super.key,
    required this.namaSiswa,
    required this.isLoading,
    required this.unreadCount,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: isLoading
                ? _buildSkeletonText()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Halo, $namaSiswa!',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Selamat datang di beranda PKL',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
          ),
          isLoading
              ? _buildSkeletonIcon()
              : Stack(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: onNotificationTap,
                        icon: const Icon(
                          Icons.notifications,
                          color: Color.fromARGB(255, 180, 16, 4),
                        ),
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSkeletonText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 120,
          height: 24,
          color: Colors.white.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 8),
        Container(
          width: 180,
          height: 14,
          color: Colors.white.withValues(alpha: 0.6),
        ),
      ],
    );
  }

  Widget _buildSkeletonIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        shape: BoxShape.circle,
      ),
    );
  }
}

class TimelineSection extends StatelessWidget {
  final bool isLoading;
  final bool isInGroup;
  final PKLGroupModel? activeGroup;
  final Map<String, dynamic>? pklData;
  final String? tanggalMulai;
  final String? tanggalSelesai;
  final String? status;

  const TimelineSection({
    super.key,
    required this.isLoading,
    required this.isInGroup,
    this.activeGroup,
    this.pklData,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const SkeletonTimeSection();

    final mulai = isInGroup
        ? DateFormatter.format(activeGroup?.tanggalMulai)
        : (pklData != null
            ? DateFormatter.format(pklData!['tanggal_mulai']?.toString())
            : '-');
    final selesai = isInGroup
        ? DateFormatter.format(activeGroup?.tanggalSelesai)
        : (pklData != null
            ? DateFormatter.format(pklData!['tanggal_selesai']?.toString())
            : '-');
    final currentStatus =
        isInGroup ? activeGroup?.status : pklData?['status']?.toString();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTimeItem('Mulai', mulai),
            Container(
              width: 2,
              height: 40,
              color: Colors.grey[300],
            ),
            _buildTimeItem('Selesai', selesai),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 27,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(13.5),
          ),
          child: Stack(
            children: [
              Container(
                width: (MediaQuery.of(context).size.width - 88) *
                    ((StatusHelper.getProgress(currentStatus) + 1.2) / 4),
                height: 27,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 88, 89, 90),
                  borderRadius: BorderRadius.circular(13.5),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      StatusHelper.getText(currentStatus),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeItem(String label, String date) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class QuickActionsMenu extends StatelessWidget {
  final VoidCallback onAjukanPKL;
  final VoidCallback onBukaIndustri;
  final VoidCallback onBukaRiwayat;

  const QuickActionsMenu({
    super.key,
    required this.onAjukanPKL,
    required this.onBukaIndustri,
    required this.onBukaRiwayat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 128, 13, 7),
            Color.fromARGB(255, 175, 20, 9),
            Color(0xFFD11F0B),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(31),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 140,
            top: 22,
            bottom: 22,
            child: Container(
              width: 1,
              color: Colors.white,
            ),
          ),
          Positioned(
            left: 158,
            right: 22,
            top: 70,
            child: Container(
              height: 1,
              color: Colors.white,
            ),
          ),
          Positioned(
            left: 45,
            top: 40,
            child:
                _buildMenuKiri('Pengajuan', Icons.assignment_add, onAjukanPKL),
          ),
          Positioned(
            right: 85,
            top: 20,
            child: _buildMenuKanan('Industri', Icons.factory, onBukaIndustri),
          ),
          Positioned(
            right: 85,
            bottom: 20,
            child: _buildMenuKanan('Riwayat', Icons.history, onBukaRiwayat),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuKiri(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 180, 16, 4),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuKanan(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 180, 16, 4),
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class GroupCard extends StatelessWidget {
  final PKLGroupModel group;
  final int? currentUserId;
  final VoidCallback? onEditMembers;
  final VoidCallback? onSubmitGroup;
  final Function(int, String) onRemoveMember;
  final VoidCallback? onDeleteGroup;

  const GroupCard({
    super.key,
    required this.group,
    this.currentUserId,
    this.onEditMembers,
    this.onSubmitGroup,
    required this.onRemoveMember,
    this.onDeleteGroup,
  });

  @override
  Widget build(BuildContext context) {
    final isUserLeader =
        currentUserId != null && group.isUserLeader(currentUserId!);
    final acceptedMembers = group.getAcceptedMembers();
    final pendingMembers = group.getPendingMembers();
    final status = group.status.toLowerCase();

    // Status yang bisa diedit (PENDING = DRAFT di database)
    final canEdit =
        isUserLeader && onEditMembers != null && status == 'pending';

    // Status yang bisa dihapus (PENDING = DRAFT di database)
    final canDelete =
        isUserLeader && onDeleteGroup != null && status == 'pending';

    // Status yang bisa di-submit (PENDING dengan syarat)
    final canSubmit = isUserLeader &&
        status == 'pending' &&
        pendingMembers.isEmpty &&
        acceptedMembers.length >= 2;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUserLeader
              ? const Color.fromARGB(255, 180, 16, 4)
              : Colors.grey[200]!,
          width: isUserLeader ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ========== HEADER dengan STATUS di KIRI dan TOMBOL di KANAN ==========
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status badge (kiri)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: StatusHelper.getColor(group.status)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: StatusHelper.getColor(group.status),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == 'approved' || status == 'disetujui'
                          ? Icons.check_circle
                          : Icons.access_time,
                      size: 14,
                      color: StatusHelper.getColor(group.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      StatusHelper.translate(group.status),
                      style: TextStyle(
                        color: StatusHelper.getColor(group.status),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // ===== TOMBOL-Tombol Aksi (Kanan) =====
              if (isUserLeader)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tombol Edit (Pensil) - hanya untuk status PENDING
                    if (canEdit)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: onEditMembers,
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 20,
                          ),
                          tooltip: 'Ubah Anggota Kelompok',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),

                    // Tombol Hapus - hanya untuk status PENDING
                    if (canDelete)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: IconButton(
                          onPressed: onDeleteGroup,
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 22,
                          ),
                          tooltip: 'Hapus Grup',
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),

                    // Info untuk status SUBMITTED (tidak bisa diedit/dihapus)
                    if (status == 'submitted' || status == 'menunggu')
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Menunggu Persetujuan',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Label Ketua Kelompok jika user adalah ketua
          if (isUserLeader)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 180, 16, 4)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'KETUA KELOMPOK',
                style: TextStyle(
                  fontSize: 10,
                  color: Color.fromARGB(255, 180, 16, 4),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Nama Industri
          Text(
            group.industri.nama,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            group.industri.alamat,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 16),

          // ========== INFO KETUA DAN ANGGOTA ==========
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ketua Kelompok
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ketua Kelompok',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            group.leader.nama,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        group.leader.kelas,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Anggota yang sudah diterima
                if (acceptedMembers.where((m) => !m.isLeader).isNotEmpty) ...[
                  const Text(
                    'Anggota yang sudah bergabung:',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...acceptedMembers.where((m) => !m.isLeader).map((member) {
                    final isCurrentUser = currentUserId == member.siswa.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.check,
                                size: 12, color: Colors.green),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.siswa.nama,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isCurrentUser
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCurrentUser
                                        ? const Color.fromARGB(255, 180, 16, 4)
                                        : Colors.black,
                                  ),
                                ),
                                Text(
                                  member.siswa.kelas,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'DITERIMA',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],

                // Anggota yang masih menunggu
                if (pendingMembers.isNotEmpty) ...[
                  if (acceptedMembers.where((m) => !m.isLeader).isNotEmpty)
                    const SizedBox(height: 12),
                  const Text(
                    'Menunggu konfirmasi:',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pendingMembers.map((member) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.access_time,
                                size: 12, color: Colors.orange),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.siswa.nama,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                Text(
                                  member.siswa.kelas,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'MENUNGGU',
                              style: TextStyle(
                                fontSize: 8,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          // Catatan jika ada
          if (group.catatan?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    group.catatan!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Status anggota count
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${acceptedMembers.length} dari ${group.memberCount} anggota',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ===== TOMBOL SUBMIT (hijau besar) - hanya untuk status PENDING =====
          if (canSubmit)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onSubmitGroup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'KIRIM KELOMPOK',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isUserLeader &&
              status == 'pending' &&
              pendingMembers.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tunggu ${pendingMembers.length} anggota menerima undangan',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (isUserLeader &&
              status == 'pending' &&
              acceptedMembers.length < 2)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Minimal 2 anggota (termasuk ketua) untuk mengirim',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Pesan untuk status SUBMITTED (tidak bisa diubah)
          if (isUserLeader && (status == 'submitted' || status == 'menunggu'))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pengajuan sedang menunggu persetujuan kaprog. Tidak dapat mengubah anggota.',
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Pesan untuk status APPROVED
          if (status == 'approved' || status == 'disetujui')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Grup telah disetujui. Selamat melaksanakan PKL!',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class PengajuanCard extends StatelessWidget {
  final Map<String, dynamic> pengajuan;
  final Map<String, dynamic>? industriData;

  const PengajuanCard({
    super.key,
    required this.pengajuan,
    this.industriData,
  });

  @override
  Widget build(BuildContext context) {
    final status = pengajuan['status']?.toString() ?? '';
    final isDisetujui = status.toLowerCase() == 'disetujui';
    final hasDetail =
        (industriData?['alamat']?.toString().isNotEmpty ?? false) ||
            (industriData?['no_telp']?.toString().isNotEmpty ?? false) ||
            (industriData?['email']?.toString().isNotEmpty ?? false);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: StatusHelper.getColor(status).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: StatusHelper.getColor(status),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDisetujui ? Icons.check_circle : Icons.access_time,
                  size: 14,
                  color: StatusHelper.getColor(status),
                ),
                const SizedBox(width: 4),
                Text(
                  StatusHelper.translate(status),
                  style: TextStyle(
                    color: StatusHelper.getColor(status),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            pengajuan['industri_nama']?.toString() ?? 'Industri',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (pengajuan['tanggal_permohonan'] != null &&
              pengajuan['tanggal_permohonan'] != '-')
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tanggal Pengajuan',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pengajuan['tanggal_permohonan']?.toString() ?? '-',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (pengajuan['catatan'] != null && pengajuan['catatan'] != '-')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: const Color.fromARGB(255, 248, 249, 250),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Catatan Pengajuan:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pengajuan['catatan']?.toString() ?? '-',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          if (pengajuan['kaprog_note'] != null &&
              pengajuan['kaprog_note'] != '-' &&
              pengajuan['kaprog_note'] != 'Tidak ada catatan')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: StatusHelper.getColor(status).withValues(alpha: 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Catatan Kaprog:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: StatusHelper.getColor(status),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pengajuan['kaprog_note']?.toString() ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: StatusHelper.getColor(status),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (hasDetail) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 180, 16, 4)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.factory,
                          size: 14,
                          color: Color.fromARGB(255, 180, 16, 4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Informasi Perusahaan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  if (industriData?['alamat']?.toString().isNotEmpty ??
                      false) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.location_on_outlined,
                      'Alamat',
                      industriData!['alamat']?.toString() ?? '',
                    ),
                  ],
                  if (industriData?['no_telp']?.toString().isNotEmpty ??
                      false) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.phone_outlined,
                      'Telepon',
                      industriData!['no_telp']?.toString() ?? '',
                    ),
                  ],
                  if (industriData?['email']?.toString().isNotEmpty ??
                      false) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.email_outlined,
                      'Email',
                      industriData!['email']?.toString() ?? '',
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: icon == Icons.location_on_outlined
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          child: Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EmptyPengajuanCard extends StatelessWidget {
  final VoidCallback onAjukan;

  const EmptyPengajuanCard({
    super.key,
    required this.onAjukan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color.fromARGB(255, 180, 16, 4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 60,
            color: Color.fromARGB(255, 180, 16, 4),
          ),
          const SizedBox(height: 20),
          const Text(
            'Belum ada pengajuan yang disetujui',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Ajukan PKL untuk memulai praktik kerja lapangan',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onAjukan,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 180, 16, 4),
            ),
            child: const Text(
              'Ajukan PKL Sekarang',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;
  final VoidCallback onLogout;

  const ErrorScreen({
    super.key,
    this.errorMessage,
    required this.onRetry,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 180, 16, 4),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Terjadi Kesalahan',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  errorMessage ?? 'Gagal memuat data',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color.fromARGB(255, 180, 16, 4),
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      onPressed: onLogout,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
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
  }
}