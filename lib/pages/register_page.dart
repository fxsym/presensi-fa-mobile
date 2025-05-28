import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:presensi_fa_mobile/functions/user_function.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  io.File? _image;
  Uint8List? _webImage;
  bool _loading = false;
  String? _error;
  bool _isSuccess = false;

  final Map<String, String> _formData = {
    'name': '',
    'nim': '',
    'class': '',
    'phone': '',
    'username': '',
    'email': '',
    'password': '',
    'confirmPassword': '',
  };

  bool _isLoading = false;
  final Map<String, String?> _errors = {};

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        if (bytes.lengthInBytes > 2 * 1024 * 1024) {
          throw "Ukuran gambar tidak boleh lebih dari 2MB";
        }
        setState(() {
          _webImage = bytes;
          _image = null;
          _error = null;
        });
      } else {
        final file = io.File(picked.path);
        final size = await file.length();
        if (size > 2 * 1024 * 1024) {
          throw "Ukuran gambar tidak boleh lebih dari 2MB";
        }
        setState(() {
          _image = file;
          _webImage = null;
          _error = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _image = null;
        _webImage = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _formKey.currentState?.save();

    if (_formData['password'] != _formData['confirmPassword']) {
      setState(() => _error = "Password dan konfirmasi password tidak sama");
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await registerUser(
        fields: _formData,
        imageFile: _image,
        webImageBytes: _webImage,
        isWeb: kIsWeb,
      );

      final resBody = await http.Response.fromStream(response);
      final jsonRes = json.decode(resBody.body);
      print(jsonRes);

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSuccessDialog();
        print('Sukse');
      } else {
        throw "Gagal registrasi: ${jsonRes['message'] ?? resBody.body}";
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            title: const Text('Registrasi Berhasil'),
            content: const Text(
              'Akun Anda berhasil dibuat. Silakan login untuk melanjutkan.',
            ),
            actions: [
              TextButton(
                onPressed:
                    () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Widget _buildTextField(
    String label,
    String key, {
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        obscureText: isPassword,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator:
            validator ??
            (val) => val?.isEmpty == true ? 'Field ini wajib diisi' : null,
        onSaved: (val) => _formData[key] = val ?? '',
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_image != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(_image!, width: 100, height: 100, fit: BoxFit.cover),
      );
    } else if (_webImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          _webImage!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
        ),
      );
    }
    return const Icon(Icons.person, size: 100, color: Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun Baru'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                _buildImagePreview(),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                      ),
                                      onPressed: _pickImage,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_error != null && _error!.contains("Gambar"))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildTextField('Nama Lengkap', 'name'),
                      _buildTextField('NIM', 'nim'),
                      _buildTextField('Kelas', 'class'),
                      _buildTextField(
                        'Nomor Telepon',
                        'phone',
                        keyboardType: TextInputType.phone,
                      ),
                      _buildTextField('Username', 'username'),
                      _buildTextField(
                        'Email',
                        'email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val?.isEmpty == true) return 'Email wajib diisi';
                          if (!val!.contains('@')) return 'Email tidak valid';
                          return null;
                        },
                      ),
                      _buildTextField(
                        'Password',
                        'password',
                        isPassword: true,
                        validator: (val) {
                          if (val?.isEmpty == true)
                            return 'Password wajib diisi';
                          if (val!.length < 6)
                            return 'Password minimal 6 karakter';
                          return null;
                        },
                      ),
                      _buildTextField(
                        'Konfirmasi Password',
                        'confirmPassword',
                        isPassword: true,
                      ),
                      const SizedBox(height: 16),
                      if (_error != null && !_error!.contains("Gambar"))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text(
                                  'Daftar Sekarang',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed:
                            () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                        child: RichText(
                          text: const TextSpan(
                            text: 'Sudah punya akun? ',
                            style: TextStyle(color: Colors.grey),
                            children: [
                              TextSpan(
                                text: 'Login di sini',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
