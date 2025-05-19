import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:presensi_fa_mobile/functions/auth_function.dart';
import 'package:presensi_fa_mobile/functions/presence_function.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  Map<String, dynamic>? userData;
  List<dynamic> presenceList = [];

  void _onSelectMenu(int index) async {
    if (_menuItems[index]['label'] == 'Logout') {
      await logoutRequest();
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      Navigator.pushNamed(context, _menuItems[index]['route']);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPresences();
  }

  void _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      setState(() {
        userData = jsonDecode(userJson);
      });
    }
  }

  void _loadPresences() async {
    try {
      final data = await getPresences();
      setState(() {
        presenceList = data;
      });
    } catch (e) {
      print('Gagal mengambil presensi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalValidated =
        presenceList
            .where((p) => p['status']?.toLowerCase() == 'validated')
            .length;

    final latestPresences = presenceList.take(4).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Utama'),
        elevation: 0,
        backgroundColor: colorScheme.primaryContainer,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: colorScheme.primaryContainer),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.primary,
                    child:
                        userData?['image'] != null
                            ? ClipOval(
                              child: Image.network(
                                userData!['image'],
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to initial if image fails to load
                                  return Text(
                                    userData?['name']?.toString().substring(
                                          0,
                                          1,
                                        ) ??
                                        'U',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: colorScheme.onPrimary,
                                    ),
                                  );
                                },
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  );
                                },
                              ),
                            )
                            : Text(
                              userData?['name']?.toString().substring(0, 1) ??
                                  'U',
                              style: TextStyle(
                                fontSize: 20,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userData?['name'] ?? 'User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    userData?['email'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            ..._menuItems.map(
              (item) => ListTile(
                leading: Icon(item['icon']),
                title: Text(item['label']),
                onTap: () => _onSelectMenu(_menuItems.indexOf(item)),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Card
            Card(
              elevation: 0,
              color: colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                    Text(
                      userData?['name'] ?? 'User',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Lakukan Presensi Sekarang'),
                        onPressed: () {
                          Navigator.pushNamed(context, '/presence/add');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stats Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _DashboardCard(
                  icon: Icons.check_circle,
                  title: 'Presensi Tervalidasi',
                  value: totalValidated.toString(),
                  color: Colors.green,
                ),
                _DashboardCard(
                  icon: Icons.access_time,
                  title: 'Total Presensi',
                  value: presenceList.length.toString(),
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Recent Presences
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Presensi Terbaru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to full presences list
                    Navigator.pushNamed(context, '/presence-list');
                  },
                  child: const Text('Lihat Semua'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: latestPresences.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = latestPresences[index];
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            item['status']?.toLowerCase() == 'validated'
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item['status']?.toLowerCase() == 'validated'
                            ? Icons.check_circle
                            : Icons.access_time,
                        color:
                            item['status']?.toLowerCase() == 'validated'
                                ? Colors.green
                                : Colors.orange,
                      ),
                    ),
                    title: Text(
                      'Status: ${item['status']}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Waktu: ${item['created_at']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                        ),
                        if (item['note'] != null &&
                            item['note'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Catatan: ${item['note']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // Navigate to presence detail
                    },
                  ),
                );
              },
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
  final Color color;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.value,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
