import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_page.dart';
import 'screens/splash_page.dart';

const String supabaseUrl =
    'https://dokqvrymoergmzitjadq.supabase.co';

const String supabaseKey =
    'sb_publishable_mw3SPCRiHq0XQNCdalZ8ug_jKzNooHc';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabaseKey,
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color primaryGreen = Color(0xFF176B52);
  static const Color darkGreen = Color(0xFF0F513D);
  static const Color backgroundColor = Color(0xFFF6F8F5);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My67Food Price',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          secondary: const Color(0xFFF4A261),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1B1B1B),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF1B1B1B),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF7F9F7),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 17,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE1E7E3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFFE1E7E3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: primaryGreen,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Colors.red,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Colors.red,
              width: 1.5,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(
              double.infinity,
              54,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      home: const SplashPage(),
    );
  }
}