import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ilustrasi atau Logo Aplikasi
              const Icon(
                Icons.recycling_rounded,
                size: 120,
                color: Colors.green,
              ),
              const SizedBox(height: 24),

              // Judul Utama
              const Text(
                'Wadah Runtah',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),

              // Subjudul / Deskripsi
              const Text(
                'Aplikasi Sistem Pengelolaan Bank Sampah Modern',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Tombol Aksi Menuju Halaman Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Berpindah ke Halaman Login menggunakan GetX
                    Get.to(() => const LoginPage());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Mulai',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // Teks Footer Identitas Perusahaan
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
        child: Text(
          'Powered By : PT. Kopi Pasteu Indonesia',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
