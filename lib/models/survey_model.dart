/// Modelo de encuesta de satisfaccion CSAT.
class SurveyModel {
  final int id;
  final int orderId;
  final String userEmail;
  final int rating;
  final String? quickTags;
  final String? comment;
  final DateTime createdAt;

  const SurveyModel({
    required this.id,
    required this.orderId,
    required this.userEmail,
    required this.rating,
    this.quickTags,
    this.comment,
    required this.createdAt,
  });

  factory SurveyModel.fromJson(Map<String, dynamic> json) {
    return SurveyModel(
      id: json['id'] as int? ?? 0,
      orderId: json['orderId'] as int? ?? 0,
      userEmail: json['userEmail'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      quickTags: json['quickTags'] as String?,
      comment: json['comment'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'rating': rating,
        if (quickTags != null && quickTags!.isNotEmpty) 'quickTags': quickTags,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
      };
}
