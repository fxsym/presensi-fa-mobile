import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      setState(() {
        _user = jsonDecode(userJson);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _user?['name'] ?? 'User';
    final userEmail = _user?['email'] ?? '';
    final userImage = _user?['image'] ?? '';
    final userClass = _user?['class'] ?? '';
    final userNim = _user?['nim'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _user == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(userImage),
                        onBackgroundImageError: (_, __) => const Icon(Icons.person),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(userEmail),
                          Text('$userClass - $userNim'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Selamat Datang di Dashboard!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Berikut ringkasan informasi Anda:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _DashboardCard(
                          icon: Icons.accessibility,
                          title: 'Role',
                          value: _user?['role'] ?? '-',
                        ),
                        _DashboardCard(
                          icon: Icons.check_circle,
                          title: 'Jumlah Presensi',
                          value: _user?['presence_count']?.toString() ?? '0',
                        ),
                        _DashboardCard(
                          icon: Icons.attach_money,
                          title: 'Honor',
                          value:
                              'Rp ${_user?['honor']?['amount']?.toString() ?? '0'}',
                        ),
                        _DashboardCard(
                          icon: Icons.info,
                          title: 'Status',
                          value: _user?['status'] ?? '-',
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
      elevation: 4,
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
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
