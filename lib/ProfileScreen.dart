// lib/ProfileScreen.dart

import 'package:flutter/material.dart';
// --- DOĞRU İMPORTLAR ---
import 'screens/settings_screen.dart';
import 'screens/help_support_screen.dart';
// ------------------------
// import 'login_screen.dart'; // Eğer lib altındaysa bu doğru

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _logout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Çıkış yapıldı (Simülasyon).'),
          backgroundColor: Colors.blueGrey),
    );
    // TODO: Navigator.pushAndRemoveUntil ile LoginScreen'e git
  }

  void _goToFollowList(String title) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$title listesi yakında!')));
    // TODO: Gerçek backend ile buraya Navigator.push eklenecek
  }

  void _searchUsers(String query) {
    if (query.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$query" için arama özelliği yakında!')));
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color accentColor = Theme.of(context).colorScheme.secondary;
    const int followerCount = 125; // Örnek sayılar
    const int followingCount = 78;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilim'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Kullanıcı Bilgi Kartı
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
              child: Column(
                children: [
                  Row(// Avatar ve İsim/Email
                      children: [
                    CircleAvatar(
                        radius: 40,
                        backgroundColor: accentColor.withOpacity(0.8),
                        child: const Icon(Icons.person,
                            size: 45, color: Colors.white)),
                    const SizedBox(width: 16.0),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Kullanıcı Adı',
                              style: textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4.0),
                          Text('kullanici@example.com',
                              style: textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                              overflow: TextOverflow.ellipsis)
                        ])),
                  ]),
                  const SizedBox(height: 20),
                  Row(
                    // Takipçi/Takip Edilen
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildFollowerStat('Takipçi', followerCount,
                          () => _goToFollowList('Takipçiler')),
                      Container(height: 30, width: 1, color: Colors.grey[300]),
                      _buildFollowerStat('Takip Edilen', followingCount,
                          () => _goToFollowList('Takip Edilenler')),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24.0),

          // Kullanıcı Arama Çubuğu
          Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                      hintText: 'Başka kullanıcıları ara...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 16)),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _searchUsers)),

          // Ayarlar ve Yardım Butonları
          ListTile(
            leading: Icon(Icons.settings_outlined, color: Colors.grey[800]),
            title: Text('Ayarlar', style: textTheme.bodyLarge),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // --- BU ÇAĞRI DOĞRU OLMALI (Import doğruysa) ---
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SettingsScreen()));
              // ----------------------------------------------
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.help_outline, color: Colors.grey[800]),
            title: Text('Yardım & Destek', style: textTheme.bodyLarge),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // --- BU ÇAĞRI DOĞRU OLMALI (Import doğruysa) ---
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HelpSupportScreen()));
              // ---------------------------------------------
            },
          ),
          const Divider(height: 1),

          const SizedBox(height: 40.0),

          // Çıkış Yap Butonu
          ElevatedButton.icon(
              icon: const Icon(Icons.logout, size: 20),
              label: const Text('Çıkış Yap'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold)),
              onPressed: _logout),
        ],
      ),
    );
  }

  // Takipçi Stat Widget'ı
  Widget _buildFollowerStat(String label, int count, VoidCallback onTap) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(count.toString(),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[600]))
            ])));
  }
}
