// lib/models/user_model.dart

/// API'den gelen iç içe kullanıcı bilgilerini temsil eden sınıf.
class UserModel {
  final int id;
  final String username;
  final String email;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
  });

  /// JSON verisinden bir UserModel nesnesi oluşturur (Daha Güvenli).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // ÖNEMLİ: json map'inin null olmadığını varsayıyoruz çünkü çağıran yer kontrol etti.
    // Ancak yine de ekstra güvenli erişim yapalım.

    // 'id' alanını güvenli bir şekilde al ve parse et
    dynamic idValue = json['id']; // Önce dynamic olarak al
    int finalId = 0; // Varsayılan değer
    if (idValue != null) {
      if (idValue is int) {
        finalId = idValue;
      } else if (idValue is String) {
        finalId = int.tryParse(idValue) ?? 0;
      } else if (idValue is double) {
        // API double gönderirse diye
        finalId = idValue.toInt();
      }
    } else {
      print(
          "UserModel.fromJson UYARI: 'id' alanı JSON'da bulunamadı veya null.");
    }

    // 'username' alanını güvenli bir şekilde al
    dynamic usernameValue = json['username'];
    String finalUsername = 'Bilinmeyen Kullanıcı'; // Varsayılan
    if (usernameValue != null && usernameValue is String) {
      finalUsername = usernameValue;
    } else {
      print(
          "UserModel.fromJson UYARI: 'username' alanı JSON'da bulunamadı veya String değil.");
    }

    // 'email' alanını güvenli bir şekilde al
    dynamic emailValue = json['email'];
    String finalEmail = ''; // Varsayılan
    if (emailValue != null && emailValue is String) {
      finalEmail = emailValue;
    } else {
      print(
          "UserModel.fromJson UYARI: 'email' alanı JSON'da bulunamadı veya String değil.");
    }

    // Güvenli bir şekilde alınan değerlerle nesneyi oluştur
    return UserModel(
      id: finalId,
      username: finalUsername,
      email: finalEmail,
    );
  }
}
