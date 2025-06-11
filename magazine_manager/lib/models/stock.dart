class Stock {
  final int id;
  final int productId;
  final int amount;
  final String location;
  final String date;
  final bool isActive;

  Stock({
    required this.id,
    required this.productId,
    required this.amount,
    required this.location,
    required this.date,
    required this.isActive,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['ID'],
      productId: json['ProductID'],
      amount: json['Amount'],
      location: json['Location'],
      date: json['Date'],
      isActive: json['IsActive'] == 1,
    );
  }
}
