// lib/views/article_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> articleData;

  const ArticleDetailScreen({super.key, required this.articleData});

  // Hàm định dạng ngày tháng hiển thị
  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "Gần đây";
    DateTime date = timestamp.toDate();
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    String title = articleData['title'] ?? 'Bài viết kiến thức';

    // ĐÃ SỬA: Lấy dữ liệu từ trường coverImage cho khớp với database
    String imageUrl = articleData['coverImage'] ?? 'https://via.placeholder.com/600x400';

    String content = articleData['content'] ?? 'Nội dung đang được cập nhật...';
    Timestamp? createdAt = articleData['createdAt'] as Timestamp?;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // KHU VỰC ẢNH BÌA TRÀN VIỀN KHI CUỘN LÊN
          SliverAppBar(
            expandedHeight: 280.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade300, child: const Icon(Icons.image, size: 50, color: Colors.grey)),
                  ),
                  // Phủ một lớp gradient đen mờ dưới đáy ảnh để nút Back màu trắng luôn dễ nhìn
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent, Colors.transparent],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // KHU VỰC NỘI DUNG BÀI VIẾT
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Thông tin Tác giả và Ngày đăng
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFFE8F5E9),
                        child: Icon(Icons.psychology, size: 18, color: Color(0xFF2E7D32)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Chuyên gia HomePlant • ${_formatDate(createdAt)}",
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // Nội dung chữ
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.8, // Khoảng cách dòng rộng rãi để dễ đọc
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 60), // Khoảng trống dưới cùng để cuộn không bị vướng
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}