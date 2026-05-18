import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'setor_sampah_page.dart';

class DashboardMember extends StatefulWidget {
  const DashboardMember({super.key});

  @override
  State<DashboardMember> createState() => _DashboardMemberState();
}

class _DashboardMemberState extends State<DashboardMember> {
  final supabase = Supabase.instance.client;
  String _namaWarga = "Memuat Nama...";
  int _saldoPoin = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMemberData();
  }

  Future<void> _fetchMemberData() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final data = await supabase
            .from('profiles')
            .select('full_name, saldo_poin')
            .eq('id', user.id)
            .single();

        setState(() {
          _namaWarga = data['full_name'] ?? "Member Wadah Runtah";
          _saldoPoin = data['saldo_poin'] ?? 0;
          _isLoading = false;
        });
      } catch (e) {
        print("Error ambil data member: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  void _showRiwayatPoin() async {
    Get.bottomSheet(
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<List<dynamic>>(
          future: supabase
              .from('deposits')
              .select('*')
              .eq('member_id', supabase.auth.currentUser!.id)
              .order('created_at', ascending: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.green),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text("Belum ada riwayat setoran sampah."),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Riwayat Setoran Sampah Anda",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final dep = snapshot.data![index];
                      final isApproved = dep['status'] == 'approved';
                      return ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: isApproved ? Colors.green : Colors.orange,
                        ),
                        title: Text(
                          "${dep['jenis_sampah']} (${dep['berat']} Kg)",
                        ),
                        subtitle: Text(
                          dep['created_at'].toString().substring(0, 10),
                        ),
                        trailing: Text(
                          "${isApproved ? '+' : ''}${dep['poin_estimasi']} Pts\n[${dep['status'].toString().toUpperCase()}]",
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isApproved ? Colors.green : Colors.orange,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showMyQR() {
    final userId = supabase.auth.currentUser!.id;
    final qrApiUrl =
        "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=$userId";

    Get.defaultDialog(
      title: "QR Code Pembayaran",
      content: Column(
        children: [
          const Text(
            "Tunjukkan QR ini ke kasir Mitra Tenant untuk memotong poin belanjaan Anda.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.network(
              qrApiUrl,
              height: 180,
              width: 180,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 180,
                  width: 180,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.broken_image,
                  size: 180,
                  color: Colors.red,
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            "ID ANDA: ${userId.substring(0, 8).toUpperCase()}...",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      textConfirm: "TUTUP",
      confirmTextColor: Colors.white,
      buttonColor: Colors.green,
      onConfirm: () => Get.back(),
    );
  }

  void _showDaftarMitra() {
    Get.bottomSheet(
      Container(
        color: Colors.white,
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<List<dynamic>>(
          future: supabase
              .from('tenants')
              .select('nama_toko, alamat')
              .eq('status', 'approved'),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.green),
              );
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text("Belum ada mitra toko yang terdaftar/disetujui."),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Daftar Warung / Mitra Tenant Aktif",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final t = snapshot.data![index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.storefront,
                            color: Colors.orange,
                          ),
                          title: Text(
                            t['nama_toko'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(t['alamat']),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Dashboard Member"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Get.offAll(() => const LoginPage()),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.green))
          : RefreshIndicator(
              onRefresh: _fetchMemberData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Selamat Datang,",
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                    Text(
                      _namaWarga,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Saldo Poin Anda",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "$_saldoPoin Poin",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(color: Colors.white38),
                          const Text(
                            "Tukarkan poin ini menjadi belanjaan di warung mitra.",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "Menu Utama Layanan",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildMenuCard(
                          Icons.delete_sweep,
                          "Setor Sampah",
                          Colors.blue,
                          () => Get.to(() => const SetorSampahPage()),
                        ),
                        _buildMenuCard(
                          Icons.history,
                          "Riwayat Setoran",
                          Colors.purple,
                          _showRiwayatPoin,
                        ),
                        _buildMenuCard(
                          Icons.qr_code_scanner,
                          "Bayar Jajan (QR)",
                          Colors.orange,
                          _showMyQR,
                        ),
                        _buildMenuCard(
                          Icons.store,
                          "Daftar Warung",
                          Colors.teal,
                          _showDaftarMitra,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    // TEKS FOOTER PERUSAHAAN
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

  Widget _buildMenuCard(
    IconData icon,
    String label,
    Color color,
    VoidCallback action,
  ) {
    return InkWell(
      onTap: action,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
