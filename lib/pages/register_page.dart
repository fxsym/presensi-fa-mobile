import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:presensi_fa_mobile/functions/user_function.dart'; // ganti sesuai path project

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
  String? _lab;
  String _note = '';
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
  final formValid = _formKey.currentState?.validate() ?? false;
  if (!formValid) return;
  _formKey.currentState?.save();

  if ((kIsWeb ? _webImage == null : _image == null)) {
    setState(() => _error = "Gambar wajib diunggah.");
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

    if (response.statusCode == 200 || response.statusCode == 201) {
      final resBody = await http.Response.fromStream(response);
      final jsonRes = json.decode(resBody.body);

      if (jsonRes['success'] == true) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Berhasil'),
            content: const Text('Akun berhasil dibuat. Silakan login.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        setState(() => _error = jsonRes['message'] ?? 'Terjadi kesalahan');
      }
    } else {
      final resBody = await response.stream.bytesToString();
      setState(() => _error = "Gagal registrasi: $resBody");
    }
  } catch (e) {
    setState(() => _error = "Gagal registrasi: ${e.toString()}");
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}


  Widget _buildTextField(
    String label,
    String key, {
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        errorText: _errors[key],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onSaved: (val) => _formData[key] = val ?? '',
      validator: (val) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black.withOpacity(0.3)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white.withOpacity(0.85),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Buat Akun',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo),
                          label: const Text('Pilih Foto Profil'),
                        ),
                        if (_errors['image'] != null)
                          Text(
                            _errors['image']!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        const SizedBox(height: 12),
                        _buildTextField('Nama', 'name'),
                        const SizedBox(height: 8),
                        _buildTextField('NIM', 'nim'),
                        const SizedBox(height: 8),
                        _buildTextField('Kelas', 'class'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          'Nomor Telepon',
                          'phone',
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField('Username', 'username'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          'Email',
                          'email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          'Password',
                          'password',
                          isPassword: true,
                        ),
                        const SizedBox(height: 8),
                        _buildTextField(
                          'Konfirmasi Password',
                          'confirmPassword',
                          isPassword: true,
                        ),
                        const SizedBox(height: 16),
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                              onPressed: _submit,
                              child: const Text('Register'),
                            ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed:
                              () => Navigator.pushReplacementNamed(
                                context,
                                '/login',
                              ),
                          child: const Text('Sudah punya akun? Login di sini'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
