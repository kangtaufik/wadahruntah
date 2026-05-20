import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScanPaymentPage extends StatefulWidget {
  const ScanPaymentPage({super.key});

  @override
  State<ScanPaymentPage> createState() => _ScanPaymentPageState();
}

class _ScanPaymentPageState extends State<ScanPaymentPage> {
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  final supabase = Supabase.instance.client;
  bool _isProcessing = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? qrData = barcodes.first.rawValue;

      if (qrData != null) {
        setState(() => _isProcessing = true);

        await _cameraController.stop();
        _showPaymentDialog(qrData);
      }
    }
  }

  void _showPaymentDialog(String memberId) {
    final TextEditingController tagihanController = TextEditingController();

    Get.defaultDialog(
      title: "Proses Pembayaran",
      barrierDismissible: false,
      content: Column(
        children: [
          const Text(
            "Kode QR Berhasil Dipindai!",
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            "ID Member: ${memberId.length > 8 ? memberId.substring(0, 8).toUpperCase() : memberId}...",
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: tagihanController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Total Tagihan (Poin)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.payments),
            ),
          ),
        ],
      ),
      textCancel: "BATAL",
      textConfirm: "POTONG POIN",
      confirmTextColor: Colors.white,
      buttonColor: Colors.orange,
      cancelTextColor: Colors.orange,
      onCancel: () {
        setState(() => _isProcessing = false);
        _cameraController.start();
      },
      onConfirm: () async {
        final tagihan = int.tryParse(tagihanController.text);
        if (tagihan == null || tagihan <= 0) {
          Get.snackbar(
            "Kesalahan",
            "Masukkan nominal poin yang valid.",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          return;
        }

        Get.dialog(
          const Center(child: CircularProgressIndicator()),
          barrierDismissible: false,
        );

        try {
          // 1. Cek saldo poin milik Member
          final memberData = await supabase
              .from('profiles')
              .select('saldo_poin')
              .eq('id', memberId)
              .maybeSingle();

          if (memberData == null) {
            Get.back();
            Get.snackbar(
              "Gagal",
              "ID Member tidak ditemukan di database.",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return;
          }

          int saldoMember = memberData['saldo_poin'] ?? 0;
          if (saldoMember < tagihan) {
            Get.back();
            Get.snackbar(
              "Ditolak",
              "Saldo poin member tidak mencukupi! (Sisa: $saldoMember Pts)",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return;
          }

          // 2. Ambil ID Tenant
          final currentUser = supabase.auth.currentUser;
          if (currentUser == null) {
            Get.back();
            Get.snackbar(
              "Error",
              "Sesi login tenant tidak ditemukan.",
              backgroundColor: Colors.red,
              colorText: Colors.white,
            );
            return;
          }

          final tenantData = await supabase
              .from('tenants')
              .select('saldo_poin')
              .eq('id', currentUser.id)
              .single();

          int saldoTenant = tenantData['saldo_poin'] ?? 0;

          // 3. EKSEKUSI PEMOTONGAN POIN
          await supabase
              .from('profiles')
              .update({'saldo_poin': saldoMember - tagihan})
              .eq('id', memberId);
          await supabase
              .from('tenants')
              .update({'saldo_poin': saldoTenant + tagihan})
              .eq('id', currentUser.id);

          // 4. MENCETAK STRUK DIGITAL (HISTORY TRANSAKSI)
          // --- INI ADALAH LOGIKA BARU UNTUK PENCATATAN ---
          await supabase.from('history_transaksi').insert({
            'member_id': memberId,
            'tenant_id': currentUser.id,
            'nominal_poin': tagihan,
          });
          // -----------------------------------------------

          Get.back(); // Tutup loading
          Get.back(); // Tutup dialog

          Get.snackbar(
            "Berhasil",
            "Pembayaran $tagihan poin sukses dicatat!",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.back();
          Get.snackbar(
            "Error Sistem",
            "Terjadi kesalahan: $e",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }

        setState(() => _isProcessing = false);
        _cameraController.start();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pindai QR Member'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.flashlight_on, color: Colors.yellow),
            tooltip: 'Nyalakan/Matikan Senter',
            onPressed: () => _cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_android, color: Colors.white),
            tooltip: 'Putar Kamera',
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: _cameraController,
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Arahkan kamera ke Kode QR Member",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Pemindaian akan berjalan secara otomatis",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
