/// Estado mínimo del turno de caja que consume la app móvil.
class CashClosureStatusModel {
  final bool open;
  final int? closureId;
  final String? cashierEmail;
  final DateTime? openingTime;
  final String message;

  const CashClosureStatusModel({
    required this.open,
    this.closureId,
    this.cashierEmail,
    this.openingTime,
    required this.message,
  });

  factory CashClosureStatusModel.fromJson(Map<String, dynamic> json) {
    return CashClosureStatusModel(
      open: json['open'] as bool? ?? false,
      closureId: json['closureId'] as int?,
      cashierEmail: json['cashierEmail'] as String?,
      openingTime: json['openingTime'] != null
          ? DateTime.tryParse(json['openingTime'].toString())
          : null,
      message: json['message'] as String? ?? '',
    );
  }
}
