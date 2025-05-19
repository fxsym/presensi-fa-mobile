import 'package:flutter/material.dart';
import 'package:presensi_fa_mobile/functions/auth_function.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.access_time, 'label': 'Presence', 'route': '/presence'},
    {'icon': Icons.person, 'label': 'Account', 'route': '/account'},
    {'icon': Icons.logout, 'label': 'Logout', 'route': '/login'},
  ];

  void _onSelectMenu(int index) async {
    if (_menuItems[index]['label'] == 'Logout') {
      await logoutRequest();
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      Navigator.pushNamed(context, _menuItems[index]['route']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Utama'),
      ),
      drawer: Drawer(
        child: ListView.builder(
          itemCount: _menuItems.length,
          itemBuilder: (context, index) {
            return ListTile(
              leading: Icon(_menuItems[index]['icon']),
              title: Text(_menuItems[index]['label']),
              onTap: () => _onSelectMenu(index),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat Datang!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Berikut ringkasan informasi aplikasi:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: const [
                  _DashboardCard(
                    icon: Icons.group,
                    title: 'Total Pengguna',
                    value: '150',
                  ),
                  _DashboardCard(
                    icon: Icons.check_circle_outline,
                    title: 'Presensi Hari Ini',
                    value: '47',
                  ),
                  _DashboardCard(
                    icon: Icons.schedule,
                    title: 'Presensi Tersisa',
                    value: '3',
                  ),
                  _DashboardCard(
                    icon: Icons.settings,
                    title: 'Pengaturan',
                    value: '-',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
