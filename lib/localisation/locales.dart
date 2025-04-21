import 'package:flutter_localization/flutter_localization.dart';

const List<MapLocale> LOCALES = [
  MapLocale('en', LocaleData.EN),
  MapLocale('de', LocaleData.DE),
];

mixin LocaleData {
  static const String appTitle = 'appTitle';
  static const String settingsTitle = 'settingsTitle';
  static const String passwordTitle = 'passwordTitle';
  static const String emailTitle = 'emailTitle';

  static const String scanCode = 'scanCode';
  static const String loadFile = 'loadFile';
  static const String cancel = 'cancel';
  static const String languageLabel = 'languageLabel';
  static const String clearDataTitle = 'clearDataTitle';
  static const String confirm = 'confirm';
  static const String syncPrompt = 'syncPrompt';
  static const String loginPrompt = 'loginPrompt';
  static const String logoutPrompt = 'logoutPrompt';
  static const String noCameraPermission = 'noCameraPermission';

  static const String loadFileSuccess = 'loadFileSuccess';
  static const String loadFileError = 'loadFileError';
  static const String validCode = 'validCode';
  static const String invalidCode = 'invalidCode';
  static const String noCode = 'noCode';
  static const String noCodesAvailable = 'noCodesAvailable';
  static const String clearDataWarning = 'clearDataWarning';
  static const String clearDataSuccess = 'clearDataSuccess';
  static const String overwriteDataWarning = 'overwriteDataWarning';
  static const String syncError = 'syncError';
  static const String syncSuccess = 'syncSuccess';
  static const String loginError = 'loginError';
  static const String loginSuccess = 'loginSuccess';
  static const String notLoggedIn = 'notLoggedIn';

  static const Map<String, dynamic> EN = {
    appTitle: 'Ticket Scanner',
    settingsTitle: 'Settings',
    passwordTitle: 'Password',
    emailTitle: 'Email',
    scanCode: 'Scan Code',
    loadFile: 'Load File',
    cancel: 'Cancel',
    languageLabel: 'Select Language',
    clearDataTitle: 'Clear Data',
    confirm: 'Confirm',
    syncPrompt: 'Synchronise Codes',
    loginPrompt: 'Login',
    logoutPrompt: 'Logout',
    noCameraPermission:
        'Camera permission denied. Please enable it in settings.',
    loadFileSuccess: 'Success! Loaded %a codes',
    loadFileError: 'Error loading file',
    validCode: 'Valid code!',
    invalidCode: 'Invalid code!',
    noCode: 'No code found!',
    noCodesAvailable: 'No codes available in local data.',
    clearDataWarning: 'Are you sure you want to clear all data?',
    clearDataSuccess: 'Data cleared successfully!',
    overwriteDataWarning:
        'There is already data present in the app. Are you sure you want to continue?',
    syncError: 'Error syncing data: %a',
    syncSuccess: 'Data synced successfully!',
    loginError: 'Login failed. Please check your credentials.',
    loginSuccess: 'Login successful!',
    notLoggedIn: 'Not logged in.',
  };

  static const Map<String, dynamic> DE = {
    appTitle: 'Ticket-Scanner',
    settingsTitle: 'Einstellungen',
    passwordTitle: 'Passwort',
    emailTitle: 'E-Mail',
    scanCode: 'Code scannen',
    loadFile: 'Datei laden',
    cancel: 'Abbrechen',
    languageLabel: 'Sprache auswählen',
    clearDataTitle: 'Daten löschen',
    confirm: 'Bestätigen',
    syncPrompt: 'Codes synchronisieren',
    loginPrompt: 'Anmelden',
    logoutPrompt: 'Abmelden',
    noCameraPermission:
        'Kameraberechtigung verweigert. Bitte aktivieren Sie sie in den Einstellungen.',
    loadFileSuccess: 'Erfolg! %a Codes geladen',
    loadFileError: 'Fehler beim Laden der Datei',
    validCode: 'Gültiger Code!',
    invalidCode: 'Ungültiger Code!',
    noCode: 'Kein Code gefunden!',
    noCodesAvailable: 'Keine Codes in den lokalen Daten verfügbar.',
    clearDataWarning: 'Sind Sie sicher, dass Sie alle Daten löschen möchten?',
    clearDataSuccess: 'Daten erfolgreich gelöscht!',
    overwriteDataWarning:
        'Es sind bereits Daten in der App vorhanden. Sind Sie sicher, dass Sie fortfahren möchten?',
    syncError: 'Fehler beim Synchronisieren der Daten: %a',
    syncSuccess: 'Daten erfolgreich synchronisiert!',
    loginError:
        'Anmeldung fehlgeschlagen. Bitte überprüfen Sie Ihre Anmeldeinformationen.',
    loginSuccess: 'Anmeldung erfolgreich!',
    notLoggedIn: 'Nicht angemeldet.',
  };
}
