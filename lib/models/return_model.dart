enum ReturnStatus { requested, approved, rejected, processed, cancelled }

class ReturnItem {
  final int id;
  final int productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final bool restock;

  ReturnItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    required this.restock,
  });

  factory ReturnItem.fromMap(Map<String, dynamic> map) {
    return ReturnItem(
      id: map['id'] as int? ?? 0,
      productId: map['productId'] as int? ?? 0,
      productName: map['productName'] as String? ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 1,
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      restock: map['restock'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
      'restock': restock,
    };
  }
}

class OrderReturn {
  final int id;
  final String returnNumber;
  final int orderId;
  final String userEmail;
  final ReturnStatus status;
  final String reason;
  final String adminNotes;
  final String refundMethod;
  final double refundAmount;
  final DateTime requestedAt;
  final DateTime? approvedAt;
  final DateTime? processedAt;
  final int? processedBy;
  final int? closureId;
  final String? creditNoteNumber;
  final List<ReturnItem> items;

  OrderReturn({
    required this.id,
    required this.returnNumber,
    required this.orderId,
    required this.userEmail,
    required this.status,
    required this.reason,
    required this.adminNotes,
    required this.refundMethod,
    required this.refundAmount,
    required this.requestedAt,
    this.approvedAt,
    this.processedAt,
    this.processedBy,
    this.closureId,
    this.creditNoteNumber,
    this.items = const [],
  });

  factory OrderReturn.fromMap(Map<String, dynamic> map) {
    return OrderReturn(
      id: map['id'] as int? ?? 0,
      returnNumber: map['returnNumber'] as String? ?? '',
      orderId: map['orderId'] as int? ?? 0,
      userEmail: map['userEmail'] as String? ?? '',
      status: _statusFromString(map['status'] as String? ?? 'requested'),
      reason: map['reason'] as String? ?? '',
      adminNotes: map['adminNotes'] as String? ?? '',
      refundMethod: map['refundMethod'] as String? ?? 'WALLET',
      refundAmount: (map['refundAmount'] as num?)?.toDouble() ?? 0.0,
      requestedAt: map['requestedAt'] != null
          ? DateTime.parse(map['requestedAt'] as String)
          : DateTime.now(),
      approvedAt: map['approvedAt'] != null
          ? DateTime.parse(map['approvedAt'] as String)
          : null,
      processedAt: map['processedAt'] != null
          ? DateTime.parse(map['processedAt'] as String)
          : null,
      processedBy: map['processedBy'] as int?,
      closureId: map['closureId'] as int?,
      creditNoteNumber: map['creditNoteNumber'] as String?,
      items: (map['items'] as List?)?
          .map((item) => ReturnItem.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  static ReturnStatus _statusFromString(String s) {
    switch (s.toLowerCase()) {
      case 'requested': return ReturnStatus.requested;
      case 'approved': return ReturnStatus.approved;
      case 'rejected': return ReturnStatus.rejected;
      case 'processed': return ReturnStatus.processed;
      case 'cancelled': return ReturnStatus.cancelled;
      default: return ReturnStatus.requested;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'returnNumber': returnNumber,
      'orderId': orderId,
      'userEmail': userEmail,
      'status': status.toString().split('.').last,
      'reason': reason,
      'adminNotes': adminNotes,
      'refundMethod': refundMethod,
      'refundAmount': refundAmount,
      'requestedAt': requestedAt.toIso8601String(),
      if (approvedAt != null) 'approvedAt': approvedAt.toIso8601String(),
      if (processedAt != null) 'processedAt': processedAt.toIso8601String(),
      'processedBy': processedBy,
      'closureId': closureId,
      'creditNoteNumber': creditNoteNumber,
      'items': items.map((e) => e.toMap()).toList(),
    };
  }
}