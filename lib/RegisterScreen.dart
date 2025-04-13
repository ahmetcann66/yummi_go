import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  // --- Constants (LoginScreen ile aynı) ---
  final String backgroundImageUrl =
      'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1740&q=80'; // Seçilen görsel URL'si
  final double backgroundOverlayOpacity = 0.65; // Siyah katman opaklığı

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password =
          _passwordController.text; // Gerçek uygulamada API'ye gönderilir

      print('Kayıt İsteği: $name, $email');
      await Future.delayed(const Duration(seconds: 2)); // Simülasyon

      print('Kayıt Başarılı (Simülasyon)');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$name, hesabınız oluşturuldu! Giriş yapabilirsiniz. (Simülasyon)',
          ),
          backgroundColor: Colors.green[600],
        ),
      );

      if (Navigator.canPop(context)) {
        Navigator.pop(context); // Login'e dön
      }
    } catch (error) {
      print('Kayıt Hatası (Simülasyon): $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kayıt oluşturulamadı! (Simülasyon)'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ana vurgu rengini temadan alalım
    final Color accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      // AppBar temadan stil alıyor (şeffaf, beyaz yazı/ikon)
      appBar: AppBar(
        title: const Text('Hesap Oluştur'), // Stil AppBarTheme'dan geliyor
        // backgroundColor: Colors.transparent, // Temadan geliyor
        // elevation: 0, // Temadan geliyor
        // iconTheme: IconThemeData(color: Colors.white), // Temadan geliyor
      ),
      // AppBar'ın arkasına içeriği uzat (görsel görünsün)
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // --- 1. Katman: Arka Plan Görseli ---
          Image.network(
            backgroundImageUrl,
            fit: BoxFit.cover,
            loadingBuilder:
                (context, child, progress) =>
                    progress == null
                        ? child
                        : Center(
                          child: CircularProgressIndicator(
                            value:
                                progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                            color: Colors.white70,
                          ),
                        ),
            errorBuilder:
                (context, error, stackTrace) => Container(color: Colors.black),
          ),

          // --- 2. Katman: Siyah Opaklık Filtresi ---
          Container(color: Colors.black.withOpacity(backgroundOverlayOpacity)),

          // --- 3. Katman: Kayıt Formu ---
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 30.0,
                ),
                // AppBar'ın kapladığı alanı hesaba katmak için üstten ek boşluk
                // padding: EdgeInsets.only(top: kToolbarHeight + 20.0, left: 24.0, right: 24.0, bottom: 30.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // Başlığı biraz aşağı alabiliriz (AppBar zaten var)
                      const SizedBox(
                        height: kToolbarHeight - 10,
                      ), // AppBar yüksekliği kadar boşluk
                      Text(
                        'YummiGo\'ya Katılın',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 6.0,
                              color: Colors.black.withOpacity(0.6),
                              offset: Offset(1.0, 1.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32.0),

                      // Ad Soyad Alanı
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        // Stil Tema'dan geliyor
                        decoration: InputDecoration(
                          hintText: 'Adınız Soyadınız',
                          // İkon rengini override edebiliriz veya temadan alır
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: Colors.grey[500],
                          ),
                        ),
                        style: TextStyle(
                          color: Colors.black87,
                        ), // Alan içi yazı
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'Ad soyad alanı boş bırakılamaz.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // E-posta Alanı
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'E-posta Adresiniz',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.grey[500],
                          ),
                        ),
                        style: TextStyle(color: Colors.black87),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty)
                            return 'E-posta alanı boş bırakılamaz.';
                          if (!RegExp(
                            r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                          ).hasMatch(value))
                            return 'Geçerli bir e-posta adresi giriniz.';
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
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Colors.grey[500],
                          ),
                        ),
                        style: TextStyle(color: Colors.black87),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Şifre alanı boş bırakılamaz.';
                          if (value.length < 6)
                            return 'Şifre en az 6 karakter olmalıdır.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),

                      // Şifre Tekrar Alanı
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Şifrenizi Tekrar Girin',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Colors.grey[500],
                          ),
                        ),
                        style: TextStyle(color: Colors.black87),
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'Şifre tekrar alanı boş bırakılamaz.';
                          if (value != _passwordController.text)
                            return 'Şifreler eşleşmiyor.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),

                      // Kayıt Ol Butonu (Stil Tema'dan)
                      ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text(
                                  'Kayıt Ol',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                      const SizedBox(height: 16.0),

                      // Giriş Yap Bağlantısı (Stil Tema'dan)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Zaten hesabınız var mı?',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          TextButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : () {
                                      Navigator.pop(context);
                                    },
                            // Stil TextButtonTheme'dan geliyor
                            child: const Text(
                              'Giriş Yap',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
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
