import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:presensi_fa_mobile/functions/user_function.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class ProfileEditScreen extends StatefulWidget {
  final User user;
  final Function(User) onUpdateUser;

  const ProfileEditScreen({
    required this.user,
    required this.onUpdateUser,
    super.key,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  late TextEditingController nameController;
  late TextEditingController usernameController;
  late TextEditingController nimController;
  late TextEditingController classController;
  late TextEditingController phoneController;
  late TextEditingController emailController;

  bool _loading = false;
  bool _showSuccessDialog = false;
  Map<String, String?> _errors = {};

  io.File? _image;
  Uint8List? _webImage;
  String? _error;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    usernameController = TextEditingController(text: widget.user.username);
    nimController = TextEditingController(text: widget.user.nim);
    classController = TextEditingController(text: widget.user.className);
    phoneController = TextEditingController(text: widget.user.phone);
    emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    nimController.dispose();
    classController.dispose();
    phoneController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
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

    setState(() {
      _loading = true;
      _errors.clear();
      _error = null;
    });

    try {
      final formFields = {
        '_method': 'PATCH',
        'name': nameController.text,
        'username': usernameController.text,
        'nim': nimController.text,
        'class': classController.text,
        'phone': phoneController.text,
        'email': emailController.text,
      };

      final responseJson = await updateUser(
        formFields,
        widget.user.id.toString(),
        isFormData: true,
        imageFile: _webImage ?? _image,
        isWeb: kIsWeb,
      );

      if (responseJson['message'] == 'User updated successfully') {
        setState(() => _showSuccessDialog = true);
      }
      final userJson = responseJson['data'] ?? responseJson;
      final updatedUser = User.fromJson(userJson);

      widget.onUpdateUser(updatedUser);
    } catch (e) {
      if (e is Map<String, dynamic>) {
        setState(() {
          _errors = Map<String, String?>.fromEntries(
            e.entries.map((entry) => MapEntry(entry.key, entry.value[0])),
          );
        });
      } else {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String field,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blue[700]),
          errorText: _errors[field],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;

    if (_webImage != null) {
      imageProvider = MemoryImage(_webImage!);
    } else if (_image != null) {
      imageProvider = FileImage(_image!);
    } else if (widget.user.image != null && widget.user.image!.isNotEmpty) {
      imageProvider = NetworkImage(widget.user.image!);
    } else {
      imageProvider = const AssetImage('assets/default-avatar.png');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profil"),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.blue[50],
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue[700]!,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.blue[100],
                            backgroundImage: imageProvider,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.blue[700],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _error != null
                      ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                      : const SizedBox.shrink(),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildInputField(
                            "Nama Lengkap",
                            nameController,
                            "name",
                          ),
                          _buildInputField(
                            "Username",
                            usernameController,
                            "username",
                          ),
                          _buildInputField("NIM", nimController, "nim"),
                          _buildInputField("Kelas", classController, "class"),
                          _buildInputField(
                            "Nomor HP",
                            phoneController,
                            "phone",
                          ),
                          _buildInputField("Email", emailController, "email"),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 2,
                              ),
                              child:
                                  _loading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : const Text(
                                        "SIMPAN PERUBAHAN",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
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
          if (_showSuccessDialog)
            Container(
              color: Colors.black54,
              child: Center(
                child: Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 60),
                        const SizedBox(height: 20),
                        const Text(
                          "Profil Berhasil Diperbarui!",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Perubahan pada profil Anda telah berhasil disimpan.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() => _showSuccessDialog = false);
                              Navigator.pushReplacementNamed(context, '/main');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "OK",
                              style: TextStyle(
                                color: Colors.white,
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
            ),
        ],
      ),
    );
  }
}
