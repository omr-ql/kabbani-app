class Reservation {
  final String id;
  final String productId;
  final String productName;
  final String customerId;
  final String customerName;
  final String customerContact;
  final int quantity;
  final DateTime pickupDate;
  final String? notes;
  final DateTime createdAt;
  final bool isFulfilled;

  Reservation({
    required this.id,
    required this.productId,
    required this.productName,
    required this.customerId,
    required this.customerName,
    required this.customerContact,
    required this.quantity,
    required this.pickupDate,
    this.notes,
    required this.createdAt,
    this.isFulfilled = false,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['_id'] ?? json['id'] ?? '',
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerContact: json['customerContact'] ?? '',
      quantity: json['quantity'] ?? 0,
      pickupDate: DateTime.parse(json['pickupDate']),
      notes: json['notes'],
      createdAt: DateTime.parse(json['createdAt']),
      isFulfilled: json['isFulfilled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'customerId': customerId,
      'customerName': customerName,
      'customerContact': customerContact,
      'quantity': quantity,
      'pickupDate': pickupDate.toIso8601String(),
      'notes': notes,
      'isFulfilled': isFulfilled,
    };
  }
}
