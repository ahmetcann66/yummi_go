// lib/models/user_model.dart
class UserModel {
  int id;
  String username;
  String email;

  UserModel({required this.id, required this.username, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userJson =
        json['user']; // API cevabındaki "user" nesnesini alıyoruz (küçük harf!)
    return UserModel(
      id: userJson['id'] as int, // Küçük harf!
      username: userJson['username'] as String, // Küçük harf!
      email: userJson['email'] as String, // Küçük harf!
    );
  }
}
