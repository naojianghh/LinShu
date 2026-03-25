import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:lingshu_app/utils/log_util.dart';

import '../models/diagnosis_report.dart';

class QwenService {
  QwenService({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    );
  }

  final Dio _dio;

  String get _apiKey => dotenv.get('DASHSCOPE_API_KEY');
  String get _baseUrl => dotenv.get('DASHSCOPE_BASE_URL');
  String get _model => dotenv.get('DASHSCOPE_MODEL');
Future<DiagnosisReport> analyzeImage({
    required File imageFile,
    required String type,
  }) async {
    final base64Image = base64Encode(await imageFile.readAsBytes());
    final target = type == 'tongue' ? '舌象' : '面部';
    final cyclePhase = _calcCyclePhase(DateTime.now());
    final prompt = '''你是一位资深中医健康顾问。请分析这张$target照片，并在一次回复中生成闭环健康报告（体质报告 + 女神专区计划 + 心灵栖息地计划）。

要求：
- 必须严格输出 JSON（不要 Markdown，不要解释文字）
- 只能输出一个 JSON 对象
- 体质报告必须包含：constitution、pattern、dietary_advice(3条)、lifestyle_advice(3条)、exercise_advice(2条)、risk_warning
- 女神专区计划必须包含：dietary_advice(至少3条)、exercise_plan(至少2条)、care_advice(至少3条)、constitution_evolution、wellness_recommendation(至少1条)、weekly_focus、drink_recommendations（数组，至少3个元素，每个元素包含 name/description/price）
- 心灵栖息地计划必须包含：stress_index(0-100整数)、relax_percent(0-100整数)、suggestion（一句可执行建议）
- 生成女神/心灵计划时，请参考你在同一 JSON 中生成的体质报告结果，并结合周期阶段 cyclePhase = "$cyclePhase"

输出 JSON 结构如下（字段名必须一致）：
{
  "constitution": "体质结论（如：平和质、气虚质、痰湿质、湿热质等）",
  "pattern": "证型倾向（用一句话概括，如：偏气虚夹湿/肝郁气滞倾向等）",
  "dietary_advice": ["建议1","建议2","建议3"],
  "lifestyle_advice": ["建议1","建议2","建议3"],
  "exercise_advice": ["建议1","建议2"],
  "risk_warning": "风险提示（仅供健康管理参考，不作为医疗诊断依据）",
  "goddess_plan": {
    "dietary_advice": ["建议1","建议2","建议3"],
    "exercise_plan": ["计划1","计划2"],
    "care_advice": ["建议1","建议2","建议3"],
    "constitution_evolution": ["趋势1","趋势2","趋势3"],
    "wellness_recommendation": ["建议1","建议2","建议3"],
    "weekly_focus": "本周调理重点",
    "drink_recommendations": [
      {"name":"name","description":"description","price":"price"},
      {"name":"name","description":"description","price":"price"},
      {"name":"name","description":"description","price":"price"},
      {"name":"name","description":"description","price":"price"},
      {"name":"name","description":"description","price":"price"}
    ]
  },
  "mind_plan": {
    "stress_index": 0,
    "relax_percent": 0,
    "suggestion": "一句可执行建议"
  }
}''';
    Log.d('分析图片prompt: $prompt');

    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
                },
              ],
            },
          ],
          'response_format': {'type': 'json_object'},
        },
      );
      Log.d('AI 请求响应：$response');
      final content =
          (response.data['choices'] as List).first['message']['content'];
      final Map<String, dynamic> data = jsonDecode(content as String);

      final constitution = (data['constitution'] as String?) ?? '未知体质';
      final pattern = (data['pattern'] as String?) ?? '暂未识别';

      final dietaryAdviceBase = _toStringList(data['dietary_advice']);
      final lifestyleAdviceBase = _toStringList(data['lifestyle_advice']);
      final exerciseAdviceBase = _toStringList(data['exercise_advice']);
      final riskWarning = (data['risk_warning'] as String?) ??
          '仅供健康管理参考，不作为医疗诊断依据。若不适加重请及时就医。';

      GoddessPlan goddessPlan = GoddessPlan.empty();
      final goddessRaw = data['goddess_plan'];
      if (goddessRaw is Map<String, dynamic>) {
        goddessPlan = GoddessPlan.fromJson(goddessRaw);
      }

      MindPlan mindPlan = MindPlan.empty();
      final mindRaw = data['mind_plan'];
      if (mindRaw is Map<String, dynamic>) {
        mindPlan = MindPlan.fromJson(mindRaw);
      }

      // 女神/心灵计划可能在模型输出中缺失：此时使用体质报告的部分字段进行回退。
      goddessPlan = goddessPlan.dietaryAdvice.isNotEmpty
          ? goddessPlan
          : GoddessPlan(
              dietaryAdvice: dietaryAdviceBase,
              exercisePlan: exerciseAdviceBase,
              careAdvice: lifestyleAdviceBase,
              constitutionEvolution: const [],
              wellnessRecommendation: const [],
              weeklyFocus: '本周以稳定作息、温和调理为主。',
              drinkRecommendations: const [],
            );

      // 优先使用女神专区的闭环建议（若缺失则回退到原始 AI 建议）。
      final dietaryAdvice = (goddessPlan.dietaryAdvice.isNotEmpty
              ? goddessPlan.dietaryAdvice.take(3).toList()
              : dietaryAdviceBase)
          .take(3)
          .toList();

      final lifestyleAdvice = (goddessPlan.careAdvice.isNotEmpty
              ? goddessPlan.careAdvice.take(3).toList()
              : lifestyleAdviceBase)
          .take(3)
          .toList();

      final exerciseAdvice = (goddessPlan.exercisePlan.isNotEmpty
              ? goddessPlan.exercisePlan.take(2).toList()
              : exerciseAdviceBase)
          .take(2)
          .toList();

      final report = DiagnosisReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        date: DateTime.now(),
        constitution: constitution,
        pattern: pattern,
        dietaryAdvice: dietaryAdvice,
        lifestyleAdvice: lifestyleAdvice,
        exerciseAdvice: exerciseAdvice,
        riskWarning: riskWarning,
        imageUrl: imageFile.path,
        goddessPlan: goddessPlan,
        mindPlan: mindPlan,
      );
      // 分段打印，避免超长 JSON 在控制台滚动/截断时看不到后续内容。
      Log.d(
        '一次性生成报告-基础信息: '
        'id=${report.id}, type=${report.type}, date=${report.date.toIso8601String()}',
        tag: 'analyzeImage',
      );
      Log.d(
        '一次性生成报告-体质: constitution=${report.constitution}, pattern=${report.pattern}',
        tag: 'analyzeImage',
      );
      Log.d(
        '一次性生成报告-建议: dietary=${report.dietaryAdvice}, '
        'lifestyle=${report.lifestyleAdvice}, exercise=${report.exerciseAdvice}',
        tag: 'analyzeImage',
      );
      Log.d(
        '一次性生成报告-风险提示: ${report.riskWarning}',
        tag: 'analyzeImage',
      );
      Log.d(
        '一次性生成报告-女神计划JSON: ${report.goddessPlan.toJson()}',
        tag: 'analyzeImage',
      );
      Log.d(
        '一次性生成报告-心灵计划JSON: ${report.mindPlan.toJson()}',
        tag: 'analyzeImage',
      );
      return report;
    } catch (e) {
      throw Exception('AI 分析失败: $e');
    }
  }

  List<String> _toStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();
  }

  String _calcCyclePhase(DateTime now) {
    final day = ((now.day - 1) % 28) + 1;
    if (day <= 5) return '经期';
    if (day <= 13) return '卵泡期';
    if (day <= 16) return '排卵期';
    return '黄体期';
  }
  

  Future<Stream<String>> chatWithTcmAssistantStream({
    required List<Map<String, String>> messages,
  }) async {
    final systemMessage = {
      'role': 'system',
      'content':
      '你是灵枢·AI的中医健康助手。请用简洁、温和、可执行的中文回答。'
          '你可以提供体质调理、作息、饮食、运动建议，但不能做医疗诊断。'
          '若用户存在明显风险症状，要明确建议及时线下就医。'
          '回答内容尽量引用《黄帝内经》，《女科经伦》和《伤寒杂病论》的一条或多条句子 ',
    };

    final recentMessages = messages.length > 12
        ? messages.sublist(messages.length - 12)
        : messages;

    final payloadMessages = [
      systemMessage,
      ...recentMessages.map(
            (m) => {'role': m['role'] ?? 'user', 'content': m['content'] ?? ''},
      ),
    ];

    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        data: {
          'model': _model,
          'messages': payloadMessages,
          'stream': true,
        },
      );

      Stream<String> parseStream(Response<dynamic> response) async* {
        final stream = response.data!.stream as Stream<List<int>>;
        String buffer = '';

        await for (final chunk in stream) {
          buffer += utf8.decode(chunk);
          final lines = buffer.split('\n');
          buffer = lines.removeLast();

          for (final line in lines) {
            if (line.startsWith('data:')) {
              final jsonStr = line.substring(5).trim();
              if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;
              try {
                final json = jsonDecode(jsonStr);
                final content = json['choices']?[0]?['delta']?['content'];
                if (content != null && content.toString().isNotEmpty) {
                  yield content.toString();
                }
              } catch (e) {
                // 忽略解析错误
              }
            }
          }
        }
      }
      return parseStream(response);
    } catch (e) {
      Log.d('流式问诊对话失败：$e');
      throw Exception('流式问诊对话失败: $e');
    }
  }

  Future<String> chatWithTcmAssistant({
    required List<Map<String, String>> messages,
  }) async {
    final systemMessage = {
      'role': 'system',
      'content':
          '你是灵枢·AI的中医健康助手。请用简洁、温和、可执行的中文回答。'
          '你可以提供体质调理、作息、饮食、运动建议，但不能做医疗诊断。'
          '若用户存在明显风险症状，要明确建议及时线下就医。',
    };

    final recentMessages = messages.length > 12
        ? messages.sublist(messages.length - 12)
        : messages;

    final payloadMessages = [
      systemMessage,
      ...recentMessages.map(
        (m) => {'role': m['role'] ?? 'user', 'content': m['content'] ?? ''},
      ),
    ];

    try {
      final response = await _dio.post(
        '$_baseUrl/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'model': _model,
          'messages': payloadMessages,
          'stream': true,
        },
      );
      Log.d('AI 请求响应：$response');
      final content =
          (response.data['choices'] as List).first['message']['content'];
      return (content as String).trim();
    } catch (e) {
      Log.d('问诊对话失败：$e');
      throw Exception('问诊对话失败: $e');
    }
  }

//   Future<Map<String, dynamic>> generateGoddessPlan({
//     required String constitution,
//     required String pattern,
//     required String cyclePhase,
//     required List<String> dietaryAdvice,
//     required List<String> lifestyleAdvice,
//     required List<String> exerciseAdvice,
//   }) async {
//     final prompt =
//         '''你是灵枢·AI女神专区健康规划助手，请基于用户的望闻问切结果生成闭环调理方案。
//
// 用户信息：
// - 体质：$constitution
// - 证型：$pattern
// - 周期阶段：$cyclePhase
//
// 输出 JSON 结构如下：
// {
//   "dietary_advice": ["建议1"],
//   "exercise_plan": ["计划1"],
//   "care_advice": ["建议1"],
//   "constitution_evolution": ["趋势1"],
//   "wellness_recommendation": ["建议1],
//   "drink_recommendations": [
//     {
//       "name": "name",
//       "description": "description",
//       "price": price,
//     },
//     {
//       "name": "name",
//       "description": "description",
//       "price": price,
//     },
//     {
//       "name": "name",
//       "description": "description",
//       "price": price,
//     },
//     {
//       "name": "name",
//       "description": "description",
//       "price": price,
//     },
//     {
//       "name": "name",
//       "description": "description",
//       "price": price,
//     }
//   ],
//   "weekly_focus": "本周调理重点"
// }
// ''';
//
//     try {
//       Log.d('prompt: $prompt');
//       Log.d('用户信息：'
//         '- 体质：$constitution'
//         '- 证型：$pattern'
//         '- 周期阶段：$cyclePhase'
//         '- 望闻问切饮食建议：${dietaryAdvice.join('；')}'
//         '- 望闻问切生活建议：${lifestyleAdvice.join('；')}'
//         '- 望闻问切运动建议：${exerciseAdvice.join('；')}'
//         );
//       final response = await _dio.post(
//         '$_baseUrl/chat/completions',
//         options: Options(
//           headers: {
//             'Authorization': 'Bearer $_apiKey',
//             'Content-Type': 'application/json',
//           },
//         ),
//         data: {
//           'model': _model,
//           'messages': [
//             {'role': 'user', 'content': prompt},
//           ],
//           'response_format': {'type': 'json_object'},
//         },
//       );
//       Log.d('AI 请求响应：$response');
//       final content =
//           (response.data['choices'] as List).first['message']['content'];
//       return jsonDecode((content as String).trim()) as Map<String, dynamic>;
//     } catch (e) {
//       Log.d('女神专区AI规划失败: $e');
//       throw Exception('女神专区AI规划失败: $e');
//     }
// }

//   Future<Map<String, dynamic>> generateMindPlan({
//     required String constitution,
//     required String pattern,
//     required String cyclePhase,
//     required List<String> lifestyleAdvice,
//   }) async {
//     final prompt =
//         '''你是灵枢·AI心灵栖息地助手，请基于体质和周期给出心理状态评估。
//
// 用户信息：
// - 体质：$constitution
// - 证型：$pattern
// - 周期阶段：$cyclePhase
// - 作息建议：${lifestyleAdvice.join('；')}
//
// 输出 JSON：
// {
//   "stress_index": 0-100整数,
//   "relax_percent": 0-100整数,
//   "suggestion": "一句可执行建议"
// }
// ''';
//
//     try {
//       final response = await _dio.post(
//         '$_baseUrl/chat/completions',
//         options: Options(
//           headers: {
//             'Authorization': 'Bearer $_apiKey',
//             'Content-Type': 'application/json',
//           },
//         ),
//         data: {
//           'model': _model,
//           'messages': [
//             {'role': 'user', 'content': prompt},
//           ],
//           'response_format': {'type': 'json_object'},
//         },
//       );
//
//       final content =
//           (response.data['choices'] as List).first['message']['content'];
//       return jsonDecode((content as String).trim()) as Map<String, dynamic>;
//     } catch (e) {
//       Log.d('心灵栖息地AI评估失败: $e');
//       throw Exception('心灵栖息地AI评估失败: $e');
//     }
//   }
}
