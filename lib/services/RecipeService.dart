// lib/services/RecipeService.dart

import 'dart:async'; // Future için
import 'dart:io'; // HttpClient, X509Certificate için (sertifika atlama)
import 'package:cookie_jar/cookie_jar.dart'; // Paylaşılan CookieJar için
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart'; // Dio için Cookie Yöneticisi
import 'package:dio/io.dart'; // IOHttpClientAdapter için
import 'package:flutter/foundation.dart'
    show kIsWeb; // Web platform kontrolü için
import 'package:yummi_go/AuthManager.dart'; // Oturum yönetimi (Yolu doğrulayın)
import '../models/RecipeModel.dart'; // Tarif modeli (Yolu doğrulayın)

// --- API Yanıt Modeli ---
// !!! TAVSİYE: Bu sınıfı projenizde merkezi bir dosyaya taşıyın !!!
// (örn: lib/models/api_response.dart veya lib/services/api_response.dart)
// ve hem LoginService hem de RecipeService bu ortak tanımı import etsin.
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;

  ApiResponse({required this.success, this.data, this.message});
}
// -------------------------

class RecipeService {
  late final Dio _dio; // Dio instance'ı geç başlatılacak
  final CookieJar _sharedCookieJar; // Dışarıdan sağlanan paylaşılan CookieJar
  final AuthManager _authManager =
      AuthManager(); // AuthManager Singleton instance'ı

  // API'nin temel URL'si (LoginService ile aynı olmalı)
  static const String _baseUrl =
      'https://localhost:7053'; // API adresini doğrulayın

  /// RecipeService constructor'ı.
  /// Paylaşılan bir [CookieJar] örneği alarak Dio istemcisini ve
  /// gerekli interceptor'ları (CookieManager, LogInterceptor, Sertifika Atlama) ayarlar.
  RecipeService(this._sharedCookieJar) {
    try {
      // Dio için temel ayarlar
      final options = BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout:
            const Duration(seconds: 15), // Bağlantı kurma zaman aşımı
        receiveTimeout: const Duration(seconds: 15), // Yanıt alma zaman aşımı
        headers: {
          'Content-Type': 'application/json', // Gönderilen verinin tipi
          'Accept': 'application/json', // Kabul edilen yanıt tipi
        },
        // Başarılı HTTP durum kodları (isteğe bağlı, Dio varsayılan olarak 2xx kabul eder)
        // validateStatus: (status) => status != null && status >= 200 && status < 300,
      );
      _dio = Dio(options); // Dio instance'ını oluştur

      // --- Interceptor'lar ---

      // 1. Cookie Yöneticisi (Web dışı platformlar için)
      if (!kIsWeb) {
        // Paylaşılan CookieJar'ı kullanarak oturum çerezlerini yönetir
        _dio.interceptors.add(CookieManager(_sharedCookieJar));
        print("RecipeService: CookieManager paylaşılan jar ile eklendi.");
      } else {
        // Web platformunda tarayıcı genellikle çerezleri yönetir.
        // 'withCredentials' gerekebilir (API CORS ayarları ve kimlik doğrulama türüne bağlı)
        print("RecipeService: CookieManager eklenmedi (Platform Web).");
        // Gerekirse deneyin: _dio.options.extra['withCredentials'] = true;
      }

      // 2. Loglama Interceptor'ı (Geliştirme/Hata Ayıklama için)
      _dio.interceptors.add(LogInterceptor(
        request: true, // İstek URL, metot
        requestHeader: true, // İstek başlıkları
        requestBody: true, // İstek gövdesi (JSON vb.)
        responseHeader: false, // Yanıt başlıkları (genellikle çok kalabalık)
        responseBody: true, // Yanıt gövdesi (JSON vb.)
        error: true, // Hataları logla
        logPrint: print, // Logları konsola yazdır
      ));

      // 3. HTTPS Sertifika Doğrulama Atlama (SADECE LOKAL GELİŞTİRME!)
      // localhost'ta kendi kendine imzalanmış (self-signed) sertifika kullanılıyorsa gereklidir.
      // !!! ASLA PRODUCTION ORTAMINDA KULLANMAYIN !!! GÜVENLİK AÇIĞI YARATIR !!!
      if (!kIsWeb) {
        // Sadece mobil/desktop platformlarında geçerli
        try {
          // Dio'nun HTTP istemci adaptörüne erişip sertifika doğrulamasını devre dışı bırak
          (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
              () {
            final client = HttpClient();
            // Tüm sertifikalara güven (güvensiz)
            client.badCertificateCallback =
                (X509Certificate cert, String host, int port) => true;
            return client;
          };
          print(
              "RecipeService: [UYARI] HTTPS SERTİFİKA DOĞRULAMASI ATLANDI (SADECE LOKAL!).");
        } catch (e) {
          // Adaptör tipi farklıysa veya başka bir sorun olursa logla
          print("RecipeService: Sertifika atlama ayarlanamadı (Hata: $e)");
        }
      }
      // --- Bitiş: Sertifika Atlama ---

      print(
          "RecipeService constructor başarıyla tamamlandı (paylaşılan jar: ${_sharedCookieJar.hashCode}).");
    } catch (e, stackTrace) {
      // Constructor sırasında bir hata olursa logla ve hatayı tekrar fırlat
      print("RecipeService CONSTRUCTOR'DA KRİTİK HATA: $e");
      print("StackTrace: $stackTrace");
      // Servis kullanılamaz durumda olacağı için hatayı yukarı iletmek önemlidir.
      throw Exception("RecipeService başlatılamadı: $e");
    }
  }

  // --- API METOTLARI ---

  /// Giriş yapmış kullanıcının tariflerini API'den alır.
  /// Oturum çerezi CookieManager tarafından otomatik olarak gönderilir.
  Future<ApiResponse<List<RecipeModel>>> getMyRecipes() async {
    // Aktif kullanıcı kontrolü (isteğe bağlı ama iyi pratik)
    if (_authManager.currentUserId == null) {
      print(
          "getMyRecipes Hata: Kullanıcı girişi gerekli (AuthManager'da ID yok).");
      return ApiResponse(
          success: false, message: "Tarifleri görmek için oturum açmalısınız.");
    }
    try {
      print("getMyRecipes isteği gönderiliyor: GET /api/Recipes");
      final response = await _dio.get('/api/Recipes');
      print("getMyRecipes yanıtı alındı: ${response.statusCode}");

      // API'nin 200 OK ile bir liste döndürdüğünü varsayıyoruz
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> responseData = response.data as List<dynamic>;
        final List<RecipeModel> recipes = responseData
            .map((json) => RecipeModel.fromJson(json as Map<String, dynamic>))
            .toList();
        print(
            "getMyRecipes: ${recipes.length} tarif başarıyla alındı ve işlendi.");
        return ApiResponse<List<RecipeModel>>(success: true, data: recipes);
      } else {
        // Yanıt formatı beklenenden farklıysa veya durum kodu 200 değilse
        print(
            "getMyRecipes Hatası: Beklenmeyen yanıt formatı veya durum kodu ${response.statusCode}. Yanıt: ${response.data}");
        return ApiResponse<List<RecipeModel>>(
          success: false,
          message:
              'Tarifler alınamadı (Kod: ${response.statusCode}). Yanıt formatı geçersiz olabilir.',
        );
      }
    } on DioException catch (e) {
      // Dio hatalarını özel olarak ele al
      print("getMyRecipes DioException: ${e.message}");
      if (e.response?.statusCode == 401) {
        // Yetkisiz erişim
        print("getMyRecipes: 401 Yetkisiz. Oturum sonlanmış veya geçersiz.");
        return ApiResponse<List<RecipeModel>>(
            success: false,
            message:
                "Oturumunuz geçersiz veya süresi dolmuş. Lütfen tekrar giriş yapın.");
      }
      return _handleDioError<List<RecipeModel>>(e,
          defaultMessage: "Tarifler yüklenirken bir hata oluştu.");
    } catch (e, stackTrace) {
      // Diğer beklenmedik hatalar
      print("getMyRecipes Beklenmedik Hata: $e");
      print("getMyRecipes StackTrace: $stackTrace");
      return ApiResponse<List<RecipeModel>>(
          success: false,
          message: 'Tarifler alınırken beklenmeyen bir hata oluştu.');
    }
  }

  /// Yeni bir tarif ekler.
  /// [recipe] modelini alır, [AuthManager]'dan aldığı userId'yi ekler ve API'ye gönderir.
  Future<ApiResponse<RecipeModel>> addRecipe(RecipeModel recipe) async {
    // Aktif kullanıcı ID'sini al
    final int? currentUserId = _authManager.currentUserId;

    // Kullanıcı ID'si yoksa işlemi durdur
    if (currentUserId == null) {
      print(
          "addRecipe Hata: Kullanıcı girişi gerekli (AuthManager'da ID yok).");
      return ApiResponse<RecipeModel>(
          success: false, message: "Tarif eklemek için oturum açmalısınız.");
    }
    // Gönderilecek ID'nin geçerli olup olmadığını kontrol et (örn: 0 olmamalı)
    if (currentUserId <= 0) {
      print("addRecipe Hata: Geçersiz kullanıcı ID'si ($currentUserId).");
      return ApiResponse<RecipeModel>(
          success: false,
          message: "Geçersiz kullanıcı bilgisiyle tarif eklenemez.");
    }

    try {
      // Modelden JSON oluştur
      Map<String, dynamic> recipeJson = recipe.toJson();

      // !!! ÖNEMLİ: Foreign Key Hatasını Önlemek İçin !!!
      // JSON'a doğru ve geçerli userId'yi eklediğimizden emin olalım.
      recipeJson['userId'] = currentUserId;

      print(
          "addRecipe isteği gönderiliyor: POST /api/Recipes (userId=$currentUserId)");
      print("Gönderilen JSON: $recipeJson");

      // API isteğini gönder
      final response = await _dio.post('/api/Recipes', data: recipeJson);
      print("addRecipe yanıtı alındı: ${response.statusCode}");

      // Yanıtı işle (201 Created veya 200 OK beklenir)
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data is Map) {
        // Başarılı: API'den dönen veriyi parse et
        final createdRecipe =
            RecipeModel.fromJson(response.data as Map<String, dynamic>);
        print("addRecipe Başarılı: Yeni tarif ID=${createdRecipe.id}");
        return ApiResponse<RecipeModel>(
            success: true,
            data: createdRecipe,
            message: "Tarif başarıyla eklendi.");
      } else {
        // Başarısız: Beklenmeyen durum kodu veya yanıt formatı
        print(
            "addRecipe Hatası: Beklenmeyen durum kodu ${response.statusCode} veya yanıt formatı. Yanıt: ${response.data}");
        return ApiResponse<RecipeModel>(
          success: false,
          message:
              'Tarif eklenemedi (Kod: ${response.statusCode}). Sunucu yanıtı geçersiz olabilir.',
        );
      }
    } on DioException catch (e) {
      print("addRecipe DioException: ${e.message}");
      if (e.response?.statusCode == 401) {
        // Yetkisiz
        print("addRecipe: 401 Yetkisiz. Oturum sonlanmış veya geçersiz.");
        return ApiResponse<RecipeModel>(
            success: false,
            message:
                "Oturumunuz geçersiz veya süresi dolmuş. Lütfen tekrar giriş yapın.");
      }
      // Diğer hataları (örn: 400 Validation Error, 500 Server Error) genel handler'a gönder
      return _handleDioError<RecipeModel>(e,
          defaultMessage: "Tarif eklenirken bir API hatası oluştu.");
    } catch (e, stackTrace) {
      // Diğer beklenmedik hatalar
      print("addRecipe Beklenmedik Hata: $e");
      print("addRecipe StackTrace: $stackTrace");
      return ApiResponse<RecipeModel>(
          success: false,
          message: 'Tarif eklenirken beklenmeyen bir hata oluştu.');
    }
  }

  /// Mevcut bir tarifi günceller.
  /// [recipe] modelini alır (ID'si dolu olmalı) ve API'ye gönderir.
  Future<ApiResponse<RecipeModel>> updateRecipe(RecipeModel recipe) async {
    // Geçerli bir tarif ID'si var mı kontrol et
    if (recipe.id <= 0) {
      print("updateRecipe Hata: Geçersiz tarif ID'si (${recipe.id}).");
      return ApiResponse<RecipeModel>(
          success: false, message: "Güncellenecek tarif ID'si geçersiz.");
    }

    // Aktif kullanıcı kontrolü
    final int? currentUserId = _authManager.currentUserId;
    if (currentUserId == null) {
      print(
          "updateRecipe Hata: Kullanıcı girişi gerekli (AuthManager'da ID yok).");
      return ApiResponse<RecipeModel>(
          success: false,
          message: "Tarif güncellemek için oturum açmalısınız.");
    }
    // Ek kontrol: Gönderilen tarifin kendi içindeki userId'si ile aktif kullanıcı uyuşuyor mu?
    // Bu kontrol API tarafında yapılmalı ama burada da bir ön kontrol olabilir (isteğe bağlı).
    // if (recipe.userId != null && recipe.userId != 0 && recipe.userId != currentUserId) {
    //    print("updateRecipe Hata: Aktif kullanıcı ($currentUserId) ile tarifin sahibi (${recipe.userId}) uyuşmuyor.");
    //    return ApiResponse<RecipeModel>(success: false, message: "Bu tarifi güncelleme yetkiniz yok (sahip uyuşmazlığı).");
    // }

    try {
      // Modelden JSON oluştur
      Map<String, dynamic> recipeJson = recipe.toJson();

      // --- !!! DÜZELTME: API'niz id ve userId'yi body'de beklediği için remove satırlarını kaldırın/yorum yapın !!! ---
      // recipeJson.remove('id');     // API body'de ID beklediği için BU SATIRI YORUM YAPIN VEYA SİLİN
      // recipeJson.remove('userId'); // API body'de UserID beklediği için BU SATIRI YORUM YAPIN VEYA SİLİN

      // Eğer RecipeModel.toJson() userId içermiyorsa veya null ise, AuthManager'dan ekleyin
      // (Ancak modelin kendisinde bu bilgi olmalı, çünkü tarifi düzenleme ekranına getirirken userId de gelmeli)
      if (recipeJson['userId'] == null || recipeJson['userId'] == 0) {
        print(
            "updateRecipe Uyarı: recipeJson içinde geçerli userId yok, AuthManager'dan ekleniyor ($currentUserId). Modelinizi kontrol edin.");
        recipeJson['userId'] = currentUserId;
      }
      // ID'nin 0 olmadığından emin olun (recipe.id kontrolü yukarıda yapıldı)
      if (recipeJson['id'] == null || recipeJson['id'] == 0) {
        print(
            "updateRecipe Uyarı: recipeJson içinde geçerli id yok, modelden ekleniyor (${recipe.id}). Modelinizi kontrol edin.");
        recipeJson['id'] =
            recipe.id; // recipe.id'nin geçerli olduğunu varsayıyoruz.
      }
      // --- Bitiş: Düzeltme ---

      print("updateRecipe isteği gönderiliyor: PUT /api/Recipes/${recipe.id}");
      // API'nin beklediği son JSON'u loglayalım
      print("Gönderilen JSON (ID/UserID dahil): $recipeJson");

      // API isteğini gönder
      final response =
          await _dio.put('/api/Recipes/${recipe.id}', data: recipeJson);
      print("updateRecipe yanıtı alındı: ${response.statusCode}");

      // --- Yanıt İşleme (öncekiyle aynı) ---
      if (response.statusCode == 200 && response.data is Map) {
        final updatedRecipe =
            RecipeModel.fromJson(response.data as Map<String, dynamic>);
        print(
            "updateRecipe Başarılı: Tarif güncellendi ID=${updatedRecipe.id}");
        return ApiResponse<RecipeModel>(
            success: true,
            data: updatedRecipe,
            message: "Tarif başarıyla güncellendi.");
      } else if (response.statusCode == 204) {
        print(
            "updateRecipe Başarılı: Tarif güncellendi (204 No Content) ID=${recipe.id}");
        return ApiResponse<RecipeModel>(
            success: true,
            data: recipe,
            message: "Tarif başarıyla güncellendi.");
      } else {
        print(
            "updateRecipe Hatası: Beklenmeyen durum kodu ${response.statusCode} veya yanıt formatı. Yanıt: ${response.data}");
        return ApiResponse<RecipeModel>(
          success: false,
          message:
              'Tarif güncellenemedi (Kod: ${response.statusCode}). Sunucu yanıtı geçersiz olabilir.',
        );
      }
    } on DioException catch (e) {
      // --- Hata Yönetimi (öncekiyle aynı, sadece log mesajları güncellendi) ---
      print("updateRecipe DioException: ${e.message}");
      if (e.response?.statusCode == 401) {
        print("updateRecipe: 401 Yetkisiz.");
        return ApiResponse<RecipeModel>(
            success: false, message: "Oturumunuz geçersiz veya süresi dolmuş.");
      } else if (e.response?.statusCode == 403) {
        print("updateRecipe: 403 Yasak.");
        return ApiResponse<RecipeModel>(
            success: false, message: "Bu tarifi güncelleme yetkiniz yok.");
      } else if (e.response?.statusCode == 404) {
        print("updateRecipe: 404 Bulunamadı.");
        return ApiResponse<RecipeModel>(
            success: false, message: "Güncellenecek tarif bulunamadı.");
      }
      // 400 Bad Request (örn: model validasyon hatası) veya 500 Internal Server Error
      // _handleDioError tarafından yakalanacaktır.
      return _handleDioError<RecipeModel>(e,
          defaultMessage: "Tarif güncellenirken bir API hatası oluştu.");
    } catch (e, stackTrace) {
      print("updateRecipe Beklenmedik Hata: $e");
      print("updateRecipe StackTrace: $stackTrace");
      return ApiResponse<RecipeModel>(
          success: false,
          message: 'Tarif güncellenirken beklenmeyen bir hata oluştu.');
    }
  }

  /// Belirtilen ID'ye sahip tarifi siler.
  Future<ApiResponse<void>> deleteRecipe(int recipeId) async {
    // Geçerli ID kontrolü
    if (recipeId <= 0) {
      print("deleteRecipe Hata: Geçersiz tarif ID'si ($recipeId).");
      return ApiResponse<void>(
          success: false, message: "Silinecek tarif ID'si geçersiz.");
    }

    // Aktif kullanıcı kontrolü
    if (_authManager.currentUserId == null) {
      print(
          "deleteRecipe Hata: Kullanıcı girişi gerekli (AuthManager'da ID yok).");
      return ApiResponse<void>(
          success: false, message: "Tarif silmek için oturum açmalısınız.");
    }

    try {
      print("deleteRecipe isteği gönderiliyor: DELETE /api/Recipes/$recipeId");
      // API isteğini gönder
      final response = await _dio.delete('/api/Recipes/$recipeId');
      print("deleteRecipe yanıtı alındı: ${response.statusCode}");

      // Yanıtı işle (204 No Content veya 200 OK beklenir)
      if (response.statusCode == 204 || response.statusCode == 200) {
        print("deleteRecipe Başarılı: Tarif silindi ID=$recipeId");
        return ApiResponse<void>(
            success: true, message: "Tarif başarıyla silindi.");
      } else {
        // Başarısız
        print(
            "deleteRecipe Hatası: Beklenmeyen durum kodu ${response.statusCode}. Yanıt: ${response.data}");
        return ApiResponse<void>(
          success: false,
          message: 'Tarif silinemedi (Kod: ${response.statusCode}).',
        );
      }
    } on DioException catch (e) {
      print("deleteRecipe DioException: ${e.message}");
      // Özel durum kodlarını ele al
      if (e.response?.statusCode == 401) {
        print("deleteRecipe: 401 Yetkisiz. Oturum sonlanmış veya geçersiz.");
        return ApiResponse<void>(
            success: false,
            message:
                "Oturumunuz geçersiz veya süresi dolmuş. Lütfen tekrar giriş yapın.");
      } else if (e.response?.statusCode == 403) {
        print("deleteRecipe: 403 Yasak. Bu tarifi silme yetkiniz yok.");
        return ApiResponse<void>(
            success: false, message: "Bu tarifi silme yetkiniz yok.");
      } else if (e.response?.statusCode == 404) {
        print("deleteRecipe: 404 Bulunamadı. Tarif ID=$recipeId mevcut değil.");
        return ApiResponse<void>(
            success: false, message: "Silinecek tarif bulunamadı.");
      }
      // Diğer hataları genel handler'a gönder
      return _handleDioError<void>(e,
          defaultMessage: "Tarif silinirken bir hata oluştu.");
    } catch (e, stackTrace) {
      // Diğer beklenmedik hatalar
      print("deleteRecipe Beklenmedik Hata: $e");
      print("deleteRecipe StackTrace: $stackTrace");
      return ApiResponse<void>(
          success: false,
          message: 'Tarif silinirken beklenmeyen bir hata oluştu.');
    }
  }

  // --- Dio Hatalarını İşleme Yardımcı Metodu ---
  /// DioException hatalarını yakalar ve kullanıcı dostu mesajlar içeren
  /// bir [ApiResponse] nesnesine dönüştürür.
  ApiResponse<T> _handleDioError<T>(DioException e,
      {String defaultMessage = "Bir ağ hatası oluştu."}) {
    String errorMessage = defaultMessage;
    print("--- Hata İşleniyor: _handleDioError ---");
    print("DioException Tipi: ${e.type}");
    print("İstek Yolu: ${e.requestOptions.path}");

    if (e.response != null) {
      // Sunucudan bir yanıt geldi ancak başarılı değil (4xx, 5xx)
      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;
      print("Yanıt Durum Kodu: $statusCode");
      print("Yanıt Verisi: $responseData");
      String? apiMessage;

      // API'den gelen mesajı ayrıştırmaya çalış
      if (responseData is Map<String, dynamic>) {
        apiMessage = responseData['message'] as String? ??
            responseData['detail'] as String? ?? // ProblemDetails için
            responseData['title'] as String?; // ProblemDetails için

        // ASP.NET Core ModelState hatalarını daha detaylı işle (varsa)
        if (statusCode == 400 && responseData.containsKey('errors')) {
          try {
            final errors = responseData['errors'] as Map<String, dynamic>;
            if (errors.isNotEmpty) {
              final firstErrorField = errors.entries.first;
              if (firstErrorField.value is List &&
                  (firstErrorField.value as List).isNotEmpty) {
                apiMessage =
                    "Hata (${firstErrorField.key}): ${(firstErrorField.value as List).first}";
              } else {
                apiMessage = "Geçersiz veri: ${firstErrorField.key}";
              }
            } else {
              apiMessage ??= "Gönderilen verilerde doğrulama hataları var.";
            }
          } catch (_) {
            apiMessage ??= "Geçersiz istek verisi.";
          }
        }
      } else if (responseData is String && responseData.isNotEmpty) {
        apiMessage = responseData; // Yanıt sadece metin ise
      }

      // Son mesajı belirle
      errorMessage = apiMessage?.isNotEmpty ?? false
          ? apiMessage!
          : 'Sunucu hatası (${statusCode ?? 'kod yok'}). Lütfen tekrar deneyin veya destek ile iletişime geçin.';
    } else {
      // Sunucudan yanıt gelmedi (bağlantı, timeout vb.)
      print("İstek Hatası (Yanıt Yok): ${e.message}");
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          errorMessage =
              'Sunucu yanıt vermedi (zaman aşımı). İnternet bağlantınızı kontrol edin veya daha sonra tekrar deneyin.';
          break;
        case DioExceptionType.cancel:
          errorMessage = 'İstek sizin tarafınızdan iptal edildi.';
          break;
        case DioExceptionType.connectionError:
          errorMessage =
              'Sunucuya bağlanılamadı. İnternet bağlantınızı veya sunucu adresini kontrol edin.';
          break;
        case DioExceptionType.badCertificate:
          errorMessage =
              'Güvenli bağlantı kurulamadı (Sertifika hatası). Bu genellikle lokal geliştirme sorunudur.';
          break;
        case DioExceptionType.badResponse:
          errorMessage =
              'Sunucudan beklenmeyen veya geçersiz bir yanıt alındı.';
          break;
        case DioExceptionType.unknown:
        default:
          // İnternet yoksa veya başka bilinmeyen bir hata varsa buraya düşebilir
          errorMessage =
              'Bilinmeyen bir ağ hatası oluştu. İnternet bağlantınızı kontrol edin. (${e.message ?? ''})'
                  .trim();
          break;
      }
    }

    print("Sonuçlanan Hata Mesajı: $errorMessage");
    print("--- Hata İşleme Bitti ---");
    return ApiResponse<T>(success: false, message: errorMessage);
  }

  // --- Diğer Yardımcı Metodlar (Varsa) ---
  // Örneğin, tüm tarifleri getirme (getAllRecipes) gibi diğer endpoint'ler buraya eklenebilir.
} // RecipeService sınıfının sonu
