// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider paketini import et
import 'package:provider/single_child_widget.dart'; // SingleChildWidget için
import 'package:cookie_jar/cookie_jar.dart'; // CookieJar için
import 'package:yummi_go/LoginScreen.dart'; // LoginScreen importu (Yolu kontrol et)

// Servisleri ve AuthManager'ı import et (Yolları kontrol et)
import 'package:yummi_go/services/LoginService.dart';
import 'package:yummi_go/services/RecipeService.dart';
import 'package:yummi_go/AuthManager.dart';

// --- 1. Paylaşılan CookieJar örneğini oluştur ---
final CookieJar sharedCookieJar = CookieJar();

void main() {
  // WidgetsBinding.ensureInitialized(); // Gerekliyse (örn: Firebase vb. için)

  // --- 2. Uygulamayı MultiProvider ile başlat ---
  runApp(
    MultiProvider(
      providers: createProviders(), // Provider listesini aşağıda tanımlayacağız
      child: const MyApp(),
    ),
  );
}

// --- 3. Provider listesini oluşturan fonksiyon ---
List<SingleChildWidget> createProviders() {
  return [
    // AuthManager (Singleton, Provider ile erişilebilir hale getiriliyor)
    Provider<AuthManager>(create: (_) => AuthManager()),

    // Servislere PAYLAŞILAN CookieJar'ı constructor üzerinden verin
    // LoginService constructor'ının CookieJar aldığından emin ol!
    Provider<LoginService>(create: (_) => LoginService(sharedCookieJar)),

    // RecipeService constructor'ının CookieJar aldığından emin ol!
    Provider<RecipeService>(create: (_) => RecipeService(sharedCookieJar)),

    // Uygulamanızdaki diğer state management veya servis provider'ları buraya eklenebilir
  ];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Tema renkleri (Değişiklik yok)
  static final MaterialColor primaryRed = Colors.red;
  static final Color accentRed = Colors.redAccent[400] ?? Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YummiGo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Tema ayarları (Mevcut ayarların kalabilir)
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
            InputDecorationTheme(/* ... önceki ayarlar ... */),
        textSelectionTheme:
            TextSelectionThemeData(/* ... önceki ayarlar ... */),
        elevatedButtonTheme:
            ElevatedButtonThemeData(/* ... önceki ayarlar ... */),
        textButtonTheme: TextButtonThemeData(/* ... önceki ayarlar ... */),
        appBarTheme: AppBarTheme(/* ... önceki ayarlar ... */),
        iconTheme: IconThemeData(color: accentRed),
        cardTheme: CardTheme(/* ... önceki ayarlar ... */),
      ),

      // Başlangıç ekranı olarak LoginScreen
      home: const LoginScreen(), // LoginScreen artık const olabilir
    );
  }
}
