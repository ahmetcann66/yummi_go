// lib/models/recipe_model.dart
class RecipeModel {
  final int id;
  final String title;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final String category;
  final String imageUrl;
  final String? videoUrl;
  final int? calories;
  final int? protein;
  final int? carbs;
  final int? fat;
  final int? cookingTimeInMinutes;
  final int likeCount;
  bool isLikedByCurrentUser; // State'i güncelleyebilmek için final değil

  RecipeModel({
    required this.id,
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
    required this.likeCount,
    required this.isLikedByCurrentUser,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic listData) {
      if (listData is List) {
        return List<String>.from(listData.map((item) => item.toString()));
      }
      return [];
    }

    return RecipeModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Başlıksız',
      description: json['description'] as String? ?? '',
      ingredients: parseList(json['ingredients']),
      steps: parseList(json['steps']),
      category: json['category'] as String? ?? 'Diğer',
      imageUrl: json['imageUrl'] as String? ??
          'https://via.placeholder.com/150?text=No+Image',
      videoUrl: json['videoUrl'] as String?,
      calories: json['calories'] as int?,
      protein: json['protein'] as int?,
      carbs: json['carbs'] as int?,
      fat: json['fat'] as int?,
      cookingTimeInMinutes: json['cookingTimeInMinutes'] as int?,
      likeCount: json['likeCount'] as int? ?? 0,
      isLikedByCurrentUser: json['isLikedByCurrentUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toCreateModelJson() {
    return {
      'title': title,
      'description': description,
      'ingredients': ingredients.join('\n'),
      'steps': steps.join('\n'),
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
