// lib/views/admin/sample_plant_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../library/library_detail_screen.dart';

class SamplePlantManagementScreen extends StatefulWidget {
  const SamplePlantManagementScreen({super.key});

  @override
  State<SamplePlantManagementScreen> createState() => _SamplePlantManagementScreenState();
}

class _SamplePlantManagementScreenState extends State<SamplePlantManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _sciNameCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _lightCtrl = TextEditingController();
  final _waterCtrl = TextEditingController();
  final _soilCtrl = TextEditingController();
  final _fertCtrl = TextEditingController();

  void _openPlantSheet(BuildContext context, {String? docId, Map<String, dynamic>? existingData}) {
    bool isEditing = docId != null;

    if (isEditing && existingData != null) {
      _nameCtrl.text = existingData['name'] ?? '';
      _sciNameCtrl.text = existingData['scientificName'] ?? '';

      // ĐÃ XÓA FALLBACK: Chỉ nạp dữ liệu từ trường imageUrl
      _imgCtrl.text = existingData['imageUrl'] ?? '';

      _descCtrl.text = existingData['description'] ?? '';

      var care = existingData['care'] ?? {};
      _lightCtrl.text = care['light'] ?? '';
      _waterCtrl.text = care['water'] ?? '';
      _soilCtrl.text = care['soil'] ?? '';
      _fertCtrl.text = care['fertilizer'] ?? '';
    } else {
      _nameCtrl.clear(); _sciNameCtrl.clear(); _imgCtrl.clear(); _descCtrl.clear();
      _lightCtrl.clear(); _waterCtrl.clear(); _soilCtrl.clear(); _fertCtrl.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(isEditing ? "Chỉnh sửa Thư viện cây" : "Thêm cây mới vào Thư viện", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Tên cây"), validator: (v) => v!.isEmpty ? "Không bỏ trống" : null),
                  TextFormField(controller: _sciNameCtrl, decoration: const InputDecoration(labelText: "Tên khoa học")),
                  TextFormField(controller: _imgCtrl, decoration: const InputDecoration(labelText: "Link ảnh đại diện cây (imageUrl)")),
                  TextFormField(controller: _descCtrl, decoration: const InputDecoration(labelText: "Mô tả ngắn gọn"), maxLines: 2),
                  const SizedBox(height: 12),
                  const Text("Chế độ chăm sóc", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  TextFormField(controller: _lightCtrl, decoration: const InputDecoration(labelText: "Ánh sáng")),
                  TextFormField(controller: _waterCtrl, decoration: const InputDecoration(labelText: "Nước tưới")),
                  TextFormField(controller: _soilCtrl, decoration: const InputDecoration(labelText: "Đất trồng")),
                  TextFormField(controller: _fertCtrl, decoration: const InputDecoration(labelText: "Phân bón")),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        String finalImg = _imgCtrl.text.trim().isEmpty ? 'https://via.placeholder.com/150' : _imgCtrl.text.trim();

                        Map<String, dynamic> plantData = {
                          'name': _nameCtrl.text.trim(),
                          'scientificName': _sciNameCtrl.text.trim(),
                          'imageUrl': finalImg, // Chỉ ghi vào imageUrl
                          'description': _descCtrl.text.trim(),
                          'care': {
                            'light': _lightCtrl.text.trim(),
                            'water': _waterCtrl.text.trim(),
                            'soil': _soilCtrl.text.trim(),
                            'fertilizer': _fertCtrl.text.trim(),
                          },
                        };

                        if (isEditing) {
                          await FirebaseFirestore.instance.collection('sample_plants').doc(docId).update(plantData);
                        } else {
                          plantData['diseases'] = [];
                          await FirebaseFirestore.instance.collection('sample_plants').add(plantData);
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text(isEditing ? "LƯU THAY ĐỔI" : "ĐĂNG LÊN THƯ VIỆN", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Quản lý Thư viện cây", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPlantSheet(context),
        backgroundColor: const Color(0xFFC62828),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sample_plants').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var samplePlants = snapshot.data!.docs;

          if (samplePlants.isEmpty) {
            return const Center(child: Text("Thư viện đang trống."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: samplePlants.length,
            itemBuilder: (context, index) {
              var doc = samplePlants[index];
              var data = doc.data() as Map<String, dynamic>;

              // ĐÃ XÓA FALLBACK: Chỉ đọc đúng trường imageUrl từ Firestore
              String displayImg = data['imageUrl'] ?? 'https://via.placeholder.com/50';

              return Card(
                elevation: 0,
                color: Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: ListTile(
                  onTap: () {
                    Map<String, dynamic> adaptedData = {
                      'name': data['name'] ?? 'Cây chưa đặt tên',
                      'scientificName': data['scientificName'] ?? '',
                      'image': displayImg, // Đóng gói dữ liệu để chuyển sang màn hình detail (màn detail vẫn đọc key 'image')
                      'description': data['description'] ?? 'Chưa có mô tả',
                      'care': data['care'] ?? {'light': '', 'water': '', 'soil': '', 'fertilizer': ''},
                      'diseases': data['diseases'] ?? []
                    };
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LibraryDetailScreen(plantData: adaptedData),
                      ),
                    );
                  },
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(displayImg, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image)),
                  ),
                  title: Text(
                    data['name'] ?? 'Chưa có tên',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    data['scientificName'] ?? "",
                    style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                          onPressed: () => _openPlantSheet(context, docId: doc.id, existingData: data),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () => FirebaseFirestore.instance.collection('sample_plants').doc(doc.id).delete(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}