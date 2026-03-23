import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;

class Log {
  static final Logger _logger = Logger();
  static void v(String message, {String? tag}) {
    _printLog('V', '🔍', message, tag);
  }

  static void d(String message, {String? tag}) {
    _printLog('D', '🐛', message, tag);
  }

  static void i(String message, {String? tag}) {
    _printLog('I', 'ℹ️', message, tag);
  }

  static void w(String message, {String? tag}) {
    _printLog('W', '⚠️', message, tag);
  }

  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    final formattedMessage = _formatMessage(message, tag);
    _printWithSplitting('🔥 E $formattedMessage');
    if (error != null) {
      _printWithSplitting('Error: $error');
    }
    if (stackTrace != null) {
      _printWithSplitting('StackTrace: $stackTrace');
    }
  }

  static void wtf(String message, {String? tag}) {
    _printLog('WTF', '💀', message, tag);
  }

  static void _printLog(String level, String emoji, String message, String? tag) {
    final formattedMessage = _formatMessage(message, tag);
    _printWithSplitting('$emoji $level $formattedMessage');
  }

  static String _formatMessage(String message, String? tag) {
    final location = _getCallerLocation();
    final tagStr = tag != null && tag.isNotEmpty ? '[$tag]' : '';
    final processedMessage = _processMessage(message);
    return '$location $tagStr $processedMessage'.trim();
  }

  static String _processMessage(String message) {
    // 尝试检测并格式化JSON
    try {
      final trimmedMessage = message.trim();
      if ((trimmedMessage.startsWith('{') && trimmedMessage.endsWith('}')) ||
          (trimmedMessage.startsWith('[') && trimmedMessage.endsWith(']'))) {
        final json = jsonDecode(trimmedMessage);
        return jsonEncode(json, toEncodable: (object) {
          if (object is Map || object is List) {
            return object;
          }
          return object.toString();
        });
      }
    } catch (e) {
      // 不是有效的JSON，保持原样
    }
    return message;
  }

  static void _printWithSplitting(String message) {
    const int chunkSize = 1048;
    if (message.length <= chunkSize) {
      _logger.d(message);
      return;
    }

    for (int i = 0; i < message.length; i += chunkSize) {
      final end = (i + chunkSize < message.length) ? i + chunkSize : message.length;
      final chunk = message.substring(i, end);
      _logger.d(chunk);
    }
  }

  static String _getCallerLocation() {
    try {
      final stackTrace = StackTrace.current;
      final frames = stackTrace.toString().split('\n');

      for (final frame in frames) {
        if (frame.contains('log_util.dart')) {
          continue;
        }
        if (frame.contains('.dart:')) {
          final match = RegExp(r'(.+?)\.dart:([0-9]+)').firstMatch(frame);
          if (match != null) {
            final fileName = path.basename('${match.group(1) ?? ''}.dart');
            final lineNumber = match.group(2) ?? '';
            return ' $fileName:$lineNumber.dart';
          }
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}
