// lib/services/auth_manager.dart

import '../models/UserModel.dart'; // UserModel'i import et

/// Uygulama genelinde kullanıcı oturum durumunu ve bilgilerini yönetir.
class AuthManager {
  // Singleton deseni için private constructor ve static instance
  AuthManager._privateConstructor();
  static final AuthManager _instance = AuthManager._privateConstructor();

  // Dışarıdan erişilecek tekil instance
  factory AuthManager() {
    return _instance;
  }

  // Saklanacak kullanıcı bilgileri (nullable)
  UserModel? _currentUser;
  // Saklanacak kullanıcı ID'si (nullable)
  int? _userId;

  // Getter'lar ile bilgilere güvenli erişim
  UserModel? get currentUser => _currentUser;
  int? get currentUserId => _userId;
  bool get isLoggedIn => _userId != null && _currentUser != null;

  /// Kullanıcı başarıyla giriş yaptığında çağrılır.
  void loginUser(UserModel user) {
    _currentUser = user;
    _userId = user.id;
    print(
        'AuthManager: Kullanıcı giriş yaptı - ID: $_userId, Username: ${user.username}');
    // İleride: Belki token'ı da burada saklayabiliriz (flutter_secure_storage ile)
  }

  /// Kullanıcı çıkış yaptığında çağrılır.
  void logoutUser() {
    _currentUser = null;
    _userId = null;
    print('AuthManager: Kullanıcı çıkış yaptı.');
    // İleride: Saklanan token'ı da silmemiz gerekir.
    // CookieJar'ı da temizlemek iyi olabilir (eğer merkezi yönetiliyorsa)
    // Örnek: DioClient.clearCookies();
  }
}
