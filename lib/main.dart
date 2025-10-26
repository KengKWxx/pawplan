import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'package:provider/provider.dart';
import 'services/theme_service.dart';
import 'services/locale_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/pet_qr_screen.dart';
import 'models/pet.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://flqoteekgzeerjaokuqc.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZscW90ZWVrZ3plZXJqYW9rdXFjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc0MjkzNzEsImV4cCI6MjA3MzAwNTM3MX0.TZnXvPhSNE9RjMCPFEd28Pz0ThTRLU4Whgn-VrnX54k',
  );
  
  // Initialize and request permissions for local notifications (skip on Web)
  try {
    if (!kIsWeb) {
      await NotificationService.initialize();
      await NotificationService.requestPermissions();
    }
  } catch (_) {}
  
  final themeService = ThemeService();
  final localeService = LocaleService();
  await Future.wait([themeService.load(), localeService.load()]);
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: themeService),
      ChangeNotifierProvider.value(value: localeService),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final localeService = Provider.of<LocaleService>(context);
    return MaterialApp(
      title: 'PawPlan',
      debugShowCheckedModeBanner: false,
      locale: localeService.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B4513), // keep brown scheme
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF6F2),
        appBarTheme: const AppBarTheme(centerTitle: true),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B4513),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B4513),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(centerTitle: true),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E1E1E),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B4513),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      themeMode: themeService.mode,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot': (context) => const ForgotPasswordScreen(),
        '/pet_qr': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          Pet? pet;
          if (args is Pet) {
            pet = args;
          } else if (args is Map && args['pet'] is Pet) {
            pet = args['pet'] as Pet;
          }
          if (pet == null) {
            return Scaffold(
              appBar: AppBar(title: Text(AppLocalizations.of(context)?.petQrCode ?? 'Pet QR Code')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    AppLocalizations.of(context)?.noPetProvidedQr ?? 'No pet provided to QR screen. Please open from a pet card.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.brown.shade700),
                  ),
                ),
              ),
            );
          }
          return PetQrScreen(pet: pet);
        },
      },
    );
  }
}