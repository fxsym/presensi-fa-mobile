import 'package:flutter/material.dart';
import 'package:presensi_fa_mobile/functions/presence_function.dart';
import 'package:presensi_fa_mobile/models/presence_model.dart';
import 'package:intl/intl.dart';

class PresencePage extends StatefulWidget {
  final String role;
  const PresencePage({super.key, required this.role});

  @override
  State<PresencePage> createState() => _PresencePageState();
}

class _PresencePageState extends State<PresencePage> {
  List<Presence> presence = [];
  List<Presence> filteredPresence = [];

  String selectedLab = "";
  String selectedDate = "";
  String selectedStatus = "";

  bool loading = true;
  bool loadingDelete = false;
  String? deleteId;

  // Blue color theme
  final Color primaryBlue = Colors.blue.shade700;
  final Color lightBlue = Colors.blue.shade100;

  @override
  void initState() {
    super.initState();
    fetchPresence();
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
      applyFilters();
    }
  }

  void fetchPresence() async {
    setState(() => loading = true);
    try {
      final data = await getPresences() as List;
      final List<Presence> presences =
          data.map((e) => Presence.fromJson(e)).toList();
      setState(() {
        presence = presences;
        filteredPresence = presences;
      });
    } catch (e) {
      print("Gagal memuat presensi: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  void applyFilters() {
    setState(() {
      filteredPresence =
          presence.where((p) {
            final matchLab =
                selectedLab.isEmpty ||
                p.lab.toLowerCase() == selectedLab.toLowerCase();
            final matchStatus =
                selectedStatus.isEmpty || p.status == selectedStatus;
            final matchDate =
                selectedDate.isEmpty ||
                (p.updatedAt?.startsWith(selectedDate) ?? false);
            return matchLab && matchStatus && matchDate;
          }).toList();
    });
  }

  void handleDelete(String id) async {
    setState(() => loadingDelete = true);
    try {
      await deletePresence(id);
      setState(() {
        presence.removeWhere((p) => p.id == id);
        filteredPresence.removeWhere((p) => p.id == id);
        deleteId = null;
      });
    } catch (e) {
      print("Gagal menghapus: $e");
    } finally {
      setState(() => loadingDelete = false);
    }
  }

  void handleUpdateStatus(String id, String status) async {
    try {
      await updatePresenceStatus(id, status);
      setState(() {
        presence =
            presence
                .map(
                  (p) =>
                      p.id == id
                          ? Presence(
                            id: p.id,
                            lab: p.lab,
                            status: status,
                            note: p.note,
                            image: p.image,
                            updatedAt: p.updatedAt,
                          )
                          : p,
                )
                .toList();
        applyFilters();
      });
    } catch (e) {
      print("Gagal update status: $e");
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "validated":
        return Colors.green;
      case "pending":
        return Colors.orange;
      case "rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Presensi"),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                  children: [
                    // Filter Section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Lab',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                    ),
                                    value:
                                        selectedLab.isEmpty
                                            ? null
                                            : selectedLab,
                                    hint: const Text("Pilih Lab"),
                                    onChanged: (val) {
                                      setState(() => selectedLab = val ?? "");
                                      applyFilters();
                                    },
                                    items: [
                                      for (var i = 1; i <= 6; i++)
                                        DropdownMenuItem(
                                          value: 'Lab $i',
                                          child: Text('Lab $i'),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: InputDecoration(
                                      labelText: 'Status',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                    ),
                                    value:
                                        selectedStatus.isEmpty
                                            ? null
                                            : selectedStatus,
                                    hint: const Text("Status"),
                                    onChanged: (val) {
                                      setState(
                                        () => selectedStatus = val ?? "",
                                      );
                                      applyFilters();
                                    },
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'validated',
                                        child: Text('Tervalidasi'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'pending',
                                        child: Text('Belum Divalidasi'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'rejected',
                                        child: Text('Ditolak'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => selectDate(context),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Tanggal',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        suffixIcon: const Icon(
                                          Icons.calendar_today,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                      ),
                                      child: Text(
                                        selectedDate.isEmpty
                                            ? 'Pilih tanggal'
                                            : selectedDate,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      selectedLab = '';
                                      selectedStatus = '';
                                      selectedDate = '';
                                    });
                                    applyFilters();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryBlue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                  ),
                                  child: const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Presence List
                    Expanded(
                      child:
                          filteredPresence.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 60,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "Tidak ada data presensi",
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    if (selectedLab.isNotEmpty ||
                                        selectedStatus.isNotEmpty ||
                                        selectedDate.isNotEmpty)
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedLab = '';
                                            selectedStatus = '';
                                            selectedDate = '';
                                          });
                                          applyFilters();
                                        },
                                        child: Text(
                                          "Reset filter",
                                          style: TextStyle(color: primaryBlue),
                                        ),
                                      ),
                                  ],
                                ),
                              )
                              : ListView.builder(
                                itemCount: filteredPresence.length,
                                itemBuilder: (context, index) {
                                  final p = filteredPresence[index];
                                  return Card(
                                    elevation: 3,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          if (p.image != null)
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Container(
                                                height: 200,
                                                width: double.infinity,
                                                decoration: BoxDecoration(
                                                  color: lightBlue,
                                                ),
                                                child: Image.network(
                                                  p.image!,
                                                  fit: BoxFit.contain,
                                                  errorBuilder:
                                                      (_, __, ___) => Center(
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 40,
                                                            ),
                                                            Text(
                                                              "Gagal memuat gambar",
                                                              style: TextStyle(
                                                                color:
                                                                    Colors
                                                                        .grey
                                                                        .shade600,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                  loadingBuilder: (
                                                    context,
                                                    child,
                                                    loadingProgress,
                                                  ) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Center(
                                                      child: CircularProgressIndicator(
                                                        value:
                                                            loadingProgress
                                                                        .expectedTotalBytes !=
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
                                              ),
                                            ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                p.lab,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: getStatusColor(
                                                    p.status,
                                                  ).withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  p.status.toUpperCase(),
                                                  style: TextStyle(
                                                    color: getStatusColor(
                                                      p.status,
                                                    ),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (p.note != null &&
                                              p.note!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              '"${p.note!}"',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          Text(
                                            "Tanggal: ${p.updatedAt ?? 'Tidak diketahui'}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              if (widget.role == 'admin' &&
                                                  p.status == 'pending')
                                                TextButton(
                                                  onPressed:
                                                      () => handleUpdateStatus(
                                                        p.id,
                                                        'validated',
                                                      ),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.green,
                                                  ),
                                                  child: const Text("Validasi"),
                                                ),
                                              if (widget.role == 'admin' &&
                                                  p.status == 'validated')
                                                TextButton(
                                                  onPressed:
                                                      () => handleUpdateStatus(
                                                        p.id,
                                                        'pending',
                                                      ),
                                                  style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        Colors.orange,
                                                  ),
                                                  child: const Text(
                                                    "Unvalidate",
                                                  ),
                                                ),
                                              if (widget.role == 'admin' ||
                                                  p.status == 'pending')
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.delete,
                                                    color: Colors.red.shade400,
                                                  ),
                                                  onPressed:
                                                      () => setState(
                                                        () => deleteId = p.id,
                                                      ),
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                    if (deleteId != null)
                      AlertDialog(
                        title: const Text("Konfirmasi Hapus"),
                        content: const Text(
                          "Apakah kamu yakin ingin menghapus data ini?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => setState(() => deleteId = null),
                            child: const Text("Batal"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed:
                                loadingDelete
                                    ? null
                                    : () => handleDelete(deleteId!),
                            child:
                                loadingDelete
                                    ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    )
                                    : const Text(
                                      "Hapus",
                                      style: TextStyle(color: Colors.white),
                                    ),
                          ),
                        ],
                      ),
                  ],
                ),
      ),

      // Delete Confirmation Dialog
    );
  }
}
