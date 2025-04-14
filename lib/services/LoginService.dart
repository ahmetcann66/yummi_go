// lib/services/LoginService.dart

import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart'; // CookieJar importu
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/UserModel.dart';

// ApiResponse tanımı burada veya ayrı bir dosyada olabilir
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  ApiResponse({required this.success, this.data, this.message});
}

class LoginService {
  late final Dio _dio;
  // final CookieJar _cookieJar = CookieJar(); // <<< BU SATIRI SİLİN veya YORUM YAPIN
  final CookieJar _sharedCookieJar; // <<< Paylaşılan CookieJar'ı tutacak alan

  static const String _baseUrl = 'https://localhost:7053';

  // <<< CONSTRUCTOR'I GÜNCELLEYİN: CookieJar parametresi ekleyin >>>
  LoginService(this._sharedCookieJar) {
    try {
      final options = BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      _dio = Dio(options);

      if (!kIsWeb) {
        // <<< PAYLAŞILAN CookieJar'ı CookieManager'a verin >>>
        _dio.interceptors.add(CookieManager(_sharedCookieJar));
        print("LoginService: CookieManager paylaşılan jar ile eklendi.");
      }
      // LogInterceptor vb. burada kalabilir
      _dio.interceptors.add(LogInterceptor(
          requestBody: true, responseBody: true /* ... diğer ayarlar ... */));
      // ... (sertifika atlama kodu varsa) ...
      print(
          "LoginService constructor başarıyla tamamlandı (paylaşılan jar ile).");
    } catch (e, stackTrace) {
      print("LoginService CONSTRUCTOR HATASI: $e");
      print("StackTrace: $stackTrace");
      // Burada bir hata olursa, Dio düzgün başlatılamayabilir.
      // Uygulamanın durumuna göre bir hata fırlatmak veya varsayılan bir Dio atamak gerekebilir.
      // Şimdilik sadece logluyoruz.
    }
  }

  // login metodu aynı kalır...
  Future<ApiResponse<UserModel>> login(String username, String password) async {
    // ... (Metodun içeriği değişmez) ...
    try {
      print("Login isteği gönderiliyor: /api/User/login"); // İstek logu
      final response = await _dio.post('/api/User/login', data: {
        'username': username,
        'password': password,
      });
      print(
          "Login yanıtı alındı: statusCode=${response.statusCode}"); // Yanıt logu

      if (response.statusCode == 200) {
        final responseData = response.data;
        print("Yanıt verisi (response.data): $responseData");
        print("Yanıt verisi tipi: ${responseData.runtimeType}");

        if (responseData is Map) {
          final responseMap = Map<String, dynamic>.from(responseData);
          print("Yanıt verisi Map'e çevrildi: $responseMap");
          final userJsonData = responseMap['user'];
          print("'user' anahtarı verisi: $userJsonData");
          print("'user' anahtarı tipi: ${userJsonData?.runtimeType}");

          if (userJsonData != null && userJsonData is Map) {
            final userMap = Map<String, dynamic>.from(userJsonData);
            print("'user' verisi Map'e çevrildi: $userMap");
            try {
              print("UserModel.fromJson çağrılıyor...");
              final user = UserModel.fromJson(userMap);
              print("UserModel başarıyla oluşturuldu: ${user.username}");
              return ApiResponse<UserModel>(
                success: true,
                data: user,
                message: responseMap['message'] as String? ?? 'Giriş başarılı.',
              );
            } catch (e, stackTrace) {
              print("UserModel.fromJson sırasında HATA: $e");
              print("UserModel.fromJson StackTrace: $stackTrace");
              return ApiResponse<UserModel>(
                  success: false, message: "Kullanıcı verisi işlenemedi.");
            }
          } else {
            print(
                "LoginService Hata: API yanıtında (200 OK) 'user' nesnesi bulunamadı veya geçersiz. Yanıt: $responseData");
            return ApiResponse<UserModel>(
                success: false,
                message: "API yanıtında kullanıcı bilgisi bulunamadı.");
          }
        } else {
          print(
              "LoginService Hata: API yanıtı (200 OK) beklenilen formatta değil (Map değil). Yanıt: $responseData");
          return ApiResponse<UserModel>(
              success: false, message: "API'den beklenmeyen yanıt formatı.");
        }
      } else {
        return ApiResponse<UserModel>(
          success: false,
          message: 'Giriş başarısız (Kod: ${response.statusCode}).',
        );
      }
    } on DioException catch (e) {
      print("Login DioException: ${e.message} - ${e.response?.data}");
      return _handleDioError<UserModel>(e);
    } catch (e, stackTrace) {
      print("Login içindeki GENEL CATCH HATASI: $e");
      print("Login GENEL CATCH StackTrace: $stackTrace");
      return ApiResponse<UserModel>(
          success: false, message: 'Bilinmeyen bir hata oluştu.');
    }
  }

  // _handleDioError metodu aynı kalır...
  ApiResponse<T> _handleDioError<T>(DioException e) {
    // ... (Metodun içeriği değişmez) ...
    String errorMessage = "Bir hata oluştu.";
    if (e.response != null) {
      errorMessage =
          'Sunucu hatası (Kod: ${e.response?.statusCode}). ${e.response?.data?['message'] ?? ''}'
              .trim();
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      errorMessage = 'Sunucuya bağlanırken zaman aşımı oluştu.';
    } else if (e.type == DioExceptionType.cancel) {
      errorMessage = 'İstek iptal edildi.';
    } else if (e.type == DioExceptionType.connectionError) {
      errorMessage = 'İnternet bağlantısı kurulamadı.';
    } else if (e.type == DioExceptionType.badCertificate) {
      errorMessage = 'Güvenli bağlantı kurulamadı (Sertifika hatası).';
    }
    print("LoginService API Hatası: ${e.message} - ${e.response?.data}");
    return ApiResponse<T>(success: false, message: errorMessage);
  }
}
