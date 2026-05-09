import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_page.dart';

class SuccessRegisterPage extends StatelessWidget {
  const SuccessRegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read, size: 100, color: Colors.green),
              const SizedBox(height: 24),
              const Text(
                'Registrasi Berhasil!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Selamat akun anda sudah berhasil dibuat. Silakan cek email untuk mengaktivasi akun anda',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () => Get.offAll(() => const LoginPage()),
                  child: const Text('Kembali Ke Halaman Login', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}