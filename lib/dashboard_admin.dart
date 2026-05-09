import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allTransactions = [];

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  // Fungsi ambil data seluruh setoran warga
  Future<void> _fetchAdminData() async {
    try {
      // Mengambil data transaksi dan join dengan tabel profiles untuk ambil nama warga
      final response = await supabase
          .from('transactions')
          .select('*, profiles(full_name)')
          .order('created_at', ascending: false);

      setState(() {
        _allTransactions = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error ambil data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Background abu kebiruan
      appBar: AppBar(
        title: Text('DASHBOARD ADMIN WADAH RUNTAH', 
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: Colors.blue[800], // WARNA KHUSUS BIRU ADMIN
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchAdminData,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await supabase.auth.signOut();
              // Navigator otomatis bakal balik ke WelcomePage karena listener di main.dart
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : RefreshIndicator(
              onRefresh: _fetchAdminData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- KARTU RINGKASAN ADMIN ---
                    Row(
                      children: [
                        _buildStatCard('Total Member', '2', Icons.groups, Colors.blue[900]!),
                        const SizedBox(width: 12),
                        _buildStatCard('Total Sampah', '7.5 kg', Icons.delete_outline, Colors.blue[600]!),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text('Log Setoran Sampah Member Terbaru',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[900])),
                    const SizedBox(height: 12),

                    // --- LIST TRANSAKSI SELURUH WARGA ---
                    _allTransactions.isEmpty 
                    ? const Center(child: Text("Belum ada data setoran masuk."))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _allTransactions.length,
                        itemBuilder: (context, index) {
                          final item = _allTransactions[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue[100],
                                child: Icon(Icons.assignment, color: Colors.blue[800]),
                              ),
                              title: Text(item['profiles']?['full_name'] ?? 'Warga Tanpa Nama',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${item['weight']} kg - ${item['waste_type']}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('+ ${item['points']} Poin',
                                      style: const TextStyle(
                                          color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const Text('Berhasil', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Nanti di sini kita buat form input setoran sampah baru
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Fitur Input Setoran segera hadir!"), backgroundColor: Colors.blue)
          );
        },
        label: const Text('Input Setoran'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue[800],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            Text(value, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}