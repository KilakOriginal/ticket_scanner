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
  bool _hasCameraPermission = false;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
    GlobalData.instance.fetchCodes();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() {
        _hasCameraPermission = true;
      });
    } else {
      _requestCameraPermission();
    }
  }

  Future<void> _requestCameraPermission() async {
    final result = await Permission.camera.request();
    if (result.isGranted) {
      setState(() {
        _hasCameraPermission = true;
      });
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocaleData.noCameraPermission.getString(context),
            style: const TextStyle(color: textLightColour, fontSize: 20),
          ),
          backgroundColor: errorColour,
        ),
      );
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
    if (_isProcessing) {
      debugPrint("Already processing.");
      return;
    }

    if (_scannedCode == null) {
      debugPrint("No code scanned.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocaleData.noCode.getString(context),
              style: const TextStyle(color: textLightColour, fontSize: 20),
            ),
            backgroundColor: errorColour,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
        _scannedCode = null;
      });
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    String code = _normaliseCode(_scannedCode!);

    ScaffoldMessenger.of(context).clearSnackBars(); // Clear previous snackbar

    if (GlobalData.instance.codes.isEmpty) {
      debugPrint("No codes available in local data.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocaleData.noCodesAvailable.getString(context),
              style: const TextStyle(color: textLightColour, fontSize: 20),
            ),
            backgroundColor: errorColour,
          ),
        );
      }
      setState(() {
        _isProcessing = false;
        _scannedCode = null;
      });
      return;
    }

    Map<String, dynamic>? localCode = GlobalData.instance.codes.firstWhere(
      (c) => c['code'] == code,
      orElse: () => <String, String>{},
    );

    if (localCode.isEmpty) {
      debugPrint("Code '$code' not found in local codes.");
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

      setState(() {
        _isProcessing = false;
        _scannedCode = null;
      });
      return;
    }

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
          _scannedCode = null;
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
          if (_hasCameraPermission)
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
            )
          else
            Center(
              child: Text(
                LocaleData.noCameraPermission.getString(context),
                style: const TextStyle(color: textColour, fontSize: 18),
                textAlign: TextAlign.center,
              ),
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
