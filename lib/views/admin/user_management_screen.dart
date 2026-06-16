// lib/views/admin/user_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_detail_admin_screen.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  // Hàm chuyển đổi trạng thái Khóa / Mở khóa của User
  Future<void> _toggleLockUser(BuildContext context, String userId, bool currentStatus) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'isLocked': !currentStatus, // Đảo trạng thái ngược lại
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(!currentStatus ? "Đã khóa tài khoản thành công!" : "Đã mở khóa tài khoản thành công!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi thao tác: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Quản lý người dùng", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var users = snapshot.data!.docs;

          if (users.isEmpty) {
            return const Center(child: Text("Hệ thống chưa có người dùng nào đăng ký."));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              var userDoc = users[index];
              var userData = userDoc.data() as Map<String, dynamic>;

              String userId = userDoc.id;
              String name = userData['displayName'] ?? "Người yêu cây";
              String email = userData['email'] ?? "Không có email";
              String? avatar = userData['avatarUrl'];
              bool isLocked = userData['isLocked'] ?? false;
              String role = userData['role'] ?? "user";

              return ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserDetailAdminScreen(
                        userId: userDoc.id,
                        userData: userData,
                      ),
                    ),
                  );
                },
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade100,
                  backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                  child: avatar == null ? const Icon(Icons.person, color: Colors.grey) : null,
                ),
                title: Row(
                  children: [
                    // ĐÃ SỬA LỖI TRÀN VIỀN Ở ĐÂY: Thêm Expanded và TextOverflow.ellipsis
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis, // Cắt thành ... nếu tên quá dài
                      ),
                    ),
                    if (role == "admin") ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
                        child: const Text("ADMIN", style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ]
                  ],
                ),
                subtitle: Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                trailing: role == "admin"
                    ? null
                    : TextButton(
                  onPressed: () => _toggleLockUser(context, userId, isLocked),
                  style: TextButton.styleFrom(
                    foregroundColor: isLocked ? Colors.green : Colors.red,
                  ),
                  child: Text(isLocked ? "MỞ KHÓA" : "KHÓA ACCT", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}