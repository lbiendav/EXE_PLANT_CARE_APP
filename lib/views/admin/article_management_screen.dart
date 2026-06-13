// lib/views/admin/article_management_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ArticleManagementScreen extends StatefulWidget {
  const ArticleManagementScreen({super.key});

  @override
  State<ArticleManagementScreen> createState() => _ArticleManagementScreenState();
}

class _ArticleManagementScreenState extends State<ArticleManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _imgCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  // Hàm mở hộp thoại Thêm hoặc Sửa
  void _openArticleSheet(BuildContext context, {String? docId, Map<String, dynamic>? existingData}) {
    bool isEditing = docId != null;

    if (isEditing && existingData != null) {
      _titleCtrl.text = existingData['title'] ?? '';
      _imgCtrl.text = existingData['imageUrl'] ?? '';
      _contentCtrl.text = existingData['content'] ?? '';
    } else {
      _titleCtrl.clear();
      _imgCtrl.clear();
      _contentCtrl.clear();
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
                  Text(isEditing ? "Sửa bài viết" : "Thêm bài viết mới", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(labelText: "Tiêu đề bài viết"),
                    validator: (v) => v!.isEmpty ? "Không được bỏ trống" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _imgCtrl,
                    decoration: const InputDecoration(labelText: "Link ảnh bìa (URL)"),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contentCtrl,
                    decoration: const InputDecoration(labelText: "Nội dung bài viết"),
                    maxLines: 5,
                    validator: (v) => v!.isEmpty ? "Không được bỏ trống" : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        Map<String, dynamic> articleData = {
                          'title': _titleCtrl.text.trim(),
                          'imageUrl': _imgCtrl.text.trim().isEmpty ? 'https://via.placeholder.com/400' : _imgCtrl.text.trim(),
                          'content': _contentCtrl.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        };

                        if (isEditing) {
                          await FirebaseFirestore.instance.collection('articles').doc(docId).update(articleData);
                        } else {
                          articleData['createdAt'] = FieldValue.serverTimestamp();
                          await FirebaseFirestore.instance.collection('articles').add(articleData);
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
                    child: Text(isEditing ? "CẬP NHẬT BÀI VIẾT" : "ĐĂNG BÀI VIẾT", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        title: const Text("Quản lý bài viết", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openArticleSheet(context),
        backgroundColor: const Color(0xFFC62828),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('articles').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          var articles = snapshot.data?.docs ?? [];

          if (articles.isEmpty) return const Center(child: Text("Chưa có bài viết nào."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              var doc = articles[index];
              var data = doc.data() as Map<String, dynamic>;

              return Card(
                elevation: 0,
                color: Colors.grey.shade50,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(data['imageUrl'] ?? 'https://via.placeholder.com/50', width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.article)),
                  ),
                  title: Text(data['title'] ?? 'Không có tiêu đề', style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(data['content'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () => _openArticleSheet(context, docId: doc.id, existingData: data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => FirebaseFirestore.instance.collection('articles').doc(doc.id).delete(),
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