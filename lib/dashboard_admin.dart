import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';
import 'input_setoran.dart'; // Pastikan file ini sudah Anda buat sebelumnya

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  final _supabase = Supabase.instance.client;
  int _totalWarga = 0;
  double _totalSampah = 0;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  // Fungsi untuk mengambil ringkasan data dari database
  Future<void> _fetchAdminData() async {
    try {
      final userRes = await _supabase.from('profiles').select('id');
      final transRes = await _supabase.from('transactions').select('weight');
      
      double totalWeight = 0;
      for (var row in transRes) {
        totalWeight += (row['weight'] ?? 0).toDouble();
      }

      setState(() {
        _totalWarga = userRes.length;
        _totalSampah = totalWeight;
      });
    } catch (e) {
      print("Error fetching data: $e");
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
        title: Text('Dashboard Admin Bank Sampah - Wadah Runtah', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              Get.defaultDialog(
                title: "Konfirmasi",
                middleText: "Keluar dari dashboard admin ?",
                textConfirm: "Ya",
                textCancel: "Batal",
                confirmTextColor: Colors.white,
                onConfirm: () => _handleLogout(),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Ringkasan Data", 
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildStatCard("Total Member", "$_totalMember", Colors.blue, Icons.people),
                const SizedBox(width: 15),
                _buildStatCard("Total Sampah", "${_totalSampah.toStringAsFixed(1)} Kg", Colors.orange, Icons.delete_sweep),
              ],
            ),
            const SizedBox(height: 30),
            const Text("Aksi Cepat", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.add_chart, color: Colors.blue),
              title: const Text("Input Setoran Sampah Baru"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Get.to(() => const InputSetoranPage())?.then((_) => _fetchAdminData());
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const InputSetoranPage())?.then((_) => _fetchAdminData()),
        label: const Text("Input Setoran"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue[800],
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
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
            Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}