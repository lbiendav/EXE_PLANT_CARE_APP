import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  final Color primaryGreen = const Color(0xFF2E7D32);

  File? _selectedImage;
  bool _isLoading = false;

  // ==========================================
  // API KEY CỦA BẠN:
  final String imgBBApiKey = "781f80a48e5cf2457ccf0b91165f0eaa";
  // ==========================================

  final TextEditingController _nameController = TextEditingController();
  String? _selectedTemplateId;
  String _selectedStatus = 'healthy';

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy ảnh: $e");
    }
  }

  // Hàm xử lý Lưu dữ liệu qua ImgBB
  Future<void> _savePlant() async {
    if (_selectedImage == null || _nameController.text.isEmpty || _selectedTemplateId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ tên, loại cây và chọn ảnh!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Chuyển đổi file ảnh sang định dạng Base64 để gửi qua mạng
      List<int> imageBytes = await _selectedImage!.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // 2. Gửi ảnh lên ImgBB qua HTTP POST
      Uri url = Uri.parse("https://api.imgbb.com/1/upload");
      var response = await http.post(url, body: {
        'key': imgBBApiKey,
        'image': base64Image,
      });

      if (response.statusCode == 200) {
        // Phân tích kết quả trả về để lấy Link ảnh
        var jsonResponse = jsonDecode(response.body);
        String downloadUrl = jsonResponse['data']['url'];

        // 3. Lưu thông tin (kèm Link ảnh) vào Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('user_plants')
            .add({
          "plantId": DateTime.now().millisecondsSinceEpoch.toString(),
          "templateId": _selectedTemplateId,
          "customName": _nameController.text.trim(),
          "imageUrl": downloadUrl, // Link ảnh từ ImgBB
          "status": _selectedStatus,
          "plantedAt": FieldValue.serverTimestamp(),
          "createdAt": FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Thêm cây mới thành công!"), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception("Lỗi từ ImgBB: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        title: Text("Thêm cây mới", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryGreen),
            const SizedBox(height: 16),
            const Text("Đang tải ảnh lên máy chủ, vui lòng đợi..."),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Khu vực chọn ảnh
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Chụp ảnh mới'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Chọn từ Thư viện'),
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: primaryGreen.withValues(alpha: 0.3), width: 2, style: BorderStyle.solid),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 50, color: primaryGreen),
                    const SizedBox(height: 8),
                    Text("Chạm để thêm ảnh", style: TextStyle(color: primaryGreen)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nhập Tên cây
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Tên gọi (Ví dụ: Bé Sen Đá Góc Bàn)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kéo danh sách Template từ Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('plant_templates').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();

                var templates = snapshot.data!.docs;
                List<DropdownMenuItem<String>> items = templates.map((doc) {
                  return DropdownMenuItem<String>(
                    value: doc['templateId'],
                    child: Text(doc['name']),
                  );
                }).toList();

                return DropdownButtonFormField<String>(
                  value: _selectedTemplateId,
                  items: items,
                  decoration: InputDecoration(
                    labelText: "Loại cây (Từ Thư viện)",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (value) {
                    setState(() => _selectedTemplateId = value);
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Chọn Trạng thái
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              items: const [
                DropdownMenuItem(value: 'healthy', child: Text("Khỏe mạnh")),
                DropdownMenuItem(value: 'sick', child: Text("Có bệnh / Cần chú ý")),
              ],
              decoration: InputDecoration(
                labelText: "Trạng thái sức khỏe",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) {
                setState(() => _selectedStatus = value!);
              },
            ),
            const SizedBox(height: 32),

            // Nút Lưu
            SizedBox(
              height: 55,
              child: ElevatedButton(
                onPressed: _savePlant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("LƯU VÀO VƯỜN", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}