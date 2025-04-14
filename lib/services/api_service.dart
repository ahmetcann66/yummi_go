// lib/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';
import '../models/recipe_create_model.dart'; // Eğer tarif oluşturma modeliniz farklıysa
import '../models/LoginModel.dart';
import '../models/UserModel.dart';

class ApiService {
  final String baseUrl = 'https://localhost:7053'; // API'nizin temel URL'si

  // --- KATEGORİLER ---
  Future<List<String>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/api/Categories'));
    if (response.statusCode == 200) {
      final List<dynamic> categoryJson = jsonDecode(response.body);
      return categoryJson.map((json) => json['name'] as String).toList();
    } else {
      throw Exception(
          'Kategoriler yüklenirken hata oluştu: ${response.statusCode}');
    }
  }

  // --- TARİFLER ---
  Future<List<RecipeModel>> getAllRecipes() async {
    final response = await http.get(Uri.parse('$baseUrl/api/Recipes'));
    if (response.statusCode == 200) {
      final List<dynamic> recipeJson = jsonDecode(response.body);
      return recipeJson.map((json) => RecipeModel.fromJson(json)).toList();
    } else {
      throw Exception(
          'Tarifler yüklenirken hata oluştu: ${response.statusCode}');
    }
  }

  Future<RecipeModel> getRecipe(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/api/Recipes/$id'));
    if (response.statusCode == 200) {
      return RecipeModel.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      throw Exception('Tarif bulunamadı.');
    } else {
      throw Exception('Tarif yüklenirken hata oluştu: ${response.statusCode}');
    }
  }

  // --- FİLTRELENMİŞ TARİFLER ---
  Future<List<RecipeModel>> getRecipes(
      {String? category, String? search, List<String>? ingredients}) async {
    final Uri uri = Uri.parse('$baseUrl/api/Recipes').replace(
      queryParameters: <String, dynamic>{
        if (category != null && category.isNotEmpty) 'category': category,
        if (search != null && search.isNotEmpty) 'search': search,
        if (ingredients != null && ingredients.isNotEmpty)
          'ingredients': jsonEncode(ingredients),
        // if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy, // Eğer API destekliyorsa
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> recipeJson = jsonDecode(response.body);
      return recipeJson.map((json) => RecipeModel.fromJson(json)).toList();
    } else {
      throw Exception(
          'Tarifler yüklenirken hata oluştu: ${response.statusCode}');
    }
  }

  Future<List<RecipeModel>> getRecipesByUserId(int userId) async {
    final Uri uri = Uri.parse(
        '$baseUrl/api/Users/$userId/Recipes'); // Örnek endpoint yapısı

    print('Recipes by UserId API İstek URL: $uri'); // LOG EKLEDİM

    final response = await http.get(uri);

    print(
        'Recipes by UserId API Yanıt Status Kodu: ${response.statusCode}'); // LOG EKLEDİM
    print('Recipes by UserId API Yanıt Body: ${response.body}'); // LOG EKLEDİM

    if (response.statusCode == 200) {
      final List<dynamic> recipeJson = jsonDecode(response.body);
      return recipeJson.map((json) => RecipeModel.fromJson(json)).toList();
    } else if (response.statusCode == 404) {
      throw Exception('Kullanıcıya ait tarif bulunamadı.');
    } else {
      throw Exception(
          'Kullanıcının tarifleri yüklenirken hata oluştu: ${response.statusCode}');
    }
  }

  Future<RecipeModel> createRecipe(RecipeCreateModel recipeData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Recipes'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(recipeData.toJson()),
    );

    if (response.statusCode == 201) {
      return RecipeModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Tarif eklenirken hata oluştu: ${response.statusCode}');
    }
  }

  Future<void> updateRecipe(int id, RecipeCreateModel recipeData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/Recipes/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(recipeData.toJson()),
    );

    if (response.statusCode == 204) {
      return; // Başarılı güncelleme, içerik yok
    } else if (response.statusCode == 404) {
      throw Exception('Tarif bulunamadı.');
    } else {
      throw Exception(
          'Tarif güncellenirken hata oluştu: ${response.statusCode}');
    }
  }

  Future<void> deleteRecipe(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/Recipes/$id'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 204) {
      return; // Başarılı silme, içerik yok
    } else if (response.statusCode == 404) {
      throw Exception('Silinecek tarif bulunamadı.');
    } else {
      throw Exception('Tarif silinirken hata oluştu: ${response.statusCode}');
    }
  }

  // --- KULLANICININ TARİFLERİ ---
  Future<List<RecipeModel>> getMyRecipes() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/Users/me/Recipes'), // Örnek endpoint
      // Eğer yetkilendirme gerekiyorsa header'a token eklemeniz gerekebilir:
      // headers: {'Authorization': 'Bearer YOUR_AUTH_TOKEN'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> recipeJson = jsonDecode(response.body);
      return recipeJson.map((json) => RecipeModel.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Yetkisiz erişim. Lütfen giriş yapın.');
    } else {
      throw Exception(
          'Tarifleriniz yüklenirken hata oluştu: ${response.statusCode}');
    }
  }

  // --- BEĞENME İŞLEMLERİ ---
  Future<void> likeRecipe(int recipeId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/Recipes/$recipeId/Like'),
      // Eğer yetkilendirme gerekiyorsa header'a token eklemeniz gerekebilir:
      // headers: {'Authorization': 'Bearer YOUR_AUTH_TOKEN'},
    );

    if (response.statusCode == 200) {
      return; // Başarılı beğeni
    } else if (response.statusCode == 401) {
      throw Exception('Beğenmek için giriş yapmalısınız.');
    } else if (response.statusCode == 404) {
      throw Exception('Beğenilecek tarif bulunamadı.');
    } else {
      throw Exception(
          'Tarif beğenilirken bir hata oluştu: ${response.statusCode}');
    }
  }

  Future<void> unlikeRecipe(int recipeId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/Recipes/$recipeId/Unlike'),
      // Eğer yetkilendirme gerekiyorsa header'a token eklemeniz gerekebilir:
      // headers: {'Authorization': 'Bearer YOUR_AUTH_TOKEN'},
    );

    if (response.statusCode == 200) {
      return; // Beğeni geri alındı
    } else if (response.statusCode == 401) {
      throw Exception('Beğeniyi geri almak için giriş yapmalısınız.');
    } else if (response.statusCode == 404) {
      throw Exception('Beğenisi geri alınacak tarif bulunamadı.');
    } else {
      throw Exception(
          'Tarif beğenisi geri alınırken bir hata oluştu: ${response.statusCode}');
    }
  }

  Future<UserModel?> login(LoginModel loginData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/User/login'), // Doğru endpoint
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8', // Doğru içerik tipi
      },
      body: jsonEncode(loginData.toJson()), // LoginModel'i JSON'a dönüştür
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return UserModel.fromJson(
          responseData); // UserModel.fromJson ile parse et
    } else if (response.statusCode == 401) {
      final String errorMessage =
          response.body; // Hata mesajını body'den alıyoruz
      throw Exception(errorMessage.isNotEmpty
          ? errorMessage
          : 'Kullanıcı adı veya şifre hatalı.');
    } else {
      throw Exception('Giriş yapılamadı: ${response.statusCode}');
    }
  }

  // --- EN POPÜLER TARİFLERİ GETİR (Filtreleme ile) ---
  Future<List<RecipeModel>> getTopRatedRecipes({int limit = 5}) async {
    // Eğer API'nizde popüler tarifler için özel bir filtreleme veya sıralama
    // mekanizması varsa, burayı ona göre düzenleyin. Örneğin, beğeni sayısına
    // göre sıralama veya belirli bir kategoriye göre filtreleme gibi.
    // Şu anda sadece ilk 'limit' kadar tarifi alıyoruz.
    final List<RecipeModel> allRecipes = await getAllRecipes();
    // Burada suni bir popülerlik sıralaması yapılıyor (gerçekte API'den gelmeli).
    // Bu satırı API'nizin popülerlik mekanizmasına göre düzenleyin.
    allRecipes.sort((a, b) => (b.likeCount ?? 0).compareTo(a.likeCount ?? 0));
    return allRecipes.take(limit).toList();
  }
}
