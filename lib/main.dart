import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_page.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My67Food Price',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}