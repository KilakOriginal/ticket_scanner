import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ticket_scanner/localisation/locales.dart';
import 'package:ticket_scanner/utils/constants.dart';
import 'package:ticket_scanner/utils/global_data.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlutterLocalization.instance.ensureInitialized();
  debugPrint('Initialising Supabase...');
  await Supabase.initialize(
    url: "https://supabase.abdoulhamidou.com/",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyAgCiAgICAicm9sZSI6ICJhbm9uIiwKICAgICJpc3MiOiAic3VwYWJhc2UtZGVtbyIsCiAgICAiaWF0IjogMTY0MTc2OTIwMCwKICAgICJleHAiOiAxNzk5NTM1NjAwCn0.dc_X5iR_VP_qT0zsiyj_I_OZ2T9FtRU2BBNWN8Bu4GE",
  );
  debugPrint('Supabase initialised.');
  await GlobalData.instance.loadCodes();

  runApp(const TicketScannerApp());
}

class TicketScannerApp extends StatefulWidget {
  const TicketScannerApp({super.key});

  @override
  State<TicketScannerApp> createState() => _TicketScannerAppState();
}

class _TicketScannerAppState extends State<TicketScannerApp>
    with WidgetsBindingObserver {
  final FlutterLocalization localisation = FlutterLocalization.instance;

  @override
  void initState() {
    configureLocalisation();
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    GlobalData.instance.startPeriodicSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    GlobalData.instance.stopPeriodicSync();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      syncCodes();
    }
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
