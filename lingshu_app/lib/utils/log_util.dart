import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class Log {
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
    debugPrint('🔥 E $formattedMessage');
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }

  static void wtf(String message, {String? tag}) {
    _printLog('WTF', '💀', message, tag);
  }

  static void _printLog(String level, String emoji, String message, String? tag) {
    final formattedMessage = _formatMessage(message, tag);
    debugPrint('$emoji $level $formattedMessage');
  }

  static String _formatMessage(String message, String? tag) {
    final location = _getCallerLocation();
    final tagStr = tag != null && tag.isNotEmpty ? '[$tag]' : '';
    return '$location $tagStr $message'.trim();
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
            final fileName = path.basename(match.group(1) ?? '');
            final lineNumber = match.group(2) ?? '';
            return ' $fileName:$lineNumber';
          }
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }
}
