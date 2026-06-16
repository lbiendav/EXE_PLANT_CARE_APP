// lib/views/admin/user_detail_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailAdminScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String userId;

  const UserDetailAdminScreen({super.key, required this.userData, required this.userId});

  // Hàm định dạng ngày tháng từ Timestamp
  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    if (timestamp is Timestamp) {
      DateTime date = timestamp.toDate();
      return "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";
    }
    return timestamp.toString();
  }

  // Widget vẽ từng dòng thông tin
  Widget _buildInfoTile(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
            onPressed: () {
              // Tính năng copy nếu cần (tùy chọn)
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String avatar = userData['avatarUrl'] ?? '';
    String name = userData['displayName'] ?? 'N/A';
    bool isLocked = userData['isLocked'] ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Hồ sơ người dùng", style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar & Name Header
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar.isEmpty ? const Icon(Icons.person, size: 50) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLocked ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isLocked ? "TÀI KHOẢN ĐANG KHÓA" : "TÀI KHOẢN HOẠT ĐỘNG",
                      style: TextStyle(color: isLocked ? Colors.red : Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Chi tiết thông tin từ DB
            _buildInfoTile(Icons.badge, "User ID (UID)", userId, Colors.blue),
            _buildInfoTile(Icons.email, "Địa chỉ Email", userData['email'] ?? 'N/A', Colors.orange),
            _buildInfoTile(Icons.admin_panel_settings, "Quyền hạn (Role)", (userData['role'] ?? 'user').toString().toUpperCase(), Colors.purple),
            _buildInfoTile(Icons.card_membership, "Gói thành viên (Membership)", (userData['membership'] ?? 'normal').toString().toUpperCase(), Colors.teal),
            _buildInfoTile(Icons.calendar_today, "Ngày gia nhập", _formatDate(userData['createdAt']), Colors.blueGrey),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // Nút hành động nhanh
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Gọi hàm toggle lock ở đây nếu muốn
                  FirebaseFirestore.instance.collection('users').doc(userId).update({'isLocked': !isLocked});
                  Navigator.pop(context);
                },
                icon: Icon(isLocked ? Icons.lock_open : Icons.lock_person),
                label: Text(isLocked ? "MỞ KHÓA TÀI KHOẢN" : "KHÓA TÀI KHOẢN NGAY"),
                style: ElevatedButton.styleFrom(
                    backgroundColor: isLocked ? Colors.green : Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}