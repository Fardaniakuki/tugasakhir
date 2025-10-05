import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  // Load file .env sebelum aplikasi dijalankan
  await dotenv.load(fileName: '.env');

  runApp(const PengajuanMagangApp());
}

class PengajuanMagangApp extends StatelessWidget {
  const PengajuanMagangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pengajuan Magang',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: const SplashScreen1(),
    );
  }
}
