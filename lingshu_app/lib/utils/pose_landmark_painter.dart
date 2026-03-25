
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../utils/log_util.dart';

class PoseLandmarkPainter extends CustomPainter {
  final Pose? pose;
  final Size previewSize;
  final CameraLensDirection cameraLensDirection;

  PoseLandmarkPainter({
    required this.pose,
    required this.previewSize,
    required this.cameraLensDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pose == null) return;

    final paint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // 要渲染的关键点类型
    final landmarkTypes = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
    ];

    for (final type in landmarkTypes) {
      final landmark = pose!.landmarks[type];
      if (landmark != null) {
        // 转换坐标
        final position = _calculatePosition(landmark, size, type.name);

        // 绘制关键点
        canvas.drawCircle(position, 3.0, paint);
        Log.d('绘制点位: name: ${type.name}, 原始点位: (${landmark.x},${landmark.y}) 转换后: (${position.dx}, ${position.dy})', tag: 'PoseRender2');

        // 绘制点位名称
        _drawLandmarkName(canvas, textPainter, type.name, position);
      }
    }
  }

  Offset _calculatePosition(PoseLandmark landmark, Size size,String name) {

    // 转换坐标（考虑相机方向）
    double x = landmark.x;
    double y = landmark.y;

    y = previewSize.width - y;

    // 调整坐标
    final adjustedX = x;
    final adjustedY = y;

    return Offset(adjustedX, adjustedY);
  }

  void _drawLandmarkName(Canvas canvas, TextPainter textPainter, String name, Offset position) {
    final textSpan = TextSpan(
      text: name,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 6,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.black54,
      ),
    );

    textPainter.text = textSpan;
    textPainter.layout();

    // 绘制文本
    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height - 10,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}