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
  // Inisialisasi pengontrol kamera dari pustaka mobile_scanner
  final MobileScannerController _cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  final supabase = Supabase.instance.client;
  bool _isProcessing = false;

  @override
  void dispose() {
    // Memastikan kamera dimatikan secara sistem saat keluar dari halaman
    _cameraController.dispose();
    super.dispose();
  }

  // Fungsi yang dieksekusi secara otomatis saat Kamera mendeteksi Kode QR
  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? qrData = barcodes.first.rawValue;

      if (qrData != null) {
        setState(() => _isProcessing = true);

        // Menghentikan pemindaian sementara agar tidak terjadi deteksi ganda
        await _cameraController.stop();

        // Memanggil fungsi untuk menampilkan antarmuka tagihan
        _showPaymentDialog(qrData);
      }
    }
  }

  // Jendela dialog untuk memproses pembayaran berdasarkan ID Member (Hasil Scan)
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
        // Jika dibatalkan, kamera diaktifkan kembali untuk memindai ulang
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

        // --- MASUKKAN LOGIKA SUPABASE ANDA DI SINI ---
        // Contoh:
        // 1. Cek apakah saldo_poin member mencukupi.
        // 2. Kurangi saldo_poin di tabel profiles.
        // 3. Tambahkan saldo_poin di tabel tenants.
        // 4. Catat transaksi di tabel history_transaksi.

        Get.back(); // Menutup dialog
        Get.snackbar(
          "Berhasil",
          "Pembayaran sebesar $tagihan poin telah memotong saldo member.",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Mengaktifkan kamera kembali setelah transaksi sukses (jika diperlukan)
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
            icon: ValueListenableBuilder(
              valueListenable: _cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off, color: Colors.grey);
                  case TorchState.on:
                    return const Icon(Icons.flash_on, color: Colors.yellow);
                }
              },
            ),
            onPressed: () => _cameraController.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _cameraController.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => _cameraController.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            // Komponen utama kamera dari mobile_scanner
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
