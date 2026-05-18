import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyPayoutsPage extends StatefulWidget {
  const VerifyPayoutsPage({super.key});

  @override
  State<VerifyPayoutsPage> createState() => _VerifyPayoutsPageState();
}

class _VerifyPayoutsPageState extends State<VerifyPayoutsPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _payoutRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPayoutRequests();
  }

  Future<void> _fetchPayoutRequests() async {
    setState(() => _isLoading = true);
    try {
      // Mengambil pengajuan payout yang berstatus pending beserta nama tokonya
      final data = await supabase
          .from('payouts')
          .select('*, tenants(nama_toko, saldo_poin)')
          .eq('status', 'pending');

      setState(() {
        _payoutRequests = data;
        _isLoading = false;
      });
    } catch (e) {
      Get.snackbar(
        "Error",
        "Gagal memuat data pencairan: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processPayout(
    Map<String, dynamic> payout,
    String targetStatus,
  ) async {
    try {
      if (targetStatus == 'approved') {
        int currentBalance = payout['tenants']['saldo_poin'] ?? 0;
        int deductedPoints = payout['jumlah_poin'];
        int newBalance = currentBalance - deductedPoints;

        if (newBalance < 0) {
          Get.snackbar(
            "Gagal",
            "Saldo toko tidak valid atau tidak mencukupi saat ini.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        // 1. Kurangi saldo poin di tabel tenants
        await supabase
            .from('tenants')
            .update({'saldo_poin': newBalance})
            .eq('id', payout['tenant_id']);
      }

      // 2. Perbarui status entri di tabel payouts
      await supabase
          .from('payouts')
          .update({'status': targetStatus})
          .eq('id', payout['id']);

      Get.snackbar(
        "Sukses",
        "Permintaan berhasil di-${targetStatus}.",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      _fetchPayoutRequests();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Gagal memproses transaksi: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verifikasi Payout Tenant"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _payoutRequests.isEmpty
          ? const Center(
              child: Text("Tidak ada pengajuan pencairan poin saat ini."),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _payoutRequests.length,
              itemBuilder: (context, index) {
                final p = _payoutRequests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.green,
                      size: 36,
                    ),
                    title: Text(
                      p['tenants']['nama_toko'] ?? "Nama Toko Tidak Diketahui",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Klaim: ${p['jumlah_poin']} Poin ➔ Rp ${p['nominal_rupiah']}\nTanggal: ${p['created_at'].toString().substring(0, 10)}",
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.cancel_outlined,
                            color: Colors.red,
                          ),
                          onPressed: () => _processPayout(p, 'rejected'),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          onPressed: () => _processPayout(p, 'approved'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
