import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:ticket_scanner/screens/login_screen.dart';
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
      // Check if there is already data in shared preferences
      if (GlobalData.instance.codes.isNotEmpty) {
        bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(LocaleData.loadFile.getString(context)),
              content: Text(LocaleData.overwriteDataWarning.getString(context)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(LocaleData.cancel.getString(context)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(LocaleData.confirm.getString(context)),
                ),
              ],
            );
          },
        );

        if (confirmed != true) {
          return;
        }
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'csv'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        List<String> lines = await file.readAsLines();

        if (lines.isEmpty) {
          throw Exception('File is empty');
        }

        // Read the encoding type from the first line and remove it
        String encoding = lines.first.trim().toLowerCase();
        lines.removeAt(0);

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

        // Normalize and filter codes
        List<Map<String, dynamic>> codes =
            lines
                .map((line) => line.trim())
                .where((line) => RegExp(r'^[a-zA-Z0-9]+$').hasMatch(line))
                .map(
                  (code) => {
                    'code': _normaliseCode(code),
                    'status': 'valid',
                    'last_modified': DateTime.now().toUtc().toIso8601String(),
                    'type': encoding,
                  },
                )
                .toList();

        GlobalData.instance.codes = codes;

        await GlobalData.instance.saveCodes();
        GlobalData.instance.syncCodes();

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

  Future<void> _clearData() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(LocaleData.clearDataTitle.getString(context)),
          content: Text(LocaleData.clearDataWarning.getString(context)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(LocaleData.cancel.getString(context)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(LocaleData.confirm.getString(context)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      GlobalData.instance.codes = [];
      GlobalData.instance.encodingType = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LocaleData.clearDataSuccess.getString(context),
              style: TextStyle(color: textLightColour),
            ),
            backgroundColor: successColour,
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
            const SizedBox(height: 32),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColour,
                foregroundColor: textLightColour,
              ),
              onPressed: () async {
                try {
                  await GlobalData.instance.syncCodes();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          LocaleData.syncSuccess.getString(context),
                          style: TextStyle(color: textLightColour),
                        ),
                        backgroundColor: successColour,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          LocaleData.syncError.getString(context),
                          style: TextStyle(color: textLightColour),
                        ),
                        backgroundColor: errorColour,
                      ),
                    );
                  }
                }
              },
              child: Text(LocaleData.syncPrompt.getString(context)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColour,
                foregroundColor: textLightColour,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: Text(LocaleData.loginPrompt.getString(context)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColour,
                foregroundColor: textLightColour,
              ),
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Logged out')));
                }
              },
              child: Text(LocaleData.logoutPrompt.getString(context)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColour,
                foregroundColor: textLightColour,
              ),
              onPressed: _clearData,
              child: Text(LocaleData.clearDataTitle.getString(context)),
            ),
          ],
        ),
      ),
    );
  }
}
