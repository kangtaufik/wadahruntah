import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'dashboard_member.dart';
import 'verification_success_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi layanan Supabase
  await Supabase.initialize(
    url: 'https://apxbviuerlkssbcgefpj.supabase.co',
    anonKey: 'sb_publishable_uNhEUcw2uHZfDZvJpofX1w_fSaOGFOS',
  );

  // Listener untuk mendeteksi perubahan status autentikasi secara otomatis
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final AuthChangeEvent event = data.event;
    
    // Jika user berhasil memverifikasi email, arahkan ke halaman sukses
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
      
      // KONFIGURASI TRANSISI GLOBAL (LEBIH HALUS)
      defaultTransition: Transition.cupertino, 
      transitionDuration: const Duration(milliseconds: 600),
      
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animasi transisi masuk untuk logo
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
                  onPressed: () {
                    final session = Supabase.instance.client.auth.currentSession;
                    if (session != null) {
                      Get.offAll(() => const DashboardMember());
                    } else {
                      Get.to(() => const LoginPage());
                    }
                  },
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