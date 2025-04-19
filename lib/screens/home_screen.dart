import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ticket_scanner/localisation/locales.dart';
import 'package:ticket_scanner/utils/constants.dart';
import 'package:ticket_scanner/screens/settings_screen.dart';
import 'package:ticket_scanner/utils/global_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isProcessing = false;
  String? _scannedCode;
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
    GlobalData.instance.fetchCodes();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (!status.isGranted) {
      final result = await Permission.camera.request();
      if (!result.isGranted && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('ERROR')));
      }
    }
  }

  void _scheduleSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer(const Duration(seconds: 5), () async {
      GlobalData.instance.syncCodes();
    });
  }

  void _handleCodeVerification() async {
    debugPrint("Scanning code...");
    if (_isProcessing || _scannedCode == null) {
      debugPrint("Already processing or no code scanned.");
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    String code = _normaliseCode(_scannedCode!);

    ScaffoldMessenger.of(context).clearSnackBars(); // Clear previous snackbar

    Map<String, dynamic>? localCode = GlobalData.instance.codes.firstWhere(
      (c) => c['code'] == code,
    );

    if (localCode['status'] == 'valid') {
      localCode['status'] = 'invalid';
      localCode['last_modified'] = DateTime.now().toUtc().toIso8601String();
      debugPrint(
        "Code '$code' is valid. Marking as invalid. Time: ${localCode['last_modified']}",
      );
      await GlobalData.instance.saveCodes();
      debugPrint("Local codes after saving: ${GlobalData.instance.codes}");

      _scheduleSync();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocaleData.validCode.getString(context),
              style: const TextStyle(color: textLightColour, fontSize: 20),
            ),
            backgroundColor: successColour,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocaleData.invalidCode.getString(context),
              style: const TextStyle(color: textLightColour, fontSize: 20),
            ),
            backgroundColor: errorColour,
          ),
        );
      }
    }

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  String _normaliseCode(String code) {
    debugPrint(
      'Normalising code: "$code" with length: ${code.length} of type: ${GlobalData.instance.encodingType}',
    );
    debugPrint(
      'Valid codes: ${GlobalData.instance.codes.map((c) => '"$c"').toList()}',
    );
    // First digit is not encoded in the barcode, so the scanner will return a 7 or 12 digit code
    final int length =
        GlobalData.instance.encodingType == EncodingType.ean8 ? 8 : 13;

    if (code.length >= length) {
      code = code.substring(
        code.length - length + 1,
        code.length - 1,
      ); // Remove check digit
    }

    code = code.replaceFirst(RegExp(r'^0+'), ''); // Remove leading zeros

    debugPrint('Normalised code: "$code" with length: ${code.length}');

    return code;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleData.appTitle.getString(context)),
        backgroundColor: primaryColour,
        foregroundColor: textLightColour,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              for (final code in capture.barcodes) {
                if (code.rawValue != null) {
                  setState(() {
                    _scannedCode = code.rawValue!;
                  });
                }
              }
            },
          ),
          Positioned(
            bottom: 100.0,
            left: 16.0,
            right: 16.0,
            child: ElevatedButton(
              onPressed: _handleCodeVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColour,
                foregroundColor: textLightColour,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
              ),
              child: Text(LocaleData.scanCode.getString(context)),
            ),
          ),
        ],
      ),
    );
  }
}
