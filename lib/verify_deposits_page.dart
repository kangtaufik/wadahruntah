import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyDepositsPage extends StatefulWidget {
  const VerifyDepositsPage({super.key});

  @override
  State<VerifyDepositsPage> createState() => _VerifyDepositsPageState();
}

class _VerifyDepositsPageState extends State<VerifyDepositsPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _pendingDeposits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingDeposits();
  }

  Future<void> _fetchPendingDeposits() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('deposits')
          .select('*, profiles(full_name)')
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      setState(() {
        _pendingDeposits = data;
        _isLoading = false;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat data setoran: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveDeposit(Map<String, dynamic> deposit) async {
    final String memberId = deposit['member_id'];
    final int poinTambah = deposit['poin_estimasi'];
    final int depositId = deposit['id'];

    try {
      final userProfile = await supabase
          .from('profiles')
          .select('saldo_poin')
          .eq('id', memberId)
          .single();

      int currentSaldo = userProfile['saldo_poin'] ?? 0;
      int saldoBaru = currentSaldo + poinTambah;

      await supabase
          .from('profiles')
          .update({'saldo_poin': saldoBaru})
          .eq('id', memberId);

      await supabase
          .from('deposits')
          .update({'status': 'approved'})
          .eq('id', depositId);

      _fetchPendingDeposits();

      Get.snackbar(
        'Berhasil',
        'Setoran disetujui! Saldo warga bertambah $poinTambah poin.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal memproses verifikasi: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verifikasi Setoran Sampah"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _pendingDeposits.isEmpty
          ? const Center(
              child: Text(
                "Tidak ada antrean setoran sampah saat ini.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: _pendingDeposits.length,
              itemBuilder: (context, index) {
                final deposit = _pendingDeposits[index];
                final warga = deposit['profiles'] ?? {};
                final namaWarga = warga['full_name'] ?? 'Warga Anonim';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment
                              .spaceBetween, // PERBAIKAN DI SINI
                          children: [
                            Text(
                              namaWarga,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                "PENDING",
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        Text("Jenis Sampah : ${deposit['jenis_sampah']}"),
                        Text("Berat Sampah : ${deposit['berat']} Kg"),
                        const SizedBox(height: 5),
                        Text(
                          "Total Hadiah : ${deposit['poin_estimasi']} Poin",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _approveDeposit(deposit),
                              icon: const Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "SETUJUI & ISI POIN",
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
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
    );
  }
}
