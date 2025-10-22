import 'package:flutter/material.dart';

class StatGrid extends StatelessWidget {
  final VoidCallback onAddPressed;
  final Map<String, dynamic>? data;
  final void Function(String)? onBoxTap;

  const StatGrid({
    super.key,
    required this.onAddPressed,
    this.data,
    this.onBoxTap,
  });

  @override
  Widget build(BuildContext context) {
    final totalJurusan = data?['total_jurusan']?.toString() ?? '0';
    final totalSiswa = data?['total_siswa']?.toString() ?? '0';
    final totalGuru = data?['total_guru']?.toString() ?? '0';
    final totalIndustri = data?['total_industri']?.toString() ?? '0';
    final totalKelas = data?['total_kelas']?.toString() ?? '0';

    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Jurusan',
                    count: totalJurusan,
                    icon: Icons.school,
                    iconColor: Colors.blue,
                    onTap: () => onBoxTap?.call('Jurusan'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    title: 'Peserta Didik',
                    count: totalSiswa,
                    icon: Icons.menu_book,
                    iconColor: Colors.green,
                    onTap: () => onBoxTap?.call('Murid'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Pembimbing',
                    count: totalGuru,
                    icon: Icons.people,
                    iconColor: Colors.purple,
                    onTap: () => onBoxTap?.call('Guru'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                    title: 'Industri',
                    count: totalIndustri,
                    icon: Icons.handshake,
                    iconColor: Colors.deepOrange,
                    onTap: () => onBoxTap?.call('Industri'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _StatCard(
                    title: 'Kelas',
                    count: totalKelas,
                    icon: Icons.class_,
                    iconColor: Colors.teal,
                    height: 90,
                    onTap: () => onBoxTap?.call('Kelas'),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onAddPressed,
                  child: Container(
                    width: 70,
                    height: 90,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B1A1A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(Icons.add, color: Colors.white, size: 32),
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

class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color iconColor;
  final double height;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.iconColor,
    this.height = 75,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.orange, width: 1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title,
                      style:
                          const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(count,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
