import 'package:flutter/foundation.dart';

import '../models/diagnosis_report.dart';
import 'diagnosis_report_db.dart';
import 'qwen_service.dart';

class GoddessPlanData {
  final List<String> dietaryPlan;
  final List<String> exercisePlan;
  final List<String> careAdvice;
  final List<String> constitutionEvolution;
  final List<String> wellnessRecommendation;
  final List<Map<String, String>> drinkRecommendations;
  final String weeklyFocus;

  const GoddessPlanData({
    required this.dietaryPlan,
    required this.exercisePlan,
    required this.careAdvice,
    required this.constitutionEvolution,
    required this.wellnessRecommendation,
    required this.drinkRecommendations,
    required this.weeklyFocus,
  });
}

class MindPlanData {
  final int stressIndex;
  final int relaxPercent;
  final String suggestion;

  const MindPlanData({
    required this.stressIndex,
    required this.relaxPercent,
    required this.suggestion,
  });
}

class UnifiedHealthInsights {
  final DiagnosisReport? latestReport;
  final String cyclePhase;
  final GoddessPlanData goddessPlan;
  final MindPlanData mindPlan;

  const UnifiedHealthInsights({
    required this.latestReport,
    required this.cyclePhase,
    required this.goddessPlan,
    required this.mindPlan,
  });
}

class UserHealthBridgeService {
  UserHealthBridgeService._();

  static final UserHealthBridgeService instance = UserHealthBridgeService._();

  final QwenService _qwenService = QwenService();

  UnifiedHealthInsights? _memoryCache;
  String? _cacheKey;

  Future<UnifiedHealthInsights> getUnifiedInsights({
    bool forceRefresh = false,
  }) async {
    final reports = await DiagnosisReportDb.instance.getReports(limit: 1);
    final latest = reports.isNotEmpty ? reports.first : null;

    final cyclePhase = _calcCyclePhase(DateTime.now());
    final currentKey =
        '${latest?.id ?? 'no_report'}-$cyclePhase-${DateTime.now().toIso8601String().substring(0, 10)}';

    if (!forceRefresh && _memoryCache != null && _cacheKey == currentKey) {
      return _memoryCache!;
    }

    final goddessRaw = await _qwenService.generateGoddessPlan(
      constitution: latest?.constitution ?? '信息不足',
      pattern: latest?.pattern ?? '信息不足',
      cyclePhase: cyclePhase,
      dietaryAdvice: latest?.dietaryAdvice ?? const [],
      lifestyleAdvice: latest?.lifestyleAdvice ?? const [],
      exerciseAdvice: latest?.exerciseAdvice ?? const [],
    );

    final mindRaw = await _qwenService.generateMindPlan(
      constitution: latest?.constitution ?? '信息不足',
      pattern: latest?.pattern ?? '信息不足',
      cyclePhase: cyclePhase,
      lifestyleAdvice: latest?.lifestyleAdvice ?? const [],
    );

    final goddessPlan = GoddessPlanData(
      dietaryPlan: _toList(goddessRaw['dietary_plan']),
      exercisePlan: _toList(goddessRaw['exercise_plan']),
      careAdvice: _toList(goddessRaw['care_advice']),
      constitutionEvolution: _toList(goddessRaw['constitution_evolution']),
      wellnessRecommendation: _toList(goddessRaw['wellness_recommendation']),
      weeklyFocus: (goddessRaw['weekly_focus'] as String?) ?? '本周以稳定作息、温和调理为主。',
      drinkRecommendations: _toDrinkList(goddessRaw['drink_recommendations']),
    );

    final mindPlan = MindPlanData(
      stressIndex: _toIntInRange(mindRaw['stress_index'], 0, 100, 60),
      relaxPercent: _toIntInRange(mindRaw['relax_percent'], 0, 100, 72),
      suggestion:
          (mindRaw['suggestion'] as String?) ?? '建议优先进行10~15分钟的呼吸冥想，再安排轻度运动。',
    );

    final insights = UnifiedHealthInsights(
      latestReport: latest,
      cyclePhase: cyclePhase,
      goddessPlan: goddessPlan,
      mindPlan: mindPlan,
    );

    _memoryCache = insights;
    _cacheKey = currentKey;

    await _writeBackLoopReport(insights);

    return insights;
  }

  Future<void> _writeBackLoopReport(UnifiedHealthInsights insights) async {
    final baseId = insights.latestReport?.id ?? 'none';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final report = DiagnosisReport(
      id: 'loop-$baseId-$today',
      type: 'holistic_loop',
      date: DateTime.now(),
      constitution: insights.latestReport?.constitution ?? '综合调理中',
      pattern: '闭环跟踪：${insights.cyclePhase}',
      dietaryAdvice: insights.goddessPlan.dietaryPlan.take(3).toList(),
      lifestyleAdvice: insights.goddessPlan.careAdvice.take(3).toList(),
      exerciseAdvice: insights.goddessPlan.exercisePlan.take(2).toList(),
      riskWarning: insights.goddessPlan.weeklyFocus,
    );
    try {
      await DiagnosisReportDb.instance.insertReport(report);
    } catch (e) {
      debugPrint('闭环回写失败: $e');
    }
  }

  String _calcCyclePhase(DateTime now) {
    final day = ((now.day - 1) % 28) + 1;
    if (day <= 5) return '经期';
    if (day <= 13) return '卵泡期';
    if (day <= 16) return '排卵期';
    return '黄体期';
  }

  List<String> _toList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    return const [];
  }

  List<Map<String, String>> _toDrinkList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (e) => {
            'name': (e['name'] ?? '').toString(),
            'description': (e['description'] ?? '').toString(),
            'price': (e['price'] ?? '').toString(),
          },
        )
        .where((e) => e['name']!.isNotEmpty)
        .toList();
  }

  int _toIntInRange(dynamic value, int min, int max, int fallback) {
    final numValue = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '');
    if (numValue == null) return fallback;
    if (numValue < min) return min;
    if (numValue > max) return max;
    return numValue;
  }
}
