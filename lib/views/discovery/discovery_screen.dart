// lib/views/discovery_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'template_detail_screen.dart';
import 'article_detail_screen.dart';

class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Trang chủ",
          style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: primaryGreen),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Khám phá cây trồng mới",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // STREAM BUIDER 1: KÉO DỮ LIỆU CÂY NỔI BẬT
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('plant_templates').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("Chưa có dữ liệu cây trồng.");
                }

                var templates = snapshot.data!.docs;

                return SizedBox(
                  height: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      var plant = templates[index].data() as Map<String, dynamic>;
                      return _buildPlantCard(context, plant);
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            const Text(
              "Cẩm nang chăm sóc",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // STREAM BUIDER 2: KÉO DỮ LIỆU BÀI VIẾT TỪ CLOUD
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('articles').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("Chưa có bài viết nào.");
                }

                var articles = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true, // Ép ListView nằm gọn trong SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(), // Tắt cuộn độc lập để cuộn chung với trang
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    var articleData = articles[index].data() as Map<String, dynamic>;
                    return _buildArticleTile(context, articleData);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Thẻ Cây Trồng
  Widget _buildPlantCard(BuildContext context, Map<String, dynamic> plant) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TemplateDetailScreen(templateData: plant),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                plant['imageUrl'] ?? 'https://via.placeholder.com/150',
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 140,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    Container(height: 140, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, color: Colors.grey)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant['name'] ?? 'Tên cây',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    plant['scientificName'] ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // ĐÃ SỬA: Thẻ Bài Viết (Nhận Map data từ Firestore)
  Widget _buildArticleTile(BuildContext context, Map<String, dynamic> data) {
    // Đọc chính xác trường coverImage và title từ cấu trúc Database của bạn
    String title = data['title'] ?? 'Bài viết không có tiêu đề';
    String imgUrl = data['coverImage'] ?? 'https://via.placeholder.com/150';

    return ListTile(
      onTap: () {
        // ĐIỀU HƯỚNG TỚI MÀN HÌNH ĐỌC CHI TIẾT
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleDetailScreen(articleData: data),
          ),
        );
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imgUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 60,
            height: 60,
            color: Colors.grey.shade200,
            child: const Icon(Icons.article_outlined, color: Colors.grey),
          ),
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
        maxLines: 2, // Cho phép tên bài rớt xuống 2 dòng
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: const Text("Bởi Chuyên gia HomePlant", style: TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}