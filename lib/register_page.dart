import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'success_register_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  Future<void> _signUp() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Mohon isi semua kolom data yang tersedia.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'full_name': _nameController.text.trim()},
      );

      if (response.user != null) {
        Get.offAll(() => const SuccessRegisterPage());
      }
    } catch (e) {
      Get.snackbar(
        'Kesalahan Registrasi',
        'Terjadi kendala saat melakukan pendaftaran: $e',
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
      appBar: AppBar(
        title: const Text('Registrasi Pengguna', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.person_add, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Alamat Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 32),
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
                      onPressed: _signUp, 
                      child: const Text('DAFTAR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}