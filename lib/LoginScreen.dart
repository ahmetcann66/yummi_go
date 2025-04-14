// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Provider paketini import et
import 'package:yummi_go/models/UserModel.dart'; // Merkezi UserModel importu
import 'RegisterScreen.dart'; // Kayıt ekranı importu (Yolu doğrulayın)
import 'ForgotPasswordScreen.dart'; // Şifremi unuttum ekranı importu (Yolu doğrulayın)
import 'HomeScreen.dart'; // Başarılı giriş sonrası yönlendirilecek ekran (Yolu doğrulayın)

// --- Servis ve AuthManager Importları ---
import 'package:yummi_go/services/LoginService.dart'; // Giriş API servisi
import 'package:yummi_go/AuthManager.dart'; // Oturum yönetimi
// ApiResponse LoginService içinde veya ortak bir yerde tanımlı olmalı

// --- Provider Kullanımı Notu ---
// Bu ekran artık Provider aracılığıyla LoginService ve AuthManager'a erişmelidir.
// main.dart'taki MultiProvider kurulumunun doğru yapıldığı varsayılmaktadır.
// Servisler ve AuthManager, paylaşılan CookieJar ile doğru şekilde yapılandırılmış olmalıdır.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- Doğrudan Instance Oluşturmayı Kaldır ---
  // final LoginService _loginService = LoginService(); // <<< SİLİNDİ
  // final AuthManager _authManager = AuthManager();   // <<< SİLİNDİ
  // --- ------------------------------------ ---

  // --- Sabit Değerler ---
  final String _backgroundImageUrl =
      'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1740&q=80';
  final double _backgroundOverlayOpacity = 0.65;
  // --- ------------- ---

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Kullanıcı giriş işlemini gerçekleştiren metot.
  Future<void> _login() async {
    // Form geçerli değilse veya zaten yükleniyorsa çık
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }

    // --- Servisleri Provider'dan al ---
    // Bu işlem, context'e erişimin olduğu yerde (onPressed gibi) yapılmalıdır.
    final loginService = Provider.of<LoginService>(context, listen: false);
    final authManager = Provider.of<AuthManager>(context, listen: false);
    // `listen: false` önemlidir, servislerin state'i değiştiğinde LoginScreen'in
    // yeniden build olmasına gerek yoktur.

    // Yükleme durumunu başlat
    setState(() {
      _isLoading = true;
    });

    final String username = _usernameController.text.trim();
    final String password = _passwordController.text;

    ApiResponse<UserModel>? result; // Nullable olarak tanımla
    try {
      // --- Provider'dan alınan 'loginService' örneğini kullan ---
      result = await loginService.login(
          username, password); // <<< Provider'dan alınan servis kullanıldı
    } catch (e) {
      // Servis çağrısında beklenmedik genel bir hata olursa
      print("Login servisi çağrılırken hata: $e");
      if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlem yapma
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Giriş sırasında beklenmedik bir hata oluştu: ${e.toString()}"),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      // Hata durumunda yükleme durumunu bitir
      setState(() {
        _isLoading = false;
      });
      return; // İşlemi durdur
    }

    // Widget ağaçtan kaldırıldıysa işlem yapma
    if (!mounted) return;

    // API Yanıtını kontrol et
    if (result.success && result.data != null) {
      // --- Başarılı Giriş ---
      try {
        // --- Provider'dan alınan 'authManager' örneğini kullan ---
        authManager.loginUser(
            result.data!); // <<< Provider'dan alınan manager kullanıldı

        // Başarı mesajı göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                result.message ?? 'Hoş geldiniz, ${result.data!.username}!'),
            backgroundColor: Colors.green[600],
          ),
        );

        // Ana ekrana yönlendir ve bu ekranı yığından kaldır
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const HomeScreen()), // HomeScreen const olabilir
        );
        // Başarılı yönlendirme sonrası isLoading false yapmaya gerek yok, ekran değişiyor.
      } catch (e) {
        // AuthManager'a kaydederken veya yönlendirme sırasında hata olursa
        print("AuthManager'a kaydederken/Yönlendirirken hata: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Oturum başlatılırken bir sorun oluştu."),
              backgroundColor: Colors.orange),
        );
        // Hata olsa bile yükleme durumunu bitir
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else {
      // --- Hatalı Giriş ---
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // API'den gelen mesajı veya varsayılan mesajı göster
          content: Text(
              result.message ?? 'Giriş yapılamadı. Bilgileri kontrol edin.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      // Hata durumunda yükleme durumunu bitir
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      // Klavye açıldığında taşmayı önlemek için SingleChildScrollView içinde
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Arka Plan Görseli
          Image.network(
            _backgroundImageUrl,
            fit: BoxFit.cover,
            // Yükleme ve hata durumları için builder'lar
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                  child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null));
            },
            errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade300,
                child: const Center(
                    child: Icon(Icons.broken_image,
                        color: Colors.grey, size: 50))),
          ),

          // Siyah Opaklık Filtresi
          Container(color: Colors.black.withOpacity(_backgroundOverlayOpacity)),

          // Giriş Formu Alanı
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                // İçerik sığmazsa kaydırmayı sağlar
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 30.0),
                child: Form(
                  key: _formKey, // Formun durumunu yönetmek için
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center, // Dikeyde ortala
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch, // Yatayda genişlet
                    children: <Widget>[
                      // Logo/İkon
                      Icon(Icons.restaurant_menu,
                          size: 80.0, color: accentColor),
                      const SizedBox(height: 16.0),
                      // Uygulama Adı
                      Text(
                        'YummiGo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 36.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  blurRadius: 6.0,
                                  color: Colors.black.withOpacity(0.7),
                                  offset: const Offset(1.0, 1.0))
                            ]),
                      ),
                      const SizedBox(height: 8.0),
                      // Slogan
                      Text(
                        'Lezzetli tariflere hoş geldiniz!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 17.0,
                            color: Colors.white.withOpacity(0.9),
                            shadows: [
                              Shadow(
                                  blurRadius: 4.0,
                                  color: Colors.black.withOpacity(0.7),
                                  offset: const Offset(1.0, 1.0))
                            ]),
                      ),
                      const SizedBox(height: 48.0),

                      // Kullanıcı Adı Giriş Alanı
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.text, // Metin klavyesi
                        textInputAction:
                            TextInputAction.next, // Klavye sonraki tuşu
                        decoration: InputDecoration(
                          hintText: 'Kullanıcı Adınız',
                          prefixIcon: Icon(Icons.person_outline,
                              color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.white
                              .withOpacity(0.9), // Hafif şeffaf beyaz dolgu
                          border: OutlineInputBorder(
                            // Kenarlık stili
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide:
                                BorderSide.none, // Kenarlık çizgisi olmasın
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 16.0), // İç boşluk
                        ),
                        style: const TextStyle(
                            color: Colors.black87), // Yazı rengi
                        validator: (value) {
                          // Doğrulama kuralı
                          if (value == null || value.trim().isEmpty) {
                            return 'Kullanıcı adı alanı boş bırakılamaz.';
                          }
                          return null; // Geçerliyse null döndür
                        },
                      ),
                      const SizedBox(height: 16.0), // Alanlar arası boşluk

                      // Şifre Giriş Alanı
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true, // Şifreyi gizle
                        keyboardType:
                            TextInputType.visiblePassword, // Şifre klavyesi
                        textInputAction:
                            TextInputAction.done, // Klavye bitti tuşu
                        onFieldSubmitted: (_) => _isLoading
                            ? null
                            : _login(), // Enter ile giriş yapmayı dene
                        decoration: InputDecoration(
                          hintText: 'Şifreniz',
                          prefixIcon:
                              Icon(Icons.lock_outline, color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14.0, horizontal: 16.0),
                        ),
                        style: const TextStyle(color: Colors.black87),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre alanı boş bırakılamaz.';
                          }
                          // Şifre uzunluk kontrolü API tarafında yapılmalı
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),

                      // Giriş Yap Butonu
                      ElevatedButton(
                        // Yükleme sırasında butonu devre dışı bırak
                        onPressed:
                            _isLoading ? null : _login, // <<< _login'i çağırır
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor, // Tema rengi
                          padding: const EdgeInsets.symmetric(
                              vertical: 14.0), // Dikey dolgu
                          shape: RoundedRectangleBorder(
                            // Yuvarlak köşeler
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 5, // Gölge
                        ),
                        child: _isLoading
                            // Yükleniyorsa dönen ikon göster
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white)),
                              )
                            // Yüklenmiyorsa metni göster
                            : const Text(
                                'Giriş Yap',
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                      ),
                      const SizedBox(height: 16.0),

                      // Kayıt Olma Bağlantısı
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Hesabınız yok mu?',
                            style:
                                TextStyle(color: Colors.white.withOpacity(0.8)),
                          ),
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () {
                                    // Yükleme sırasında devre dışı
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const RegisterScreen())); // Kayıt ekranına git
                                  },
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.white, // Metin rengi
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6)), // Daha az boşluk
                            child: const Text(
                              'Kayıt Ol',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      // Şifremi Unuttum Bağlantısı
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                // Yükleme sırasında devre dışı
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPasswordScreen())); // İlgili ekrana git
                              },
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white
                                .withOpacity(0.7)), // Hafif soluk renk
                        child: const Text('Şifremi Unuttum'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
