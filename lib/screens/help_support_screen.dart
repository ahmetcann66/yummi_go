// lib/screens/help_support_screen.dart

import 'package:flutter/material.dart';
// --- DÜZELTİLDİ: Bir üst klasörden import ---
import '../ForgotPasswordScreen.dart';
// -------------------------------------------
// import '../change_password_screen.dart'; // Eğer bu da lib altındaysa böyle olacak

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yardım & Destek'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.lock_reset_outlined),
            title: const Text('Şifremi Unuttum'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Sınıf adı doğru, import yolu düzeltildiği için çalışmalı
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen()));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.password_outlined),
            title: const Text('Şifre Değiştir'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Şifre değiştirme ekranı yakında!')));
              // Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('E-posta ile Destek'),
            subtitle: const Text('Destek ekibimize ulaşın'),
            trailing: const Icon(Icons.send_outlined),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('E-posta gönderme özelliği yakında!')));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.question_answer_outlined),
            title: const Text('Sıkça Sorulan Sorular'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SSS bölümü yakında!')));
            },
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
