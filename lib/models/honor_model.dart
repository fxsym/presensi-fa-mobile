class Honor {
  final int id;
  final String category;
  final int amount;
  final String info;

  Honor({
    required this.id,
    required this.category,
    required this.amount,
    required this.info,
  });

  factory Honor.fromJson(Map<String, dynamic> json) {
    return Honor(
      id: json['id'],
      category: json['category'],
      amount: json['amount'],
      info: json['info'],
    );
  }
}
