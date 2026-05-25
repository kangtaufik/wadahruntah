import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'manage_waste_categories_page.dart';
import 'verify_deposits_page.dart';
import 'verify_payouts_page.dart';

// Pastikan 3 file ini sudah lu bikin ya bray, sesuai kode yang gw kasih sebelumnya
import 'admin_detail_member_page.dart';
import 'admin_detail_waste_page.dart';
import 'admin_detail_point_page.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  final supabase = Supabase.instance.client;
  List<dynamic> _pendingTenants = [];
  bool _isLoading = true;

  int _totalWarga = 0;
  int _totalPoinBeredar = 0;
  double _totalSampahKg = 0.0;

  Map<String, double> _kategoriSampah = {};

  // Variabel untuk Filter Waktu
  String _selectedFilter = 'Semua Waktu';
  final List<String> _filterOptions = [
    'Hari Ini',
    'Minggu Ini',
    'Bulan Ini',
    'Tahun Ini',
    'Semua Waktu',
  ];

  @override
  void initState() {
    super.initState();
    _loadAdminDashboardData();
  }

  // Fungsi untuk mendapatkan batas waktu berdasarkan filter yang dipilih
  String? _getDateThreshold() {
    DateTime now = DateTime.now();
    if (_selectedFilter == 'Hari Ini') {
      return DateTime(now.year, now.month, now.day).toIso8601String();
    } else if (_selectedFilter == 'Minggu Ini') {
      return now.subtract(Duration(days: now.weekday - 1)).toIso8601String();
    } else if (_selectedFilter == 'Bulan Ini') {
      return DateTime(now.year, now.month, 1).toIso8601String();
    } else if (_selectedFilter == 'Tahun Ini') {
      return DateTime(now.year, 1, 1).toIso8601String();
    }
    return null; // Semua Waktu
  }

  Future<void> _loadAdminDashboardData() async {
    setState(() => _isLoading = true);
    try {
      String? dateThreshold = _getDateThreshold();

      // 1. Ambil Kategori Dasar dulu biar grafik tetap muncul walau kosong
      final kategoriData = await supabase
          .from('waste_categories')
          .select('name');
      Map<String, double> hitungKategori = {};
      for (var k in kategoriData) {
        hitungKategori[k['name'].toString()] = 0.0;
      }

      // 2. Query Data dengan Filter Waktu
      var depositQuery = supabase
          .from('deposits')
          .select('berat, jenis_sampah')
          .eq('status', 'approved');
      var wargaQuery = supabase
          .from('profiles')
          .select('id, saldo_poin, created_at')
          .eq('role', 'member');
      var tenantQuery = supabase
          .from('tenants')
          .select('saldo_poin, created_at')
          .eq('status', 'approved');

      // Antrean verifikasi biasanya tidak difilter waktu (selalu tampil yang pending)
      final tenantPending = await supabase
          .from('tenants')
          .select('*, profiles(foto_ktp_url, full_name, nomor_hp)')
          .eq('status', 'pending');

      if (dateThreshold != null) {
        depositQuery = depositQuery.gte('created_at', dateThreshold);
        wargaQuery = wargaQuery.gte('created_at', dateThreshold);
        tenantQuery = tenantQuery.gte('created_at', dateThreshold);
      }

      final depositData = await depositQuery;
      final wargaData = await wargaQuery;
      final tenantAktifData = await tenantQuery;

      // Kalkulasi Poin
      int totalPoin = 0;
      for (var item in wargaData) {
        totalPoin += (item['saldo_poin'] as int? ?? 0);
      }
      for (var item in tenantAktifData) {
        totalPoin += (item['saldo_poin'] as int? ?? 0);
      }

      // Kalkulasi Sampah ke dalam Map Kategori
      double totalBerat = 0.0;
      for (var item in depositData) {
        double berat = (item['berat'] as num? ?? 0.0).toDouble();
        String jenis = (item['jenis_sampah'] ?? 'Lainnya').toString();

        totalBerat += berat;

        if (hitungKategori.containsKey(jenis)) {
          hitungKategori[jenis] = hitungKategori[jenis]! + berat;
        } else {
          hitungKategori[jenis] = berat;
        }
      }

      if (hitungKategori.isEmpty) {
        hitungKategori = {"Plastik": 0.0, "Kertas": 0.0, "Logam": 0.0};
      }

      setState(() {
        _pendingTenants = tenantPending;
        _totalWarga = wargaData.length;
        _totalPoinBeredar = totalPoin;
        _totalSampahKg = totalBerat;
        _kategoriSampah = hitungKategori;
        _isLoading = false;
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal memuat data statistik: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTenantStatus(String tenantId, String status) async {
    try {
      await supabase
          .from('tenants')
          .update({'status': status})
          .eq('id', tenantId);
      Get.back();
      _loadAdminDashboardData();
      Get.snackbar(
        'Sukses',
        status == 'approved' ? 'Mitra Disetujui.' : 'Ditolak.',
        backgroundColor: status == 'approved' ? Colors.green : Colors.red,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Gagal',
        'Gagal update: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _tinjauDataTenant(dynamic tenant) {
    final profile = tenant['profiles'];
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Review Data Tenant",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
                const Divider(),
                _buildInfoRow("Nama Pemilik", profile?['full_name'] ?? '-'),
                _buildInfoRow("Nomor HP", profile?['nomor_hp'] ?? '-'),
                _buildInfoRow("Nama Usaha", tenant['nama_toko'] ?? '-'),
                _buildInfoRow("Alamat", tenant['alamat'] ?? '-'),
                const SizedBox(height: 16),
                const Text(
                  "Foto KTP:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildImagePreview(profile?['foto_ktp_url']),
                const SizedBox(height: 16),
                const Text(
                  "Foto Tempat Usaha:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildImagePreview(tenant['foto_usaha_url']),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.cancel),
                        label: const Text("Tolak"),
                        onPressed: () =>
                            _updateTenantStatus(tenant['id'], 'rejected'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle),
                        label: const Text("Setujui (ACC)"),
                        onPressed: () =>
                            _updateTenantStatus(tenant['id'], 'approved'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          const Text(": "),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        height: 150,
        color: Colors.grey[200],
        child: const Center(child: Text("Tidak ada gambar")),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Container(
          height: 150,
          color: Colors.grey[200],
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Dashboard Admin",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // JURUS LOGOUT SAPU JAGAT DITAMBAHKAN DI SINI
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
          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
          : RefreshIndicator(
              onRefresh: _loadAdminDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Ringkasan Performa Sistem",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedFilter,
                              icon: const Icon(
                                Icons.filter_list,
                                color: Colors.blue,
                              ),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                              items: _filterOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedFilter = newValue;
                                  });
                                  _loadAdminDashboardData();
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        _buildStatCard(
                          "Total Member",
                          "$_totalWarga Orang",
                          Icons.people,
                          Colors.purple,
                          () => Get.to(() => const AdminDetailMemberPage()),
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          "Sampah Terkumpul",
                          "${_totalSampahKg.toStringAsFixed(1)} Kg",
                          Icons.delete_sweep,
                          Colors.green,
                          () => Get.to(() => const AdminDetailSampahPage()),
                        ),
                        const SizedBox(width: 12),
                        _buildStatCard(
                          "Poin Beredar",
                          "$_totalPoinBeredar Pts",
                          Icons.monetization_on,
                          Colors.orange,
                          () => Get.to(() => const AdminDetailPoinPage()),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "Grafik Volume Setoran per Kategori",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCustomBarChart(),

                    const SizedBox(height: 30),
                    const Text(
                      "Menu Navigasi Admin",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    Get.to(() => const VerifyDepositsPage()),
                                icon: const Icon(
                                  Icons.fact_check,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Verifikasi Setoran",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => Get.to(
                                  () => const ManageWasteCategoriesPage(),
                                ),
                                icon: const Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Kelola Harga Sampah",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                Get.to(() => const VerifyPayoutsPage()),
                            icon: const Icon(
                              Icons.payments,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Verifikasi Payout Dana Tenant",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "Antrean Verifikasi Mitra Tenant",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _pendingTenants.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Center(
                                child: Text(
                                  "Bersih! Tidak ada antrean verifikasi mitra tenant.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _pendingTenants.length,
                            itemBuilder: (context, index) {
                              final tenant = _pendingTenants[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  onTap: () => _tinjauDataTenant(tenant),
                                  leading: const Icon(
                                    Icons.store,
                                    color: Colors.blue,
                                    size: 36,
                                  ),
                                  title: Text(
                                    tenant['nama_toko'] ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Alamat: ${tenant['alamat'] ?? '-'}",
                                  ),
                                  trailing: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                    icon: const Icon(Icons.search, size: 18),
                                    label: const Text("Tinjau"),
                                    onPressed: () => _tinjauDataTenant(tenant),
                                  ),
                                ),
                              );
                            },
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
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomBarChart() {
    double total = _totalSampahKg > 0 ? _totalSampahKg : 1.0;
    List<Color> colorPalette = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.cyan,
      Colors.indigo,
      Colors.amber,
      Colors.brown,
    ];
    List<Widget> bars = [];
    List<Widget> legends = [];

    int colorIndex = 0;
    _kategoriSampah.forEach((namaKategori, beratKategori) {
      Color barColor = colorPalette[colorIndex % colorPalette.length];
      bars.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: _buildBar(namaKategori, beratKategori / total, barColor),
        ),
      );
      legends.add(_buildLegend(barColor, namaKategori));
      colorIndex++;
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars,
            ),
          ),
          const Divider(height: 30),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 15,
            runSpacing: 10,
            children: legends,
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String label, double fillPercent, Color color) {
    String shortLabel = label.length > 8 ? "${label.substring(0, 6)}.." : label;
    return Column(
      children: [
        Text(
          "${(fillPercent * 100).toInt()}%",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Container(
          height: 150,
          width: 35,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            height: 150 * fillPercent,
            width: 35,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          shortLabel,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
