import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'login_page.dart';

class DashboardMember extends StatefulWidget {
  const DashboardMember({super.key});

  @override
  State<DashboardMember> createState() => _DashboardMemberState();
}

class _DashboardMemberState extends State<DashboardMember> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  
  // Data Warga
  String name = "...";
  int points = 0;
  double wasteKg = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Fungsi buat narik data asli dari Tabel Profiles di Supabase
  Future<void> _loadUserData() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      setState(() {
        name = data['full_name'] ?? 'Warga Girimekar';
        points = data['total_points'] ?? 0;
        wasteKg = (data['total_waste_kg'] ?? 0).toDouble();
        _isLoading = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Gagal ambil data: $e', backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  // Fungsi Logout
  Future<void> _logout() async {
    await supabase.auth.signOut();
    Get.offAll(() => const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Wadah Runtah', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.green))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat Datang,', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 25),
                
                // Card Saldo Poin
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      const Text('TOTAL SALDO POIN', style: TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 10),
                      Text('$points Poin', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Card Statistik Sampah
                Row(
                  children: [
                    Expanded(
                      child: _statCard('Total Sampah', '${wasteKg.toStringAsFixed(1)} Kg', Icons.delete_outline, Colors.orange),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _statCard('Status Akun', 'Aktif', Icons.check_circle_outline, Colors.blue),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                const Text('Menu Utama', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                
                // List Menu Simpel
                _menuItem(Icons.qr_code_scanner, 'Setor Sampah', 'Dalam Pengembangan'),
                _menuItem(Icons.history, 'Riwayat Setoran', 'Cek aktivitas Anda'),
                _menuItem(Icons.card_giftcard, 'Tukar Poin', 'Ambil hadiah menarik'),
              ],
            ),
          ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, String subtitle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
           Get.snackbar('Info', 'Fitur $title Segera Hadir', backgroundColor: Colors.orange, colorText: Colors.white);
        },
      ),
    );
  }
}