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
  final MobileScannerController _mobileScannerController =
      MobileScannerController();
  bool _isProcessing = false;
  bool _isScanning = false;
  String? _scannedCode;
  Timer? _syncTimer;
  bool _hasCameraPermission = false;
  Completer<void>? _scanCompleter;

  @override
  void initState() {
    super.initState();
    _checkCameraPermission();
    GlobalData.instance.syncCodes();
  }

  Future<void> _checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      setState(() => _hasCameraPermission = true);
    } else {
      _requestCameraPermission();
    }
  }

  Future<void> _requestCameraPermission() async {
    final result = await Permission.camera.request();
    if (result.isGranted) {
      setState(() => _hasCameraPermission = true);
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
    _syncTimer = Timer(const Duration(seconds: 5), () {
      GlobalData.instance.syncCodes();
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning || _isProcessing) return;
    for (final code in capture.barcodes) {
      final raw = code.rawValue;
      if (raw != null) {
        setState(() {
          _scannedCode = raw;
          _isScanning = false;
        });
        _scanCompleter?.complete();
        _handleCodeVerification();
        break;
      }
    }
  }

  void _handleCodeVerification() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    if (_scannedCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocaleData.noCode.getString(context),
            style: const TextStyle(color: textLightColour, fontSize: 20),
          ),
          backgroundColor: errorColour,
        ),
      );
      setState(() {
        _isProcessing = false;
        _scannedCode = null;
      });
      return;
    }

    String code = _normaliseCode(_scannedCode!);

    if (GlobalData.instance.codes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocaleData.noCodesAvailable.getString(context),
            style: const TextStyle(color: textLightColour, fontSize: 20),
          ),
          backgroundColor: errorColour,
        ),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocaleData.invalidCode.getString(context),
            style: const TextStyle(color: textLightColour, fontSize: 20),
          ),
          backgroundColor: errorColour,
        ),
      );
      setState(() {
        _isProcessing = false;
        _scannedCode = null;
      });
      return;
    }

    if (localCode['status'] == 'valid') {
      localCode['status'] = 'invalid';
      localCode['last_modified'] = DateTime.now().toUtc().toIso8601String();
      await GlobalData.instance.saveCodes();
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
  }

  String _normaliseCode(String code) {
    final int length =
        GlobalData.instance.encodingType == EncodingType.ean8 ? 8 : 13;
    if (code.length >= length) {
      code = code.substring(code.length - length + 1, code.length - 1);
    } else if (code.length == length - 1) {
      code = code.substring(
        0,
        code.length - 1,
      ); // On some platforms, the first digit is not scanned
    }
    return code.replaceFirst(RegExp(r'^0+'), ''); // Remove leading zeros
  }

  void _startScanning() async {
    ScaffoldMessenger.of(context).clearSnackBars();

    if (GlobalData.instance.isFlashEnabled) {
      _mobileScannerController.toggleTorch();
      await Future.delayed(const Duration(milliseconds: 800));
    }

    setState(() {
      _scannedCode = null;
      _isScanning = true;
      _scanCompleter = Completer<void>();
    });

    Future.any([
      Future.delayed(const Duration(milliseconds: 400)),
      _scanCompleter!.future,
    ]).then((_) {
      if (_scannedCode == null && _isScanning) {
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
          _isScanning = false;
        });
      }

      if (GlobalData.instance.isFlashEnabled) {
        _mobileScannerController.toggleTorch();
      }
    });
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
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasCameraPermission)
            MobileScanner(
              controller: _mobileScannerController,
              onDetect: _onDetect,
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
              onPressed: _isProcessing ? null : _startScanning,
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
