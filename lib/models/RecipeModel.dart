// lib/models/recipe_model.dart
import 'UserModel.dart';

class RecipeModel {
  final int id;
  final String title;
  final String description; // final olduğu için initialize edilmeli
  final String ingredients;
  final String steps;
  final String category;
  final String imageUrl;
  final String? videoUrl;
  final int? calories;
  final int? protein;
  final int? carbs;
  final int? fat;
  final int? cookingTimeInMinutes;
  final int? userId;
  final UserModel? user;

  RecipeModel({
    required this.id,
    required this.title,
    required this.description, // <<< 'required' eklendi
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
    this.userId,
    this.user,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    // ... (fromJson içeriği aynı kalır) ...
    int? _parseIntOrNull(dynamic value) {/* ... */}
    String? _parseStringOrNull(dynamic value) {/* ... */}

    return RecipeModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Başlıksız Tarif',
      description:
          json['description'] as String? ?? '', // fromJson'da zaten vardı
      ingredients: json['ingredients'] as String? ?? '',
      steps: json['steps'] as String? ?? '',
      category: json['category'] as String? ?? 'Kategorisiz',
      imageUrl: json['imageUrl'] as String? ?? '',
      videoUrl: _parseStringOrNull(json['videoUrl']),
      calories: _parseIntOrNull(json['calories']),
      protein: _parseIntOrNull(json['protein']),
      carbs: _parseIntOrNull(json['carbs']),
      fat: _parseIntOrNull(json['fat']),
      cookingTimeInMinutes: _parseIntOrNull(json['cookingTimeInMinutes']),
      userId: _parseIntOrNull(json['userId']),
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    // ... (toJson içeriği aynı kalır) ...
    return {
      'id': id,
      'title': title,
      'description': description, // description zaten ekleniyordu
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
      'userId': userId ?? 0,
    };
  }
}
