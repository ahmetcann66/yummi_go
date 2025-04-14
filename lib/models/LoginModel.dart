// lib/models/login_model.dart
class LoginModel {
  String username;
  String password;

  LoginModel({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {
      'username':
          username, // API'deki alan adıyla eşleşmeli (büyük/küçük harf duyarlılığına dikkat!)
      'password': password, // API'deki alan adıyla eşleşmeli
    };
  }
}
