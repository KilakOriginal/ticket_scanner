import 'package:shared_preferences/shared_preferences.dart';

enum EncodingType { ean8, ean13, qr }

class GlobalData {
  GlobalData._privateConstructor();

  static final GlobalData instance = GlobalData._privateConstructor();

  List<String> codes = [];
  EncodingType? encodingType;

  // Load codes from shared preferences
  Future<void> loadCodes() async {
    final prefs = await SharedPreferences.getInstance();
    codes = prefs.getStringList('invalidated_codes') ?? [];
    String? encoding = prefs.getString('encoding_type');
    if (encoding != null) {
      encodingType = EncodingType.values.firstWhere(
        (e) => e.toString().split('.').last == encoding,
        orElse: () => EncodingType.qr,
      );
    }
  }

  // Save codes to shared preferences
  Future<void> saveCodes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('invalidated_codes', codes);
    if (encodingType != null) {
      await prefs.setString(
        'encoding_type',
        encodingType.toString().split('.').last,
      );
    }
  }
}
