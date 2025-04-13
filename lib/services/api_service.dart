// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io'; // HttpOverrides için
import 'package:flutter/foundation.dart'; // kReleaseMode için
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';
import '../models/user_model.dart';
import '../models/login_model.dart';
import '../models/register_model.dart';
import '../models/recipe_create_model.dart';

/// Geliştirme ortamında HTTPS sertifika doğrulamasını devre dışı bırakır.
/// NOT: Bu ayar yalnızca geliştirme modunda kullanılmalı, üretimde kaldırılmalıdır.
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

/// Uygulama başlangıcında [MyHttpOverrides]'ı devreye sokar.
void initializeHttpOverrides() {
  if (!kReleaseMode) {
    HttpOverrides.global = MyHttpOverrides();
    print("!!! Geliştirme modunda: HTTPS sertifika doğrulaması atlanıyor. !!!");
  }
}

class ApiService {
  // Program.cs dosyamızda HTTPS ve port bilgisi bu şekilde tanımlanmıştı.
  static const String _baseUrl = "https://localhost:7053/api";

  /// Tüm isteklerde aynı Client örneğini kullanarak cookie yönetimini sağlıyoruz.
  final http.Client _client = http.Client();

  /// (Debug amaçlı) İstek ve yanıt header bilgilerini loglar.
  void _logHeaders(String requestType, String url, String method,
      {Map<String, String>? requestHeaders, http.Response? response}) {
    if (!kReleaseMode) {
      print("\n--- $requestType ($method $url) ---");
      if (requestHeaders != null) {
        print(">> Request Headers:");
        requestHeaders.forEach((key, value) => print("   $key: $value"));
        print("   (Cookie header'ı otomatik eklenir, burada görünmeyebilir)");
      }
      if (response != null) {
        print("<< Response Status: ${response.statusCode}");
        print("<< Response Headers:");
        response.headers.forEach((key, value) => print("   $key: $value"));
      }
      print("---------------------------------------\n");
    }
  }

  // --- Tarif İşlemleri ---

  Future<List<RecipeModel>> getRecipes({
    String? category,
    String? search,
    String? searchField,
    String? sortBy,
    List<String>? ingredients,
    int? limit,
  }) async {
    // Query parametrelerini sadeleştirerek ekliyoruz.
    final uri = _buildUri(
      '/recipes',
      {
        'category': category,
        'search': search,
        'searchField': searchField,
        'sortBy': sortBy,
        'limit': limit?.toString(),
        // Eğer API'niz malzemeleri virgülle ayrılmış string olarak bekliyorsa:
        if (ingredients != null && ingredients.isNotEmpty)
          'ingredients': ingredients.join(',')
      },
    );
    print("API Request: GET $uri");
    try {
      final response = await _client.get(uri);
      _logHeaders("Get Recipes", uri.toString(), "GET", response: response);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List;
        return decoded
            .map<RecipeModel>((item) => RecipeModel.fromJson(item))
            .toList();
      } else {
        throw _handleError(response, 'Tarifler yüklenemedi');
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<RecipeModel> getRecipeById(int id) async {
    final uri = _buildUri('/recipes/$id');
    print("API Request: GET $uri");
    try {
      final response = await _client.get(uri);
      _logHeaders("Get Recipe By ID", uri.toString(), "GET",
          response: response);
      if (response.statusCode == 200) {
        return RecipeModel.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Tarif bulunamadı.');
      } else {
        throw _handleError(response, 'Tarif detayı yüklenemedi');
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<RecipeModel> createRecipe(RecipeCreateModel recipeData) async {
    final uri = _buildUri('/recipes');
    print("API Request: POST $uri");
    final requestHeaders = _jsonHeaders();
    _logHeaders("Create Recipe", uri.toString(), "POST",
        requestHeaders: requestHeaders);
    try {
      final response = await _client.post(
        uri,
        headers: requestHeaders,
        body: jsonEncode(recipeData.toJson()),
      );
      _logHeaders("Create Recipe", uri.toString(), "POST", response: response);
      if (response.statusCode == 201) {
        return RecipeModel.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Yetkisiz: Tarif eklemek için giriş yapmalısınız.');
      } else {
        throw _handleError(response, 'Tarif oluşturulamadı');
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<void> updateRecipe(int id, RecipeCreateModel recipeData) async {
    final uri = _buildUri('/recipes/$id');
    final requestHeaders = _jsonHeaders();
    print("API Request: PUT $uri");
    _logHeaders("Update Recipe", uri.toString(), "PUT",
        requestHeaders: requestHeaders);
    try {
      final response = await _client.put(
        uri,
        headers: requestHeaders,
        body: jsonEncode(recipeData.toJson()),
      );
      _logHeaders("Update Recipe", uri.toString(), "PUT", response: response);
      if (response.statusCode == 204)
        return;
      else if (response.statusCode == 401) {
        throw Exception('Yetkisiz: Bu tarifi güncellemek için yetkiniz yok.');
      } else if (response.statusCode == 404) {
        throw Exception('Güncellenecek tarif bulunamadı.');
      } else {
        throw _handleError(response, 'Tarif güncellenemedi');
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<void> deleteRecipe(int id) async {
    final uri = _buildUri('/recipes/$id');
    print("API Request: DELETE $uri");
    _logHeaders("Delete Recipe", uri.toString(), "DELETE");
    try {
      final response = await _client.delete(uri);
      _logHeaders("Delete Recipe", uri.toString(), "DELETE",
          response: response);
      if (response.statusCode == 204)
        return;
      else if (response.statusCode == 401) {
        throw Exception('Yetkisiz: Bu tarifi silmek için yetkiniz yok.');
      } else if (response.statusCode == 404) {
        throw Exception('Silinecek tarif bulunamadı.');
      } else {
        throw _handleError(response, 'Tarif silinemedi');
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<void> likeRecipe(int id) async {
    final uri = _buildUri('/recipes/$id/like');
    print("API Request: POST $uri");
    _logHeaders("Like Recipe", uri.toString(), "POST");
    try {
      final response = await _client.post(uri);
      _logHeaders("Like Recipe", uri.toString(), "POST", response: response);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print(jsonDecode(response.body)['message']);
        return;
      } else if (response.statusCode == 401) {
        throw Exception('Yetkisiz: Beğenmek için giriş yapmalısınız.');
      } else if (response.statusCode == 404) {
        throw Exception('Beğenilecek tarif bulunamadı.');
      } else {
        throw _handleError(response, 'Tarif beğenilemedi');
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<void> unlikeRecipe(int id) async {
    final uri = _buildUri('/recipes/$id/like');
    print("API Request: DELETE $uri");
    _logHeaders("Unlike Recipe", uri.toString(), "DELETE");
    try {
      final response = await _client.delete(uri);
      _logHeaders("Unlike Recipe", uri.toString(), "DELETE",
          response: response);
      if (response.statusCode == 200) {
        print(jsonDecode(response.body)['message']);
        return;
      } else if (response.statusCode == 401) {
        throw Exception(
            'Yetkisiz: Beğeniyi geri almak için giriş yapmalısınız.');
      } else if (response.statusCode == 404) {
        throw Exception('Beğenisi geri alınacak tarif bulunamadı.');
      } else {
        throw _handleError(response, 'Tarif beğenisi geri alınamadı');
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<List<String>> getCategories() async {
    final uri = _buildUri('/recipes/categories');
    print("API Request: GET $uri");
    try {
      final response = await _client.get(uri);
      _logHeaders("Get Categories", uri.toString(), "GET", response: response);
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => item.toString()).toList();
      } else {
        throw _handleError(response, 'Kategoriler yüklenemedi');
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  // --- Kullanıcı İşlemleri ---

  Future<UserModel> registerUser(RegisterModel registerData) async {
    final uri = _buildUri('/user/register');
    print("API Request: POST $uri");
    final requestHeaders = _jsonHeaders();
    _logHeaders("Register User", uri.toString(), "POST",
        requestHeaders: requestHeaders);
    try {
      final response = await _client.post(
        uri,
        headers: requestHeaders,
        body: jsonEncode(registerData.toJson()),
      );
      _logHeaders("Register User", uri.toString(), "POST", response: response);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return UserModel.fromJson(jsonDecode(response.body)['user']);
      } else if (response.statusCode == 400) {
        throw Exception(
            'Kayıt başarısız: ${jsonDecode(response.body)['message']}');
      } else {
        throw _handleError(response, 'Kayıt oluşturulamadı');
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<UserModel> loginUser(LoginModel loginData) async {
    final uri = _buildUri('/user/login');
    print("API Request: POST $uri");
    final requestHeaders = _jsonHeaders();
    _logHeaders("Login User", uri.toString(), "POST",
        requestHeaders: requestHeaders);
    try {
      final response = await _client.post(
        uri,
        headers: requestHeaders,
        body: jsonEncode(loginData.toJson()),
      );
      _logHeaders("Login User", uri.toString(), "POST", response: response);
      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body)['user']);
      } else if (response.statusCode == 401) {
        throw Exception('Giriş başarısız: Kullanıcı adı veya şifre hatalı.');
      } else {
        throw _handleError(response, 'Giriş yapılamadı');
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<void> logoutUser() async {
    final uri = _buildUri('/user/logout');
    print("API Request: POST $uri");
    _logHeaders("Logout User", uri.toString(), "POST");
    try {
      final response = await _client.post(uri);
      _logHeaders("Logout User", uri.toString(), "POST", response: response);
      if (response.statusCode == 200) {
        print('Logout başarılı.');
      } else {
        print("API Hatası [${response.statusCode}]: ${response.body}");
      }
    } catch (e) {
      print("API Bağlantı Hatası: $e");
    }
  }

  Future<UserModel> getCurrentUser() async {
    final uri = _buildUri('/user/me');
    print("API Request: GET $uri");
    _logHeaders("Get Current User", uri.toString(), "GET");
    try {
      final response = await _client.get(uri);
      _logHeaders("Get Current User", uri.toString(), "GET",
          response: response);
      if (response.statusCode == 200) {
        return UserModel.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 401) {
        throw Exception('Yetkisiz: Oturum açık değil.');
      } else {
        throw _handleError(response, 'Kullanıcı bilgisi alınamadı');
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  Future<List<RecipeModel>> getMyRecipes() async {
    final uri = _buildUri('/user/me/recipes');
    print("API Request: GET $uri");
    _logHeaders("Get My Recipes", uri.toString(), "GET");
    try {
      final response = await _client.get(uri);
      _logHeaders("Get My Recipes", uri.toString(), "GET", response: response);
      if (response.statusCode == 200) {
        final List<dynamic> body = jsonDecode(response.body);
        return body.map((item) => RecipeModel.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        throw Exception(
            'Yetkisiz: Tariflerinizi görmek için giriş yapmalısınız.');
      } else {
        throw _handleError(response, 'Tarifleriniz yüklenemedi');
      }
    } catch (e) {
      throw _handleConnectionError(e);
    }
  }

  // --- Yardımcı Metotlar ---
  Map<String, String> _jsonHeaders() =>
      {'Content-Type': 'application/json; charset=UTF-8'};

  /// Temel URL ile verilen path'i ve varsa query parametrelerini birleştirir.
  Uri _buildUri(String path, [Map<String, String?>? queryParameters]) {
    var baseUri = Uri.parse(_baseUrl);
    // baseUri içindeki path sonuna yeni path'i ekliyoruz
    String finalPath = baseUri.path + path;
    return baseUri.replace(
      path: finalPath,
      queryParameters:
          queryParameters?.map((key, value) => MapEntry(key, value!)),
    );
  }

  Exception _handleConnectionError(dynamic e) {
    print("API Bağlantı Hatası Detayı: $e");
    if (e is SocketException) {
      return Exception(
          'API sunucusuna bağlanılamadı. İnternet bağlantınızı veya API adresini kontrol edin.');
    } else if (e is HandshakeException) {
      return Exception(
          'Güvenli bağlantı kurulamadı (Sertifika Hatası?). Geliştirme için HttpOverrides kontrol edin.');
    } else if (e is http.ClientException) {
      return Exception('Ağ hatası: ${e.message}');
    }
    return Exception('Bilinmeyen bir ağ hatası oluştu: $e');
  }

  Exception _handleError(http.Response response, String defaultMessage) {
    print("API Hatası [${response.statusCode}]: ${response.body}");
    try {
      final errorBody = jsonDecode(response.body);
      if (errorBody is Map && errorBody.containsKey('message')) {
        return Exception(
            '$defaultMessage: ${errorBody['message']} (${response.statusCode})');
      }
      if (errorBody is Map && errorBody.containsKey('errors')) {
        var errors = errorBody['errors'] as Map;
        if (errors.isNotEmpty) {
          var firstErrorField = errors.keys.first;
          var firstErrorMessages = errors[firstErrorField] as List;
          if (firstErrorMessages.isNotEmpty) {
            return Exception(
                '$defaultMessage: $firstErrorField - ${firstErrorMessages.first} (${response.statusCode})');
          }
        }
      }
    } catch (e) {
      print("Hata yanıtı parse edilemedi: ${response.body}");
    }
    return Exception('$defaultMessage (${response.statusCode})');
  }
}
