import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'manage_waste_categories_page.dart';
import 'verify_deposits_page.dart';
import 'verify_payouts_page.dart'; // Memastikan halaman baru terimport dengan benar

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _pendingTenants = [];
  bool _isLoading = true;

  int _totalWarga = 0;
  int _totalPoinBeredar = 0;
  double _totalSampahKg = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAdminDashboardData();
  }

  Future<void> _loadAdminDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final tenantData = await supabase
          .from('tenants')
          .select('*')
          .eq('status', 'pending');
      final wargaData = await supabase
          .from('profiles')
          .select('id, saldo_poin')
          .eq('role', 'member');
      final depositData = await supabase
          .from('deposits')
          .select('berat')
          .eq('status', 'approved');

      int totalPoin = 0;
      for (var item in wargaData) {
        totalPoin += (item['saldo_poin'] as int? ?? 0);
      }

      double totalBerat = 0.0;
      for (var item in depositData) {
        totalBerat += (item['berat'] as num? ?? 0.0).toDouble();
      }

      setState(() {
        _pendingTenants = tenantData;
        _totalWarga = wargaData.length;
        _totalPoinBeredar = totalPoin;
        _totalSampahKg = totalBerat;
        _isLoading = false;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat data statistik: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTenantStatus(String tenantId, String status) async {
    try {
      await supabase
          .from('tenants')
          .update({'status': status})
          .eq('id', tenantId);
      _loadAdminDashboardData();
      Get.snackbar(
        'Sukses',
        'Status mitra diperbarui.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal update status: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Dashboard Admin",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Get.offAll(() => const LoginPage()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : RefreshIndicator(
              onRefresh: _loadAdminDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ringkasan Performa Sistem",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatCard(
                          "Total Member",
                          "$_totalWarga Orang",
                          Icons.people,
                          Colors.purple,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          "Sampah Terkumpul",
                          "${_totalSampahKg.toStringAsFixed(1)} Kg",
                          Icons.delete_sweep,
                          Colors.green,
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          "Poin Beredar",
                          "$_totalPoinBeredar Pts",
                          Icons.monetization_on,
                          Colors.orange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "Grafik Volume Setoran per Kategori",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCustomBarChart(),

                    const SizedBox(height: 30),
                    const Text(
                      "Menu Navigasi Admin",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // MENU NAVIGASI DENGAN TAMBAHAN TOMBOL PAYOUT
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    Get.to(() => const VerifyDepositsPage()),
                                icon: const Icon(
                                  Icons.fact_check,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Verifikasi Setoran",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Get.to(
                                  () => const ManageWasteCategoriesPage(),
                                ),
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Kelola Harga Sampah",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                Get.to(() => const VerifyPayoutsPage()),
                            icon: const Icon(
                              Icons.payments,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Verifikasi Payout Dana Tenant",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "Antrean Verifikasi Mitra Tenant",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _pendingTenants.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(
                                child: Text(
                                  "Bersih! Tidak ada antrean verifikasi mitra tenant.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _pendingTenants.length,
                            itemBuilder: (context, index) {
                              final tenant = _pendingTenants[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  title: Text(
                                    tenant['nama_toko'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Alamat: ${tenant['alamat'] ?? '-'}",
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _updateTenantStatus(
                                          tenant['id'],
                                          'rejected',
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        ),
                                        onPressed: () => _updateTenantStatus(
                                          tenant['id'],
                                          'approved',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 40),
                    // TEKS FOOTER PERUSAHAAN
                    const Center(
                      child: Text(
                        "Powered By PT. Kopi Pasteu Indonesia",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomBarChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar("Plastik", 0.75, Colors.blue),
              _buildBar("Kertas", 0.40, Colors.green),
              _buildBar("Logam", 0.25, Colors.orange),
              _buildBar("Minyak", 0.55, Colors.red),
              _buildBar("E-Waste", 0.15, Colors.purple),
            ],
          ),
          const Divider(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(Colors.blue, "Plastik"),
              const SizedBox(width: 15),
              _buildLegend(Colors.green, "Kertas"),
              const SizedBox(width: 15),
              _buildLegend(Colors.orange, "Logam"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double fillPercent, Color color) {
    return Column(
      children: [
        Text(
          "${(fillPercent * 100).toInt()}%",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          height: 150,
          width: 35,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 150 * fillPercent,
            width: 35,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
