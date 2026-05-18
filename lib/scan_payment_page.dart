import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScanPaymentPage extends StatefulWidget {
  const ScanPaymentPage({super.key});

  @override
  State<ScanPaymentPage> createState() => _ScanPaymentPageState();
}

class _ScanPaymentPageState extends State<ScanPaymentPage> {
  final supabase = Supabase.instance.client;
  final _memberIdController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  // --- PROSES POTONG POIN & PINDAH SALDO (TRANSAKSI) ---
  Future<void> _prosesPembayaran() async {
    String memberIdInput = _memberIdController.text.trim();
    String amountInput = _amountController.text.trim();

    if (memberIdInput.isEmpty || amountInput.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Mohon isi ID Warga dan Nominal Poin Belanja.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    int? nominalBelanja = int.tryParse(amountInput);
    if (nominalBelanja == null || nominalBelanja <= 0) {
      Get.snackbar(
        'Peringatan',
        'Nominal belanja harus berupa angka !',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final tenantUser = supabase.auth.currentUser;
      if (tenantUser == null) return;

      // 1. Cek apakah ID Warga tersebut terdaftar di tabel profiles
      final memberProfile = await supabase
          .from('profiles')
          .select('id, full_name, saldo_poin')
          .eq('id', memberIdInput)
          .maybeSingle();

      if (memberProfile == null) {
        Get.snackbar(
          'Gagal',
          'ID Warga tidak ditemukan di Aplikasi',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        setState(() => _isLoading = false);
        return;
      }

      String memberIdTrue = memberProfile['id'];
      String namaWarga = memberProfile['full_name'] ?? 'Warga';
      int saldoWargaSekarang = memberProfile['saldo_poin'] ?? 0;

      // 2. Lapis Keamanan: Cek apakah saldo poin warga cukup buat jajan
      if (saldoWargaSekarang < nominalBelanja) {
        Get.snackbar(
          'Transaksi Ditolak',
          'Maaf, saldo poin milik $namaWarga tidak cukup untuk transaksi ini.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        setState(() => _isLoading = false);
        return;
      }

      // 3. Ambil saldo poin warung (tenant) saat ini
      final tenantData = await supabase
          .from('tenants')
          .select('saldo_poin')
          .eq('id', tenantUser.id)
          .single();
      int saldoTenantSekarang = tenantData['saldo_poin'] ?? 0;

      // 4. Hitung perhitungan saldo baru
      int saldoWargaBaru = saldoWargaSekarang - nominalBelanja;
      int saldoTenantBaru = saldoTenantSekarang + nominalBelanja;

      // 5. Eksekusi Update ke Database Supabase (Potong & Tambah Poin)
      await supabase
          .from('profiles')
          .update({'saldo_poin': saldoWargaBaru})
          .eq('id', memberIdTrue);
      await supabase
          .from('tenants')
          .update({'saldo_poin': saldoTenantBaru})
          .eq('id', tenantUser.id);

      // 6. Catat log riwayat ke tabel transactions
      await supabase.from('transactions').insert({
        'member_id': memberIdTrue,
        'tenant_id': tenantUser.id,
        'amount': nominalBelanja,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 7. Tampilkan Dialog Sukses Besar
      Get.defaultDialog(
        title: "Transaksi Sukses!",
        middleText:
            "Berhasil menerima pembayaran sebesar $nominalBelanja Poin dari $namaWarga. Saldo toko Anda bertambah!",
        textConfirm: "MANTAP",
        confirmTextColor: Colors.white,
        buttonColor: Colors.orange,
        onConfirm: () {
          Get.back(); // Tutup dialog
          Get.back(); // Kembali ke Dashboard Tenant
        },
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Terjadi kesalahan sistem: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kasir Terima Pembayaran"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.orange, size: 30),
                    SizedBox(width: 10),
                    Text(
                      "Simulasi Scan QR Member",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  "Masukkan nomor ID member yang tertera di bawah gambar QR Code",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 20),

                // INPUT ID WARGA (HASIL SCAN QR)
                TextField(
                  controller: _memberIdController,
                  decoration: const InputDecoration(
                    labelText: "ID UUID Warga (Hasil Scan QR)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.vpn_key),
                  ),
                ),
                const SizedBox(height: 16),

                // INPUT NOMINAL POIN BELANJA
                TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Total Nominal Poin Belanja",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payments),
                    suffixText: "Poin",
                  ),
                ),
                const SizedBox(height: 28),

                // TOMBOL PROSES POTONG SALDO
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.orange),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: _prosesPembayaran,
                          child: const Text(
                            'PROSES POTONG POIN',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
