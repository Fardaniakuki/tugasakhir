// laporan_siswa_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LaporanSiswaScreen extends StatefulWidget {
  final ScrollController? scrollController;
  
  const LaporanSiswaScreen({
    super.key,
    this.scrollController,
  });

  @override
  State<LaporanSiswaScreen> createState() => _LaporanSiswaScreenState();
}

class _LaporanSiswaScreenState extends State<LaporanSiswaScreen> 
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
                            'Laporan Siswa',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: _primaryBlue,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kelola dan pantau laporan PKL siswa',
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
                _buildReportStats(),
                const SizedBox(height: 20),
                _buildReportList(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReportStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildReportStat('Total Laporan', '48', Icons.description),
          _buildReportStat('Terkirim', '42', Icons.send),
          _buildReportStat('Belum Dikirim', '6', Icons.schedule),
          _buildReportStat('Perlu Review', '3', Icons.feedback),
        ],
      ),
    );
  }

  Widget _buildReportStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _primaryBlue.withValues(alpha:0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: _primaryBlue),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
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

  Widget _buildReportList() {
    final reports = [
      {
        'siswa': 'Ahmad Rizki',
        'jenis': 'Laporan Mingguan',
        'tanggal': '22 Jan 2024',
        'status': 'Terkirim',
        'statusColor': Colors.green,
        'review': 'Sudah',
      },
      {
        'siswa': 'Siti Nurhaliza',
        'jenis': 'Laporan Bulanan',
        'tanggal': '20 Jan 2024',
        'status': 'Perlu Review',
        'statusColor': Colors.orange,
        'review': 'Belum',
      },
      {
        'siswa': 'Budi Santoso',
        'jenis': 'Laporan Mingguan',
        'tanggal': '19 Jan 2024',
        'status': 'Terkirim',
        'statusColor': Colors.green,
        'review': 'Sudah',
      },
      {
        'siswa': 'Dewi Lestari',
        'jenis': 'Laporan Bulanan',
        'tanggal': '18 Jan 2024',
        'status': 'Belum Dikirim',
        'statusColor': Colors.red,
        'review': 'Menunggu',
      },
      {
        'siswa': 'Rizky Pratama',
        'jenis': 'Laporan Mingguan',
        'tanggal': '17 Jan 2024',
        'status': 'Perlu Review',
        'statusColor': Colors.orange,
        'review': 'Belum',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
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
                'Daftar Laporan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _primaryBlue,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _primaryBlue.withValues(alpha:0.2)),
                ),
                child: Text(
                  '5 Terbaru',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...reports.map((report) => _buildReportCard(report)),
        ],
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryBlue.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                report['jenis'].contains('Mingguan') ? Icons.calendar_view_week : Icons.calendar_today,
                color: _primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report['siswa'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report['jenis'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tanggal: ${report['tanggal']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: report['statusColor'].withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    report['status'],
                    style: TextStyle(
                      color: report['statusColor'],
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review: ${report['review']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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