import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:presensi_fa_mobile/functions/auth_function.dart';
import 'package:presensi_fa_mobile/functions/presence_function.dart';
import 'package:presensi_fa_mobile/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Map<String, dynamic>> _getMenuItems() {
    final baseMenuItems = [
      {'icon': Icons.access_time, 'label': 'Presence', 'route': '/presence'},
      {'icon': Icons.person, 'label': 'Profile', 'route': '/profile'},
      {'icon': Icons.logout, 'label': 'Logout', 'route': '/login'},
    ];

    if (userData?['role'] == 'admin') {
      return [
        ...baseMenuItems,
        {'icon': Icons.people, 'label': 'Data Anggota', 'route': '/members'},
        {
          'icon': Icons.money,
          'label': 'Rekap Honor',
          'route': '/honors',
        },
      ];
    }
    return baseMenuItems;
  }

  Map<String, dynamic>? userData;
  User? userDataModel;
  List<dynamic> presenceList = [];
  late List<Map<String, dynamic>> _currentMenuItems;

  void _onSelectMenu(int index) async {
    if (index >= _currentMenuItems.length || index < 0) return;

    Navigator.pop(context); // Close drawer
    final item = _currentMenuItems[index];

    switch (item['label']) {
      case 'Logout':
        try {
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => const Center(child: CircularProgressIndicator()),
          );

          await logoutRequest();
          if (mounted) {
            Navigator.of(context).pop(); // Close loading
            Navigator.pushReplacementNamed(context, '/login');
          }
        } catch (e) {
          if (mounted) {
            Navigator.of(context).pop(); // Close loading
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Logout failed: ${e.toString()}')),
            );
          }
        }
        break;

      case 'Presence':
        Navigator.pushNamed(
          context,
          '/presence',
          arguments: {'role': userData?['role'] ?? 'guest'},
        );
        break;

      case 'Profile':
        Navigator.pushNamed(
          context,
          '/profile',
          arguments: {
            'user': userDataModel,
            'onUpdateUser': (updatedUser) {
              if (mounted) setState(() => userDataModel = updatedUser);
            },
          },
        );
        break;

      // Add cases for admin menus if needed
      case 'Data Anggota':
        Navigator.pushNamed(context, '/members');
        break;

      case 'Rekap Honor':
        Navigator.pushNamed(context, '/honors');
        break;
    }
  }

  Future<void> _initialize() async {
    await _loadUserData();
    await _loadUserDataModel();
    await _loadPresences();
    setState(() {
      _currentMenuItems = _getMenuItems();
    });
  }

  @override
  void initState() {
    super.initState();
    _initialize();
    _updateMenuItems();
  }

  void _updateMenuItems() {
    setState(() {
      _currentMenuItems = _getMenuItems();
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      setState(() {
        userData = jsonDecode(userJson);
      });
    }
  }

  Future<void> _loadUserDataModel() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      final Map<String, dynamic> userMap = jsonDecode(userJson);
      setState(() {
        userDataModel = User.fromJson(userMap);
      });
    }
  }

  Future<void> _loadPresences() async {
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
            ..._currentMenuItems.map(
              (item) => ListTile(
                leading: Icon(item['icon']),
                title: Text(item['label']),
                onTap: () => _onSelectMenu(_currentMenuItems.indexOf(item)),
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
                    userData == null
                        ? const SizedBox.shrink() // Tidak tampilkan apa-apa saat userData belum tersedia
                        : SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            icon: const Icon(Icons.add),
                            label: Text(
                              userData!['role'] == 'admin'
                                  ? 'Lakukan Validasi Sekarang'
                                  : 'Lakukan Presensi Sekarang',
                            ),
                            onPressed: () {
                              if (userData!['role'] == 'admin') {
                                Navigator.pushNamed(
                                  context,
                                  '/presence',
                                  arguments: {
                                    'role': userData?['role'] ?? 'guest',
                                  },
                                );
                              } else {
                                Navigator.pushNamed(context, '/presence/add');
                              }
                            },
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final userString = prefs.getString('user');
                    if (userString != null) {
                      final userData = jsonDecode(userString);
                      final role = userData['role'];
                      Navigator.pushNamed(
                        context,
                        '/presence',
                        arguments: {'role': role},
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Data user tidak ditemukan'),
                        ),
                      );
                    }
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
                      // Navigate to detail presensi (jika ada)
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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
