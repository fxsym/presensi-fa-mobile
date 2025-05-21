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
      );
}
