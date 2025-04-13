// lib/Recipe.dart

class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final int likeCount;
  final String description; // Bu alan önceki kodlarda vardı, korunuyor
  final List<String> ingredients;
  final List<String> steps;
  final String? videoUrl; // Bu alan önceki kodlarda vardı, korunuyor
  final int calories; // Bu alan önceki kodlarda vardı, korunuyor
  final int protein; // Bu alan önceki kodlarda vardı, korunuyor
  final int carbs; // Bu alan önceki kodlarda vardı, korunuyor
  final int fat; // Bu alan önceki kodlarda vardı, korunuyor
  final String category;
  final int? cookingTimeInMinutes;
  final String? authorId; // <-- Güncellendi: Eklendi

  const Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.likeCount,
    required this.description, // Constructor'da korunuyor
    required this.ingredients,
    required this.steps,
    this.videoUrl, // Constructor'da korunuyor
    required this.calories, // Constructor'da korunuyor
    required this.protein, // Constructor'da korunuyor
    required this.carbs, // Constructor'da korunuyor
    required this.fat, // Constructor'da korunuyor
    required this.category,
    this.cookingTimeInMinutes,
    this.authorId, // <-- Güncellendi: Constructor'a eklendi (opsiyonel)
  });
}
