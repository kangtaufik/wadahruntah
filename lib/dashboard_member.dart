import 'package:flutter/material.dart';

class DashboardMember extends StatelessWidget {
  const DashboardMember({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          'Wadah Runtah', 
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Profil
            const Text(
              'Halo, Taufik!', 
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Mari selamatkan bumi hari ini 🌍', 
              style: TextStyle(color: Colors.grey, fontSize: 16)
            ),
            const SizedBox(height: 24),

            // Card Saldo Poin & Sampah
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade600, Colors.green.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Saldo Poin', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      SizedBox(height: 8),
                      Text('15.000', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('Total Setor', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      SizedBox(height: 8),
                      Text('12 Kg', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Menu Cepat (Tukar Poin, Riwayat, Katalog)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMenuIcon(Icons.qr_code_scanner, 'Tukar Poin'),
                _buildMenuIcon(Icons.history, 'Riwayat'),
                _buildMenuIcon(Icons.price_change, 'Katalog Harga'),
              ],
            ),
            const SizedBox(height: 32),

            // Daftar Riwayat Setoran Terakhir
            const Text(
              'Setoran Terakhir',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildHistoryCard('Botol Plastik PET', '+ 3.000 Poin', 'Hari ini', '2 Kg'),
            _buildHistoryCard('Kardus Bekas', '+ 2.000 Poin', 'Kemarin', '1 Kg'),
            _buildHistoryCard('Besi / Logam', '+ 10.000 Poin', 'Minggu lalu', '5 Kg'),
          ],
        ),
      ),
    );
  }

  // Bagian ini buat nyetak menu bunder-bunder biar kodenya ngga kepanjangan di atas
  Widget _buildMenuIcon(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.green.shade100,
          child: Icon(icon, color: Colors.green.shade700, size: 30),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Bagian ini buat nyetak list riwayat biar rapi
  Widget _buildHistoryCard(String title, String points, String date, String weight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.green.shade50,
          child: const Icon(Icons.recycling, color: Colors.green),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text('$date • $weight', style: TextStyle(color: Colors.grey.shade600)),
        ),
        trailing: Text(points, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}