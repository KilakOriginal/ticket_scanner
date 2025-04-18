import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

enum EncodingType { ean8, ean13, qr }

class GlobalData {
  GlobalData._privateConstructor();

  static final GlobalData instance = GlobalData._privateConstructor();

  List<String> codes = [];
  List<String> invalidatedCodes = [];
  EncodingType? encodingType;

  final SupabaseClient _supabase = Supabase.instance.client;
  Timer? _periodicSyncTimer;

  void startPeriodicSync({Duration interval = const Duration(minutes: 1)}) {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = Timer.periodic(interval, (timer) async {
      await syncCodes();
    });
  }

  void stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

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

  // Push codes to Supabase
  Future<void> pushCodesToDatabase() async {
    for (var code in codes) {
      await _supabase.from('codes').upsert({
        'code': code,
        'type': encodingType?.toString().split('.').last ?? 'unknown',
      });
    }
  }

  // Update invalidated codes in Supabase
  Future<void> invalidateCodes() async {
    for (var code in invalidatedCodes) {
      await _supabase.from('codes').delete().eq('code', code);
    }

    invalidatedCodes.clear();
  }

  // Fetch codes from Supabase
  Future<void> fetchCodes() async {
    try {
      final response = await _supabase.from('codes').select();

      final List<dynamic> fetchedCodes = response;
      for (var code in fetchedCodes) {
        if (!codes.contains(code['code'])) {
          codes.add(code['code']);
        }
      }
      await saveCodes();
    } catch (e) {
      debugPrint('Failed to fetch remote codes: $e');
    }
  }
}

// Sync codes
Future<void> syncCodes() async {
  await GlobalData.instance.invalidateCodes();
  await GlobalData.instance.pushCodesToDatabase();
  await GlobalData.instance.fetchCodes();
}
