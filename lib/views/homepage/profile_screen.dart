import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'auth_screen.dart';
import '../admin/admin_dashboard_screen.dart'; // Nạp màn hình Admin Dashboard sắp tạo

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final Color primaryGreen = const Color(0xFF2E7D32);

  final String imgBBApiKey = "781f80a48e5cf2457ccf0b91165f0eaa";
  bool _isLoadingAvatar = false;

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
            (route) => false,
      );
    }
  }

  Future<void> _changeAvatar() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (pickedFile == null || user == null) return;

      setState(() => _isLoadingAvatar = true);

      File imageFile = File(pickedFile.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      Uri url = Uri.parse("https://api.imgbb.com/1/upload");
      var response = await http.post(url, body: {
        'key': imgBBApiKey,
        'image': base64Image,
      });

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        String finalImageUrl = jsonResponse['data']['url'];

        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'avatarUrl': finalImageUrl,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cập nhật ảnh đại diện thành công!"), backgroundColor: Colors.green));
        }
      } else {
        throw Exception("Lỗi server up ảnh");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi up ảnh: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoadingAvatar = false);
    }
  }

  void _showEditNameDialog(String currentName) {
    TextEditingController nameController = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Đổi tên hiển thị"),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: "Nhập tên mới",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty && user != null) {
                  await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                    'displayName': nameController.text.trim(),
                  });
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật tên!"), backgroundColor: Colors.green));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
              child: const Text("Lưu", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _sendPasswordResetEmail() {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isSending = false;
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text("Đổi mật khẩu"),
                content: Text("Chúng tôi sẽ gửi một đường link bảo mật đến thư:\n\n${user!.email}\n\nBạn hãy kiểm tra email để đặt lại mật khẩu nhé!"),
                actions: [
                  TextButton(
                      onPressed: isSending ? null : () => Navigator.pop(ctx),
                      child: const Text("Hủy", style: TextStyle(color: Colors.grey))
                  ),
                  ElevatedButton(
                    onPressed: isSending ? null : () async {
                      setDialogState(() => isSending = true);
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Đã gửi thư đổi mật khẩu! Vui lòng kiểm tra Email của bạn."), backgroundColor: Colors.green)
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red)
                          );
                        }
                      } finally {
                        setDialogState(() => isSending = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                    child: isSending
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Gửi Email", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text("Vui lòng đăng nhập."));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("Tài khoản", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          String displayName = "Người yêu cây";
          String? avatarUrl;
          String role = "user"; // Mặc định quyền là user bình thường

          if (snapshot.hasData && snapshot.data!.data() != null) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            displayName = data['displayName'] ?? displayName;
            avatarUrl = data['avatarUrl'];
            role = data['role'] ?? "user"; // Đọc quyền của tài khoản từ Firestore
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _changeAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0xFFE8F5E9),
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: _isLoadingAvatar
                            ? const CircularProgressIndicator()
                            : (avatarUrl == null ? Icon(Icons.person, size: 50, color: primaryGreen) : null),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: primaryGreen, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                      onPressed: () => _showEditNameDialog(displayName),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(user!.email ?? "", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 32),
                const Divider(),

                // --- CHÈN NÚT BẤM BÍ MẬT: CHỈ HIỂN THỊ NẾU LÀ ADMIN ---
                if (role == "admin") ...[
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.admin_panel_settings, color: Colors.red),
                    ),
                    title: const Text("Bảng điều khiển Admin", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    trailing: const Icon(Icons.chevron_right, color: Colors.red),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],

                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.lock_outline, color: Colors.blue),
                  ),
                  title: const Text("Đổi mật khẩu qua Email", style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _sendPasswordResetEmail,
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.help_outline, color: Colors.orange),
                  ),
                  title: const Text("Hỗ trợ & Góp ý", style: TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tính năng đang phát triển")));
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _signOut(context),
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text("ĐĂNG XUẤT", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}