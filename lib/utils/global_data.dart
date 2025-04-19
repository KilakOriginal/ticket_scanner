import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

enum EncodingType { ean8, ean13, qr }

class GlobalData {
  GlobalData._privateConstructor();

  static final GlobalData instance = GlobalData._privateConstructor();

  List<Map<String, dynamic>> codes = [];
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

  // Load codes from SharedPreferences
  Future<void> loadCodes() async {
    final prefs = await SharedPreferences.getInstance();
    String? codesJson = prefs.getString('codes');
    if (codesJson != null) {
      codes = List<Map<String, dynamic>>.from(jsonDecode(codesJson));
    }

    String? encoding = prefs.getString('encoding_type');
    if (encoding != null) {
      encodingType = EncodingType.values.firstWhere(
        (e) => e.toString().split('.').last == encoding,
        orElse: () => EncodingType.qr,
      );
    }
    encodingType ??= EncodingType.ean13;
  }

  // Save codes to SharedPreferences
  Future<void> saveCodes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('codes', jsonEncode(codes));
    if (encodingType != null) {
      await prefs.setString(
        'encoding_type',
        encodingType.toString().split('.').last,
      );
    }
  }

  // Fetch codes from Supabase
  Future<void> fetchCodes() async {
    final response = await _supabase.from('codes').select();

    if (codes.isEmpty) {
      codes = List<Map<String, dynamic>>.from(response);
      debugPrint("Fetched all remote codes: ${codes.length} codes loaded.");
    } else {
      final List<dynamic> fetchedCodes = response;
      for (var remoteCode in fetchedCodes) {
        String remoteCodeValue = remoteCode['code'];
        String remoteStatus = remoteCode['status'];
        String remoteLastModified = remoteCode['last_modified'];

        DateTime remoteLastModifiedDate = DateTime.parse(remoteLastModified);

        Map<String, dynamic>? localCode = codes.firstWhere(
          (code) => code['code'] == remoteCodeValue,
          orElse: () => <String, String>{},
        );

        DateTime localLastModifiedDate = DateTime.parse(
          localCode['last_modified'],
        );

        if (remoteLastModifiedDate.isAfter(localLastModifiedDate)) {
          debugPrint("Updating local code $remoteCodeValue");
          localCode['status'] = remoteStatus;
          localCode['last_modified'] = remoteLastModifiedDate.toIso8601String();
        }
      }
    }

    await saveCodes();
  }

  // Push local changes to Supabase
  Future<void> pushCodesToDatabase() async {
    for (var localCode in codes) {
      // Check if the remote code exists and fetch its last_modified timestamp
      final response =
          await _supabase
              .from('codes')
              .select('last_modified')
              .eq('code', localCode['code'])
              .maybeSingle();

      if (response == null) {
        // Code does not exist in the remote database, insert it
        await _supabase.from('codes').insert(localCode);
      } else {
        DateTime remoteLastModified = DateTime.parse(response['last_modified']);
        DateTime localLastModified = DateTime.parse(localCode['last_modified']);

        if (localLastModified.isAfter(remoteLastModified)) {
          debugPrint("Updating code ${localCode['code']}");
          await _supabase
              .from('codes')
              .update(localCode)
              .eq('code', localCode['code']);
        } else {
          debugPrint(
            "$localLastModified is not newer than $remoteLastModified for code ${localCode['code']}",
          );
        }
      }
    }
  }

  Future<void> syncCodes() async {
    await pushCodesToDatabase();
    await fetchCodes();
  }
}
