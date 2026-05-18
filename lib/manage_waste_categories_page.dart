import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageWasteCategoriesPage extends StatefulWidget {
  const ManageWasteCategoriesPage({super.key});

  @override
  State<ManageWasteCategoriesPage> createState() =>
      _ManageWasteCategoriesPageState();
}

class _ManageWasteCategoriesPageState extends State<ManageWasteCategoriesPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('waste_categories')
          .select('*')
          .order('name', ascending: true);
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat data: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() => _isLoading = false);
    }
  }

  void _showFormDialog({Map<String, dynamic>? category}) {
    final nameController = TextEditingController(
      text: category != null ? category['name'] : '',
    );
    final priceController = TextEditingController(
      text: category != null ? category['points_per_kg'].toString() : '',
    );
    final isEdit = category != null;

    Get.defaultDialog(
      title: isEdit ? "Edit Jenis Sampah" : "Tambah Jenis Sampah",
      content: Column(
        children: [
          TextField(
            controller: nameController,
            enabled: !isEdit,
            decoration: const InputDecoration(
              labelText: "Nama Jenis Sampah",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Nilai Poin per Kg",
              border: OutlineInputBorder(),
              suffixText: "Poin",
            ),
          ),
        ],
      ),
      textConfirm: "SIMPAN",
      textCancel: "BATAL",
      confirmTextColor: Colors.white,
      buttonColor: Colors.blue,
      onConfirm: () async {
        if (nameController.text.isEmpty || priceController.text.isEmpty) {
          Get.snackbar(
            'Peringatan',
            'Semua kolom wajib diisi!',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          return;
        }

        try {
          if (isEdit) {
            await supabase
                .from('waste_categories')
                .update({'points_per_kg': int.parse(priceController.text)})
                .eq('id', category['id']);
          } else {
            await supabase.from('waste_categories').insert({
              'name': nameController.text.trim(),
              'points_per_kg': int.parse(priceController.text),
            });
          }
          Get.back();
          _fetchCategories();
          Get.snackbar(
            'Sukses',
            'Data berhasil diperbarui',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar(
            'Gagal',
            'Terjadi kesalahan: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      },
    );
  }

  Future<void> _deleteCategory(int id) async {
    Get.defaultDialog(
      title: "Hapus Barang?",
      middleText:
          "Apakah Anda yakin ingin menghapus jenis sampah ini dari sistem?",
      textConfirm: "HAPUS",
      textCancel: "BATAL",
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        try {
          await supabase.from('waste_categories').delete().eq('id', id);
          Get.back();
          _fetchCategories();
          Get.snackbar(
            'Sukses',
            'Barang berhasil dihapus',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.back();
          Get.snackbar(
            'Gagal',
            'Tidak bisa menghapus barang yang sudah memiliki transaksi.',
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
      appBar: AppBar(
        title: const Text("Kelola Harga Sampah"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : _categories.isEmpty
          ? const Center(
              child: Text("Belum ada jenis sampah. Klik + untuk menambah."),
            )
          : ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.layers, color: Colors.blue),
                    title: Text(
                      cat['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "Harga: ${cat['points_per_kg']} Poin / Kg",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _showFormDialog(category: cat),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteCategory(cat['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
