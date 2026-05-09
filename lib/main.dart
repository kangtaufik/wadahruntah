import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_page.dart';

void main() {
  runApp(const WadahRuntahApp());
}

class WadahRuntahApp extends StatelessWidget {
  const WadahRuntahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Wadah Runtah',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    // Ini timer 3 detik buat pindah ke halaman Login
    Future.delayed(const Duration(seconds: 3), () {
      Get.off(() => const LoginPage());
    });

    return Scaffold(
      backgroundColor: Colors.green.shade700,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.recycling,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'WADAH RUNTAH',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Sampah -> Poin -> Reward',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}