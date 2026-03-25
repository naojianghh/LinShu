import 'dart:math';
import 'dart:ui';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../utils/log_util.dart';

// 用户个人资料类
class UserProfile {
  final double height; // 身高（厘米）
  final double armSpan; // 臂展（厘米）
  final String? gender; // 性别
  
  UserProfile({
    required this.height,
    required this.armSpan,
    this.gender,
  });
}

// 动作分析结果
class ActionAnalysisResult {
  final double similarity; // 相似度 (0.0-1.0)
  final bool isCompleted; // 是否完成
  final Map<String, double> angles; // 关键角度
  
  ActionAnalysisResult({
    required this.similarity,
    required this.isCompleted,
    required this.angles,
  });
}

// 用户校准类
class UserCalibration {
  Map<PoseLandmarkType, Offset> baseRelativeLandmarks = {};
  bool isCalibrated = false;
  
  // 校准：让用户做标准站立动作
  void calibrate(Pose standingPose) {
    baseRelativeLandmarks = calculateRelativeLandmarks(standingPose);
    isCalibrated = true;
  }
  
  // 计算相对坐标（相对于身体关键部位）
  static Map<PoseLandmarkType, Offset> calculateRelativeLandmarks(Pose pose) {
    final relativeLandmarks = <PoseLandmarkType, Offset>{};
    
    try {
      // 获取关键参考点
      final nose = pose.landmarks[PoseLandmarkType.nose] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.nose, likelihood: 0);
      final leftHip = pose.landmarks[PoseLandmarkType.leftHip] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.leftHip, likelihood: 0);
      final rightHip = pose.landmarks[PoseLandmarkType.rightHip] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.rightHip, likelihood: 0);
      
      // 计算身体中心（髋部中点）
      final hipCenter = Offset(
        (leftHip.x + rightHip.x) / 2,
        (leftHip.y + rightHip.y) / 2,
      );
      
      // 计算身体高度（从鼻子到髋部的距离）
      final bodyHeight = sqrt(
        pow(nose.x - hipCenter.dx, 2) + pow(nose.y - hipCenter.dy, 2),
      );
      
      if (bodyHeight == 0) {
        Log.d('身体高度为零');
        return relativeLandmarks;
      }
      
      // 计算每个关键点的相对位置
      for (final landmark in pose.landmarks.entries) {
        final relativeX = (landmark.value.x - hipCenter.dx) / bodyHeight;
        final relativeY = (landmark.value.y - hipCenter.dy) / bodyHeight;
        relativeLandmarks[landmark.key] = Offset(relativeX, relativeY);
      }
    } catch (e) {
      // 如果找不到关键点位，返回空映射
      Log.d('计算相对坐标时出错: $e',tag: 'user_calibration');
    }
    
    return relativeLandmarks;
  }
  
  // 调整实时姿势到个人坐标系
  Map<PoseLandmarkType, Offset> adjustToUserCoordinateSystem(Pose currentPose) {
    if (!isCalibrated) return calculateRelativeLandmarks(currentPose);
    
    final currentRelative = calculateRelativeLandmarks(currentPose);
    final adjusted = <PoseLandmarkType, Offset>{};
    
    // 根据校准数据调整
    for (final entry in currentRelative.entries) {
      final type = entry.key;
      final current = entry.value;
      final base = baseRelativeLandmarks[type];
      
      if (base != null) {
        // 基于个人基准调整
        adjusted[type] = Offset(
          current.dx * (base.dx / 0.5), // 假设标准宽度为0.5
          current.dy * (base.dy / 0.5),
        );
      } else {
        adjusted[type] = current;
      }
    }
    
    return adjusted;
  }
  
  // 获取单个关键点的相对位置
  Offset getRelativePosition(PoseLandmark landmark) {
    if (!isCalibrated) {
      // 未校准情况下，计算相对于髋部中心的位置
      try {
        // 获取髋部中心作为参考点
        final leftHip = PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.leftHip, likelihood: 0);
        final rightHip = PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.rightHip, likelihood: 0);
        final hipCenter = Offset(
          (leftHip.x + rightHip.x) / 2,
          (leftHip.y + rightHip.y) / 2,
        );
        
        // 计算身体高度（使用默认值）
        const bodyHeight = 1.0;
        
        // 计算相对位置
        final relativeX = (landmark.x - hipCenter.dx) / bodyHeight;
        final relativeY = (landmark.y - hipCenter.dy) / bodyHeight;
        return Offset(relativeX, relativeY);
      } catch (e) {
        // 如果计算失败，返回原始位置
        return Offset(landmark.x, landmark.y);
      }
    } else {
      // 校准情况下，使用调整后的坐标
      final relativeLandmarks = calculateRelativeLandmarks(Pose(landmarks: {landmark.type: landmark}));
      final relativePosition = relativeLandmarks[landmark.type];
      
      if (relativePosition != null) {
        // 基于个人基准调整
        final base = baseRelativeLandmarks[landmark.type];
        if (base != null) {
          return Offset(
            relativePosition.dx * (base.dx / 0.5),
            relativePosition.dy * (base.dy / 0.5),
          );
        }
        return relativePosition;
      } else {
        // 如果计算失败，返回原始位置
        return Offset(landmark.x, landmark.y);
      }
    }
  }
}

// 动态阈值管理器
class DynamicThresholdManager {
  // 根据用户体型特征调整阈值
  double getThresholdForAction(String actionType, UserProfile user) {
    // 基础阈值
    final baseThreshold = _getBaseThreshold(actionType);
    
    // 根据身高调整
    double heightAdjustment = 1.0;
    if (user.height < 160) {
      heightAdjustment = 0.9; // 小个子放宽标准
    } else if (user.height > 185) {
      heightAdjustment = 1.1; // 大个子提高标准
    }
    
    // 根据臂长比例调整
    double armLengthAdjustment = 1.0;
    final armToHeightRatio = user.armSpan / user.height;
    if (armToHeightRatio < 0.95) {
      armLengthAdjustment = 0.95; // 臂短放宽
    } else if (armToHeightRatio > 1.05) {
      armLengthAdjustment = 1.05; // 臂长提高
    }
    
    return baseThreshold * heightAdjustment * armLengthAdjustment;
  }
  
  double _getBaseThreshold(String actionType) {
    switch (actionType) {
      case '双手托天': return 0.8;
      case '马步': return 0.75;
      case '瑜伽山式': return 0.85;
      case '猫牛式': return 0.8;
      case '左右野马分鬃': return 0.78;
      default: return 0.8;
    }
  }
}

// 动作分析器
class ActionAnalyzer {
  final UserCalibration _calibration;
  final DynamicThresholdManager _thresholdManager;
  
  ActionAnalyzer(this._calibration, this._thresholdManager);
  
  // 分析动作
  ActionAnalysisResult analyzeAction(Pose pose, String actionType, UserProfile user) {
    // 1. 调整到个人坐标系
    final adjustedLandmarks = _calibration.adjustToUserCoordinateSystem(pose);
    
    // 2. 计算角度特征
    final angles = _calculateKeyAngles(pose);
    
    // 3. 获取动态阈值
    final threshold = _thresholdManager.getThresholdForAction(actionType, user);
    
    // 4. 计算动作相似度
    final similarity = _calculateAdjustedSimilarity(adjustedLandmarks, angles, actionType);
    
    // 5. 判断动作完成度
    final isCompleted = similarity >= threshold;
    
    return ActionAnalysisResult(
      similarity: similarity,
      isCompleted: isCompleted,
      angles: angles,
    );
  }
  
  // 计算关键关节角度
  Map<String, double> _calculateKeyAngles(Pose pose) {
    final angles = <String, double>{};
    
    try {
      // 左肘关节角度
      angles['leftElbow'] = calculateJointAngle(
        pose.landmarks[PoseLandmarkType.leftShoulder] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.leftShoulder, likelihood: 0),
        pose.landmarks[PoseLandmarkType.leftElbow] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.leftElbow, likelihood: 0),
        pose.landmarks[PoseLandmarkType.leftWrist] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.leftWrist, likelihood: 0),
      );
      
      // 右肘关节角度
      angles['rightElbow'] = calculateJointAngle(
        pose.landmarks[PoseLandmarkType.rightShoulder] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.rightShoulder, likelihood: 0),
        pose.landmarks[PoseLandmarkType.rightElbow] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.rightElbow, likelihood: 0),
        pose.landmarks[PoseLandmarkType.rightWrist] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.rightWrist, likelihood: 0),
      );
      
      // 左膝关节角度
      angles['leftKnee'] = calculateJointAngle(
        pose.landmarks[PoseLandmarkType.leftHip] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.leftHip, likelihood: 0),
        pose.landmarks[PoseLandmarkType.leftKnee] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.leftKnee, likelihood: 0),
        pose.landmarks[PoseLandmarkType.leftAnkle] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.leftAnkle, likelihood: 0),
      );
      
      // 右膝关节角度
      angles['rightKnee'] = calculateJointAngle(
        pose.landmarks[PoseLandmarkType.rightHip] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.rightHip, likelihood: 0),
        pose.landmarks[PoseLandmarkType.rightKnee] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.rightKnee, likelihood: 0),
        pose.landmarks[PoseLandmarkType.rightAnkle] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.rightAnkle, likelihood: 0),
      );
      
      // 肩部角度
      angles['shoulderAngle'] = calculateJointAngle(
        pose.landmarks[PoseLandmarkType.leftShoulder] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.leftShoulder, likelihood: 0),
        pose.landmarks[PoseLandmarkType.nose] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.nose, likelihood: 0),
        pose.landmarks[PoseLandmarkType.rightShoulder] ?? PoseLandmark(x: 0, y: 0, z: 0, type: PoseLandmarkType.rightShoulder, likelihood: 0),
      );
    } catch (e) {
      Log.d('计算角度时出错: $e');
    }
    
    return angles;
  }
  
  // 计算调整后的相似度
  double _calculateAdjustedSimilarity(
    Map<PoseLandmarkType, Offset> adjustedLandmarks,
    Map<String, double> angles,
    String actionType,
  ) {
    // 这里实现基于调整后坐标和角度的相似度计算
    // 结合位置和角度的加权评分
    
    // 示例实现：基于关键角度的评分
    double angleScore = 0.0;
    int angleCount = 0;
    
    // 根据动作类型定义目标角度
    final targetAngles = _getTargetAngles(actionType);
    
    for (final entry in angles.entries) {
      final angleName = entry.key;
      final currentAngle = entry.value;
      final targetAngle = targetAngles[angleName];
      
      if (targetAngle != null) {
        // 计算角度接近程度 (0.0-1.0)
        final angleDifference = (currentAngle - targetAngle).abs();
        final angleSimilarity = max(0.0, 1.0 - angleDifference / 90.0);
        angleScore += angleSimilarity;
        angleCount++;
      }
    }
    
    // 计算平均角度评分
    final averageAngleScore = angleCount > 0 ? angleScore / angleCount : 0.0;
    
    // 位置评分（简化版）
    final positionScore = adjustedLandmarks.isNotEmpty ? 0.7 : 0.0;
    
    // 综合评分（角度占70%，位置占30%）
    return averageAngleScore * 0.7 + positionScore * 0.3;
  }
  
  // 获取动作的目标角度
  Map<String, double> _getTargetAngles(String actionType) {
    switch (actionType) {
      case '双手托天':
        return {
          'leftElbow': 180.0, // 手臂伸直
          'rightElbow': 180.0,
          'leftKnee': 180.0, // 双腿伸直
          'rightKnee': 180.0,
        };
      case '马步':
        return {
          'leftKnee': 90.0, // 膝盖90度
          'rightKnee': 90.0,
          'leftElbow': 90.0, // 手臂弯曲
          'rightElbow': 90.0,
        };
      case '瑜伽山式':
        return {
          'leftKnee': 180.0,
          'rightKnee': 180.0,
          'shoulderAngle': 180.0, // 肩部水平
        };
      case '猫牛式':
        return {
          'leftKnee': 90.0,
          'rightKnee': 90.0,
          'leftElbow': 90.0,
          'rightElbow': 90.0,
        };
      case '左右野马分鬃':
        return {
          'leftKnee': 135.0,
          'rightKnee': 45.0,
          'leftElbow': 120.0,
          'rightElbow': 120.0,
        };
      default:
        return {};
    }
  }
}

// 计算关节角度
double calculateJointAngle(
  PoseLandmark point1, // 第一个点（如肩部）
  PoseLandmark point2, // 关节点（如肘部）
  PoseLandmark point3, // 第三个点（如手腕）
) {
  // 计算向量
  final v1 = Offset(point1.x - point2.x, point1.y - point2.y);
  final v2 = Offset(point3.x - point2.x, point3.y - point2.y);
  
  // 计算点积
  final dotProduct = v1.dx * v2.dx + v1.dy * v2.dy;
  
  // 计算模长
  final v1Magnitude = sqrt(v1.dx * v1.dx + v1.dy * v1.dy);
  final v2Magnitude = sqrt(v2.dx * v2.dx + v2.dy * v2.dy);
  
  // 避免除以零
  if (v1Magnitude == 0 || v2Magnitude == 0) {
    return 0.0;
  }
  
  // 计算角度（弧度转角度）
  final cosAngle = dotProduct / (v1Magnitude * v2Magnitude);
  // 确保值在有效范围内
  final clampedCos = max(-1.0, min(1.0, cosAngle));
  return acos(clampedCos) * (180 / pi);
}

// 扩展方法：计算列表平均值
extension IterableExtensions on Iterable<double> {
  double get average => isEmpty ? 0.0 : reduce((a, b) => a + b) / length;
}