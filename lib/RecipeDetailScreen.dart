import 'package:flutter/material.dart';
import '../models/RecipeModel.dart';
import '../models/UserModel.dart'; // UserModel gerekebilir
// import 'package:url_launcher/url_launcher.dart'; // videoUrl için gerekebilir

class RecipeDetailScreen extends StatelessWidget {
  final RecipeModel recipe;

  const RecipeDetailScreen({Key? key, required this.recipe}) : super(key: key);

  // Pişirme süresini formatla
  String _formatCookingTime(int? minutes) {
    if (minutes == null || minutes <= 0) return '-';
    if (minutes < 60) return '${minutes}dk';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) return '${hours}sa';
    return '${hours}sa ${remainingMinutes}dk';
  }

  // Besin değeri öğesi
  Widget _buildNutritionItem(
      BuildContext context, String label, int? value, String unit) {
    if (value == null || value <= 0) return const SizedBox.shrink();
    return Column(
      children: [
        Text(value.toString(),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text("$label ($unit)",
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey[600])),
      ],
    );
  }

  // String'i satırlara bölüp liste widget'ı oluşturan yardımcı metot
  Widget _buildMultilineTextSection(
      BuildContext context, String title, String textContent,
      {bool numbered = false}) {
    if (textContent.trim().isEmpty) return const SizedBox.shrink();

    final lines = textContent
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    if (lines.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          SizedBox(height: numbered ? 12 : 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(lines.length, (index) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: numbered ? 6.0 : 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (numbered) // Numaralı liste ise
                      Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(right: 12.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      )
                    else // Numarasız liste ise (malzemeler)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0, top: 4.0),
                        child: Icon(Icons.circle,
                            size: 8,
                            color: Theme.of(context).colorScheme.secondary),
                      ),
                    Expanded(
                      child: Text(lines[index],
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(height: 1.4)),
                    ),
                  ],
                ),
              );
            }),
          ),
          if (numbered)
            const SizedBox(height: 8), // Numaralı liste sonrası ekstra boşluk
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        // actions: [ ... Share/Favorite actions ... ]
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tarif Resmi (Aynı kalabilir)
            Hero(
              tag: 'recipeImage_${recipe.id}',
              child: Image.network(
                /* ... Image.network kodu aynı ... */
                recipe.imageUrl,
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.35,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) => progress == null
                    ? child
                    : Container(
                        height: MediaQuery.of(context).size.height * 0.35,
                        color: Colors.grey[200],
                        child: Center(
                            child: CircularProgressIndicator(
                                color: colorScheme.secondary))),
                errorBuilder: (ctx, err, st) => Container(
                    height: MediaQuery.of(context).size.height * 0.35,
                    color: Colors.grey[200],
                    child: Center(
                        child: Icon(Icons.broken_image,
                            size: 60, color: Colors.grey[400]))),
              ),
            ),

            // 2. Başlık ve Temel Bilgiler
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe.title,
                      style: textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    // Kategori ve Kullanıcı Adı yan yana
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(recipe.category,
                          style: textTheme.titleMedium
                              ?.copyWith(color: colorScheme.secondary)),
                      if (recipe.user?.username != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_pin,
                                size: 14, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text(recipe.user!.username,
                                style: textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600])),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Sadece Pişirme Süresi
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 18, color: colorScheme.secondary),
                      const SizedBox(width: 6),
                      Text('Pişirme Süresi:',
                          style: textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600])),
                      const SizedBox(width: 4),
                      Text(_formatCookingTime(recipe.cookingTimeInMinutes),
                          style: textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  // Video URL butonu (varsa)
                  if (recipe.videoUrl != null &&
                      recipe.videoUrl!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.play_circle_outline, size: 18),
                      label: const Text('Tarif Videosu'),
                      onPressed: () async {
                        // TODO: url_launcher paketini ekleyip videoyu aç
                        // final Uri videoUri = Uri.parse(recipe.videoUrl!);
                        // if (await canLaunchUrl(videoUri)) {
                        //   await launchUrl(videoUri);
                        // } else {
                        //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video açılamadı: ${recipe.videoUrl}')));
                        // }
                        print("Video URL Tıklandı: ${recipe.videoUrl}");
                      },
                      style: ElevatedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                    )
                  ]
                ],
              ),
            ),

            // Besin Değerleri Bölümü
            if (recipe.calories != null ||
                recipe.protein != null ||
                recipe.carbs != null ||
                recipe.fat != null) ...[
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Besin Değerleri (Yaklaşık)',
                        style: textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNutritionItem(
                            context, 'Kalori', recipe.calories, 'kcal'),
                        _buildNutritionItem(
                            context, 'Protein', recipe.protein, 'g'),
                        _buildNutritionItem(
                            context, 'Karbonhidrat', recipe.carbs, 'g'),
                        _buildNutritionItem(context, 'Yağ', recipe.fat, 'g'),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Açıklama Bölümü (Aynı kalabilir)
            if (recipe.description.isNotEmpty) ...[
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Açıklama', style: textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(recipe.description,
                        style: textTheme.bodyLarge?.copyWith(height: 1.5)),
                  ],
                ),
              ),
            ],

            // Malzemeler Bölümü (String'i bölecek şekilde güncellendi)
            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
            _buildMultilineTextSection(
                context, 'Malzemeler', recipe.ingredients,
                numbered: false),

            // Yapılış Talimatları Bölümü (String'i bölecek ve numaralandıracak şekilde güncellendi)
            const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
            _buildMultilineTextSection(
                context, 'Yapılış Talimatları', recipe.steps,
                numbered: true),

            const SizedBox(height: 30), // En alta boşluk
          ],
        ),
      ),
    );
  }
}
