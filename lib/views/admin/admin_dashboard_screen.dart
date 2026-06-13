// lib/views/admin/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_management_screen.dart';
import 'sample_plant_management_screen.dart'; // Quản lý Thư viện
import 'plant_template_management_screen.dart'; // Quản lý Cây nổi bật
import 'article_management_screen.dart';        // Quản lý Bài viết

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final Color adminColor = const Color(0xFFC62828);

  Future<Map<String, int>> _fetchSystemStats() async {
    final firestore = FirebaseFirestore.instance;

    var usersSnap = await firestore.collection('users').count().get();
    var plantsSnap = await firestore.collectionGroup('user_plants').count().get();

    // Đếm độc lập 3 bảng dữ liệu
    var librarySnap = await firestore.collection('sample_plants').count().get();
    var templatesSnap = await firestore.collection('plant_templates').count().get();
    var articlesSnap = await firestore.collection('articles').count().get();

    return {
      'users': usersSnap.count ?? 0,
      'plants': plantsSnap.count ?? 0,
      'library': librarySnap.count ?? 0,
      'templates': templatesSnap.count ?? 0,
      'articles': articlesSnap.count ?? 0,
    };
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 24),
              ),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.2, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Icon(icon, color: adminColor, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: adminColor),
        title: Text("Tổng quan Hệ thống", style: TextStyle(color: adminColor, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _fetchSystemStats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          var stats = snapshot.data ?? {'users': 0, 'plants': 0, 'library': 0, 'templates': 0, 'articles': 0};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Dashboard & Thống kê", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Mở rộng lưới thống kê cho đủ các bảng
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 1.25,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildStatCard("Người dùng", stats['users'].toString(), Icons.people, Colors.blue),
                    _buildStatCard("Cây trong vườn", stats['plants'].toString(), Icons.yard, Colors.green),
                    _buildStatCard("Thư viện cây", stats['library'].toString(), Icons.local_library, Colors.brown),
                    _buildStatCard("Cây nổi bật", stats['templates'].toString(), Icons.eco, Colors.orange),
                    _buildStatCard("Bài viết", stats['articles'].toString(), Icons.article, Colors.teal),
                  ],
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),

                const Text("Danh mục Quản lý nghiệp vụ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                _buildMenuTile(
                  "Quản lý Người dùng",
                  "Xem thông tin danh sách, Khóa/Mở khóa tài khoản",
                  Icons.manage_accounts,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen())),
                ),
                _buildMenuTile(
                  "Quản lý Thư viện cây",
                  "Thêm, sửa, xóa bách khoa thực vật (sample_plants)",
                  Icons.local_library,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SamplePlantManagementScreen())),
                ),
                _buildMenuTile(
                  "Quản lý Cây nổi bật",
                  "Thêm, sửa, xóa cây mẫu gợi ý (plant_templates)",
                  Icons.eco,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlantTemplateManagementScreen())),
                ),
                _buildMenuTile(
                  "Quản lý Bài viết",
                  "Thêm, sửa, xóa kiến thức chăm sóc (articles)",
                  Icons.article,
                      () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ArticleManagementScreen())),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}