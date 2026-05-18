import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import 'login_page.dart';

class DashboardTenantPage extends StatefulWidget {
  const DashboardTenantPage({super.key});

  @override
  State<DashboardTenantPage> createState() => _DashboardTenantPageState();
}

class _DashboardTenantPageState extends State<DashboardTenantPage> {
  String _storeName = "Memuat Toko...";
  String _status = "pending";
  int _pointsReceived = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkTenantStatus();
  }

  // Mengambil data status verifikasi toko tenant dari Supabase
  Future<void> _checkTenantStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('tenants')
            .select('nama_toko, status, saldo_poin')
            .eq('id', user.id)
            .maybeSingle();

        if (data != null) {
          setState(() {
            _storeName = data['nama_toko'] ?? "Mitra Tenant";
            _status = data['status'] ?? "pending";
            _pointsReceived = data['saldo_poin'] ?? 0;
            _isLoading = false;
          });
        } else {
          setState(() {
            _storeName = "Toko Tidak Ditemukan";
            _status = "rejected";
            _isLoading = false;
          });
        }
      } catch (e) {
        print("Error Tenant Check: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Dashboard Mitra Tenant"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Get.offAll(() => const LoginPage()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    // 1. KONDISI JIKA AKUN MASIH PENDING
    if (_status == 'pending') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_empty,
                size: 100,
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              Text(
                _storeName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Akun toko Anda sedang dalam antrean verifikasi berkas oleh Admin Wadah Runtah. Mohon tunggu maksimal 1x24 jam.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // 2. KONDISI JIKA AKUN DITOLAK ADMIN
    if (_status == 'rejected') {
      return const Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gpp_bad, size: 100, color: Colors.red),
              SizedBox(height: 20),
              Text(
                "Verifikasi Mitra Ditolak",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Mohon maaf, dokumen KTP atau Foto Usaha Anda dinilai tidak valid oleh tim verifikator kami. Silakan hubungi admin.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // 3. KONDISI JIKA AKUN SUDAH DI-APPROVED (AKTIF)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Selamat Datang,",
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          Text(
            _storeName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 20),

          // Kartu Poin Toko
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Poin Yang Dikumpulkan Toko",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 5),
                Text(
                  "$_pointsReceived Poin",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(color: Colors.white54),
                const Text(
                  "Dapat dicairkan ke kasir atau ditukar kembali.",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            "Menu Kasir Toko",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          // Grid Menu Tenant
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            children: [
              _buildTenantMenuCard(
                Icons.qr_code_scanner,
                "Terima Pembayaran",
                Colors.blue,
              ),
              _buildTenantMenuCard(
                Icons.receipt_long,
                "Riwayat Nota",
                Colors.green,
              ),
              _buildTenantMenuCard(
                Icons.payments,
                "Pencairan Dana",
                Colors.purple,
              ),
              _buildTenantMenuCard(
                Icons.settings,
                "Pengaturan Toko",
                Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTenantMenuCard(IconData icon, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
