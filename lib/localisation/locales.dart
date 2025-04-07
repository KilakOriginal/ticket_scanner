import 'package:flutter_localization/flutter_localization.dart';

const List<MapLocale> LOCALES = [
  MapLocale('en', LocaleData.EN),
  MapLocale('de', LocaleData.DE),
];

mixin LocaleData {
  static const String appTitle = 'appTitle';
  static const String settingsTitle = 'settingsTitle';

  static const String scanCode = 'scanCode';
  static const String loadFile = 'loadFile';
  static const String cancel = 'cancel';
  static const String languageLabel = 'languageLabel';

  static const String loadFileSuccess = 'loadFileSuccess';
  static const String loadFileError = 'loadFileError';
  static const String validCode = 'validCode';
  static const String invalidCode = 'invalidCode';

  static const Map<String, dynamic> EN = {
    appTitle: 'Ticket Scanner',
    settingsTitle: 'Settings',
    scanCode: 'Scan Code',
    loadFile: 'Load File',
    cancel: 'Cancel',
    languageLabel: 'Select Language',
    loadFileSuccess: 'Success! Loaded %a codes',
    loadFileError: 'Error loading file',
    validCode: 'Valid code!',
    invalidCode: 'Invalid code!',
  };

  static const Map<String, dynamic> DE = {
    appTitle: 'Ticket-Scanner',
    settingsTitle: 'Einstellungen',
    scanCode: 'Code scannen',
    loadFile: 'Datei laden',
    cancel: 'Abbrechen',
    languageLabel: 'Sprache auswählen',
    loadFileSuccess: 'Erfolg! %a Codes geladen',
    loadFileError: 'Fehler beim Laden der Datei',
    validCode: 'Gültiger Code!',
    invalidCode: 'Ungültiger Code!',
  };
}
