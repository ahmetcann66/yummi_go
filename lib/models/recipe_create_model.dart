// lib/models/recipe_create_model.dart
class RecipeCreateModel {
  final String title;
  final String description;
  final String
      ingredients; // API'ye string olarak gönderilecek (\n ile ayrılmış)
  final String steps; // API'ye string olarak gönderilecek (\n ile ayrılmış)
  final String category;
  final String imageUrl;
  final String? videoUrl;
  final int? calories;
  final int? protein;
  final int? carbs;
  final int? fat;
  final int? cookingTimeInMinutes;

  RecipeCreateModel({
    required this.title,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.category,
    required this.imageUrl,
    this.videoUrl,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.cookingTimeInMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
      'category': category,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'cookingTimeInMinutes': cookingTimeInMinutes,
    };
  }
}
