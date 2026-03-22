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
    final prompt = _getPrompt(type);
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

      return DiagnosisReport(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        date: DateTime.now(),
        constitution: (data['constitution'] as String?) ?? '未知体质',
        pattern: (data['pattern'] as String?) ?? '暂未识别',
        dietaryAdvice: List<String>.from(
          (data['dietary_advice'] as List?) ?? const [],
        ),
        lifestyleAdvice: List<String>.from(
          (data['lifestyle_advice'] as List?) ?? const [],
        ),
        exerciseAdvice: List<String>.from(
          (data['exercise_advice'] as List?) ?? const [],
        ),
        riskWarning:
            (data['risk_warning'] as String?) ??
            '仅供健康管理参考，不作为医疗诊断依据。若不适加重请及时就医。',
        imageUrl: imageFile.path,
      );
    } catch (e) {
      throw Exception('AI 分析失败: $e');
    }
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

  Future<Map<String, dynamic>> generateGoddessPlan({
    required String constitution,
    required String pattern,
    required String cyclePhase,
    required List<String> dietaryAdvice,
    required List<String> lifestyleAdvice,
    required List<String> exerciseAdvice,
  }) async {
    final prompt =
        '''你是灵枢·AI女神专区健康规划助手，请基于用户的望闻问切结果生成闭环调理方案。

用户信息：
- 体质：$constitution
- 证型：$pattern
- 周期阶段：$cyclePhase

输出 JSON 结构如下：
{
  "dietary_advice": ["建议1"],
  "exercise_plan": ["计划1"],
  "care_advice": ["建议1"],
  "constitution_evolution": ["趋势1"],
  "wellness_recommendation": ["建议1],
  "drink_recommendations": [
    {
      "name": "name",
      "description": "description",
      "price": price,
    },
    {
      "name": "name",
      "description": "description",
      "price": price,
    },
    {
      "name": "name",
      "description": "description",
      "price": price,
    },
    {
      "name": "name",
      "description": "description",
      "price": price,
    },
    {
      "name": "name",
      "description": "description",
      "price": price,
    }
  ],
  "weekly_focus": "本周调理重点"
}
''';

    try {
      Log.d('prompt: $prompt');
      Log.d('用户信息：'
        '- 体质：$constitution'
        '- 证型：$pattern'
        '- 周期阶段：$cyclePhase'
        '- 望闻问切饮食建议：${dietaryAdvice.join('；')}'
        '- 望闻问切生活建议：${lifestyleAdvice.join('；')}'
        '- 望闻问切运动建议：${exerciseAdvice.join('；')}'
        );
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
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
        },
      );
      Log.d('AI 请求响应：$response');
      final content =
          (response.data['choices'] as List).first['message']['content'];
      return jsonDecode((content as String).trim()) as Map<String, dynamic>;
    } catch (e) {
      Log.d('女神专区AI规划失败: $e');
      throw Exception('女神专区AI规划失败: $e');
    }
  }

  Future<Map<String, dynamic>> generateMindPlan({
    required String constitution,
    required String pattern,
    required String cyclePhase,
    required List<String> lifestyleAdvice,
  }) async {
    final prompt =
        '''你是灵枢·AI心灵栖息地助手，请基于体质和周期给出心理状态评估。

用户信息：
- 体质：$constitution
- 证型：$pattern
- 周期阶段：$cyclePhase
- 作息建议：${lifestyleAdvice.join('；')}

输出 JSON：
{
  "stress_index": 0-100整数,
  "relax_percent": 0-100整数,
  "suggestion": "一句可执行建议"
}
''';

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
            {'role': 'user', 'content': prompt},
          ],
          'response_format': {'type': 'json_object'},
        },
      );

      final content =
          (response.data['choices'] as List).first['message']['content'];
      return jsonDecode((content as String).trim()) as Map<String, dynamic>;
    } catch (e) {
      Log.d('心灵栖息地AI评估失败: $e');
      throw Exception('心灵栖息地AI评估失败: $e');
    }
  }

  String _getPrompt(String type) {
    final target = type == 'tongue' ? '舌象' : '面部';
    return '''你是一位资深中医健康顾问。请分析这张$target照片并生成“比赛展示友好”的健康报告。

要求：
- 必须严格输出 JSON（不要 Markdown，不要解释文字）
- dietary_advice 必须 3 条
- lifestyle_advice 必须 3 条
- exercise_advice 必须 2 条
- 建议要具体、可执行、不过度医疗化
- 加上风险提示（如需就医的情况）

输出 JSON 结构如下：
{
  "constitution": "体质结论（如：平和质、气虚质、痰湿质、湿热质等）",
  "pattern": "证型倾向（用一句话概括，如：偏气虚夹湿/肝郁气滞倾向等）",
  "dietary_advice": ["建议1", "建议2", "建议3"],
  "lifestyle_advice": ["建议1", "建议2", "建议3"],
  "exercise_advice": ["建议1", "建议2"],
  "risk_warning": "风险提示"
}''';
  }
}
