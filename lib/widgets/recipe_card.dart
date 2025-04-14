// lib/widgets/recipe_card.dart
import 'package:flutter/material.dart';
import '../models/RecipeModel.dart'; // Güncellenmiş modeli import et

class RecipeCard extends StatelessWidget {
  final RecipeModel recipe;
  final VoidCallback onTap;
  final Widget? trailing;

  const RecipeCard({
    Key? key,
    required this.recipe,
    required this.onTap,
    this.trailing,
  }) : super(key: key);

  // Pişirme süresini formatlayan metot
  String _formatCookingTime(int? minutes) {
    if (minutes == null || minutes <= 0) return ''; // Süre yoksa boş
    if (minutes < 60) return '${minutes}dk';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}sa';
    return '${hours}sa ${remainingMinutes}dk';
  }

  @override
  Widget build(BuildContext context) {
    final Color accentColor = Theme.of(context).colorScheme.secondary;
    final textTheme = Theme.of(context).textTheme;

    // Gösterilecek bilgi (Pişirme süresi veya kategori)
    String infoText = _formatCookingTime(recipe.cookingTimeInMinutes);
    IconData infoIcon = Icons.timer_outlined;

    // Eğer pişirme süresi yoksa kategoriyi gösterelim
    if (infoText.isEmpty) {
      infoText = recipe.category;
      infoIcon = Icons.category_outlined; // Farklı ikon kullanabiliriz
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim Alanı (Aynı kalabilir)
            SizedBox(
              width: 110,
              height: 110,
              child: Image.network(
                recipe.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) => progress == null
                    ? child
                    : Container(
                        color: Colors.grey[200],
                        child: Center(
                            child: Padding(
                                padding: const EdgeInsets.all(30.0),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: accentColor)))),
                errorBuilder: (ctx, err, st) => Container(
                    color: Colors.grey[200],
                    alignment: Alignment.center,
                    child: Icon(Icons.restaurant_menu,
                        color: Colors.grey[400], size: 40)),
              ),
            ),
            // İçerik Alanı
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 12.0, right: 4.0, top: 10.0, bottom: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Başlık
                    Text(
                      recipe.title,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8), // Boşluk artırıldı

                    // Alt Satır: Bilgi (Süre/Kategori) ve Trailing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Süre veya Kategori Bilgisi
                        if (infoText.isNotEmpty)
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(infoIcon,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    infoText,
                                    style: textTheme.bodySmall
                                        ?.copyWith(color: Colors.grey[700]),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Bilgi yoksa ve trailing varsa boşluk
                        if (infoText.isEmpty && trailing != null)
                          const Spacer(),

                        // Trailing Widget (Düzenle/Sil)
                        if (trailing != null)
                          Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: trailing!),
                      ],
                    ),
                    // İsteğe bağlı: Kullanıcı adı gösterilebilir
                    if (recipe.user?.username != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person_outline,
                              size: 12, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            recipe.user!.username,
                            style: textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
