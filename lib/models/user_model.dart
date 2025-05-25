import 'package:presensi_fa_mobile/models/honor_model.dart';

class User {
  final int id;
  final String? name;
  final String? username;
  final String? nim;
  final String? className;
  final String? phone;
  final String? email;
  final String? image;
  final String? role;
  String? status;
  int? presencecount;
  Honor? honor;

  User({
    required this.id,
    this.name,
    this.username,
    this.nim,
    this.className,
    this.phone,
    this.email,
    this.image,
    this.role,
    this.status,
    this.presencecount,
    this.honor
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        username: json['username'],
        nim: json['nim'],
        className: json['class'],
        phone: json['phone'],
        email: json['email'],
        image: json['image'],
        role: json['role'],
        status: json['status'],
        presencecount: json['presence_count'],
        honor: json['honor'] != null ? Honor.fromJson(json['honor']) : null,
      );
}
