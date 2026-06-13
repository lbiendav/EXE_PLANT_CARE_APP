// lib/views/admin/plant_template_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlantTemplateManagementScreen extends StatefulWidget {
  const PlantTemplateManagementScreen({super.key});

  @override
  State<PlantTemplateManagementScreen> createState() => _PlantTemplateManagementScreenState();
}

class _PlantTemplateManagementScreenState extends State<PlantTemplateManagementScreen> {
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
      _imgCtrl.text = existingData['image'] ?? '';
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
                  Text(isEditing ? "Sửa thông tin cây" : "Thêm cây nổi bật", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Tên cây"), validator: (v) => v!.isEmpty ? "Không bỏ trống" : null),
                  TextFormField(controller: _sciNameCtrl, decoration: const InputDecoration(labelText: "Tên khoa học")),
                  TextFormField(controller: _imgCtrl, decoration: const InputDecoration(labelText: "Link ảnh đại diện cây")),
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
                        Map<String, dynamic> plantData = {
                          'name': _nameCtrl.text.trim(),
                          'scientificName': _sciNameCtrl.text.trim(),
                          'image': _imgCtrl.text.trim().isEmpty ? 'https://via.placeholder.com/150' : _imgCtrl.text.trim(),
                          'description': _descCtrl.text.trim(),
                          'care': {
                            'light': _lightCtrl.text.trim(),
                            'water': _waterCtrl.text.trim(),
                            'soil': _soilCtrl.text.trim(),
                            'fertilizer': _fertCtrl.text.trim(),
                          },
                        };

                        if (isEditing) {
                          await FirebaseFirestore.instance.collection('plant_templates').doc(docId).update(plantData);
                        } else {
                          plantData['diseases'] = [];
                          await FirebaseFirestore.instance.collection('plant_templates').add(plantData);
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text(isEditing ? "LƯU THAY ĐỔI" : "ĐĂNG CÂY LÊN CLOUD", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: const Text("Quản lý Cây nổi bật", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPlantSheet(context),
        backgroundColor: const Color(0xFFC62828),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // SỬ DỤNG ĐÚNG COLLECTION CỦA BẠN LÀ plant_templates
        stream: FirebaseFirestore.instance.collection('plant_templates').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var templates = snapshot.data!.docs;

          if (templates.isEmpty) return const Center(child: Text("Chưa có cây nổi bật nào."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: templates.length,
            itemBuilder: (context, index) {
              var doc = templates[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 0,
                color: Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(data['image'] ?? 'https://via.placeholder.com/50', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image)),
                  ),
                  title: Text(data['name'] ?? 'Chưa có tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['scientificName'] ?? "", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () => _openPlantSheet(context, docId: doc.id, existingData: data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => FirebaseFirestore.instance.collection('plant_templates').doc(doc.id).delete(),
                      ),
                    ],
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