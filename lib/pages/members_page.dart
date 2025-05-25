import 'package:flutter/material.dart';
import 'package:presensi_fa_mobile/models/user_model.dart';
import 'package:presensi_fa_mobile/functions/user_function.dart'; // Pastikan ini sesuai path kamu

class MembersScreen extends StatefulWidget {
  @override
  _MembersScreenState createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List<User> members = [];
  bool loading = false;
  String? error;
  int currentPage = 1;
  final int itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await getMembersData();
      print(response);

      final List<dynamic> usersJson =
          response['users']; // asumsi responsenya seperti: { "data": [user1, user2, ...] }

      final allUsers = usersJson.map((json) => User.fromJson(json)).toList();

      setState(() {
        members = allUsers.where((user) => user.role == 'member').toList();
      });
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> toggleStatus(String id) async {
    final index = members.indexWhere((m) => m.id.toString() == id);
    print(index);
    if (index == -1) return;

    final oldStatus = members[index].status;
    final newStatus = oldStatus == "active" ? "inactive" : "active";
    print('Changing status to: $newStatus');

    // Optimistic update
    setState(() {
      members[index].status = newStatus;
    });

    try {
      await updateUser({'status': newStatus}, id);
    } catch (e) {
      print("Error updating status: $e");

      // Rollback
      setState(() {
        members[index].status = oldStatus;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengupdate status')));
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() => currentPage = page);
    }
  }

  int get totalPages => (members.length / itemsPerPage).ceil();

  List<User> get currentMembers {
    final start = (currentPage - 1) * itemsPerPage;
    final end = start + itemsPerPage;
    return members.sublist(start, end > members.length ? members.length : end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Data Anggota')),
      body:
          loading
              ? Center(child: CircularProgressIndicator())
              : error != null
              ? Center(child: Text('Terjadi kesalahan: $error'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(12),
                      itemCount: currentMembers.length,
                      itemBuilder: (context, index) {
                        final member = currentMembers[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: NetworkImage(
                                        member.image ??
                                            'https://via.placeholder.com/150',
                                      ),
                                      radius: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            member.name ?? '-',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            member.nim ?? '',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Status switch (dummy, karena tidak ada API update)
                                    Switch(
                                      value: member.status == "active",
                                      onChanged:
                                          (_) => toggleStatus(
                                            member.id.toString(),
                                          ),
                                      activeColor: Colors.green,
                                      inactiveThumbColor: Colors.grey,
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text('Email: ${member.email ?? '-'}'),
                                Text('Kelas: ${member.className ?? '-'}'),
                                Text('Telepon: ${member.phone ?? '-'}'),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed:
                            currentPage > 1
                                ? () => goToPage(currentPage - 1)
                                : null,
                        icon: Icon(Icons.chevron_left),
                      ),
                      ...List.generate(totalPages, (i) => i + 1).map(
                        (page) => TextButton(
                          onPressed: () => goToPage(page),
                          child: Text(
                            '$page',
                            style: TextStyle(
                              fontWeight:
                                  currentPage == page
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                            currentPage < totalPages
                                ? () => goToPage(currentPage + 1)
                                : null,
                        icon: Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ],
              ),
    );
  }
}
