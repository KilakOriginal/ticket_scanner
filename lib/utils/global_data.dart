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

  Future<void> syncCodes() async {
    await Future.forEach(codes, (localCode) async {
      final response =
          await _supabase
              .from('codes')
              .select('last_modified')
              .eq('code', localCode['code'])
              .maybeSingle();

      if (response == null) {
        // Code does not exist in Supabase, insert it
        await _supabase.from('codes').insert(localCode);
      } else {
        final remoteLastModified = DateTime.parse(response['last_modified']);
        final localLastModified = DateTime.parse(localCode['last_modified']);

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
    });

    // Fetch and merge remote codes
    final fetchedCodes = await _supabase.from('codes').select();

    for (var remoteCode in fetchedCodes) {
      final remoteLastModified = DateTime.parse(remoteCode['last_modified']);
      final localCode = codes.firstWhere(
        (code) => code['code'] == remoteCode['code'],
        orElse: () => <String, dynamic>{},
      );

      if (localCode.isEmpty) {
        codes.add(remoteCode);
        debugPrint("Added new remote code ${remoteCode['code']}");
      } else {
        final localLastModified = DateTime.parse(localCode['last_modified']);
        if (remoteLastModified.isAfter(localLastModified)) {
          // Update local code with remote changes
          debugPrint("Updating local code ${remoteCode['code']}");
          localCode['status'] = remoteCode['status'];
          localCode['last_modified'] = remoteLastModified.toIso8601String();
        }
      }
    }

    // Save updated codes to local storage
    await saveCodes();
  }
}
