import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:ticket_scanner/utils/constants.dart';
import 'package:ticket_scanner/localisation/locales.dart';
import 'package:ticket_scanner/utils/global_data.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage =
        FlutterLocalization.instance.currentLocale?.languageCode ?? 'en';
  }

  void _changeLanguage(String languageCode) {
    setState(() {
      _selectedLanguage = languageCode;
    });
    FlutterLocalization.instance.translate(languageCode);
  }

  Future<void> _loadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt'], // Restrict to text files
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        List<String> lines = await file.readAsLines();

        if (lines.isEmpty) {
          throw Exception('File is empty');
        }

        // Read the encoding type from the first line
        String encoding = lines.first.trim().toLowerCase();
        lines.removeAt(0); // Remove the first line (encoding)

        // Parse the encoding type
        switch (encoding) {
          case 'ean8':
            GlobalData.instance.encodingType = EncodingType.ean8;
            break;
          case 'ean13':
            GlobalData.instance.encodingType = EncodingType.ean13;
            break;
          case 'qr':
            GlobalData.instance.encodingType = EncodingType.qr;
            break;
          default:
            throw Exception('Unsupported encoding type: $encoding');
        }

        // Normalise and filter codes
        List<String> codes =
            lines
                .map((line) => line.trim())
                .where((line) => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(line))
                .map((code) => _normaliseCode(code))
                .toList();

        GlobalData.instance.codes = codes;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.formatString(LocaleData.loadFileSuccess, [
                  codes.length,
                ]),
                style: TextStyle(color: textLightColour),
              ),
              backgroundColor: successColour,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocaleData.loadFileError.getString(context),
              style: TextStyle(color: textLightColour),
            ),
            backgroundColor: errorColour,
          ),
        );
      }
    }
  }

  String _normaliseCode(String code) {
    if ((GlobalData.instance.encodingType == EncodingType.ean8 &&
            code.length == 8) ||
        (GlobalData.instance.encodingType == EncodingType.ean13 &&
            code.length == 13)) {
      code = code.substring(
        1,
        code.length - 1,
      ); // Remove checksum and first digit
    }
    code = code.replaceFirst(RegExp(r'^0+'), ''); // Remove leading zeros
    return code;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocaleData.settingsTitle.getString(context),
          style: TextStyle(color: textLightColour),
        ),
        backgroundColor: primaryColour,
        foregroundColor: textLightColour,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              LocaleData.languageLabel.getString(context),
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _selectedLanguage,
              items:
                  FlutterLocalization.instance.supportedLocales.map((locale) {
                    return DropdownMenuItem<String>(
                      value: locale.languageCode,
                      child: Text(locale.languageCode.toUpperCase()),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _changeLanguage(value);
                }
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColour,
                foregroundColor: textLightColour,
              ),
              onPressed: _loadFile,
              child: Text(LocaleData.loadFile.getString(context)),
            ),
          ],
        ),
      ),
    );
  }
}

// List<String> codes = GlobalData.instance.codes;
