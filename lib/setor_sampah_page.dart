import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetorSampahPage extends StatefulWidget {
  const SetorSampahPage({super.key});

  @override
  State<SetorSampahPage> createState() => _SetorSampahPageState();
}

class _SetorSampahPageState extends State<SetorSampahPage> {
  final _beratController = TextEditingController();
  final supabase = Supabase.instance.client;

  List<dynamic> _categories = []; // Menampung data jenis sampah dari database
  String? _selectedCategoryName;
  int _currentPricePerKg = 0;
  int _estimasiPoin = 0;
  bool _isPageLoading = true;
  bool _isSubmitLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchWasteCategories(); // Ambil data live dari Supabase pas halaman dibuka
  }

  // --- 1. AMBIL DATA MASTER HARGA SAMPAH DARI SUPABASE ---
  Future<void> _fetchWasteCategories() async {
    try {
      final data = await supabase
          .from('waste_categories')
          .select('name, points_per_kg')
          .order('name', ascending: true);

      setState(() {
        _categories = data;
        _isPageLoading = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengambil data harga sampah: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
      setState(() => _isPageLoading = false);
    }
  }

  // --- 2. HITUNG POIN OTOMATIS BERDASARKAN BERAT ---
  void _hitungPoin(String value) {
    if (value.isEmpty || _selectedCategoryName == null) {
      setState(() => _estimasiPoin = 0);
      return;
    }
    double? berat = double.tryParse(value);
    if (berat != null) {
      setState(() {
        _estimasiPoin = (berat * _currentPricePerKg).round();
      });
    }
  }

  // --- 3. PROSES KIRIM TIKET ANTREAN SETORAN ---
  Future<void> _kirimSetoran() async {
    if (_selectedCategoryName == null || _beratController.text.isEmpty) {
      Get.snackbar('Peringatan', 'Mohon pilih jenis sampah dan isi beratnya.',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    setState(() => _isSubmitLoading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Data masuk ke tabel 'deposits' dengan status awal 'pending'
        await supabase.from('deposits').insert({
          'member_id': user.id,
          'jenis_sampah': _selectedCategoryName,
          'berat': double.parse(_beratController.text),
          'poin_estimasi': _estimasiPoin,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
        });

        Get.defaultDialog(
          title: "Berhasil!",
          middleText: "Tiket setoran berhasil dibuat. Silakan bawa sampah Anda ke petugas terdekat untuk ditimbang.",
          textConfirm: "OK",
          confirmTextColor: Colors.white,
          buttonColor: Colors.green,
          onConfirm: () {
            Get.back(); // Tutup dialog
            Get.back(); // Balik ke Dashboard Member
          },
        );
      }
    } catch (e) {
      Get.snackbar('Gagal', 'Gagal membuat tiket setoran: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    } final {
      setState(() => _isSubmitLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Form Setor Sampah"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isPageLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : Center(
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
                      const Text(
                        "Pilih Kategori & Berat Sampah",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // DROPDOWN DATA LIVE DARI DB
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: "Jenis Sampah", border: OutlineInputBorder()),
                        value: _selectedCategoryName,
                        items: _categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat['name'].toString(),
                            child: Text("${cat['name']} (${cat['points_per_kg']} Poin/Kg)"),
                          );
                        }).toList(),
                        onChanged: (val) {
                          final selectedItem = _categories.firstWhere((element) => element['name'] == val);
                          setState(() {
                            _selectedCategoryName = val;
                            _currentPricePerKg = selectedItem['points_per_kg'];
                          });
                          _hitungPoin(_beratController.text);
                        },
                      ),
                      const SizedBox(height: 16),

                      // INPUT BERAT SAMPAH
                      TextField(
                        controller: _beratController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: "Perkiraan Berat (Kg)",
                          border: OutlineInputBorder(),
                          suffixText: "Kg",
                        ),
                        onChanged: _hitungPoin,
                      ),
                      const SizedBox(height: 24),

                      // BOX ESTIMASI POIN
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            const Text("Estimasi Poin Diperoleh:", style: TextStyle(fontWeight: FontWeight.w600)),
                            Text(
                              "$_estimasiPoin Poin",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // TOMBOL SUBMIT TIKET
                      _isSubmitLoading
                          ? const Center(child: CircularProgressIndicator(color: Colors.green))
                          : SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                onPressed: _kirimSetoran,
                                child: const Text(
                                  'BUAT TIKET SETORAN',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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