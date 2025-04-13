// lib/forgot_password_screen.dart // İstersen yeniden adlandır

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // InputFormatter için

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  final String backgroundImageUrl =
      'https://images.unsplash.com/photo-1504754524776-8f4f37790ca0?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1740&q=80';
  final double backgroundOverlayOpacity = 0.65;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate() || _isLoading) {
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '$email adresine sıfırlama bağlantısı gönderildi. (Simülasyon)'),
          backgroundColor: Colors.blue[600],
        ),
      );

      if (Navigator.canPop(context)) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Sıfırlama bağlantısı gönderilemedi! (Simülasyon)'),
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
      appBar: AppBar(title: const Text('Şifremi Unuttum')),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.network(
            backgroundImageUrl,
            fit: BoxFit.cover, /* ... */
          ),
          Container(
              color: Colors.black
                  .withAlpha((255 * backgroundOverlayOpacity).round())),
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
                      Icon(Icons.lock_reset, size: 70.0, color: accentColor),
                      const SizedBox(height: 24.0),
                      Text('Şifrenizi Sıfırlayın',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                    blurRadius: 6.0,
                                    color: Colors.black
                                        .withAlpha((255 * 0.6).round()),
                                    offset: const Offset(1.0, 1.0))
                              ])),
                      const SizedBox(height: 16.0),
                      Text(
                          'Kayıtlı e-posta adresinizi girin, size şifre sıfırlama bağlantısı gönderelim.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16.0,
                              color:
                                  Colors.white.withAlpha((255 * 0.85).round()),
                              shadows: [
                                Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.black
                                        .withAlpha((255 * 0.7).round()),
                                    offset: const Offset(1.0, 1.0))
                              ])),
                      const SizedBox(height: 32.0),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                            hintText: 'E-posta Adresiniz',
                            prefixIcon: Icon(Icons.email_outlined,
                                color: Colors.grey[500])),
                        style: const TextStyle(color: Colors.black87),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'E-posta alanı boş bırakılamaz.';
                          }
                          if (!RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                              .hasMatch(value)) {
                            return 'Geçerli bir e-posta adresi giriniz.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24.0),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _sendResetLink,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white)))
                            : const Text('Sıfırlama Bağlantısı Gönder',
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16.0),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        style: TextButton.styleFrom(
                            foregroundColor:
                                Colors.white.withAlpha((255 * 0.7).round())),
                        child: const Text('Giriş Ekranına Dön'),
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
