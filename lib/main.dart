import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'dashboard_member.dart';
import 'dashboard_admin.dart'; // Import Dashboard Admin yang baru dibuat
import 'verification_success_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi layanan Supabase (Key lo tetap aman di sini bray)
  await Supabase.initialize(
    url: 'https://apxbviuerlkssbcgefpj.supabase.co',
    anonKey: 'sb_publishable_uNhEUcw2uHZfDZvJpofX1w_fSaOGFOS',
  );

  // Listener untuk mendeteksi perubahan status autentikasi
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    
    if (event == AuthChangeEvent.userUpdated) {
      Get.offAll(
        () => const VerificationSuccessPage(),
        transition: Transition.fadeIn,
        duration: const Duration(milliseconds: 800),
      );
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

  // FUNGSI BARU: Ngecek Role ke Supabase sebelum masuk Dashboard
  Future<void> handleAuthAndRole() async {
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      // Tampilkan loading sebentar bray
      Get.dialog(const Center(child: CircularProgressIndicator(color: Colors.white,)), barrierDismissible: false);

      try {
        final user = session.user;
        final response = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .single();

        String role = response['role'] ?? 'member';

        Get.back(); // Tutup loading

        if (role == 'admin') {
          Get.offAll(() => const DashboardAdminPage());
        } else {
          Get.offAll(() => const DashboardMember());
        }
      } catch (e) {
        Get.back(); // Tutup loading
        // Jika profile belum ada atau error, default ke Member
        Get.offAll(() => const DashboardMember());
      }
    } else {
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
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(scale: value, child: child),
                );
              },
              child: const Icon(Icons.recycling, size: 120, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text(
              'Wadah Runtah',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
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
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () => handleAuthAndRole(), // Panggil fungsi cek role
                  child: const Text(
                    'MULAI SEKARANG',
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