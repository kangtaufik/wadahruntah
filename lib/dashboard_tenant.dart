import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'scan_payment_page.dart';

class DashboardTenantPage extends StatefulWidget {
  const DashboardTenantPage({super.key});

  @override
  State<DashboardTenantPage> createState() => _DashboardTenantPageState();
}

class _DashboardTenantPageState extends State<DashboardTenantPage> {
  final supabase = Supabase.instance.client;
  String _namaToko = "Memuat Nama Toko...";
  int _saldoPoinToko = 0;
  bool _isLoading = true;
  final _poinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTenantData();
  }

  Future<void> _fetchTenantData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await supabase
            .from('tenants')
            .select('nama_toko, saldo_poin')
            .eq('id', user.id)
            .single();

        setState(() {
          _namaToko = data['nama_toko'] ?? "Mitra Tenant";
          _saldoPoinToko = data['saldo_poin'] ?? 0;
          _isLoading = false;
        });
      } catch (e) {
        print("Error mengambil data tenant: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  // FUNGSI UNTUK MENGAJUKAN PENCAIRAN POIN
  void _showPayoutDialog() {
    _poinController.clear();
    Get.defaultDialog(
      title: "Ajukan Pencairan Poin",
      content: Column(
        children: [
          Text(
            "Saldo Aktif: $_saldoPoinToko Poin",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Konversi: 1 Poin = Rp 1.000",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _poinController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Jumlah Poin yang Dicairkan",
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      textCancel: "BATAL",
      textConfirm: "KIRIM",
      confirmTextColor: Colors.white,
      buttonColor: Colors.orange,
      onConfirm: () async {
        int? inputPoin = int.tryParse(_poinController.text);
        if (inputPoin == null || inputPoin <= 0) {
          Get.snackbar(
            "Gagal",
            "Masukkan jumlah poin yang valid.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }
        if (inputPoin > _saldoPoinToko) {
          Get.snackbar(
            "Gagal",
            "Saldo poin toko Anda tidak mencukupi.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        try {
          int nominalRupiah = inputPoin * 1000; // Skema konversi rupiah
          await supabase.from('payouts').insert({
            'tenant_id': supabase.auth.currentUser!.id,
            'jumlah_poin': inputPoin,
            'nominal_rupiah': nominalRupiah,
            'status': 'pending',
          });
          Get.back();
          Get.snackbar(
            "Sukses",
            "Permintaan pencairan berhasil dikirim ke Admin.",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            "Error",
            "Gagal mengirim permintaan: $e",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    );
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
          // LOGOUT SAPU JAGAT DITAMBAHKAN DI SINI
          IconButton(
            onPressed: () async {
              try {
                // 1. Hapus sesi dari server Supabase & Local Storage
                await Supabase.instance.client.auth.signOut();

                // 2. Hancurkan semua controller/state GetX yang nyangkut di memori
                Get.deleteAll(force: true);

                // 3. Kasih jeda dikit biar browser beneran nafas buang cache
                await Future.delayed(const Duration(milliseconds: 300));

                // 4. Tendang ke halaman login
                Get.offAll(() => const LoginPage());
              } catch (error) {
                Get.snackbar(
                  'Error',
                  'Gagal logout: $error',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
              onRefresh: _fetchTenantData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Selamat Datang Mitra,",
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                        Text(
                          _namaToko,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 20),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Total Pendapatan Poin Toko Anda",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$_saldoPoinToko Poin",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(color: Colors.white38),
                              const Text(
                                "Poin ini dapat dicairkan kembali menjadi uang tunai melalui persetujuan Admin.",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
                        const Text(
                          "Layanan Operasional",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),

                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 1.4,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  Get.to(() => const ScanPaymentPage()),
                              child: _buildTenantMenuCard(
                                Icons.qr_code_scanner,
                                "Terima Pembayaran",
                                Colors.blue,
                              ),
                            ),
                            GestureDetector(
                              onTap:
                                  _showPayoutDialog, // Memicu fungsi dialog pencairan dana
                              child: _buildTenantMenuCard(
                                Icons.payments,
                                "Tarik Poin (Payout)",
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
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
              ),
            ),
    );
  }

  Widget _buildTenantMenuCard(IconData icon, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, size: 26, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
