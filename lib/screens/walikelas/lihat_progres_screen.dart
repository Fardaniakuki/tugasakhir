// lihat_progres_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LihatProgresScreen extends StatefulWidget {
  final ScrollController? scrollController;
  
  const LihatProgresScreen({
    super.key,
    this.scrollController,
  });

  @override
  State<LihatProgresScreen> createState() => _LihatProgresScreenState();
}

class _LihatProgresScreenState extends State<LihatProgresScreen> 
    with AutomaticKeepAliveClientMixin {
  
  final Color _primaryBlue = const Color(0xFF1B4F72);
  final Color _bgSoft = const Color(0xFFF5F7FA);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: _bgSoft,
      body: NestedScrollView(
        controller: widget.scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 150.0,
              backgroundColor: Colors.white,
              pinned: true,
              floating: true,
              leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  color: _primaryBlue,
                  size: 22,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: Colors.white,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            'Lihat Progres PKL',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _primaryBlue,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pantau perkembangan siswa selama PKL',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ];
        },
        body: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildProgressStats(),
                const SizedBox(height: 20),
                _buildStudentProgress(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistik Progres',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStat('Sangat Baik', '8', Colors.green),
              _buildProgressStat('Baik', '15', Colors.blue),
              _buildProgressStat('Cukup', '10', Colors.orange),
              _buildProgressStat('Perlu Bimbingan', '3', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withValues(alpha:.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentProgress() {
    final students = [
      {'nama': 'Ahmad Rizki', 'industri': 'PT. Teknologi Indonesia', 'progres': 85, 'status': 'Sangat Baik'},
      {'nama': 'Siti Nurhaliza', 'industri': 'CV. Digital Solusi', 'progres': 78, 'status': 'Baik'},
      {'nama': 'Budi Santoso', 'industri': 'PT. Media Kreatif', 'progres': 65, 'status': 'Cukup'},
      {'nama': 'Dewi Lestari', 'industri': 'PT. Network Indonesia', 'progres': 92, 'status': 'Sangat Baik'},
      {'nama': 'Rizky Pratama', 'industri': 'PT. Software House', 'progres': 55, 'status': 'Perlu Bimbingan'},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progres Siswa',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _primaryBlue,
                ),
              ),
              Text(
                '36 Siswa',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...students.map((student) => _buildProgressCard(student)),
        ],
      ),
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> student) {
    Color getStatusColor(int progress) {
      if (progress >= 85) return Colors.green;
      if (progress >= 70) return Colors.blue;
      if (progress >= 60) return Colors.orange;
      return Colors.red;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha:.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['nama'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      student['industri'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor(student['progres']).withValues(alpha:.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${student['progres']}%',
                  style: TextStyle(
                    color: getStatusColor(student['progres']),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: student['progres'] / 100,
            backgroundColor: Colors.grey[200],
            color: getStatusColor(student['progres']),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                student['status'],
                style: TextStyle(
                  fontSize: 13,
                  color: getStatusColor(student['progres']),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${student['progres']}% selesai',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}