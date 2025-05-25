import 'package:flutter/material.dart';
import 'package:presensi_fa_mobile/models/user_model.dart';
import 'package:presensi_fa_mobile/functions/user_function.dart'; // Pastikan ini sesuai path kamu
import 'dart:convert';

class HonorsPage extends StatefulWidget {
  @override
  _HonorsPageState createState() => _HonorsPageState();
}

class _HonorsPageState extends State<HonorsPage> {
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
      appBar: AppBar(title: Text('Rekap Honor')),
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
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text('Jumlah Presensi: ${member.presencecount ?? '-'}'),
                                Text('Kategori: ${member.honor?.category ?? '-'}'),
                                Text('Honor Per Pertemuan: ${member.honor?.amount ?? '-'}'),
                                Text('Total Honor: ${member.honor != null && member.presencecount != null ? member.honor!.amount * member.presencecount! : '-'}'),
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
