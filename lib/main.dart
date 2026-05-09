import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'dashboard_member.dart';
import 'dashboard_admin.dart'; 
import 'verification_success_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://apxbviuerlkssbcgefpj.supabase.co',
    anonKey: 'sb_publishable_uNhEUcw2uHZfDZvJpofX1w_fSaOGFOS',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Aplikasi Bank Sampah - Wadah Runtah',
      theme: ThemeData(
        primaryColor: Colors.green,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino, 
      home: const WelcomePage(),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // LOGIKA FIX: Pake currentSession biar nggak error compile
  Future<void> handleAuthAndRole() async {
    final session = Supabase.instance.client.auth.currentSession;
    
    if (session != null) {
      // Munculkan loading bray
      Get.dialog(
        const Center(child: CircularProgressIndicator(color: Colors.white)),
        barrierDismissible: false,
      );

      try {
        // Ambil data role terbaru
        final response = await Supabase.instance.client
            .from('profiles')
            .select('role')
            .eq('id', session.user.id)
            .single();

        String role = response['role'] ?? 'member';
        
        // Tutup loading
        if (Get.isDialogOpen ?? false) Get.back();

        // Pindah halaman sesuai role di database
        if (role == 'admin') {
          Get.offAll(() => const DashboardAdminPage());
        } else {
          Get.offAll(() => const DashboardMember());
        }
      } catch (e) {
        if (Get.isDialogOpen ?? false) Get.back();
        print("Error Role: $e");
        // Kalau error (misal profile blum dibuat), lempar ke member dulu
        Get.offAll(() => const DashboardMember());
      }
    } else {
      // Kalau belum login sama sekali
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
                  onPressed: () => handleAuthAndRole(), 
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