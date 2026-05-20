import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDetailSampahPage extends StatefulWidget {
  const AdminDetailSampahPage({super.key});

  @override
  State<AdminDetailSampahPage> createState() => _AdminDetailSampahPageState();
}

class _AdminDetailSampahPageState extends State<AdminDetailSampahPage> {
  final supabase = Supabase.instance.client;
  String _filter = 'Semua Waktu';
  bool _isLoading = false;
  Map<String, double> _rekapSampah = {};
  double _totalBeratSemua = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    DateTime now = DateTime.now();
    String? start;

    if (_filter == 'Hari Ini')
      start = DateTime(now.year, now.month, now.day).toIso8601String();
    if (_filter == 'Minggu Ini')
      start = now.subtract(Duration(days: now.weekday - 1)).toIso8601String();
    if (_filter == 'Bulan Ini')
      start = DateTime(now.year, now.month, 1).toIso8601String();
    if (_filter == 'Tahun Ini')
      start = DateTime(now.year, 1, 1).toIso8601String();

    var query = supabase
        .from('deposits')
        .select('berat, jenis_sampah')
        .eq('status', 'approved');
    if (start != null) query = query.gte('created_at', start);

    final data = await query;
    Map<String, double> tempMap = {};
    double total = 0.0;

    for (var item in data) {
      String j = item['jenis_sampah'] ?? 'Lainnya';
      double b = (item['berat'] as num).toDouble();
      total += b;
      tempMap[j] = (tempMap[j] ?? 0) + b;
    }

    setState(() {
      _rekapSampah = tempMap;
      _totalBeratSemua = total;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Analitik Volume Sampah"),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Filter Rentang:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _filter,
                  items:
                      [
                            'Hari Ini',
                            'Minggu Ini',
                            'Bulan Ini',
                            'Tahun Ini',
                            'Semua Waktu',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) {
                    setState(() => _filter = v!);
                    _loadData();
                  },
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator())),
          if (!_isLoading)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 20),
                  const Text(
                    "Rincian Per Kategori",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._rekapSampah.entries
                      .map(
                        (e) => Card(
                          child: ListTile(
                            leading: const Icon(
                              Icons.category,
                              color: Colors.green,
                            ),
                            title: Text(e.key),
                            trailing: Text(
                              "${e.value.toStringAsFixed(1)} Kg",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Text(
            "TOTAL BERAT TERKUMPUL",
            style: TextStyle(color: Colors.white70, letterSpacing: 1),
          ),
          Text(
            "${_totalBeratSemua.toStringAsFixed(1)} Kg",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 35,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
