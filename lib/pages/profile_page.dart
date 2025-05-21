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
  bool _success = false;
  String? _imageError;
  Map<String, String?> _errors = {};

  io.File? _image; // untuk mobile
  Uint8List? _webImage; // untuk web
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
        '_method': 'PATCH', // Laravel-style method override
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
        imageFile: _webImage ?? _image, // ini bisa File atau Uint8List (untuk web)
        isWeb: kIsWeb,
      );

      print('formFields: $formFields');
      print(_image);

      final userJson = responseJson['data'] ?? responseJson;
      final updatedUser = User.fromJson(userJson);

      widget.onUpdateUser(updatedUser);
      setState(() => _success = true);
    } catch (e) {
      if (e is Map<String, dynamic>) {
        setState(() {
          _errors = Map<String, String?>.fromEntries(
            e.entries.map((entry) => MapEntry(entry.key, entry.value[0])),
          );
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
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          errorText: _errors[field],
          border: const OutlineInputBorder(),
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
      appBar: AppBar(title: const Text("Edit Profil")),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_success)
                  AlertDialog(
                    title: const Text("Berhasil"),
                    content: const Text("Akun berhasil diupdate!"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Oke"),
                      ),
                    ],
                  ),
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(radius: 60, backgroundImage: imageProvider),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: const CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.edit, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildInputField("Nama", nameController, "name"),
                      _buildInputField(
                        "Username",
                        usernameController,
                        "username",
                      ),
                      _buildInputField("NIM", nimController, "nim"),
                      _buildInputField("Kelas", classController, "class"),
                      _buildInputField("No. HP", phoneController, "phone"),
                      _buildInputField("Email", emailController, "email"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                      onPressed: _submit,
                      child: const Text("Simpan Perubahan"),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
