import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase menggunakan URL proyek Anda
  await Supabase.initialize(
    url: 'https://apxbviuerlkssbcgefpj.supabase.co',
    anonKey:
        'sb_publishable_uNhEUcw2uHZfDZvJpofX1w_fSaOGFOS', // <--- GANTI TEKS INI DENGAN KUNCI YANG ANDA SALIN
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Aplikasi Pengelolaan Bank Sampah - Wadah Runtah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      // Konfigurasi Transisi Halaman Global (Fade In)
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 300),

      home: const LoginPage(),
    );
  }
}
