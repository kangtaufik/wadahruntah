import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  final _supabase = Supabase.instance.client;
  int _totalMember = 0; // Menggunakan variabel member sesuai keinginan Anda
  double _totalSampah = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Fungsi untuk menarik data Member dan Statistik Sampah
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      // Menghitung jumlah akun yang terdaftar di tabel profiles
      final memberRes = await _supabase.from('profiles').select('id');
      
      // Mengambil data berat sampah dari tabel transactions (jika ada)
      final transRes = await _supabase.from('transactions').select('weight');
      
      double weightSum = 0;
      for (var item in transRes) {
        weightSum += (item['weight'] ?? 0).toDouble();
      }

      setState(() {
        _totalMember = memberRes.length;
        _totalSampah = weightSum;
      });
    } catch (e) {
      debugPrint("Log: Tabel transaksi mungkin belum tersedia: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    await _supabase.auth.signOut();
    Get.offAll(() => const WelcomePage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Admin - Bank Sampah - Wadah Runtah', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Get.defaultDialog(
                title: "Konfirmasi",
                middleText: "Keluar dari sistem ?",
                textConfirm: "Ya",
                textCancel: "Batal",
                onConfirm: () => _handleLogout(),
              );
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Statistik Member & Sampah", 
                  style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // Menampilkan data Member sesuai yang Anda minta
                    _buildStatCard("Total Member", "$_totalMember", Colors.blue, Icons.group),
                    const SizedBox(width: 15),
                    _buildStatCard("Total Sampah", "${_totalSampah.toStringAsFixed(1)} Kg", Colors.orange, Icons.delete),
                  ],
                ),
                const SizedBox(height: 30),
                const Center(
                  child: Text("Data ditarik otomatis realtime",
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                )
              ],
            ),
          ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}