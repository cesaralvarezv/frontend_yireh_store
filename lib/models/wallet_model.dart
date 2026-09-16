class WalletBalance {
  final double balance;

  const WalletBalance({required this.balance});

  factory WalletBalance.fromJson(Map<String, dynamic> json) {
    return WalletBalance(
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class RechargeTransaction {
  final int id;
  final String userId;
  final double amount;
  final String paymentMethod;
  final String status;
  final String referenceCode;
  final DateTime createdAt;

  const RechargeTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.referenceCode,
    required this.createdAt,
  });

  factory RechargeTransaction.fromJson(Map<String, dynamic> json) {
    return RechargeTransaction(
      id: json['id'] as int? ?? 0,
      userId: json['userId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      referenceCode: json['referenceCode'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
