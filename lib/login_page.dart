import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_page.dart';
import 'dashboard_member.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _login() async {
    // 1. Validasi Input: Memastikan kolom tidak kosong
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      Get.snackbar(
        'Informasi', 
        'Silakan masukkan alamat email dan kata sandi Anda terlebih dahulu.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
        icon: const Icon(Icons.info_outline, color: Colors.white),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 2. Proses Otentikasi ke Supabase
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        Get.offAll(() => const DashboardMember());
      }
    } on AuthException catch (e) {
      // 3. Penanganan Error Spesifik dari Supabase (Password Salah/User Tidak Ada)
      Get.snackbar(
        'Login Gagal', 
        'Email atau kata sandi yang Anda masukkan tidak sesuai.',
        backgroundColor: Colors.red, 
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(15),
      );
    } catch (e) {
      Get.snackbar(
        'Kesalahan', 
        'Terjadi kesalahan sistem: $e',
        backgroundColor: Colors.red, 
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.recycling, size: 80, color: Colors.green),
              const SizedBox(height: 16),
              const Text(
                'Wadah Runtah',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 32),
              // Input Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Alamat Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              // Input Password dengan fitur Show/Hide
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscureText = !_obscureText),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.green)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _login,
                        child: const Text(
                          'MASUK', 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Get.to(() => const RegisterPage()),
                child: const Text(
                  'Belum memiliki akun? Registrasi di sini', 
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}