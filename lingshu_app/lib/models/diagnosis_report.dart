import 'dart:convert';

class MindPlan {
  final int stressIndex; // 0-100
  final int relaxPercent; // 0-100
  final String suggestion;

  const MindPlan({
    required this.stressIndex,
    required this.relaxPercent,
    required this.suggestion,
  });

  factory MindPlan.empty() {
    return const MindPlan(
      stressIndex: 60,
      relaxPercent: 72,
      suggestion: '建议优先进行10~15分钟的呼吸冥想，再安排轻度运动。',
    );
  }

  Map<String, dynamic> toJson() => {
        'stress_index': stressIndex,
        'relax_percent': relaxPercent,
        'suggestion': suggestion,
      };

  factory MindPlan.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value, int fallback) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return MindPlan(
      stressIndex: toInt(json['stress_index'], 60).clamp(0, 100),
      relaxPercent: toInt(json['relax_percent'], 72).clamp(0, 100),
      suggestion:
          (json['suggestion'] as String?) ?? MindPlan.empty().suggestion,
    );
  }
}

class GoddessPlan {
  final List<String> dietaryAdvice; // dietary_advice
  final List<String> exercisePlan; // exercise_plan
  final List<String> careAdvice; // care_advice
  final List<String> constitutionEvolution; // constitution_evolution
  final List<String> wellnessRecommendation; // wellness_recommendation
  final String weeklyFocus; // weekly_focus
  final List<Map<String, String>> drinkRecommendations; // drink_recommendations

  const GoddessPlan({
    required this.dietaryAdvice,
    required this.exercisePlan,
    required this.careAdvice,
    required this.constitutionEvolution,
    required this.wellnessRecommendation,
    required this.weeklyFocus,
    required this.drinkRecommendations,
  });

  factory GoddessPlan.empty() {
    return const GoddessPlan(
      dietaryAdvice: [],
      exercisePlan: [],
      careAdvice: [],
      constitutionEvolution: [],
      wellnessRecommendation: [],
      weeklyFocus: '本周以稳定作息、温和调理为主。',
      drinkRecommendations: [],
    );
  }

  Map<String, dynamic> toJson() => {
        'dietary_advice': dietaryAdvice,
        'exercise_plan': exercisePlan,
        'care_advice': careAdvice,
        'constitution_evolution': constitutionEvolution,
        'wellness_recommendation': wellnessRecommendation,
        'weekly_focus': weeklyFocus,
        'drink_recommendations': drinkRecommendations,
      };

  factory GoddessPlan.fromJson(Map<String, dynamic> json) {
    List<String> toStringList(dynamic value) {
      if (value is! List) return const [];
      return value
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }

    List<Map<String, String>> toDrinkList(dynamic value) {
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map((e) {
            return {
              'name': (e['name'] ?? '').toString(),
              'description': (e['description'] ?? '').toString(),
              'price': (e['price'] ?? '').toString(),
            };
          })
          .where((e) => e['name']!.isNotEmpty)
          .toList();
    }

    return GoddessPlan(
      dietaryAdvice: toStringList(
        json['dietary_advice'] ?? json['dietary_plan'],
      ),
      exercisePlan: toStringList(json['exercise_plan']),
      careAdvice: toStringList(json['care_advice']),
      constitutionEvolution: toStringList(json['constitution_evolution']),
      wellnessRecommendation:
          toStringList(json['wellness_recommendation']),
      weeklyFocus: (json['weekly_focus'] as String?) ?? '本周以稳定作息、温和调理为主。',
      drinkRecommendations: toDrinkList(json['drink_recommendations']),
    );
  }
}

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
  final GoddessPlan goddessPlan;
  final MindPlan mindPlan;

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
    required this.goddessPlan,
    required this.mindPlan,
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
      'goddessPlanJson': jsonEncode(goddessPlan.toJson()),
      'mindPlanJson': jsonEncode(mindPlan.toJson()),
    };
  }

  factory DiagnosisReport.fromMap(Map<String, dynamic> map) {
    GoddessPlan goddessPlan = GoddessPlan.empty();
    MindPlan mindPlan = MindPlan.empty();

    final goddessPlanJson = map['goddessPlanJson'];
    if (goddessPlanJson is String && goddessPlanJson.isNotEmpty) {
      goddessPlan = GoddessPlan.fromJson(
        jsonDecode(goddessPlanJson) as Map<String, dynamic>,
      );
    }

    final mindPlanJson = map['mindPlanJson'];
    if (mindPlanJson is String && mindPlanJson.isNotEmpty) {
      mindPlan = MindPlan.fromJson(
        jsonDecode(mindPlanJson) as Map<String, dynamic>,
      );
    }

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
      goddessPlan: goddessPlan,
      mindPlan: mindPlan,
    );
  }
}


