import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Wajib untuk Tema
import 'services/notification_service.dart';
import 'providers/theme_provider.dart';
import 'pages/splash_page.dart'; // Pastikan import ini ada

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Init Firebase
  await Firebase.initializeApp();

  // 2. Init Notifikasi
  await NotificationService.init();

  // 3. Lock Orientasi Portrait
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    // Bungkus App dengan Provider Tema
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..loadTheme()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ambil data Tema dari Provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Monitor Elite',

      // --- TEMA TERANG (Light Mode) ---
      theme: ThemeData(
        primarySwatch: themeProvider.primaryColor, // Warna dinamis
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),

      // --- TEMA GELAP (Dark Mode) ---
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: themeProvider.primaryColor, // Warna dinamis
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.dark(
          primary: themeProvider.primaryColor,
          secondary: themeProvider.primaryColor,
          surface: const Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
        ),
      ),

      themeMode: ThemeMode.system, // Ikut settingan HP User

      // --- PERBAIKAN SPLASH SCREEN DI SINI ---
      // Dulu: Cek FirebaseAuth langsung (Splash terlewati)
      // Sekarang: Panggil SplashPage dulu
      home: const SplashPage(),
    );
  }
}