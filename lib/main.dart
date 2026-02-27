import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // TAMBAHKAN INI
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
      // TAMBAHKAN INI - Localizations untuk DatePicker
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
