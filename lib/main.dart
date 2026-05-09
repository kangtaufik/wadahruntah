import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'dashboard_member.dart';
import 'dashboard_admin.dart'; 
import 'verification_success_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase - URL & Key lo tetap aman di sini
  await Supabase.initialize(
    url: 'https://apxbviuerlkssbcgefpj.supabase.co',
    anonKey: 'sb_publishable_uNhEUcw2uHZfDZvJpofX1w_fSaOGFOS',
  );

  // Listener untuk verifikasi email otomatis
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.userUpdated) {
      Get.offAll(() => const VerificationSuccessPage());
    }
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Wadah Runtah',
      theme: ThemeData(
        primaryColor: Colors.green,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino, 
      transitionDuration: const Duration(milliseconds: 600),
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // LOGIKA ANTI-SALAH DASHBOARD: Cek role secara real-time
  Future<void> handleAuthAndRole() async {
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      // Munculkan loading biar nggak loncat ke dashboard salah
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.white)),
        barrierDismissible: false,
      );

      try {
        // Ambil data role dari tabel profiles berdasarkan ID user
        final response = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', session.user.id)
            .single();

        String role = response['role'] ?? 'member';
        
        Get.back(); // Tutup loading

        // Eksekusi pemindahan halaman berdasarkan role database
        if (role == 'admin') {
          Get.offAll(() => const DashboardAdminPage());
        } else {
          Get.offAll(() => const DashboardMember());
        }
      } catch (e) {
        Get.back(); // Tutup loading
        print("Error Role: $e");
        // Jika error, default ke Member bray biar aman
        Get.offAll(() => const DashboardMember());
      }
    } else {
      // Jika belum login, lempar ke halaman login
      Get.to(() => const LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.recycling, size: 120, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'Aplikasi Bank Sampah - Wadah Runtah',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text(
              'Kelola Sampah Jadi Berkah',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 50),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  // Manggil fungsi pengecekan role yang baru
                  onPressed: () => handleAuthAndRole(), 
                  child: const Text(
                    'Mulai Sekarang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}