import 'package:flutter/material.dart';

class SiswaRekap extends StatelessWidget {
  const SiswaRekap({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF641E20),
        title: const Text(
          'Rekap PKL',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Hari Hadir',
                    '18/20',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Progress',
                    '75%',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Nilai Rata-rata',
                    '85',
                    Icons.grade,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Sisa Hari',
                    '45',
                    Icons.calendar_today,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Progress Section
            const Text(
              'Progress PKL',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF641E20),
              ),
            ),
            const SizedBox(height: 16),
            _buildProgressItem('Pendaftaran', 100, true),
            _buildProgressItem('Penempatan', 100, true),
            _buildProgressItem('Pelaksanaan', 75, false),
            _buildProgressItem('Monitoring', 60, false),
            _buildProgressItem('Laporan', 30, false),
            _buildProgressItem('Selesai', 0, false),

            const SizedBox(height: 24),

            // Recent Activities
            const Text(
              'Aktivitas Terbaru',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF641E20),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _buildActivityItem('Monitoring ke-3', 'Pembimbing: Bu Siti', '2 hari lalu', Icons.supervised_user_circle),
                  _buildActivityItem('Konsultasi laporan', 'Bab 1 & 2 disetujui', '1 minggu lalu', Icons.chat),
                  _buildActivityItem('Penilaian harian', 'Nilai: 85', '2 minggu lalu', Icons.assessment),
                  _buildActivityItem('Mulai PKL', 'Di PT. Contoh', '1 bulan lalu', Icons.work),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF641E20),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(String step, int progress, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                step,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isCompleted ? Colors.green : Colors.grey[700],
                ),
              ),
              Text(
                '$progress%',
                style: TextStyle(
                  color: isCompleted ? Colors.green : const Color(0xFF641E20),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress / 100,
            backgroundColor: Colors.grey[300],
            color: isCompleted ? Colors.green : const Color(0xFF641E20),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF641E20).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF641E20), size: 20),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          time,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
    );
  }
}