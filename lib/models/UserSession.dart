// lib/services/user_session.dart
import 'UserModel.dart';

class UserSession {
  static UserModel? currentUser;

  static int? get currentUserId => currentUser?.id;

  static void clear() {
    currentUser = null;
  }
}
