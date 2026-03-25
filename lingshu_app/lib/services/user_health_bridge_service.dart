import 'package:flutter/foundation.dart';
import 'package:lingshu_app/utils/log_util.dart';

import '../models/diagnosis_report.dart';
import 'diagnosis_report_db.dart';

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

  UnifiedHealthInsights? _memoryCache;
  String? _cacheKey;

  Future<UnifiedHealthInsights> getUnifiedInsights({
    bool forceRefresh = false,
  }) async {
    final reports = await DiagnosisReportDb.instance.getReports(limit: 1);
    final latest = reports.isNotEmpty ? reports.first : null;

    Log.d(
      '基础信息: '
          'id=${latest?.id}, type=${latest?.type}, date=${latest?.date.toIso8601String()}',
      tag: 'report',
    );
    Log.d(
      '体质: constitution=${latest?.constitution}, pattern=${latest?.pattern}',
      tag: 'report',
    );
    Log.d(
      '建议: dietary=${latest?.dietaryAdvice}, '
          'lifestyle=${latest?.lifestyleAdvice}, exercise=${latest?.exerciseAdvice}',
      tag: 'report',
    );
    Log.d(
      '风险提示: ${latest?.riskWarning}',
      tag: 'report',
    );
    Log.d(
      '女神计划JSON: ${latest?.goddessPlan.toJson()}',
      tag: 'report',
    );
    Log.d(
      '心灵计划JSON: ${latest?.mindPlan.toJson()}',
      tag: 'report',
    );

    final cyclePhase = _calcCyclePhase(DateTime.now());
    final currentKey =
        '${latest?.id ?? 'no_report'}-$cyclePhase-${DateTime.now().toIso8601String().substring(0, 10)}';

    if (!forceRefresh && _memoryCache != null && _cacheKey == currentKey) {
      Log.d('提前return_memoryCache',tag: 'getUnifiedInsights');
      return _memoryCache!;
    }

    final goddessPlanRaw = latest?.goddessPlan ?? GoddessPlan.empty();
    final mindPlanRaw = latest?.mindPlan ?? MindPlan.empty();

    final goddessPlan = GoddessPlanData(
      dietaryPlan: goddessPlanRaw.dietaryAdvice,
      exercisePlan: goddessPlanRaw.exercisePlan,
      careAdvice: goddessPlanRaw.careAdvice,
      constitutionEvolution: goddessPlanRaw.constitutionEvolution,
      wellnessRecommendation: goddessPlanRaw.wellnessRecommendation,
      weeklyFocus: goddessPlanRaw.weeklyFocus,
      drinkRecommendations: goddessPlanRaw.drinkRecommendations,
    );
    final mindPlan = MindPlanData(
      stressIndex: mindPlanRaw.stressIndex,
      relaxPercent: mindPlanRaw.relaxPercent,
      suggestion: mindPlanRaw.suggestion,
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
      goddessPlan: GoddessPlan(
        dietaryAdvice: insights.goddessPlan.dietaryPlan,
        exercisePlan: insights.goddessPlan.exercisePlan,
        careAdvice: insights.goddessPlan.careAdvice,
        constitutionEvolution: insights.goddessPlan.constitutionEvolution,
        wellnessRecommendation: insights.goddessPlan.wellnessRecommendation,
        weeklyFocus: insights.goddessPlan.weeklyFocus,
        drinkRecommendations: insights.goddessPlan.drinkRecommendations,
      ),
      mindPlan: MindPlan(
        stressIndex: insights.mindPlan.stressIndex,
        relaxPercent: insights.mindPlan.relaxPercent,
        suggestion: insights.mindPlan.suggestion,
      ),
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

}
