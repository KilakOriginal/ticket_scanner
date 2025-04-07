import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
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

  void _handleCodeVerification() {
    if (_isProcessing || _scannedCode == null) return;

    setState(() {
      _isProcessing = true;
    });

    String code = _normaliseCode(_scannedCode!);

    ScaffoldMessenger.of(context).clearSnackBars(); // Clear previous snackbar

    if (GlobalData.instance.codes.contains(code)) {
      GlobalData.instance.codes.remove(code);

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
    if ((GlobalData.instance.encodingType == EncodingType.ean8 &&
            code.length == 7) ||
        (GlobalData.instance.encodingType == EncodingType.ean13 &&
            code.length == 12)) {
      code = code.substring(0, code.length - 1); // Remove checksum
    }
    code = code.replaceFirst(RegExp(r'^0+'), ''); // Remove leading zeros
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
            bottom: 60.0,
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
