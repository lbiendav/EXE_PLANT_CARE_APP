import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'template_detail_screen.dart'; // thêm chi tiết cây nổi bật.


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
          "HomePlant",
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

            // StreamBuilder lắng nghe dữ liệu từ collection 'plant_templates'
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
                      // Truyền BuildContext và Dữ liệu vào hàm tạo thẻ
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

            _buildArticleTile(context, "Bí quyết cứu sống Sen Đá mùa mưa bão", "Chuyên gia Trần Đắc"),
            _buildArticleTile(context, "Làm sao để Lưỡi Hổ ra hoa?", "HomePlant Admin"),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị thẻ cây trồng (Đã thêm GestureDetector)
  Widget _buildPlantCard(BuildContext context, Map<String, dynamic> plant) {
    return GestureDetector(
      onTap: () {
        // Chuyển sang màn hình Bách khoa khi chạm vào
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

  // Widget hiển thị bài viết (Tạm thời chỉ làm hiệu ứng chạm)
  Widget _buildArticleTile(BuildContext context, String title, String author) {
    return ListTile(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng đọc bài viết đang phát triển")));
      },
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.article_outlined, color: Colors.grey),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("Bởi $author", style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}