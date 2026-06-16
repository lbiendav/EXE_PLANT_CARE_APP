// lib/views/library_detail_screen.dart
import 'package:flutter/material.dart';

class LibraryDetailScreen extends StatelessWidget {
  final Map<String, dynamic> plantData;

  const LibraryDetailScreen({super.key, required this.plantData});

  Widget _buildCareItem(IconData icon, Color color, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.grey.shade800, height: 1.4)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDiseaseCard(Map<String, dynamic> disease) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          collapsedIconColor: Colors.red,
          iconColor: Colors.red,
          title: Text(disease['issue'], style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800)),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Nguyên nhân: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(disease['cause'])),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.medical_services_outlined, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Cách xử lý:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      const SizedBox(height: 4),
                      Text(disease['treatment'], style: const TextStyle(height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final care = plantData['care'] as Map<String, dynamic>? ?? {};
    final diseases = plantData['diseases'] as List<dynamic>? ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 300.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF2E7D32),
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ĐÃ SỬA: Đọc từ key imageUrl
                      Image.network(plantData['imageUrl'] ?? 'https://via.placeholder.com/600', fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.7)],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plantData['name'] ?? '',
                              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              plantData['scientificName'] ?? '',
                              style: const TextStyle(color: Colors.white70, fontSize: 16, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text(
                    plantData['description'] ?? '',
                    style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  const TabBar(
                    labelColor: Color(0xFF2E7D32),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF2E7D32),
                    indicatorWeight: 3,
                    tabs: [
                      Tab(text: "HƯỚNG DẪN CHĂM SÓC"),
                      Tab(text: "BẮT BỆNH & XỬ LÝ"),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              // TAB 1: HƯỚNG DẪN CHĂM SÓC
              ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  _buildCareItem(Icons.wb_sunny_outlined, Colors.orange, "Ánh sáng", care['light'] ?? ''),
                  _buildCareItem(Icons.water_drop_outlined, Colors.blue, "Tưới nước", care['water'] ?? ''),
                  _buildCareItem(Icons.landscape_outlined, Colors.brown, "Đất trồng", care['soil'] ?? ''),
                  _buildCareItem(Icons.eco_outlined, Colors.green, "Phân bón", care['fertilizer'] ?? ''),
                ],
              ),

              // TAB 2: BỆNH VÀ CÁCH XỬ LÝ
              diseases.isEmpty
                  ? const Center(child: Text("Cây này trộm vía rất khỏe, chưa có dữ liệu bệnh!"))
                  : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: diseases.length,
                itemBuilder: (context, index) {
                  return _buildDiseaseCard(diseases[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Bổ trợ để TabBar dính chặt lên trên khi cuộn
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}