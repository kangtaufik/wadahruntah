import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDetailMemberPage extends StatefulWidget {
  const AdminDetailMemberPage({super.key});

  @override
  State<AdminDetailMemberPage> createState() => _AdminDetailMemberPageState();
}

class _AdminDetailMemberPageState extends State<AdminDetailMemberPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<dynamic> _members = [];

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  Future<void> _fetchMembers() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('profiles')
          .select('*, deposits(id), tenants(id)') // Asumsi ada relasi belanja
          .eq('role', 'member')
          .order('full_name', ascending: true);
      setState(() {
        _members = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // DIALOG DETAIL MEMBER (BOR DATA KE DALAM)
  void _showMemberDeepDetail(dynamic member) async {
    // Ambil riwayat setoran member ini
    final deposits = await supabase
        .from('deposits')
        .select('*')
        .eq('member_id', member['id'])
        .order('created_at', ascending: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              member['full_name'],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            Text(
              "Email: ${member['email'] ?? '-'} | HP: ${member['nomor_hp'] ?? '-'}",
            ),
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat("Total Poin", "${member['saldo_poin']} Pts"),
                _miniStat("Total Setoran", "${deposits.length} Kali"),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Riwayat Aktivitas Setoran",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: deposits.isEmpty
                  ? const Center(child: Text("Belum ada riwayat setoran"))
                  : ListView.builder(
                      itemCount: deposits.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: const Icon(
                          Icons.delete_outline,
                          color: Colors.green,
                        ),
                        title: Text(
                          "${deposits[i]['jenis_sampah']} (${deposits[i]['berat']} Kg)",
                        ),
                        subtitle: Text(
                          deposits[i]['created_at'].toString().substring(0, 10),
                        ),
                        trailing: Text(
                          "+${deposits[i]['poin_estimasi']} Pts",
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(
          val,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Database Member Aktif"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final m = _members[index];
                return Card(
                  child: ListTile(
                    onTap: () => _showMemberDeepDetail(m),
                    leading: CircleAvatar(child: Text(m['full_name'][0])),
                    title: Text(
                      m['full_name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Saldo: ${m['saldo_poin']} Poin"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  ),
                );
              },
            ),
    );
  }
}
