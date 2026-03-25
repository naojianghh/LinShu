
import 'dart:ui';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/user_calibration.dart';

class ActionStep {
  final String name; // 动作名称
  final String actionType; // 动作类型（用于分析）
  final List<String> checkItems; // 检查项
  final String description; // 动作描述
  final Map<PoseLandmarkType, Map<String, dynamic>>? targetPositions; // 目标位置（基于相对关系或相对位置）

  ActionStep({
    required this.name,
    required this.actionType,
    required this.checkItems,
    required this.description,
    this.targetPositions,
  });
}

// 运动序列管理器
class SportSequenceManager {
  final String tag = 'analyzeTrajectory';
  final List<ActionStep> _actionSteps;
  int _currentStepIndex = 0;
  bool _isSequenceCompleted = false;
  Size previewSize;

  SportSequenceManager(this._actionSteps, {UserCalibration? userCalibration, required this.previewSize});

  // 获取当前动作步骤
  ActionStep get currentStep => _actionSteps[_currentStepIndex];

  // 获取当前步骤索引（从1开始）
  int get currentStepIndex => _currentStepIndex + 1;

  // 获取总步骤数
  int get totalSteps => _actionSteps.length;

  // 检查序列是否完成
  bool get isSequenceCompleted => _isSequenceCompleted;


  // 进入下一步
  bool nextStep() {
    if (_currentStepIndex < _actionSteps.length - 1) {
      _currentStepIndex++;
      return true;
    } else {
      _isSequenceCompleted = true;
      return false;
    }
  }
}