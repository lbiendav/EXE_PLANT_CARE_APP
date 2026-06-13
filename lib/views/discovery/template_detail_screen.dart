import 'package:flutter/material.dart';
import '../garden/add_plant_screen.dart';

class TemplateDetailScreen extends StatelessWidget {
  final Map<String, dynamic> templateData;

  const TemplateDetailScreen({super.key, required this.templateData});

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
      ),
      extendBodyBehindAppBar: true, // Cho phép ảnh nền tràn lên cả khu vực AppBar
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ảnh bìa tràn viền
            SizedBox(
              height: 350,
              width: double.infinity,
              child: Image.network(
                templateData['imageUrl'] ?? 'https://via.placeholder.com/400',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 50, color: Colors.grey)),
              ),
            ),

            // Khu vực thông tin
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    templateData['name'] ?? 'Tên cây',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    templateData['scientificName'] ?? 'Chưa có tên khoa học',
                    style: const TextStyle(fontSize: 16, color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 24),

                  // Các thông số chăm sóc cơ bản (Thiết kế dạng hàng ngang)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoBadge(Icons.wb_sunny_outlined, Colors.orange, "Ánh sáng", templateData['sunlight'] ?? "Vừa phải"),
                      _buildInfoBadge(Icons.water_drop_outlined, Colors.blue, "Tưới nước", templateData['watering'] ?? "Thường xuyên"),
                      _buildInfoBadge(Icons.thermostat_outlined, Colors.red, "Nhiệt độ", templateData['temperature'] ?? "20-25°C"),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Mô tả chi tiết
                  const Text("Giới thiệu", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    templateData['description'] ?? "Chưa có thông tin mô tả chi tiết cho loại cây này. Hãy tự mình khám phá và thêm vào vườn nhé!",
                    style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                  ),
                  const SizedBox(height: 32),

                  // Mẹo chăm sóc
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9).withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryGreen.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
                            const SizedBox(width: 8),
                            const Text("Mẹo nhỏ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Luôn kiểm tra độ ẩm của đất trước khi tưới. Không nên tưới quá nhiều để tránh tình trạng ngập úng rễ.",
                          style: TextStyle(color: Colors.black87, height: 1.5),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 100), // Khoảng trống cho nút nổi bên dưới
                ],
              ),
            ),
          ],
        ),
      ),

      // Nút Thêm vào vườn (Call to Action)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPlantScreen()),
              );
            },
            backgroundColor: primaryGreen,
            elevation: 4,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("THÊM VÀO VƯỜN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }

  // Widget con để vẽ các icon thông số
  Widget _buildInfoBadge(IconData icon, Color color, String title, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}