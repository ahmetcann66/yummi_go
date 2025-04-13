// lib/main.dart

import 'package:flutter/material.dart';
import 'package:yummi_go/LoginScreen.dart';
import 'services/api_service.dart';
// --- Ana Ekranı Tekrar Import Et ---
import 'HomeScreen.dart'; // Veya: import 'package:yummi_go/HomeScreen.dart';
// Test ekranı importunu kaldır veya yorum satırı yap
// import 'test_carousel_screen.dart';
// ---------------------------------

void main() {
  initializeHttpOverrides();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Tema renkleri (Değişiklik yok)
  static final MaterialColor primaryRed = Colors.red;
  static final Color accentRed = Colors.redAccent[400] ?? Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YummiGo', // Başlık eski haline döndü
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Tema ayarları
        primarySwatch: primaryRed,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: primaryRed,
          brightness: Brightness.light,
        ).copyWith(
          secondary: accentRed,
          error: Colors.red[700] ?? Colors.red,
        ),
        inputDecorationTheme:
            InputDecorationTheme(/* ... */), // Tema ayarları aynı kalabilir
        textSelectionTheme: TextSelectionThemeData(/* ... */),
        elevatedButtonTheme: ElevatedButtonThemeData(/* ... */),
        textButtonTheme: TextButtonThemeData(/* ... */),
        appBarTheme: AppBarTheme(/* ... */),
        iconTheme: IconThemeData(color: accentRed),
        cardTheme: CardTheme(/* ... */),
      ),

      // --- BAŞLANGIÇ EKRANI ESKİ HALİNE DÖNDÜ ---
      //home: const HomeScreen(),
      home: LoginScreen(),
      // home: const TestCarouselScreen(), // Test ekranı satırı kaldırıldı/yorumlandı
      // ----------------------------------------
    );
  }
}
