class Presence {
  final String id;
  final String lab;
  final String status;
  final String? note;
  final String? image;
  final String? updatedAt;

  Presence({
    required this.id,
    required this.lab,
    required this.status,
    this.note,
    this.image,
    this.updatedAt,
  });

  factory Presence.fromJson(Map<String, dynamic> json) {
    return Presence(
      id: json['id'].toString(),
      lab: json['lab'],
      status: json['status'],
      note: json['note'],
      image: json['image'],
      updatedAt: json['updated_at'],
    );
  }
}
