import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDetailPoinPage extends StatefulWidget {
  const AdminDetailPoinPage({super.key});

  @override
  State<AdminDetailPoinPage> createState() => _AdminDetailPoinPageState();
}

class _AdminDetailPoinPageState extends State<AdminDetailPoinPage>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _memberRanking = [];
  List<dynamic> _tenantRanking = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRankings();
  }

  Future<void> _loadRankings() async {
    setState(() => _isLoading = true);
    // 1. Ranking Member
    final mData = await supabase
        .from('profiles')
        .select('full_name, saldo_poin')
        .eq('role', 'member')
        .order('saldo_poin', ascending: false);
    // 2. Ranking Tenant (Saldo Sekarang)
    final tData = await supabase
        .from('tenants')
        .select('nama_toko, saldo_poin')
        .order('saldo_poin', ascending: false);

    setState(() {
      _memberRanking = mData;
      _tenantRanking = tData;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analitik & Ranking Poin"),
        backgroundColor: Colors.orange,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Ranking Member"),
            Tab(text: "Ranking Tenant"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_memberRanking, "Member", Icons.person),
                _buildList(_tenantRanking, "Tenant/Toko", Icons.storefront),
              ],
            ),
    );
  }

  Widget _buildList(List<dynamic> data, String type, IconData icon) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: data.length,
      itemBuilder: (context, i) {
        return Card(
          child: ListTile(
            leading: Text(
              "#${i + 1}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.orange,
              ),
            ),
            title: Text(data[i]['full_name'] ?? data[i]['nama_toko']),
            subtitle: Text("$type Aktif"),
            trailing: Text(
              "${data[i]['saldo_poin']} Pts",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
