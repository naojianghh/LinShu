import 'dart:convert';

class DiagnosisReport {
  final String id;
  final String type; // 'tongue' or 'face' or 'voice'
  final DateTime date;
  final String constitution; // 体质结论
  final String pattern; // 证型倾向
  final List<String> dietaryAdvice; // 3条饮食建议
  final List<String> lifestyleAdvice; // 3条作息建议
  final List<String> exerciseAdvice; // 2条运动建议
  final String riskWarning; // 风险提示
  final String? imageUrl; // 采集的图片路径

  DiagnosisReport({
    required this.id,
    required this.type,
    required this.date,
    required this.constitution,
    required this.pattern,
    required this.dietaryAdvice,
    required this.lifestyleAdvice,
    required this.exerciseAdvice,
    required this.riskWarning,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'date': date.toIso8601String(),
      'constitution': constitution,
      'pattern': pattern,
      'dietaryAdvice': jsonEncode(dietaryAdvice),
      'lifestyleAdvice': jsonEncode(lifestyleAdvice),
      'exerciseAdvice': jsonEncode(exerciseAdvice),
      'riskWarning': riskWarning,
      'imageUrl': imageUrl,
    };
  }

  factory DiagnosisReport.fromMap(Map<String, dynamic> map) {
    return DiagnosisReport(
      id: map['id'],
      type: map['type'],
      date: DateTime.parse(map['date']),
      constitution: map['constitution'],
      pattern: map['pattern'],
      dietaryAdvice: List<String>.from(jsonDecode(map['dietaryAdvice'])),
      lifestyleAdvice: List<String>.from(jsonDecode(map['lifestyleAdvice'])),
      exerciseAdvice: List<String>.from(jsonDecode(map['exerciseAdvice'])),
      riskWarning: map['riskWarning'],
      imageUrl: map['imageUrl'],
    );
  }
}


