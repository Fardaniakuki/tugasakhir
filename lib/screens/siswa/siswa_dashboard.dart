import 'package:flutter/material.dart';
import 'pengajuan_pkl.dart';
import 'jadwal_pembimbing.dart';

class SiswaDashboard extends StatefulWidget {
  const SiswaDashboard({super.key});

  @override
  State<SiswaDashboard> createState() => _SiswaDashboardState();
}

class _SiswaDashboardState extends State<SiswaDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF641E20),
        title: const Text(
          'Dashboard Siswa',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Pengajuan PKL
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF641E20).withValues(alpha: 0.1),
                  child: const Icon(Icons.assignment, color: Color(0xFF641E20)),
                ),
                title: const Text(
                  'Pengajuan PKL',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Ajukan PKL baru',
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PengajuanPKLScreen()),
                  );
                },
              ),
            ),
            // Status PKL
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF641E20).withValues(alpha: 0.1),
                  child: const Icon(Icons.verified, color: Color(0xFF641E20)),
                ),
                title: const Text(
                  'Status PKL',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Lihat status pengajuan',
                  textAlign: TextAlign.center,
                ),
                onTap: () {},
              ),
            ),
            // Jadwal & Pembimbing
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF641E20).withValues(alpha: 0.1),
                  child: const Icon(Icons.event_note, color: Color(0xFF641E20)),
                ),
                title: const Text(
                  'Jadwal & Pembimbing',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Lihat jadwal dan guru pembimbing',
                  textAlign: TextAlign.center,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const JadwalPembimbingScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
