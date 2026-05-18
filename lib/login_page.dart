import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_admin.dart';
import 'dashboard_member.dart';
import 'dashboard_tenant.dart';
import 'register_member_page.dart';
import 'register_tenant_page.dart';

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
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Email dan password tidak boleh kosong.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Proses Autentikasi ke Supabase
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        final userId = response.user!.id;

        // 2. Ambil Role Pengguna dari Tabel Profiles
        final profileData = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .single();

        String role = profileData['role'] ?? 'member';

        // 3. Multi-Role Routing (Pengalihan Halaman Sesuai Role)
        if (role == 'admin') {
          Get.offAll(() => const DashboardAdminPage());
        } else if (role == 'tenant') {
          Get.offAll(() => const DashboardTenantPage());
        } else {
          Get.offAll(() => const DashboardMember());
        }
      }
    } catch (e) {
      Get.snackbar(
        'Gagal Masuk',
        'Email atau password salah, atau terjadi kendala jaringan.',
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
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.recycling, size: 80, color: Colors.green),
                const SizedBox(height: 12),
                const Text(
                  'WADAH RUNTAH',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const Text(
                  'Aplikasi Sistem Pengelolaan Bank Sampah',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscureText = !_obscureText),
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
                          ),
                          onPressed: _login,
                          child: const Text(
                            'MASUK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                const Text('Belum punya akun? Daftar sebagai:'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Get.to(() => const RegisterMemberPage()),
                        child: const Text(
                          'Member',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Get.to(() => const RegisterTenantPage()),
                        child: const Text(
                          'Mitra Tenant',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
