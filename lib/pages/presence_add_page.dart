import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:presensi_fa_mobile/functions/presence_function.dart';

class PresenceAddPage extends StatefulWidget {
  @override
  _PresenceAddPageState createState() => _PresenceAddPageState();
}

class _PresenceAddPageState extends State<PresenceAddPage> {
  io.File? _image;
  Uint8List? _webImage;
  String? _lab;
  String _note = '';
  bool _loading = false;
  String? _error;
  bool _isSuccess = false;

  final _formKey = GlobalKey<FormState>();
  final Color _primaryColor = Colors.blue.shade700;
  final Color _accentColor = Colors.blue.shade400;
  final Color _lightBlue = Colors.blue.shade50;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        final size = bytes.lengthInBytes;

        if (size > 2 * 1024 * 1024) {
          setState(() {
            _error = "Ukuran gambar tidak boleh lebih dari 2MB.";
            _webImage = null;
          });
        } else {
          setState(() {
            _webImage = bytes;
            _image = null;
            _error = null;
          });
        }
      } else {
        final file = io.File(picked.path);
        final size = await file.length();

        if (size > 2 * 1024 * 1024) {
          setState(() {
            _error = "Ukuran gambar tidak boleh lebih dari 2MB.";
            _image = null;
          });
        } else {
          setState(() {
            _image = file;
            _webImage = null;
            _error = null;
          });
        }
      }
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if ((kIsWeb ? _webImage == null : _image == null)) {
      setState(() => _error = "Gambar wajib diunggah.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await addPresence(
        lab: _lab!,
        note: _note.isEmpty ? null : _note,
        imageFile: _image,
        webImageBytes: _webImage,
        isWeb: kIsWeb,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _isSuccess = true);
      } else {
        final resBody = await response.stream.bytesToString();
        setState(() => _error = "Gagal menyimpan data: ${resBody}");
      }
    } catch (e) {
      setState(() => _error = "Gagal menyimpan data: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildImagePreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _accentColor,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child:
            _webImage != null
                ? Image.memory(
                  _webImage!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                )
                : _image != null
                ? Image.file(
                  _image!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                )
                : Container(
                  width: double.infinity,
                  height: 200,
                  color: _lightBlue,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 50,
                        color: _primaryColor,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Upload Foto Presensi",
                        style: TextStyle(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "PNG, JPG, JPEG (Maks. 2MB)",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Presensi"),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: _lightBlue,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: _buildImagePreview(),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: "Pilih Lab *",
                                labelStyle: TextStyle(color: _primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _accentColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _primaryColor),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              value: _lab,
                              validator:
                                  (value) =>
                                      value == null
                                          ? "Pilih lab terlebih dahulu"
                                          : null,
                              onChanged:
                                  (value) => setState(() => _lab = value),
                              items:
                                  List.generate(6, (i) => "Lab ${i + 1}")
                                      .map(
                                        (lab) => DropdownMenuItem(
                                          value: lab,
                                          child: Text(lab),
                                        ),
                                      )
                                      .toList(),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: "Catatan (Opsional)",
                                labelStyle: TextStyle(color: _primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _accentColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: _primaryColor),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              onChanged: (val) => _note = val,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child:
                            _loading
                                ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                                : const Text(
                                  "Simpan Presensi",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isSuccess) _buildSuccessDialog(),
        ],
      ),
    );
  }

  Widget _buildSuccessDialog() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 20),
                const Text(
                  "Presensi Berhasil!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Data presensi telah berhasil disimpan",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/main');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "OK",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
