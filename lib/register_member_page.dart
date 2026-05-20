import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'success_register_page.dart';

class RegisterMemberPage extends StatefulWidget {
  const RegisterMemberPage({super.key});

  @override
  State<RegisterMemberPage> createState() => _RegisterMemberPageState();
}

class _RegisterMemberPageState extends State<RegisterMemberPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _detailAlamatController = TextEditingController();
  final _rtController = TextEditingController();
  final _rwController = TextEditingController();

  List<dynamic> _provinces = [];
  List<dynamic> _regencies = [];
  List<dynamic> _districts = [];
  List<dynamic> _villages = [];

  String? _selectedProvinceId, _selectedProvinceName;
  String? _selectedRegencyId, _selectedRegencyName;
  String? _selectedDistrictId, _selectedDistrictName;
  String? _selectedVillageId, _selectedVillageName;

  LatLng _pickedLocation = const LatLng(-6.8833, 107.6833);
  final MapController _mapController = MapController();

  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _obscureText = true;

  // Menambahkan konstanta URL Proxy untuk mengatasi kendala CORS pada platform Web
  static const String _corsProxy = 'https://corsproxy.io/?';

  @override
  void initState() {
    super.initState();
    _fetchProvinces();
  }

  Future<void> _fetchProvinces() async {
    try {
      const String targetUrl =
          'https://emsifa.github.io/api-wilayah-indonesia/api/provinces.json';
      final response = await http.get(Uri.parse('$_corsProxy$targetUrl'));

      if (response.statusCode == 200) {
        setState(() => _provinces = jsonDecode(response.body));
      }
    } catch (e) {
      print("Gagal mengambil data Provinsi: $e");
    }
  }

  Future<void> _fetchRegencies(String provinceId) async {
    try {
      final String targetUrl =
          'https://emsifa.github.io/api-wilayah-indonesia/api/regencies/$provinceId.json';
      final response = await http.get(Uri.parse('$_corsProxy$targetUrl'));

      if (response.statusCode == 200) {
        setState(() {
          _regencies = jsonDecode(response.body);
          _districts = [];
          _villages = [];
        });
      }
    } catch (e) {
      print("Gagal mengambil data Kota/ Kabupaten: $e");
    }
  }

  Future<void> _fetchDistricts(String regencyId) async {
    try {
      final String targetUrl =
          'https://emsifa.github.io/api-wilayah-indonesia/api/districts/$regencyId.json';
      final response = await http.get(Uri.parse('$_corsProxy$targetUrl'));

      if (response.statusCode == 200) {
        setState(() {
          _districts = jsonDecode(response.body);
          _villages = [];
        });
      }
    } catch (e) {
      print("Gagal mengambil data Kecamatan: $e");
    }
  }

  Future<void> _fetchVillages(String districtId) async {
    try {
      final String targetUrl =
          'https://emsifa.github.io/api-wilayah-indonesia/api/villages/$districtId.json';
      final response = await http.get(Uri.parse('$_corsProxy$targetUrl'));

      if (response.statusCode == 200) {
        setState(() => _villages = jsonDecode(response.body));
      }
    } catch (e) {
      print("Gagal mengambil data Desa/Kelurahan: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      final fileBytes = await pickedFile.readAsBytes();
      final kbSize = fileBytes.lengthInBytes / 1024;

      if (kbSize > 250) {
        Get.snackbar(
          'Gagal',
          'Ukuran foto terlalu besar. Silakan pilih foto lain.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      setState(() {
        _imageBytes = fileBytes;
      });
    }
  }

  Future<void> _signUp() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _selectedProvinceName == null ||
        _selectedRegencyName == null ||
        _selectedDistrictName == null ||
        _selectedVillageName == null ||
        _detailAlamatController.text.isEmpty) {
      Get.snackbar(
        'Peringatan',
        'Mohon isi semua data yang tersedia.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final checkPhone = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('nomor_hp', _phoneController.text.trim())
          .maybeSingle();

      if (checkPhone != null) {
        String roleTerdaftar = checkPhone['role'] == 'tenant'
            ? 'Mitra Tenant'
            : 'Member Warga';
        Get.snackbar(
          'Pendaftaran Ditolak',
          'Nomor HP ini sudah terdaftar sebagai $roleTerdaftar. Anda tidak boleh menggunakan nomor HP yang sama.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
        setState(() => _isLoading = false);
        return;
      }

      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'full_name': _nameController.text.trim(), 'role': 'member'},
      );

      if (response.user != null) {
        final userId = response.user!.id;
        String? ktpUrl;

        if (_imageBytes != null) {
          final fileName = '${userId}_member_ktp.jpg';
          await Supabase.instance.client.storage
              .from('verifikasi')
              .uploadBinary(fileName, _imageBytes!);
          ktpUrl = Supabase.instance.client.storage
              .from('verifikasi')
              .getPublicUrl(fileName);
        }

        String alamatLengkap =
            "$_selectedProvinceName, $_selectedRegencyName, Kec. $_selectedDistrictName, Kel/Desa $_selectedVillageName, RT ${_rtController.text.trim()}/RW ${_rwController.text.trim()}. Detail: ${_detailAlamatController.text.trim()}";

        final Map<String, dynamic> updateData = {
          'nomor_hp': _phoneController.text.trim(),
          'alamat': alamatLengkap,
          'latitude': _pickedLocation.latitude,
          'longitude': _pickedLocation.longitude,
        };

        if (ktpUrl != null) updateData['foto_ktp_url'] = ktpUrl;

        await Supabase.instance.client
            .from('profiles')
            .update(updateData)
            .eq('id', userId);
        Get.offAll(() => const SuccessRegisterPage());
      }
    } on AuthException catch (error) {
      String errorMsg = 'Terjadi kesalahan autentikasi.';
      if (error.message.contains('already exists') ||
          error.statusCode == '400') {
        errorMsg = 'Email ini sudah terdaftar di sistem Aplikasi Wadah Runtah!';
      }
      Get.snackbar(
        'Registrasi Gagal',
        errorMsg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Kesalahan Sistem',
        'Terjadi kendala: $e',
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
        title: const Text(
          'Daftar Member',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.person_add, size: 60, color: Colors.green),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Alamat Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor WhatsApp / HP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Alamat Tempat Tinggal",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Provinsi",
                  border: OutlineInputBorder(),
                ),
                value: _selectedProvinceId,
                items: _provinces
                    .map(
                      (prov) => DropdownMenuItem<String>(
                        value: prov['id'].toString(),
                        child: Text(prov['name']),
                      ),
                    )
                    .toList(),
                onChanged: (String? val) {
                  setState(() {
                    _selectedProvinceId = val;
                    _selectedProvinceName = _provinces.firstWhere(
                      (p) => p['id'].toString() == val,
                    )['name'];
                    _selectedRegencyId = null;
                    _selectedDistrictId = null;
                    _selectedVillageId = null;
                  });
                  if (val != null) _fetchRegencies(val);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Kota / Kabupaten",
                  border: OutlineInputBorder(),
                ),
                value: _selectedRegencyId,
                items: _regencies
                    .map(
                      (reg) => DropdownMenuItem<String>(
                        value: reg['id'].toString(),
                        child: Text(reg['name']),
                      ),
                    )
                    .toList(),
                onChanged: _selectedProvinceId == null
                    ? null
                    : (String? val) {
                        setState(() {
                          _selectedRegencyId = val;
                          _selectedRegencyName = _regencies.firstWhere(
                            (r) => r['id'].toString() == val,
                          )['name'];
                          _selectedDistrictId = null;
                          _selectedVillageId = null;
                        });
                        if (val != null) _fetchDistricts(val);
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Kecamatan",
                  border: OutlineInputBorder(),
                ),
                value: _selectedDistrictId,
                items: _districts
                    .map(
                      (dist) => DropdownMenuItem<String>(
                        value: dist['id'].toString(),
                        child: Text(dist['name']),
                      ),
                    )
                    .toList(),
                onChanged: _selectedRegencyId == null
                    ? null
                    : (String? val) {
                        setState(() {
                          _selectedDistrictId = val;
                          _selectedDistrictName = _districts.firstWhere(
                            (d) => d['id'].toString() == val,
                          )['name'];
                          _selectedVillageId = null;
                        });
                        if (val != null) _fetchVillages(val);
                      },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Kelurahan / Desa",
                  border: OutlineInputBorder(),
                ),
                value: _selectedVillageId,
                items: _villages
                    .map(
                      (vil) => DropdownMenuItem<String>(
                        value: vil['id'].toString(),
                        child: Text(vil['name']),
                      ),
                    )
                    .toList(),
                onChanged: _selectedDistrictId == null
                    ? null
                    : (String? val) {
                        setState(() {
                          _selectedVillageId = val;
                          _selectedVillageName = _villages.firstWhere(
                            (v) => v['id'].toString() == val,
                          )['name'];
                        });
                      },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _rtController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'RT',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _rwController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'RW',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _detailAlamatController,
                decoration: const InputDecoration(
                  labelText: 'Nama Jalan / Kampung / Nomor Rumah',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Tandai Titik Rumah di Peta (Klik pada Peta)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _pickedLocation,
                      initialZoom: 13.0,
                      onTap: (tapPosition, point) {
                        setState(() {
                          _pickedLocation = point;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.wadah_runtah',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _pickedLocation,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Koordinat terpilih: ${_pickedLocation.latitude.toStringAsFixed(6)}, ${_pickedLocation.longitude.toStringAsFixed(6)}",
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Upload KTP (Wajib)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _imageBytes == null
                        ? ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Pilih Foto dari Galeri'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          )
                        : Column(
                            children: [
                              Image.memory(_imageBytes!, height: 100),
                              TextButton(
                                onPressed: _pickImage,
                                child: const Text(
                                  'Ganti Foto',
                                  style: TextStyle(color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.green)
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _signUp,
                        child: const Text(
                          'DAFTAR SEBAGAI MEMBER',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
