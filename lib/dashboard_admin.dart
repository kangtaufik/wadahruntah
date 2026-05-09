import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart'; // Wajib diimport agar sistem mengenali halaman WelcomePage

class DashboardAdminPage extends StatelessWidget {
  const DashboardAdminPage({super.key});

  /// Fungsi untuk menghapus sesi dan mengarahkan kembali ke halaman utama
  Future<void> _handleLogout() async {
    try {
      // Menghapus sesi autentikasi dari Supabase
      await Supabase.instance.client.auth.signOut();

      // Menghapus riwayat navigasi dan kembali ke halaman awal (WelcomePage)
      Get.offAll(() => const WelcomePage());
      
      Get.snackbar(
        "Berhasil",
        "Anda telah keluar dari sistem.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Gagal Keluar",
        "Terjadi kesalahan: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard Admin Bank Sampah - Wadah Runtah',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              // Dialog konfirmasi untuk menghindari klik yang tidak sengaja
              Get.defaultDialog(
                title: "Konfirmasi",
                middleText: "Apakah Anda ingin keluar dari Panel Admin?",
                textConfirm: "Ya, Keluar",
                textCancel: "Batal",
                confirmTextColor: Colors.white,
                buttonColor: Colors.red,
                onConfirm: () {
                  Get.back(); // Menutup dialog
                  _handleLogout(); // Eksekusi proses logout
                },
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text("Selamat Datang di Dashboard Admin"),
      ),
    );
  }
}