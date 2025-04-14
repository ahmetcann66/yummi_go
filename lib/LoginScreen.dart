// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'RegisterScreen.dart'; // Kayıt ekranı importu
import 'ForgotPasswordScreen.dart'; // Şifremi unuttum ekranı importu
import 'HomeScreen.dart'; // Başarılı giriş sonrası yönlendirilecek ekran

// --- GEREKLİ IMPORTLAR ---
import '../services/api_service.dart'; // ApiService sınıfının bulunduğu dosya yolu
import '../models/LoginModel.dart'; // LoginModel sınıfının bulunduğu dosya yolu
import '../models/UserModel.dart'; // UserModel sınıfının bulunduğu dosya yolu (isteğe bağlı)
// --- ---------------- ---

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController =
      TextEditingController(); // Kullanıcı adı kontrolcüsü
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- API Servisi Örneği ---
  final ApiService _apiService = ApiService();
  // --- ------------------ ---

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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final String username = _usernameController.text.trim();
      final String password = _passwordController.text;

      final LoginModel loginData =
          LoginModel(username: username, password: password);

      print('API isteği gönderiliyor: Kullanıcı Adı = $username');

      final UserModel? user = await _apiService.login(loginData);

      print('Giriş Başarılı: Kullanıcı = ${user!.username}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hoş geldiniz, ${user.username}!'),
          backgroundColor: Colors.green[600],
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (error) {
      print('Giriş Hatası: $error');

      if (!mounted) return;

      String errorMessage = 'Giriş yapılamadı.';
      if (error is Exception &&
          error.toString().contains('Kullanıcı adı veya şifre hatalı')) {
        errorMessage = 'Kullanıcı adı veya şifre hatalı.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
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
            _backgroundImageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.broken_image, color: Colors.grey, size: 50)),
          ),

          // Siyah Opaklık Filtresi
          Container(color: Colors.black.withOpacity(_backgroundOverlayOpacity)),

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

                      // Kullanıcı Adı Alanı
                      TextFormField(
                        controller: _usernameController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'Kullanıcı Adınız',
                          prefixIcon: Icon(Icons.person_outline,
                              color: Colors.grey[500]),
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
                            return 'Kullanıcı adı alanı boş bırakılamaz.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

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
                            return 'Şifre en az 6 karakter olmalıdır.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),

                      // Giriş Yap Butonu
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
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
                            foregroundColor: Colors.white.withOpacity(0.7)),
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
