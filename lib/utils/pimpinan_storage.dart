import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class PimpinanStorage {
  static Future<File> _getFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/data_industri.json');
  }

  static Future<void> simpanDataIndustri({
    required int applicationId,
    required String namaPimpinan,
    required String jenisNomorPimpinan, // ✅ TAMBAHKAN INI
    required String nipPimpinan,
    required String jabatanPimpinan,
    required String namaPembimbingIndustri,
    required String jenisNomorPembimbing, // ✅ TAMBAHKAN INI
    required String nipPembimbingIndustri,
    required String jabatanPembimbingIndustri,
    Map<String, dynamic>? dataSiswa,
  }) async {
    final file = await _getFile();
    
    Map<String, dynamic> allData = {};
    if (await file.exists()) {
      final contents = await file.readAsString();
      allData = jsonDecode(contents);
    }
    
    allData['industri_$applicationId'] = {
      'application_id': applicationId,
      'pimpinan': {
        'nama': namaPimpinan,
        'jenis_nomor': jenisNomorPimpinan, // ✅ TAMBAHKAN INI
        'nip': nipPimpinan,
        'jabatan': jabatanPimpinan,
      },
      'pembimbing_industri': {
        'nama': namaPembimbingIndustri,
        'jenis_nomor': jenisNomorPembimbing, // ✅ TAMBAHKAN INI
        'nip': nipPembimbingIndustri,
        'jabatan': jabatanPembimbingIndustri,
      },
      'siswa_nama': dataSiswa?['siswa_username'] ?? '',
      'industri_nama': dataSiswa?['industri_nama'] ?? '',
      'waktu_simpan': DateTime.now().toIso8601String(),
    };
    
    await file.writeAsString(jsonEncode(allData));
    print('✅ Data industri tersimpan di file untuk aplikasi $applicationId');
    print('   - Pimpinan: $namaPimpinan ($jenisNomorPimpinan: $nipPimpinan)');
    print('   - Pembimbing: $namaPembimbingIndustri ($jenisNomorPembimbing: $nipPembimbingIndustri)');
  }

  static Future<Map<String, dynamic>?> ambilDataIndustri(int applicationId) async {
    final file = await _getFile();
    
    if (!await file.exists()) return null;
    
    final contents = await file.readAsString();
    final allData = jsonDecode(contents);
    
    return allData['industri_$applicationId'];
  }
}