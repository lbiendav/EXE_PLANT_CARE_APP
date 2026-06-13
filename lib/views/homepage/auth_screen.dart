import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLogin = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final Color primaryGreen = const Color(0xFF2E7D32);

  Future<void> _submitAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin!")));
      return;
    }

    if (!_isLogin && _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập Tên của bạn!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': _emailController.text.trim(),
          'displayName': _nameController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'avatarUrl': null,
        });
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainScreen()));
      }
    } on FirebaseAuthException catch (e) {
      String message = "Đã xảy ra lỗi!";
      if (e.code == 'user-not-found') message = "Không tìm thấy tài khoản với email này.";
      else if (e.code == 'wrong-password') message = "Mật khẩu không chính xác.";
      else if (e.code == 'email-already-in-use') message = "Email này đã được sử dụng.";
      else if (e.code == 'weak-password') message = "Mật khẩu quá yếu.";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HÀM MỚI: XỬ LÝ QUÊN MẬT KHẨU ---
  void _showForgotPasswordDialog() {
    TextEditingController resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        bool isSending = false;
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text("Khôi phục mật khẩu"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Nhập địa chỉ Email của bạn, chúng tôi sẽ gửi đường dẫn để tạo mật khẩu mới.", style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: "Email đăng ký",
                        prefixIcon: const Icon(Icons.email_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: isSending ? null : () => Navigator.pop(ctx),
                      child: const Text("Hủy", style: TextStyle(color: Colors.grey))
                  ),
                  ElevatedButton(
                    onPressed: isSending ? null : () async {
                      if (resetEmailController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập Email!")));
                        return;
                      }
                      setDialogState(() => isSending = true);
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(email: resetEmailController.text.trim());
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Đã gửi thư khôi phục! Vui lòng kiểm tra Email."), backgroundColor: Colors.green)
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red));
                        }
                      } finally {
                        setDialogState(() => isSending = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                    child: isSending
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Gửi link", style: TextStyle(color: Colors.white)),
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.eco, size: 80, color: primaryGreen),
              const SizedBox(height: 16),
              Text(
                _isLogin ? "Chào mừng trở lại!" : "Tạo tài khoản mới",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryGreen),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Khám phá và chăm sóc khu vườn của bạn",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              if (!_isLogin) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Tên hiển thị",
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Mật khẩu",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // NÚT QUÊN MẬT KHẨU CHO MÀN HÌNH ĐĂNG NHẬP
              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text("Quên mật khẩu?", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
                  ),
                ),

              const SizedBox(height: 24),

              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitAuth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    _isLogin ? "ĐĂNG NHẬP" : "ĐĂNG KÝ",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isLogin ? "Chưa có tài khoản? " : "Đã có tài khoản? "),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _emailController.clear();
                        _passwordController.clear();
                        _nameController.clear();
                      });
                    },
                    child: Text(
                      _isLogin ? "Đăng ký ngay" : "Đăng nhập",
                      style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}