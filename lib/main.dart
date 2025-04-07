import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:ticket_scanner/localisation/locales.dart';
import 'package:ticket_scanner/utils/constants.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterLocalization.instance.ensureInitialized();

  runApp(const TicketScannerApp());
}

class TicketScannerApp extends StatefulWidget {
  const TicketScannerApp({super.key});

  @override
  State<TicketScannerApp> createState() => _TicketScannerAppState();
}

class _TicketScannerAppState extends State<TicketScannerApp> {
  final FlutterLocalization localisation = FlutterLocalization.instance;

  @override
  void initState() {
    configureLocalisation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ticket Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: primarySwatch,
          accentColor: secondarySwatch,
          backgroundColor: backgroundColour,
          errorColor: errorColour,
        ),
        useMaterial3: true,
      ),
      supportedLocales: localisation.supportedLocales,
      localizationsDelegates: localisation.localizationsDelegates,
      home: HomeScreen(),
    );
  }

  void configureLocalisation() {
    localisation.init(mapLocales: LOCALES, initLanguageCode: 'en');
    localisation.onTranslatedLanguage = onTranslatedLanguage;
  }

  void onTranslatedLanguage(Locale? locale) {
    setState(() {});
  }
}
