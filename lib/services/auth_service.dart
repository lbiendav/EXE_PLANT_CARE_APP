import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lắng nghe trạng thái đăng nhập
  Stream<User?> get userStream => _auth.authStateChanges();

  // Đăng ký tài khoản mới và lưu thông tin vào Firestore
  Future<UserModel?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = credential.user;
      if (user != null) {
        // Tạo đối tượng UserModel chuẩn theo cấu trúc của bạn
        UserModel newUser = UserModel(
          uid: user.uid,
          email: email,
          displayName: displayName,
          avatarUrl: "https://i.pravatar.cc/150", // Avatar mặc định
          role: "user", // Mặc định là user thường
          membership: "normal",
          createdAt: DateTime.now(),
        );

        // Lưu vào Firestore collection 'users'
        await _db.collection('users').doc(user.uid).set(newUser.toMap());

        return newUser;
      }
    } catch (e) {
      print("Lỗi đăng ký: $e");
      rethrow;
    }
    return null;
  }

  // Đăng nhập
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      print("Lỗi đăng nhập: $e");
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }
}