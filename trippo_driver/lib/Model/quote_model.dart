/// Quote/Estimate Model
/// Provider submits quotes after arriving at the house

class ServiceQuote {
  final String id;
  final String serviceRequestId;
  final String providerId;
  final String providerName;
  final double houseCallFee; // Fee charged for coming to the house
  final List<QuoteLineItem> lineItems;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String notes;
  final DateTime createdAt;
  final QuoteStatus status;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final String? userDeclineReason;

  ServiceQuote({
    required this.id,
    required this.serviceRequestId,
    required this.providerId,
    required this.providerName,
    required this.houseCallFee,
    required this.lineItems,
    required this.subtotal,
    required this.taxAmount,
    required this.totalAmount,
    required this.notes,
    required this.createdAt,
    required this.status,
    this.acceptedAt,
    this.declinedAt,
    this.userDeclineReason,
  });

  factory ServiceQuote.fromFirestore(Map<String, dynamic> data, String id) {
    return ServiceQuote(
      id: id,
      serviceRequestId: data['serviceRequestId'] ?? '',
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      houseCallFee: (data['houseCallFee'] ?? 0.0).toDouble(),
      lineItems: (data['lineItems'] as List<dynamic>?)
              ?.map((e) => QuoteLineItem.fromMap(e))
              .toList() ??
          [],
      subtotal: (data['subtotal'] ?? 0.0).toDouble(),
      taxAmount: (data['taxAmount'] ?? 0.0).toDouble(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      notes: data['notes'] ?? '',
      createdAt: DateTime.parse(data['createdAt']),
      status: QuoteStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => QuoteStatus.pending,
      ),
      acceptedAt: data['acceptedAt'] != null ? DateTime.parse(data['acceptedAt']) : null,
      declinedAt: data['declinedAt'] != null ? DateTime.parse(data['declinedAt']) : null,
      userDeclineReason: data['userDeclineReason'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serviceRequestId': serviceRequestId,
      'providerId': providerId,
      'providerName': providerName,
      'houseCallFee': houseCallFee,
      'lineItems': lineItems.map((e) => e.toMap()).toList(),
      'subtotal': subtotal,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'declinedAt': declinedAt?.toIso8601String(),
      'userDeclineReason': userDeclineReason,
    };
  }

  ServiceQuote copyWith({
    String? id,
    String? serviceRequestId,
    String? providerId,
    String? providerName,
    double? houseCallFee,
    List<QuoteLineItem>? lineItems,
    double? subtotal,
    double? taxAmount,
    double? totalAmount,
    String? notes,
    DateTime? createdAt,
    QuoteStatus? status,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    String? userDeclineReason,
  }) {
    return ServiceQuote(
      id: id ?? this.id,
      serviceRequestId: serviceRequestId ?? this.serviceRequestId,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      houseCallFee: houseCallFee ?? this.houseCallFee,
      lineItems: lineItems ?? this.lineItems,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      declinedAt: declinedAt ?? this.declinedAt,
      userDeclineReason: userDeclineReason ?? this.userDeclineReason,
    );
  }
}

/// Individual line item in a quote
class QuoteLineItem {
  final String description;
  final double quantity;
  final double unitPrice;
  final double totalPrice;

  QuoteLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory QuoteLineItem.fromMap(Map<String, dynamic> map) {
    return QuoteLineItem(
      description: map['description'] ?? '',
      quantity: (map['quantity'] ?? 1.0).toDouble(),
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }
}

enum QuoteStatus {
  pending,
  accepted,
  declined,
  expired,
}

extension QuoteStatusExtension on QuoteStatus {
  String get displayName {
    switch (this) {
      case QuoteStatus.pending:
        return 'Awaiting Your Approval';
      case QuoteStatus.accepted:
        return 'Accepted';
      case QuoteStatus.declined:
        return 'Declined';
      case QuoteStatus.expired:
        return 'Expired';
    }
  }
}

/// Payment Transaction Model
class PaymentTransaction {
  final String id;
  final String serviceRequestId;
  final String userId;
  final String providerId;
  final PaymentType type;
  final double amount;
  final PaymentStatus status;
  final PaymentMethod method;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? transactionId; // Stripe/PayPal transaction ID
  final String? errorMessage;

  PaymentTransaction({
    required this.id,
    required this.serviceRequestId,
    required this.userId,
    required this.providerId,
    required this.type,
    required this.amount,
    required this.status,
    required this.method,
    required this.createdAt,
    this.completedAt,
    this.transactionId,
    this.errorMessage,
  });

  factory PaymentTransaction.fromFirestore(Map<String, dynamic> data, String id) {
    return PaymentTransaction(
      id: id,
      serviceRequestId: data['serviceRequestId'] ?? '',
      userId: data['userId'] ?? '',
      providerId: data['providerId'] ?? '',
      type: PaymentType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => PaymentType.houseCallFee,
      ),
      amount: (data['amount'] ?? 0.0).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PaymentStatus.pending,
      ),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == data['method'],
        orElse: () => PaymentMethod.stripe,
      ),
      createdAt: DateTime.parse(data['createdAt']),
      completedAt: data['completedAt'] != null ? DateTime.parse(data['completedAt']) : null,
      transactionId: data['transactionId'],
      errorMessage: data['errorMessage'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'serviceRequestId': serviceRequestId,
      'userId': userId,
      'providerId': providerId,
      'type': type.name,
      'amount': amount,
      'status': status.name,
      'method': method.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'transactionId': transactionId,
      'errorMessage': errorMessage,
    };
  }
}

enum PaymentType {
  houseCallFee,    // Fee to come to the house
  jobPayment,      // Payment for the actual job
  tip,             // Optional tip
  refund,          // Refund (if job cancelled)
}

enum PaymentStatus {
  pending,          // Payment authorized but not captured
  processing,       // Payment being processed
  completed,        // Payment captured successfully
  failed,           // Payment failed
  refunded,         // Payment refunded
  cancelled,        // Payment cancelled before capture
}

enum PaymentMethod {
  stripe,
  paypal,
  applePay,
  googlePay,
}

extension PaymentTypeExtension on PaymentType {
  String get displayName {
    switch (this) {
      case PaymentType.houseCallFee:
        return 'House Call Fee';
      case PaymentType.jobPayment:
        return 'Job Payment';
      case PaymentType.tip:
        return 'Tip';
      case PaymentType.refund:
        return 'Refund';
    }
  }
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.stripe:
        return 'Credit/Debit Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.stripe:
        return '💳';
      case PaymentMethod.paypal:
        return '🅿️';
      case PaymentMethod.applePay:
        return '';
      case PaymentMethod.googlePay:
        return '🅶';
    }
  }
}
