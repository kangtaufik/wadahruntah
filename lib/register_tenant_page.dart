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

class RegisterTenantPage extends StatefulWidget {
  const RegisterTenantPage({super.key});

  @override
  State<RegisterTenantPage> createState() => _RegisterTenantPageState();
}

class _RegisterTenantPageState extends State<RegisterTenantPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _storeNameController = TextEditingController();
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

  Uint8List? _ktpBytes;
  Uint8List? _usahaBytes;
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
      print("Gagal mengambil data Kota/Kabupaten: $e");
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
      print("Gagal mengambil data Kelurahan/Desa: $e");
    }
  }

  Future<void> _pickImage(bool isKtp) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
    );
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (isKtp) {
          _ktpBytes = bytes;
        } else {
          _usahaBytes = bytes;
        }
      });
    }
  }

  Future<void> _signUp() async {
    if (_nameController.text.isEmpty ||
        _storeNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _selectedProvinceName == null ||
        _selectedRegencyName == null ||
        _selectedDistrictName == null ||
        _selectedVillageName == null ||
        _detailAlamatController.text.isEmpty ||
        _ktpBytes == null ||
        _usahaBytes == null) {
      Get.snackbar(
        'Peringatan',
        'Mohon lengkapi seluruh data, alamat, dan dokumen.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'full_name': _nameController.text.trim(), 'role': 'tenant'},
      );

      if (response.user != null) {
        final userId = response.user!.id;

        final ktpFileName = '${userId}_tenant_ktp.jpg';
        await Supabase.instance.client.storage
            .from('verifikasi')
            .uploadBinary(ktpFileName, _ktpBytes!);
        final ktpUrl = Supabase.instance.client.storage
            .from('verifikasi')
            .getPublicUrl(ktpFileName);

        final usahaFileName = '${userId}_foto_usaha.jpg';
        await Supabase.instance.client.storage
            .from('verifikasi')
            .uploadBinary(usahaFileName, _usahaBytes!);
        final usahaUrl = Supabase.instance.client.storage
            .from('verifikasi')
            .getPublicUrl(usahaFileName);

        String alamatLengkap =
            "$_selectedProvinceName, $_selectedRegencyName, Kec. $_selectedDistrictName, Kel/Desa $_selectedVillageName, RT ${_rtController.text}/RW ${_rwController.text}. Jalan/Kampung: ${_detailAlamatController.text}";

        await Supabase.instance.client
            .from('profiles')
            .update({'foto_ktp_url': ktpUrl})
            .eq('id', userId);

        await Supabase.instance.client.from('tenants').insert({
          'id': userId,
          'nama_toko': _storeNameController.text.trim(),
          'alamat': alamatLengkap,
          'foto_usaha_url': usahaUrl,
          'latitude': _pickedLocation.latitude,
          'longitude': _pickedLocation.longitude,
          'status': 'pending',
        });

        Get.offAll(() => const SuccessRegisterPage());
      }
    } on AuthException catch (error) {
      String errorMsg = 'Terjadi kesalahan autentikasi.';
      if (error.message.contains('already exists') ||
          error.statusCode == '400') {
        errorMsg =
            'Email ini sudah terdaftar sebagai Member! Gunakan email lain khusus untuk toko Anda.';
      }
      Get.snackbar(
        'Registrasi Gagal',
        errorMsg,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Kesalahan',
        e.toString(),
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
        title: const Text('Daftar Mitra Tenant'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.storefront, size: 60, color: Colors.orange),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap Pemilik',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _storeNameController,
              decoration: const InputDecoration(
                labelText: 'Nama Toko / Usaha',
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

            // KOLOM KATA SANDI YANG SUDAH DIPERBARUI
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
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Alamat Usaha",
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
                "Tandai Lokasi di Peta (Klik pada Peta)",
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
            OutlinedButton.icon(
              onPressed: () => _pickImage(true),
              icon: const Icon(Icons.credit_card),
              label: Text(
                _ktpBytes == null
                    ? 'Unggah KTP (Wajib)'
                    : 'KTP Berhasil Diunggah',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _pickImage(false),
              icon: const Icon(Icons.store),
              label: Text(
                _usahaBytes == null
                    ? 'Foto Tempat Usaha (Wajib)'
                    : 'Foto Usaha Berhasil Diunggah',
              ),
            ),
            const SizedBox(height: 32),

            _isLoading
                ? const CircularProgressIndicator(color: Colors.orange)
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: _signUp,
                      child: const Text(
                        'DAFTAR SEBAGAI MITRA TENANT',
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
    );
  }
}
