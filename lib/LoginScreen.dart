// lib/screens/login_screen.dart <-- Örnek dosya yolu

import 'package:flutter/material.dart';
import 'RegisterScreen.dart'; // Kayıt ekranı importu
import 'ForgotPasswordScreen.dart'; // Şifremi unuttum ekranı importu
import 'HomeScreen.dart'; // Başarılı giriş sonrası yönlendirilecek ekran (Varsayılan isim)

// --- GEREKLİ IMPORTLAR ---
import '../services/api_service.dart'; // ApiService sınıfının bulunduğu dosya yolu
import '../models/login_model.dart'; // LoginModel sınıfının bulunduğu dosya yolu
import '../models/user_model.dart'; // UserModel sınıfının bulunduğu dosya yolu (isteğe bağlı, kullanıcı bilgisini saklamak için)
// --- ---------------- ---

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController =
      TextEditingController(); // E-posta yerine kullanıcı adı kullanıldığı varsayıldı
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- API Servisi Örneği ---
  // Not: Daha büyük uygulamalarda bu servisi Provider, Riverpod, GetIt gibi
  // bir state management/dependency injection çözümü ile sağlamak daha iyidir.
  final ApiService _apiService = ApiService();
  // --- ------------------ ---

  // --- Constants ---
  final String backgroundImageUrl =
      'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1740&q=80';
  final double backgroundOverlayOpacity = 0.65;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final username = _usernameController.text.trim(); // Kullanıcı adını al
      final password = _passwordController.text;

      // LoginModel oluştur (API'nin beklediği alanlar)
      final loginData = LoginModel(username: username, password: password);

      print('API ye giriş isteği gönderiliyor: $username'); // Loglama

      // ApiService üzerinden giriş yapmayı dene
      final UserModel user = await _apiService.loginUser(loginData);

      print('Giriş Başarılı: ${user.username}'); // Başarılı loglama

      if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlem yapma

      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Hoş geldiniz, ${user.username}!'), // Kullanıcı adını göster
          backgroundColor: Colors.green[600],
        ),
      );

      // Başarılı giriş sonrası ana ekrana yönlendir
      // pushReplacement, geri tuşuyla login ekranına dönülmesini engeller
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => const HomeScreen()), // HomeScreen'a yönlendir
      );
    } catch (error) {
      print('Giriş Hatası: $error'); // Hata loglama

      if (!mounted) return; // Widget ağaçtan kaldırıldıysa işlem yapma

      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // ApiService'den gelen hata mesajını göster
          content: Text('Giriş yapılamadı: ${error.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      // İşlem bittiğinde yükleniyor durumunu kapat
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
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Arka Plan Görseli
          Image.network(
            backgroundImageUrl,
            fit: BoxFit.cover,
            // Hata ve yüklenme durumları için builder ekleyebilirsiniz
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                  child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ));
            },
            errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
          ),

          // Siyah Opaklık Filtresi
          Container(color: Colors.black.withOpacity(backgroundOverlayOpacity)),

          // Giriş Formu
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 30.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Icon(Icons.restaurant_menu,
                          size: 80.0, color: accentColor),
                      const SizedBox(height: 16.0),
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
                              offset: const Offset(1.0, 1.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8.0),
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
                              offset: const Offset(1.0, 1.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48.0),

                      // --- Kullanıcı Adı Alanı ---
                      TextFormField(
                        controller:
                            _usernameController, // Kullanıcı adı controller'ı
                        keyboardType:
                            TextInputType.text, // Klavye tipini text yap
                        decoration: InputDecoration(
                          hintText: 'Kullanıcı Adınız', // Hint text'i güncelle
                          prefixIcon: Icon(Icons.person_outline,
                              color: Colors.grey[500]), // İkonu güncelle
                          // Arka plan, kenarlık vb. stiller eklenebilir
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.black87),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            // E-posta yerine kullanıcı adı kontrolü
                            return 'Kullanıcı adı alanı boş bırakılamaz.';
                          }
                          // İsteğe bağlı: Kullanıcı adı için ek kurallar (örn: uzunluk)
                          // if (value.length < 3) {
                          //   return 'Kullanıcı adı en az 3 karakter olmalıdır.';
                          // }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      // --- ------------------- ---

                      // Şifre Alanı
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
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
                        ),
                        style: const TextStyle(color: Colors.black87),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre alanı boş bırakılamaz.';
                          }
                          if (value.length < 2) {
                            // API'nizin gereksinimine göre ayarlayın
                            return 'Şifre en az 6 karakter olmalıdır.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),

                      // Giriş Yap Butonu
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : _login, // _login fonksiyonunu çağır
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor, // Buton rengi
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white)),
                              )
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
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                const RegisterScreen()));
                                  },
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.white),
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
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ForgotPasswordScreen()));
                              },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white.withOpacity(0.7),
                        ),
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
