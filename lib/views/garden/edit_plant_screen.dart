import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPlantScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> currentPlantData;

  const EditPlantScreen({super.key, required this.docId, required this.currentPlantData});

  @override
  State<EditPlantScreen> createState() => _EditPlantScreenState();
}

class _EditPlantScreenState extends State<EditPlantScreen> {
  final String? uid = FirebaseAuth.instance.currentUser?.uid;
  final Color primaryGreen = const Color(0xFF2E7D32);

  // API Key ImgBB của bạn
  final String imgBBApiKey = "781f80a48e5cf2457ccf0b91165f0eaa";

  File? _selectedImage;
  bool _isLoading = false;

  late TextEditingController _nameController;
  late String _selectedStatus;
  String? _currentImageUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Nạp dữ liệu cũ vào các ô nhập liệu
    _nameController = TextEditingController(text: widget.currentPlantData['customName']);
    _selectedStatus = widget.currentPlantData['status'] ?? 'healthy';
    _currentImageUrl = widget.currentPlantData['imageUrl'];
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Lỗi lấy ảnh: $e");
    }
  }

  Future<void> _updatePlant() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tên cây không được để trống!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String finalImageUrl = _currentImageUrl ?? "";

      // Nếu người dùng có chọn ảnh mới, tiến hành up lên ImgBB
      if (_selectedImage != null) {
        List<int> imageBytes = await _selectedImage!.readAsBytes();
        String base64Image = base64Encode(imageBytes);

        Uri url = Uri.parse("https://api.imgbb.com/1/upload");
        var response = await http.post(url, body: {
          'key': imgBBApiKey,
          'image': base64Image,
        });

        if (response.statusCode == 200) {
          var jsonResponse = jsonDecode(response.body);
          finalImageUrl = jsonResponse['data']['url'];
        } else {
          throw Exception("Lỗi up ảnh lên ImgBB");
        }
      }

      // Cập nhật thông tin vào Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('user_plants')
          .doc(widget.docId)
          .update({
        "customName": _nameController.text.trim(),
        "status": _selectedStatus,
        "imageUrl": finalImageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cập nhật thông tin thành công!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Quay lại màn hình chi tiết
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
        title: Text("Chỉnh sửa cây", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryGreen),
            const SizedBox(height: 16),
            const Text("Đang cập nhật dữ liệu..."),
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
                    : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(_currentImageUrl!, fit: BoxFit.cover, width: double.infinity),
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 50, color: primaryGreen),
                    const SizedBox(height: 8),
                    Text("Chạm để đổi ảnh", style: TextStyle(color: primaryGreen)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Nhập Tên cây
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: "Tên gọi",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryGreen, width: 2),
                ),
              ),
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
                onPressed: _updatePlant,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("CẬP NHẬT", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}