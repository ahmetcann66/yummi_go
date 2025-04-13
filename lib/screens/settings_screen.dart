// lib/settings_screen.dart (veya lib/screens/settings_screen.dart)

import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Simülasyon için state değişkenleri
  bool _notificationsEnabled = true; // Başlangıçta açık varsayalım
  bool _isDarkMode = false; // Başlangıçta açık tema varsayalım

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          // Bildirim Ayarı
          SwitchListTile(
            title: const Text('Bildirimler'),
            subtitle: Text(_notificationsEnabled ? 'Açık' : 'Kapalı'),
            value: _notificationsEnabled,
            onChanged: (bool value) {
              setState(() {
                _notificationsEnabled = value;
              });
              print(
                  "Bildirimler: ${_notificationsEnabled ? 'AÇIK' : 'KAPALI'} (Simülasyon)");
              // TODO: Backend'e bu ayarı kaydetme isteği gönderilecek.
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Bildirim ayarı değiştirildi (Simülasyon).'),
                  duration: Duration(seconds: 1)));
            },
            secondary: Icon(
              _notificationsEnabled
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_off_outlined,
              color: Theme.of(context).colorScheme.secondary, // Tema rengi
            ),
          ),
          const Divider(height: 1),

          // Tema Ayarı (Basit Toggle)
          SwitchListTile(
            title: const Text('Koyu Tema'),
            subtitle: Text(_isDarkMode ? 'Aktif' : 'Pasif'),
            value: _isDarkMode,
            onChanged: (bool value) {
              setState(() {
                _isDarkMode = value;
              });
              print(
                  "Koyu Tema: ${_isDarkMode ? 'AKTİF' : 'PASİF'} (Simülasyon)");
              // TODO: Gerçek tema değişimi için ThemeProvider gibi bir state management çözümü kullanılacak.
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text('Tema değiştirme özelliği yakında! (Simülasyon)'),
                  duration: Duration(seconds: 1)));
            },
            secondary: Icon(
              _isDarkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const Divider(height: 1),

          // Diğer ayarlar buraya eklenebilir (Dil, Hesap vb.)
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Dil'),
            trailing: const Row(
              // Mevcut dili göstermek için Row
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Türkçe'),
                SizedBox(width: 4),
                Icon(Icons.chevron_right)
              ],
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dil değiştirme yakında!')));
            },
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
