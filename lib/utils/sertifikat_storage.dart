import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SertifikatStorage {
  static const String _prefix = 'sertifikat_config_';

  // Simpan konfigurasi sertifikat untuk form tertentu
  static Future<void> simpanConfig({
    required int formId,
    required String prefix,
    required String format,
    required String separator,
    required bool useTahun,
    required int counterStart,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$formId';
    
    final Map<String, dynamic> config = {
      'prefix': prefix,
      'format': format,
      'separator': separator,
      'use_tahun': useTahun,
      'counter_start': counterStart,
      'current_counter': counterStart,
      'waktu_simpan': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(key, jsonEncode(config));
    print('✅ Konfigurasi sertifikat disimpan untuk form $formId');
  }

  // Ambil konfigurasi sertifikat untuk form tertentu
  static Future<Map<String, dynamic>?> ambilConfig(int formId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$formId';
    
    final String? configString = prefs.getString(key);
    if (configString != null) {
      return jsonDecode(configString);
    }
    return null;
  }

  // Hapus konfigurasi sertifikat
  static Future<void> hapusConfig(int formId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix$formId';
    await prefs.remove(key);
  }

  // Update counter (untuk increment nomor sertifikat)
  static Future<void> updateCounter(int formId, int newCounter) async {
    final config = await ambilConfig(formId);
    if (config != null) {
      config['current_counter'] = newCounter;
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefix$formId';
      await prefs.setString(key, jsonEncode(config));
    }
  }

  // Dapatkan nomor sertifikat berikutnya
  static Future<String> generateNomorSertifikat(int formId) async {
    final config = await ambilConfig(formId);
    if (config == null) return '';
    
    final now = DateTime.now();
    final counter = (config['current_counter'] ?? 1).toString().padLeft(3, '0');
    final tgl = '${now.day}${now.month}${now.year}';
    const instansi = '101.6.9.19';
    final tahun = config['use_tahun'] == true ? now.year.toString() : '';
    
    String nomor = config['format']
        .replaceAll('PREFIX', config['prefix'] ?? '420')
        .replaceAll('COUNTER', counter)
        .replaceAll('TGL', tgl)
        .replaceAll('INSTANSI', instansi)
        .replaceAll('TAHUN', tahun);
    
    // Bersihkan separator ganda
    nomor = nomor.replaceAll('//', '/').replaceAll('//', '/');
    if (nomor.endsWith(config['separator'] ?? '/')) {
      nomor = nomor.substring(0, nomor.length - 1);
    }
    
    // Update counter untuk next
    await updateCounter(formId, (config['current_counter'] ?? 1) + 1);
    
    return nomor;
  }
}