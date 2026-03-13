import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_downloader/flutter_downloader.dart'; // TAMBAHKAN INI
import 'screens/splash_screen.dart';

Future<void> main() async {
  // Pastikan Widgets binding sudah diinisialisasi
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load file .env sebelum aplikasi dijalankan
  await dotenv.load(fileName: '.env');
  
  // Inisialisasi Flutter Downloader
  await FlutterDownloader.initialize(
    debug: true, // Set false untuk production
    ignoreSsl: true, // Hanya untuk development, hapus untuk production
  );

  runApp(const PengajuanMagangApp());
}

class PengajuanMagangApp extends StatelessWidget {
  const PengajuanMagangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pengajuan Magang',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.brown,
        ).copyWith(
          primary: const Color(0xFF6B1B1B),
        ),
      ),
      // Localizations untuk DatePicker
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), // Bahasa Indonesia
        Locale('en', 'US'), // Bahasa Inggris (fallback)
      ],
      locale: const Locale('id', 'ID'), // Set default ke Indonesia
      home: const SplashScreen1(),
    );
  }
}