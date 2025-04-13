// lib/CategoriesScreen.dart  <- Dosyanın konumu önemli

import 'package:flutter/material.dart';
// --- DÜZELTİLMİŞ IMPORT YOLU ---
// RecipesScreen'in bulunduğu doğru yolu belirtin
import 'RecipesScreen.dart';
// --------------------------------

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  // Örnek kategori listesi
  final List<String> categories = const [
    'Çorbalar',
    'Salatalar',
    'Ana Yemekler',
    'Tatlılar',
    'Sporcu Yiyecekleri',
    'Fast Food',
    'Akdeniz Mutfağı',
    'Kahvaltılıklar',
    'İçecekler',
  ];

  // Kategoriye özel ikonlar (isteğe bağlı)
  final Map<String, IconData> categoryIcons = const {
    'Çorbalar': Icons.soup_kitchen_outlined,
    'Salatalar': Icons.local_florist_outlined,
    'Ana Yemekler': Icons.dinner_dining_outlined,
    'Tatlılar': Icons.cake_outlined,
    'Sporcu Yiyecekleri': Icons.fitness_center,
    'Fast Food': Icons.fastfood_outlined,
    'Akdeniz Mutfağı': Icons.restaurant_outlined,
    'Kahvaltılıklar': Icons.free_breakfast_outlined,
    'İçecekler': Icons.local_cafe_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategoriler'),
        backgroundColor: primaryColor,
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        iconTheme: Theme.of(context).appBarTheme.iconTheme,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 3 / 2,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final categoryName = categories[index];
          final categoryIcon =
              categoryIcons[categoryName] ?? Icons.category_outlined;

          return InkWell(
            onTap: () {
              print('$categoryName kategorisi seçildi.');
              // RecipesScreen'e yönlendir ve kategori adını parametre olarak gönder
              Navigator.push(
                context,
                MaterialPageRoute(
                  // Hata 2'nin çözümü: Import doğru olunca bu satır sorunsuz çalışır.
                  builder: (context) => RecipesScreen(category: categoryName),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(categoryIcon, size: 40.0, color: accentColor),
                  const SizedBox(height: 12.0),
                  Text(
                    categoryName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
