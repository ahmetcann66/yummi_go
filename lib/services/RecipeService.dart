import 'dart:convert';
import 'package:http/http.dart' as http;

class RecipeService {
  final String baseUrl;

  RecipeService({required this.baseUrl});

  Future<List<Recipe>> getRecipes() async {
    final response = await http.get(Uri.parse('$baseUrl/api/Recipes'));

    if (response.statusCode == 200) {
      // Eğer istek başarılıysa, JSON verisini çöz ve Recipe listesine dönüştür.
      final List<dynamic> recipeJson = jsonDecode(response.body);
      return recipeJson.map((json) => Recipe.fromJson(json)).toList();
    } else {
      // Eğer istek başarısız olursa, bir hata fırlat.
      throw Exception(
          'Tarifler yüklenirken hata oluştu: ${response.statusCode}');
    }
  }

  Future<Recipe?> getRecipe(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/Recipes/$id'));

    if (response.statusCode == 200) {
      return Recipe.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null; // Tarif bulunamadı
    } else {
      throw Exception('Tarif yüklenirken hata oluştu: ${response.statusCode}');
    }
  }

  Future<Recipe> addRecipe(Recipe recipe) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Recipes'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(recipe.toJson()),
    );

    if (response.statusCode == 201) {
      return Recipe.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Tarif eklenirken hata oluştu: ${response.statusCode}');
    }
  }

  Future<Recipe> updateRecipe(int id, Recipe recipe) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/Recipes/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(recipe.toJson()),
    );

    if (response.statusCode == 204) {
      return recipe; // Başarılı güncelleme, API 204 No Content dönebilir.
    } else {
      throw Exception(
          'Tarif güncellenirken hata oluştu: ${response.statusCode}');
    }
  }

  Future<void> deleteRecipe(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/Recipes/$id'),
    );

    if (response.statusCode != 204) {
      throw Exception('Tarif silinirken hata oluştu: ${response.statusCode}');
    }
  }
}

class Recipe {
  final int id;
  final String title;
  final String description;
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
  final int userId;

  Recipe({
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
    required this.userId,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      ingredients: json['ingredients'],
      steps: json['steps'],
      category: json['category'],
      imageUrl: json['imageUrl'],
      videoUrl: json['videoUrl'],
      calories: json['calories'],
      protein: json['protein'],
      carbs: json['carbs'],
      fat: json['fat'],
      cookingTimeInMinutes: json['cookingTimeInMinutes'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'userId': userId,
    };
  }
}
