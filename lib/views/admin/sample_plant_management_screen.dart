// lib/views/admin/sample_plant_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Hàm mở trang/hộp thoại để Thêm mới một cây mẫu lên Firestore Cloud
  void _openAddPlantSheet(BuildContext context) {
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
                  const Text("Thêm cây mẫu mới", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                        await FirebaseFirestore.instance.collection('sample_plants').add({
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
                          'diseases': [] // Mặc định tạo mảng rỗng cho Admin cập nhật sau
                        });
                        _clearControllers();
                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text("ĐĂNG CÂY MẪU lên CLOUD", style: TextStyle(color: Colors.white)),
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

  void _clearControllers() {
    _nameCtrl.clear(); _sciNameCtrl.clear(); _imgCtrl.clear(); _descCtrl.clear();
    _lightCtrl.clear(); _waterCtrl.clear(); _soilCtrl.clear(); _fertCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Quản lý cây mẫu bách khoa", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddPlantSheet(context),
        backgroundColor: const Color(0xFFC62828),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sample_plants').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var samplePlants = snapshot.data!.docs;

          if (samplePlants.isEmpty) {
            return const Center(child: Text("Hội đồng Admin chưa đăng cây mẫu nào lên Cloud."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: samplePlants.length,
            itemBuilder: (context, index) {
              var plantDoc = samplePlants[index];
              var plant = plantDoc.data() as Map<String, dynamic>;

              return Card(
                elevation: 0,
                color: Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(plant['image'], width: 50, height: 50, fit: BoxFit.cover),
                  ),
                  title: Text(plant['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(plant['scientificName'] ?? "", style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      await FirebaseFirestore.instance.collection('sample_plants').doc(plantDoc.id).delete();
                    },
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