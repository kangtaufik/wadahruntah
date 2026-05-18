import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'manage_waste_categories_page.dart';
import 'verify_deposits_page.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _pendingTenants = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingTenants(); // Ambil daftar toko yang nunggu verifikasi berkas
  }

  // --- 1. AMBIL DATA TENANT PENDING DARI DB ---
  Future<void> _fetchPendingTenants() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('tenants')
          .select('*')
          .eq('status', 'pending');
      setState(() {
        _pendingTenants = data;
        _isLoading = false;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat data tenant: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() => _isLoading = false);
    }
  }

  // --- 2. PROSES UPDATE STATUS TENANT (SETUJUI / TOLAK) ---
  Future<void> _updateTenantStatus(String tenantId, String status) async {
    try {
      await supabase
          .from('tenants')
          .update({'status': status})
          .eq('id', tenantId);

      _fetchPendingTenants(); // Refresh data antrean secara live

      Get.snackbar(
        'Sukses',
        'Status mitra berhasil diperbarui menjadi $status.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal memperbarui status mitra: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Dashboard Pusat Admin"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Get.offAll(() => const LoginPage()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Menu Utama Pengendalian Admin",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // HUBUNGAN TOMBOL NAVIGASI UTAMA ADMIN
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Get.to(() => const VerifyDepositsPage()),
                    icon: const Icon(Icons.fact_check, color: Colors.white),
                    label: const Text(
                      "Verifikasi Setoran Warga",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Get.to(() => const ManageWasteCategoriesPage()),
                    icon: const Icon(Icons.settings, color: Colors.white),
                    label: const Text(
                      "Kelola Harga Sampah",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
            const Text(
              "Antrean Verifikasi Berkas Mitra Tenant",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            // DAFTAR ANTREAN VERIFIKASI MITRA TENANT (TOKO)
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  )
                : _pendingTenants.isEmpty
                ? const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(
                        child: Text(
                          "Bersih! Tidak ada antrean verifikasi toko/tenant saat ini.",
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
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenant['nama_toko'] ?? 'Nama Toko Kosong',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text("Alamat Usaha: ${tenant['alamat'] ?? '-'}"),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => _updateTenantStatus(
                                      tenant['id'],
                                      'rejected',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text("TOLAK"),
                                  ),
                                  const SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () => _updateTenantStatus(
                                      tenant['id'],
                                      'approved',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    child: const Text(
                                      "SETUJUI MITRA",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
