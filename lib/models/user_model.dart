import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String avatarUrl;
  final String role;
  final String membership;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.avatarUrl,
    required this.role,
    required this.membership,
    required this.createdAt,
  });

  // Chuyển đổi từ Firestore Document sang Object
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      role: data['role'] ?? 'user',
      membership: data['membership'] ?? 'normal',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Chuyển đổi từ Object sang Map để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'role': role,
      'membership': membership,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}