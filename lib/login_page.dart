import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_admin.dart';
import 'dashboard_member.dart';
import 'dashboard_tenant.dart';
import 'register_member_page.dart';
import 'register_tenant_page.dart';
import 'lupa_password.dart'; // IMPORT FILE LUPA PASSWORD BARU

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
  final supabase = Supabase.instance.client;

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Email dan kata sandi tidak boleh kosong.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user != null) {
        final userId = response.user!.id;

        // 1. Cek apakah user adalah Tenant
        final tenantCheck = await supabase
            .from('tenants')
            .select('status')
            .eq('id', userId)
            .maybeSingle();

        if (tenantCheck != null) {
          if (tenantCheck['status'] == 'approved') {
            Get.offAll(() => DashboardTenantPage());
          } else {
            await supabase.auth.signOut();
            Get.snackbar(
              'Akses Ditangguhkan',
              'Akun Mitra Tenant Anda belum disetujui oleh Admin pusat.',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          }
          return;
        }

        // 2. Cek apakah user adalah Admin atau Member biasa
        final profileCheck = await supabase
            .from('profiles')
            .select('role')
            .eq('id', userId)
            .maybeSingle();

        if (profileCheck != null) {
          String role = profileCheck['role'] ?? 'member';
          if (role == 'admin') {
            Get.offAll(() => DashboardAdminPage());
          } else {
            Get.offAll(() => DashboardMember());
          }
          return;
        }

        // 3. Default jika tidak ada di kedua tabel
        Get.offAll(() => DashboardMember());
      }
    } on AuthException catch (error) {
      Get.snackbar(
        'Login Gagal',
        error.message,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan sistem: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.recycling, size: 60, color: Colors.green),
                    const SizedBox(height: 10),
                    const Text(
                      "Wadah Runtah",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 24),
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
                          icon: Icon(
                            _obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                    ),
                    // TOMBOL LUPA PASSWORD DITAMBAHKAN DI SINI
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Get.to(() => const LupaPasswordPage()),
                        child: const Text(
                          'Lupa Password?',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.green)
                        : SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: _login,
                              child: const Text(
                                'MASUK APLIKASI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Get.to(() => RegisterMemberPage()),
                          child: const Text(
                            'Daftar Member',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.to(() => RegisterTenantPage()),
                          child: const Text(
                            'Daftar Mitra Tenant',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Powered By PT. Kopi Pasteu Indonesia",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
