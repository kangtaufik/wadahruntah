import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_member.dart';
import 'dashboard_admin.dart';
import 'main.dart'; // Import WelcomePage di sini

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // FUNGSI INTI: Login + Cek Role Otomatis
  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Get.snackbar("Error", "Silahkan isi Email dan Password dengan benar",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Proses Login ke Supabase
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        // 2. Ambil data ROLE dari tabel profiles secara real-time
        final profileData = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', response.user!.id)
            .single();

        String role = profileData['role'] ?? 'member';

        // 3. Lempar ke Dashboard yang Sesuai
        if (role == 'admin') {
          Get.offAll(() => const DashboardAdminPage());
        } else {
          Get.offAll(() => const DashboardMember());
        }
      }
    } catch (e) {
      Get.snackbar("Gagal Login", "Silahkan Cek kembali email atau passwonrd Anda $e",
          snackPosition: SnackPosition.BOTTOM, backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login Aplikasi Wadah Runtah')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // INPUT EMAIL
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next, // Pindah ke password pas di-next
            ),
            const SizedBox(height: 20),

            // INPUT PASSWORD + FITUR ENTER
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              textInputAction: TextInputAction.done, // Muncul tombol "Enter/Done" di keyboard
              onSubmitted: (_) => _handleLogin(), // JALANKAN LOGIN PAS PENCET ENTER
            ),
            const SizedBox(height: 30),

            // TOMBOL LOGIN
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('LOGIN SEKARANG', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}