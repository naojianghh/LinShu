// 动作步骤类
import 'dart:math';
import 'dart:ui';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/user_calibration.dart';
import '../utils/log_util.dart';

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

  // 轨迹记录
  final Map<PoseLandmarkType, List<Offset>> _trajectories = {};
  static const int _trajectoryMaxPoints = 10; // 轨迹最大点数
  bool _canRecord = true; // 是否可以记录轨迹点

  // 目标位置保持时间记录
  final Map<PoseLandmarkType, int> _targetPositionHoldTime = {};
  static const int _minHoldFrames = 5; // 最小保持帧数（约0.5秒）

  // 动作开始检测（更早触发：用于记录起始点）
  static const int _minStartHoldFrames = 2; // 最小保持帧数（起点触发更快）
  final Map<PoseLandmarkType, int> _startPositionHoldTime = {};
  bool _hasDetectedStart = false;
  Map<PoseLandmarkType, PoseLandmark>? _startLandmarks;

  // 校准系统
  UserCalibration? _userCalibration;

  SportSequenceManager(this._actionSteps, {UserCalibration? userCalibration, required this.previewSize}) {
    _userCalibration = userCalibration;
  }

  // 设置校准系统
  void setUserCalibration(UserCalibration userCalibration) {
    _userCalibration = userCalibration;
  }

  // 获取当前动作步骤
  ActionStep get currentStep => _actionSteps[_currentStepIndex];

  // 获取当前步骤索引（从1开始）
  int get currentStepIndex => _currentStepIndex + 1;

  // 获取总步骤数
  int get totalSteps => _actionSteps.length;

  // 检查序列是否完成
  bool get isSequenceCompleted => _isSequenceCompleted;

  
  // 记录轨迹点
  void recordTrajectory(Pose pose) {
    if (_canRecord) {
      for (final landmark in pose.landmarks.entries) {
        final type = landmark.key;
        final position = _convertLandmarkPosition(landmark.value);

        if (!_trajectories.containsKey(type)) {
          _trajectories[type] = [];
        }
        
        // 检查与上一个点的距离，如果距离太小则不记录
        bool shouldRecord = true;
        if (_trajectories[type]!.isNotEmpty) {
          final lastPosition = _trajectories[type]!.last;
          final distance = (position - lastPosition).distance;
          if (distance < 10) { // 距离阈值，可根据需要调整
            shouldRecord = false;
          }
        }
        
        if (shouldRecord) {
          if (type == PoseLandmarkType.leftWrist) {
            Log.d('记录点leftWrist：(${position.dx} ${position.dy})', tag: 'PoseRender3');
          }
          _trajectories[type]!.add(position);

          // 保持轨迹长度
          if (_trajectories[type]!.length > _trajectoryMaxPoints) {
            _trajectories[type]!.removeAt(0);
          }
        }
      }
      
      // 设置为不可记录
      _canRecord = false;
      
      // 0.5秒后恢复可记录状态
      Future.delayed(const Duration(milliseconds: 1000), () {
        _canRecord = true;
      });
    }
  }
  
  // 转换关键点位置（应用与渲染相同的坐标转换）
  Offset _convertLandmarkPosition(PoseLandmark landmark) {
    double x = landmark.x;
    double y = landmark.y;

    y = previewSize.width - y;

    return Offset(x, y);
  }

  // 分析轨迹是否完成当前动作
  bool analyzeTrajectory(Pose pose, ActionAnalysisResult analysisResult) {
    // 记录当前轨迹
    recordTrajectory(pose);

    // 基于分析结果和轨迹判断动作是否完成
    bool isActionCompleted = analysisResult.isCompleted;

    // 检查轨迹
    isActionCompleted = isActionCompleted && _checkTrajectory();

    // 如果动作完成，打印pose点集
    if (isActionCompleted) {
      Log.d('动作完成 - 动作: ${currentStep.name}', tag: tag);
      Log.d('完成动作的pose点集:', tag: tag);
      for (final entry in pose.landmarks.entries) {
        final landmarkType = entry.key;
        final landmark = entry.value;
        Log.d('  ${landmarkType.name}: (${landmark.x.toStringAsFixed(3)}, ${landmark.y.toStringAsFixed(3)}, ${landmark.z.toStringAsFixed(3)}) - 置信度: ${(landmark.likelihood * 100).toStringAsFixed(0)}%', tag: 'ActionComplete');
      }
    }

    return isActionCompleted;
  }

  /// 检测当前动作是否“开始”（用于记录起始点/终止点）。
  /// 逻辑：当 `currentStep.targetPositions` 中的各关键点相对条件在连续帧内成立，则判定开始，并缓存起始帧的关键点快照。
  /// 注意：该方法只会在每个 step 内触发一次。
  bool detectActionStart(Pose pose) {
    if (_hasDetectedStart) return false;
    final targetPositions = currentStep.targetPositions;
    if (targetPositions == null || targetPositions.isEmpty) return false;

    Log.d('开始检测 - 动作: ${currentStep.name}', tag: 'StartDetect');

    bool allPositionsReached = true;
    bool allPositionsHeld = true;

    for (final entry in targetPositions.entries) {
      final landmarkType = entry.key;
      final targetConfig = entry.value;

      final currentLandmark = pose.landmarks[landmarkType];
      if (currentLandmark == null) {
        allPositionsReached = false;
        allPositionsHeld = false;
        _startPositionHoldTime[landmarkType] = 0;
        continue;
      }

      final isPositionReached = _checkPositionRequirement(pose, landmarkType, targetConfig);
      if (!isPositionReached) {
        allPositionsReached = false;
        _startPositionHoldTime[landmarkType] = 0;
        allPositionsHeld = false;
        continue;
      }

      _startPositionHoldTime[landmarkType] = (_startPositionHoldTime[landmarkType] ?? 0) + 1;
      if ((_startPositionHoldTime[landmarkType] ?? 0) < _minStartHoldFrames) {
        allPositionsHeld = false;
      }
    }

    // 满足：全部相对条件已成立且连续保持足够帧数
    if (allPositionsReached && allPositionsHeld) {
      _hasDetectedStart = true;
      _startLandmarks = _clonePoseLandmarks(pose);
      Log.d('动作开始检测成功 - 动作: ${currentStep.name}', tag: 'StartDetect');
      return true;
    }

    return false;
  }

  /// 获取检测到的起始关键点快照（detectActionStart() 触发后可用）
  Map<PoseLandmarkType, PoseLandmark>? get startLandmarks => _startLandmarks;

  Map<PoseLandmarkType, PoseLandmark> _clonePoseLandmarks(Pose pose) {
    final cloned = <PoseLandmarkType, PoseLandmark>{};
    for (final entry in pose.landmarks.entries) {
      final type = entry.key;
      final v = entry.value;
      cloned[type] = PoseLandmark(
        x: v.x,
        y: v.y,
        z: v.z,
        type: v.type,
        likelihood: v.likelihood,
      );
    }
    return cloned;
  }

  // 检查轨迹
  bool _checkTrajectory() {
    Log.d('开始轨迹检查 - 动作: ${currentStep.name}', tag: 'Trajectory');
    
    // 可以根据不同动作类型添加特定的轨迹判断逻辑
    switch (currentStep.actionType) {
      case '双手托天':
        // 检查手腕和肘部轨迹是否向上移动，并且轨迹平滑
        final wristRaise = _checkWristRaiseTrajectory();
        final elbowRaise = _checkElbowRaiseTrajectory();
        final smooth = _checkSmoothTrajectory([PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist]);
        Log.d('双手托天轨迹检查 - 手腕抬起: $wristRaise, 肘部抬起: $elbowRaise, 轨迹平滑: $smooth', tag: 'Trajectory');
        return wristRaise && elbowRaise && smooth;
      case '左右开弓':
        // 检查手臂和肩部轨迹是否向两侧展开，并且轨迹符合标准动作模式
        final armSpread = _checkArmSpreadTrajectory();
        final shoulderRotation = _checkShoulderRotationTrajectory();
        final spreadPattern = _checkTrajectoryPattern([PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist], 'spread');
        Log.d('左右开弓轨迹检查 - 手臂展开: $armSpread, 肩部旋转: $shoulderRotation, 展开模式: $spreadPattern', tag: 'Trajectory');
        return armSpread && shoulderRotation && spreadPattern;
      case '调理脾胃':
        // 检查手臂轨迹是否上下运动，并且轨迹符合交替模式
        final armUpDown = _checkArmUpDownTrajectory();
        final alternatePattern = _checkTrajectoryPattern([PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist], 'alternate');
        Log.d('调理脾胃轨迹检查 - 手臂上下: $armUpDown, 交替模式: $alternatePattern', tag: 'Trajectory');
        return armUpDown && alternatePattern;
      case '摇头摆尾':
        // 检查头部和臀部轨迹，并且轨迹符合摆动模式
        final headHip = _checkHeadHipTrajectory();
        final kneeBend = _checkKneeBendTrajectory();
        final swayPattern = _checkTrajectoryPattern([PoseLandmarkType.nose, PoseLandmarkType.leftHip], 'sway');
        Log.d('摇头摆尾轨迹检查 - 头部臀部: $headHip, 膝盖弯曲: $kneeBend, 摆动模式: $swayPattern', tag: 'Trajectory');
        return headHip && kneeBend && swayPattern;
      case '瑜伽山式':
        // 检查身体是否保持正直，并且关键点保持稳定
        final bodyAlignment = _checkBodyAlignmentTrajectory();
        final stability = _checkStabilityTrajectory([PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip]);
        Log.d('瑜伽山式轨迹检查 - 身体对齐: $bodyAlignment, 稳定性: $stability', tag: 'Trajectory');
        return bodyAlignment && stability;
      case '猫牛式':
        // 检查脊柱起伏轨迹，并且轨迹符合波浪模式
        final spineMovement = _checkSpineMovementTrajectory();
        final wavePattern = _checkTrajectoryPattern([PoseLandmarkType.nose, PoseLandmarkType.leftHip], 'wave');
        Log.d('猫牛式轨迹检查 - 脊柱运动: $spineMovement, 波浪模式: $wavePattern', tag: 'Trajectory');
        return spineMovement && wavePattern;
      case '下犬式':
        // 检查身体呈倒V形轨迹，并且轨迹符合伸展模式
        final invertedV = _checkInvertedVTrajectory();
        final stretchPattern = _checkTrajectoryPattern([PoseLandmarkType.nose, PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist], 'stretch');
        Log.d('下犬式轨迹检查 - 倒V形: $invertedV, 伸展模式: $stretchPattern', tag: 'Trajectory');
        return invertedV && stretchPattern;
      case '树式':
        // 检查单脚站立和手臂上举轨迹，并且保持平衡
        final singleLegStand = _checkSingleLegStandTrajectory();
        final armRaise = _checkArmRaiseTrajectory();
        final treeStability = _checkStabilityTrajectory([PoseLandmarkType.nose, PoseLandmarkType.leftAnkle]);
        Log.d('树式轨迹检查 - 单脚站立: $singleLegStand, 手臂上举: $armRaise, 稳定性: $treeStability', tag: 'Trajectory');
        return singleLegStand && armRaise && treeStability;
      case '起势':
        // 检查手臂抬起轨迹，并且轨迹缓慢平滑
        final armLift = _checkArmLiftTrajectory();
        final liftSmooth = _checkSmoothTrajectory([PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist]);
        Log.d('起势轨迹检查 - 手臂抬起: $armLift, 轨迹平滑: $liftSmooth', tag: 'Trajectory');
        return armLift && liftSmooth;
      case '左右野马分鬃':
        // 检查手臂分开和弓步轨迹，并且轨迹符合武术动作模式
        final wildHorseArmSpread = _checkArmSpreadTrajectory();
        final lunge = _checkLungeTrajectory();
        final martialPattern = _checkTrajectoryPattern([PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist, PoseLandmarkType.leftKnee], 'martial');
        Log.d('左右野马分鬃轨迹检查 - 手臂展开: $wildHorseArmSpread, 弓步: $lunge, 武术模式: $martialPattern', tag: 'Trajectory');
        return wildHorseArmSpread && lunge && martialPattern;
      case '白鹤亮翅':
        // 检查手臂展开和虚步轨迹，并且轨迹优雅流畅
        final whiteCraneArmSpread = _checkArmSpreadTrajectory();
        final emptyStep = _checkEmptyStepTrajectory();
        final whiteCraneSmooth = _checkSmoothTrajectory([PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist]);
        Log.d('白鹤亮翅轨迹检查 - 手臂展开: $whiteCraneArmSpread, 虚步: $emptyStep, 轨迹平滑: $whiteCraneSmooth', tag: 'Trajectory');
        return whiteCraneArmSpread && emptyStep && whiteCraneSmooth;
      case '搂膝拗步':
        // 检查搂膝和推掌轨迹，并且轨迹符合武术动作模式
        final kneeHold = _checkKneeHoldTrajectory();
        final palmPush = _checkPalmPushTrajectory();
        final kneeHoldMartialPattern = _checkTrajectoryPattern([PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist, PoseLandmarkType.leftKnee], 'martial');
        Log.d('搂膝拗步轨迹检查 - 搂膝: $kneeHold, 推掌: $palmPush, 武术模式: $kneeHoldMartialPattern', tag: 'Trajectory');
        return kneeHold && palmPush && kneeHoldMartialPattern;
      default:
        Log.d('默认轨迹检查 - 动作类型: ${currentStep.actionType}', tag: 'Trajectory');
        return true;
    }
  }

  // 检查目标位置
  bool _checkTargetPositions(Pose pose) {
    if (currentStep.targetPositions == null) {
      return true;
    }

    bool allPositionsReached = true;
    bool allPositionsHeld = true;

    // 打印目标位置信息
    Log.d('目标位置检查 - 动作: ${currentStep.name}', tag: tag);
    for (final entry in currentStep.targetPositions!.entries) {
      final landmarkType = entry.key;
      final targetConfig = entry.value;
      Log.d('  ${landmarkType.name}: $targetConfig', tag: tag);
    }

    for (final entry in currentStep.targetPositions!.entries) {
      final landmarkType = entry.key;
      final targetConfig = entry.value;
      final currentLandmark = pose.landmarks[landmarkType];

      if (currentLandmark != null) {
        // 检查是否达到目标位置
        bool isPositionReached = _checkPositionRequirement(pose, landmarkType, targetConfig);
        
        if (!isPositionReached) {
          allPositionsReached = false;
          // 重置保持时间
          _targetPositionHoldTime[landmarkType] = 0;
        } else {
          // 增加保持时间
          _targetPositionHoldTime[landmarkType] = (_targetPositionHoldTime[landmarkType] ?? 0) + 1;
          // 检查是否保持足够时间
          if ((_targetPositionHoldTime[landmarkType] ?? 0) < _minHoldFrames) {
            allPositionsHeld = false;
          } else {
            Log.d('  ${landmarkType.name}: 已保持目标位置 ${_targetPositionHoldTime[landmarkType]} 帧', tag: tag);
          }
        }
      } else {
        allPositionsReached = false;
        allPositionsHeld = false;
        Log.d('  ${landmarkType.name}: 未检测到关键点', tag: tag);
      }
    }

    Log.d('目标位置检查结果 - 所有位置达到: $allPositionsReached，所有位置保持: $allPositionsHeld', tag: tag);

    return allPositionsReached && allPositionsHeld;
  }
  
  // 检查单个位置要求
  bool _checkPositionRequirement(Pose pose, PoseLandmarkType landmarkType, Map<String, dynamic> targetConfig) {
    final currentLandmark = pose.landmarks[landmarkType];
    if (currentLandmark == null) return false;
    
    final currentPosition = _getPositionForComparison(currentLandmark);
    
    // 处理不同类型的目标位置要求
    if (targetConfig.containsKey('relativeTo')) {
      // 基于与其他关键点的相对关系
      return _checkRelativeToPosition(pose, landmarkType, currentPosition, targetConfig);
    } else if (targetConfig.containsKey('relativePosition')) {
      // 基于相对坐标
      return _checkRelativePosition(currentPosition, targetConfig);
    } else if (targetConfig.containsKey('calibratedOffset')) {
      // 基于校准后的偏移
      return _checkCalibratedOffset(landmarkType, currentPosition, targetConfig);
    }
    
    return false;
  }
  
  // 检查基于其他关键点的相对位置
  bool _checkRelativeToPosition(Pose pose, PoseLandmarkType landmarkType, Offset currentPosition, Map<String, dynamic> targetConfig) {
    final relativeTo = targetConfig['relativeTo'];
    final relation = targetConfig['relation'];
    final threshold = targetConfig['threshold'] ?? 0.05;
    
    if (relativeTo is PoseLandmarkType) {
      final relativeLandmark = pose.landmarks[relativeTo];
      if (relativeLandmark != null) {
        final relativePosition = _getPositionForComparison(relativeLandmark);
        
        switch (relation) {
          case 'above':
            // 检查当前点是否在参考点上方（y值更小）
            return currentPosition.dy < relativePosition.dy - threshold;
          case 'below':
            // 检查当前点是否在参考点下方（y值更大）
            return currentPosition.dy > relativePosition.dy + threshold;
          case 'left':
            // 检查当前点是否在参考点左侧（x值更小）
            return currentPosition.dx < relativePosition.dx - threshold;
          case 'right':
            // 检查当前点是否在参考点右侧（x值更大）
            return currentPosition.dx > relativePosition.dx + threshold;
          case 'distance':
            // 检查当前点与参考点的距离
            final targetDistance = targetConfig['distance'];
            if (targetDistance != null) {
              final distance = (currentPosition - relativePosition).distance;
              return (distance - targetDistance).abs() < threshold;
            }
            return false;
          default:
            return false;
        }
      }
    }
    
    return false;
  }
  
  // 检查基于相对坐标的位置
  bool _checkRelativePosition(Offset currentPosition, Map<String, dynamic> targetConfig) {
    final targetPosition = targetConfig['relativePosition'];
    if (targetPosition is Offset) {
      final positionThreshold = _getDynamicThreshold(null); // 使用默认阈值
      final distance = (currentPosition - targetPosition).distance;
      return distance < positionThreshold;
    }
    return false;
  }
  
  // 检查基于校准后的偏移
  bool _checkCalibratedOffset(PoseLandmarkType landmarkType, Offset currentPosition, Map<String, dynamic> targetConfig) {
    if (_userCalibration == null || !_userCalibration!.isCalibrated) {
      return false;
    }
    
    final offset = targetConfig['calibratedOffset'];
    if (offset is Offset) {
      // 获取校准位置
      final calibratedLandmark = _userCalibration!.baseRelativeLandmarks[landmarkType];
      if (calibratedLandmark != null) {
        // 计算目标位置
        final targetPosition = Offset(
          calibratedLandmark.dx + offset.dx,
          calibratedLandmark.dy + offset.dy
        );
        
        final positionThreshold = _getDynamicThreshold(landmarkType);
        final distance = (currentPosition - targetPosition).distance;
        return distance < positionThreshold;
      }
    }
    
    return false;
  }

  // 获取用于比较的位置（使用校准后的相对坐标或原始坐标）
  Offset _getPositionForComparison(PoseLandmark landmark) {
    if (_userCalibration != null) {
      // 使用校准后的相对坐标
      final relativePosition = _userCalibration!.getRelativePosition(landmark);
      return Offset(relativePosition.dx, relativePosition.dy);
    } else {
      // 使用转换后的坐标
      return _convertLandmarkPosition(landmark);
    }
  }

  // 获取动态阈值
  double _getDynamicThreshold(PoseLandmarkType? landmarkType) {
    if (landmarkType == null) {
      return 0.1; // 默认阈值
    }
    
    // 根据不同部位设置不同的阈值
    switch (landmarkType) {
      case PoseLandmarkType.nose:
      case PoseLandmarkType.leftEye:
      case PoseLandmarkType.rightEye:
      case PoseLandmarkType.leftEar:
      case PoseLandmarkType.rightEar:
        return 0.05; // 头部关键点需要更高精度
      case PoseLandmarkType.leftWrist:
      case PoseLandmarkType.rightWrist:
      case PoseLandmarkType.leftAnkle:
      case PoseLandmarkType.rightAnkle:
        return 0.08; // 四肢末端需要较高精度
      default:
        return 0.1; // 其他部位使用默认阈值
    }
  }


  // 检查手腕上抬轨迹
  bool _checkWristRaiseTrajectory() {
    final leftWristTraj = _trajectories[PoseLandmarkType.leftWrist];
    final rightWristTraj = _trajectories[PoseLandmarkType.rightWrist];
    final nose = _trajectories[PoseLandmarkType.nose]?.last;
    final leftShoulderTraj = _trajectories[PoseLandmarkType.leftShoulder];
    final rightShoulderTraj = _trajectories[PoseLandmarkType.rightShoulder];

    if (leftWristTraj == null || rightWristTraj == null || leftWristTraj.length < 4 ||
        nose == null || leftShoulderTraj == null || rightShoulderTraj == null) {
      return false;
    }
    Log.d('正确1',tag: '_checkWristRaiseTrajectory');
    bool isCorrect = _normalUpCheck(leftWristTraj) && _normalUpCheck(rightWristTraj);

    if (!isCorrect) {
      return false;
    }
    Log.d('正确2',tag: '_checkWristRaiseTrajectory');
    // 计算肩膀距离
    final leftShoulder = leftShoulderTraj.last;
    final rightShoulder = rightShoulderTraj.last;
    final shoulderDistance = (leftShoulder.dx - rightShoulder.dx).abs();

    // 检查所有时间点的手腕距离是否不超过肩宽
    for (int i = 0; i < leftWristTraj.length; i++) {
      final leftWrist = leftWristTraj[i];
      final rightWrist = rightWristTraj[i];
      final wristDistance = (leftWrist.dx - rightWrist.dx).abs();
      if (wristDistance > shoulderDistance + 20) {
        return false;
      }
    }
    Log.d('正确3',tag: '_checkWristRaiseTrajectory');
    // 检查最终手腕高度是否高于鼻子
    final lastLeftWrist = leftWristTraj.last;
    final lastRightWrist = rightWristTraj.last;
    if (lastLeftWrist.dy >= nose.dy || lastRightWrist.dy >= nose.dy) {
      return false;
    }
    Log.d('正确4',tag: '_checkWristRaiseTrajectory');
    return true;
  }

  // 检查手臂展开轨迹
  bool _checkArmSpreadTrajectory() {
    final leftWristTraj = _trajectories[PoseLandmarkType.leftWrist];
    final rightWristTraj = _trajectories[PoseLandmarkType.rightWrist];

    if (leftWristTraj == null || rightWristTraj == null || leftWristTraj.length < 5) {
      return false;
    }

    // 检查手臂是否向两侧展开
    final firstLeftWrist = leftWristTraj.first;
    final lastLeftWrist = leftWristTraj.last;
    final firstRightWrist = rightWristTraj.first;
    final lastRightWrist = rightWristTraj.last;

    // 左臂向左移动，右臂向右移动
    return lastLeftWrist.dx < firstLeftWrist.dx - 0.1 &&
        lastRightWrist.dx > firstRightWrist.dx + 0.1;
  }


  // 检查头部和臀部轨迹
  bool _checkHeadHipTrajectory() {
    final noseTraj = _trajectories[PoseLandmarkType.nose];
    final leftHipTraj = _trajectories[PoseLandmarkType.leftHip];
    final rightHipTraj = _trajectories[PoseLandmarkType.rightHip];
    
    if (noseTraj == null || leftHipTraj == null || rightHipTraj == null || noseTraj.length < 5) {
      return false;
    }
    
    // 检查头部是否有左右摆动
    final noseStart = noseTraj.first;
    final noseEnd = noseTraj.last;
    final noseMovement = (noseEnd.dx - noseStart.dx).abs();
    
    // 检查臀部是否有左右摆动
    final leftHipStart = leftHipTraj.first;
    final leftHipEnd = leftHipTraj.last;
    final rightHipStart = rightHipTraj.first;
    final rightHipEnd = rightHipTraj.last;
    
    final leftHipMovement = (leftHipEnd.dx - leftHipStart.dx).abs();
    final rightHipMovement = (rightHipEnd.dx - rightHipStart.dx).abs();
    
    return noseMovement > 0.05 && (leftHipMovement > 0.05 || rightHipMovement > 0.05);
  }
  
  // 检查肘部上抬轨迹
  bool _checkElbowRaiseTrajectory() {
    final leftElbowTraj = _trajectories[PoseLandmarkType.leftElbow];
    final rightElbowTraj = _trajectories[PoseLandmarkType.rightElbow];
    
    if (leftElbowTraj == null || rightElbowTraj == null || leftElbowTraj.length < 5) {
      return false;
    }
    
    // 检查肘部是否向上移动
    final firstLeftElbow = leftElbowTraj.first;
    final lastLeftElbow = leftElbowTraj.last;
    final firstRightElbow = rightElbowTraj.first;
    final lastRightElbow = rightElbowTraj.last;
    
    return lastLeftElbow.dy < firstLeftElbow.dy - 0.05 && 
           lastRightElbow.dy < firstRightElbow.dy - 0.05;
  }
  
  // 检查肩部旋转轨迹
  bool _checkShoulderRotationTrajectory() {
    final leftShoulderTraj = _trajectories[PoseLandmarkType.leftShoulder];
    final rightShoulderTraj = _trajectories[PoseLandmarkType.rightShoulder];
    
    if (leftShoulderTraj == null || rightShoulderTraj == null || leftShoulderTraj.length < 5) {
      return false;
    }
    
    // 检查肩部是否向两侧展开
    final firstLeftShoulder = leftShoulderTraj.first;
    final lastLeftShoulder = leftShoulderTraj.last;
    final firstRightShoulder = rightShoulderTraj.first;
    final lastRightShoulder = rightShoulderTraj.last;
    
    return lastLeftShoulder.dx < firstLeftShoulder.dx - 0.03 && 
           lastRightShoulder.dx > firstRightShoulder.dx + 0.03;
  }
  
  // 检查手臂上下运动轨迹
  bool _checkArmUpDownTrajectory() {
    final leftWristTraj = _trajectories[PoseLandmarkType.leftWrist];
    final rightWristTraj = _trajectories[PoseLandmarkType.rightWrist];
    
    if (leftWristTraj == null || rightWristTraj == null || leftWristTraj.length < 5) {
      return false;
    }
    
    // 检查一手向上，一手向下
    final leftWristStart = leftWristTraj.first;
    final leftWristEnd = leftWristTraj.last;
    final rightWristStart = rightWristTraj.first;
    final rightWristEnd = rightWristTraj.last;
    
    return (leftWristEnd.dy < leftWristStart.dy - 0.05 && 
            rightWristEnd.dy > rightWristStart.dy + 0.05) ||
           (leftWristEnd.dy > leftWristStart.dy + 0.05 && 
            rightWristEnd.dy < rightWristStart.dy - 0.05);
  }
  
  // 检查膝盖弯曲轨迹
  bool _checkKneeBendTrajectory() {
    final leftKneeTraj = _trajectories[PoseLandmarkType.leftKnee];
    final rightKneeTraj = _trajectories[PoseLandmarkType.rightKnee];
    
    if (leftKneeTraj == null || rightKneeTraj == null || leftKneeTraj.length < 5) {
      return false;
    }
    
    // 检查膝盖是否弯曲（向下移动）
    final firstLeftKnee = leftKneeTraj.first;
    final lastLeftKnee = leftKneeTraj.last;
    final firstRightKnee = rightKneeTraj.first;
    final lastRightKnee = rightKneeTraj.last;
    
    return lastLeftKnee.dy > firstLeftKnee.dy + 0.05 && 
           lastRightKnee.dy > firstRightKnee.dy + 0.05;
  }
  
  // 检查身体对齐轨迹
  bool _checkBodyAlignmentTrajectory() {
    final leftShoulderTraj = _trajectories[PoseLandmarkType.leftShoulder];
    final rightShoulderTraj = _trajectories[PoseLandmarkType.rightShoulder];
    final leftHipTraj = _trajectories[PoseLandmarkType.leftHip];
    final rightHipTraj = _trajectories[PoseLandmarkType.rightHip];
    
    if (leftShoulderTraj == null || rightShoulderTraj == null || 
        leftHipTraj == null || rightHipTraj == null || 
        leftShoulderTraj.length < 5) {
      return false;
    }
    
    // 检查肩部和髋部是否保持水平
    final lastLeftShoulder = leftShoulderTraj.last;
    final lastRightShoulder = rightShoulderTraj.last;
    final lastLeftHip = leftHipTraj.last;
    final lastRightHip = rightHipTraj.last;
    
    final shoulderYDiff = (lastLeftShoulder.dy - lastRightShoulder.dy).abs();
    final hipYDiff = (lastLeftHip.dy - lastRightHip.dy).abs();
    
    return shoulderYDiff < 0.05 && hipYDiff < 0.05;
  }
  
  // 检查脊柱运动轨迹
  bool _checkSpineMovementTrajectory() {
    final noseTraj = _trajectories[PoseLandmarkType.nose];
    final leftHipTraj = _trajectories[PoseLandmarkType.leftHip];
    final rightHipTraj = _trajectories[PoseLandmarkType.rightHip];
    
    if (noseTraj == null || leftHipTraj == null || rightHipTraj == null || noseTraj.length < 5) {
      return false;
    }
    
    // 检查头部和髋部的相对运动
    final noseStart = noseTraj.first;
    final noseEnd = noseTraj.last;
    final leftHipStart = leftHipTraj.first;
    final leftHipEnd = leftHipTraj.last;
    
    // 头部和髋部应该有相反方向的运动
    final noseMovement = noseEnd.dy - noseStart.dy;
    final hipMovement = leftHipEnd.dy - leftHipStart.dy;
    
    return (noseMovement > 0.05 && hipMovement < -0.05) || 
           (noseMovement < -0.05 && hipMovement > 0.05);
  }
  
  // 检查倒V形轨迹
  bool _checkInvertedVTrajectory() {
    final noseTraj = _trajectories[PoseLandmarkType.nose];
    final leftWristTraj = _trajectories[PoseLandmarkType.leftWrist];
    final rightWristTraj = _trajectories[PoseLandmarkType.rightWrist];
    final leftAnkleTraj = _trajectories[PoseLandmarkType.leftAnkle];
    final rightAnkleTraj = _trajectories[PoseLandmarkType.rightAnkle];
    
    if (noseTraj == null || leftWristTraj == null || rightWristTraj == null || 
        leftAnkleTraj == null || rightAnkleTraj == null || noseTraj.length < 5) {
      return false;
    }
    
    // 检查鼻子是否向下移动，手腕和脚踝是否分开
    final noseStart = noseTraj.first;
    final noseEnd = noseTraj.last;
    final leftWristEnd = leftWristTraj.last;
    final rightWristEnd = rightWristTraj.last;
    final leftAnkleEnd = leftAnkleTraj.last;
    final rightAnkleEnd = rightAnkleTraj.last;
    
    return noseEnd.dy > noseStart.dy + 0.1 && 
           rightWristEnd.dx - leftWristEnd.dx > 0.3 && 
           rightAnkleEnd.dx - leftAnkleEnd.dx > 0.3;
  }
  
  // 检查单脚站立轨迹
  bool _checkSingleLegStandTrajectory() {
    final leftAnkleTraj = _trajectories[PoseLandmarkType.leftAnkle];
    final rightAnkleTraj = _trajectories[PoseLandmarkType.rightAnkle];
    
    if (leftAnkleTraj == null || rightAnkleTraj == null || leftAnkleTraj.length < 5) {
      return false;
    }
    
    // 检查一只脚是否基本不动，另一只脚是否抬起
    final leftAnkleStart = leftAnkleTraj.first;
    final leftAnkleEnd = leftAnkleTraj.last;
    final rightAnkleStart = rightAnkleTraj.first;
    final rightAnkleEnd = rightAnkleTraj.last;
    
    final leftAnkleMovement = (leftAnkleEnd - leftAnkleStart).distance;
    final rightAnkleMovement = (rightAnkleEnd - rightAnkleStart).distance;
    
    return (leftAnkleMovement < 0.05 && rightAnkleMovement > 0.1) || 
           (rightAnkleMovement < 0.05 && leftAnkleMovement > 0.1);
  }
  
  // 检查手臂抬起轨迹
  bool _checkArmRaiseTrajectory() {
    final leftWristTraj = _trajectories[PoseLandmarkType.leftWrist];
    final rightWristTraj = _trajectories[PoseLandmarkType.rightWrist];
    
    if (leftWristTraj == null || rightWristTraj == null || leftWristTraj.length < 5) {
      return false;
    }
    
    // 检查双手是否向上抬起
    final firstLeftWrist = leftWristTraj.first;
    final lastLeftWrist = leftWristTraj.last;
    final firstRightWrist = rightWristTraj.first;
    final lastRightWrist = rightWristTraj.last;
    
    return lastLeftWrist.dy < firstLeftWrist.dy - 0.1 && 
           lastRightWrist.dy < firstRightWrist.dy - 0.1;
  }
  
  // 检查手臂抬起轨迹（起势）
  bool _checkArmLiftTrajectory() {
    final leftWristTraj = _trajectories[PoseLandmarkType.leftWrist];
    final rightWristTraj = _trajectories[PoseLandmarkType.rightWrist];
    
    if (leftWristTraj == null || rightWristTraj == null || leftWristTraj.length < 5) {
      return false;
    }
    
    // 检查手臂是否从下向上抬起至胸前
    final firstLeftWrist = leftWristTraj.first;
    final lastLeftWrist = leftWristTraj.last;
    final firstRightWrist = rightWristTraj.first;
    final lastRightWrist = rightWristTraj.last;
    
    return lastLeftWrist.dy < firstLeftWrist.dy - 0.1 && 
           lastRightWrist.dy < firstRightWrist.dy - 0.1 &&
           lastLeftWrist.dy > 0.3 && lastRightWrist.dy > 0.3; // 手臂在胸前位置
  }
  
  // 检查弓步轨迹
  bool _checkLungeTrajectory() {
    final leftKneeTraj = _trajectories[PoseLandmarkType.leftKnee];
    final rightKneeTraj = _trajectories[PoseLandmarkType.rightKnee];
    
    if (leftKneeTraj == null || rightKneeTraj == null || leftKneeTraj.length < 5) {
      return false;
    }
    
    // 检查一个膝盖是否向前迈出弯曲，另一个膝盖是否伸直
    final leftKneeStart = leftKneeTraj.first;
    final leftKneeEnd = leftKneeTraj.last;
    final rightKneeStart = rightKneeTraj.first;
    final rightKneeEnd = rightKneeTraj.last;
    
    final leftKneeMovement = leftKneeEnd.dy - leftKneeStart.dy;
    final rightKneeMovement = rightKneeEnd.dy - rightKneeStart.dy;
    
    return (leftKneeMovement > 0.1 && rightKneeMovement < 0.05) || 
           (rightKneeMovement > 0.1 && leftKneeMovement < 0.05);
  }
  
  // 检查虚步轨迹
  bool _checkEmptyStepTrajectory() {
    final leftAnkleTraj = _trajectories[PoseLandmarkType.leftAnkle];
    final rightAnkleTraj = _trajectories[PoseLandmarkType.rightAnkle];
    
    if (leftAnkleTraj == null || rightAnkleTraj == null || leftAnkleTraj.length < 5) {
      return false;
    }
    
    // 检查一只脚是否作为支撑，另一只脚是否虚点地面
    final leftAnkleStart = leftAnkleTraj.first;
    final leftAnkleEnd = leftAnkleTraj.last;
    final rightAnkleStart = rightAnkleTraj.first;
    final rightAnkleEnd = rightAnkleTraj.last;
    
    final leftAnkleMovement = (leftAnkleEnd - leftAnkleStart).distance;
    final rightAnkleMovement = (rightAnkleEnd - rightAnkleStart).distance;
    
    return (leftAnkleMovement < 0.05 && rightAnkleMovement > 0.05 && rightAnkleEnd.dy > rightAnkleStart.dy) || 
           (rightAnkleMovement < 0.05 && leftAnkleMovement > 0.05 && leftAnkleEnd.dy > leftAnkleStart.dy);
  }
  
  // 检查搂膝轨迹
  bool _checkKneeHoldTrajectory() {
    final leftWristTraj = _trajectories[PoseLandmarkType.leftWrist];
    final leftKneeTraj = _trajectories[PoseLandmarkType.leftKnee];
    
    if (leftWristTraj == null || leftKneeTraj == null || leftWristTraj.length < 5) {
      return false;
    }
    
    // 检查手是否向膝盖方向移动
    final leftWristEnd = leftWristTraj.last;
    final leftKneeEnd = leftKneeTraj.last;
    
    final distance = (leftWristEnd - leftKneeEnd).distance;
    return distance < 0.15;
  }
  
  // 检查推掌轨迹
  bool _checkPalmPushTrajectory() {
    final rightWristTraj = _trajectories[PoseLandmarkType.rightWrist];
    
    if (rightWristTraj == null || rightWristTraj.length < 5) {
      return false;
    }
    
    // 检查手掌是否向前推出
    final firstRightWrist = rightWristTraj.first;
    final lastRightWrist = rightWristTraj.last;
    
    return lastRightWrist.dx > firstRightWrist.dx + 0.1;
  }
  
  // 检查轨迹平滑度
  bool _checkSmoothTrajectory(List<PoseLandmarkType> landmarkTypes) {
    Log.d('开始轨迹平滑度检查 - 关键点: ${landmarkTypes.map((t) => t.name).join(', ')}', tag: 'Trajectory');
    
    for (final type in landmarkTypes) {
      final trajectory = _trajectories[type];
      if (trajectory == null || trajectory.length < 3) {
        Log.d('轨迹平滑度检查 - ${type.name} 轨迹数据不足', tag: 'Trajectory');
        return false;
      }
      
      // 计算轨迹的平滑度（相邻点之间的角度变化）
      double totalAngleChange = 0;
      for (int i = 1; i < trajectory.length - 1; i++) {
        final prev = trajectory[i - 1];
        final curr = trajectory[i];
        final next = trajectory[i + 1];
        
        // 计算向量
        final v1 = Offset(curr.dx - prev.dx, curr.dy - prev.dy);
        final v2 = Offset(next.dx - curr.dx, next.dy - curr.dy);
        
        // 计算向量夹角
        final dotProduct = v1.dx * v2.dx + v1.dy * v2.dy;
        final v1Magnitude = v1.distance;
        final v2Magnitude = v2.distance;
        
        if (v1Magnitude > 0 && v2Magnitude > 0) {
          final cosAngle = dotProduct / (v1Magnitude * v2Magnitude);
          final angle = acos(cosAngle).abs();
          totalAngleChange += angle;
        }
      }
      
      // 平均角度变化不应太大
      final averageAngleChange = totalAngleChange / (trajectory.length - 2);
      final averageAngleDegrees = averageAngleChange * (180 / pi);
      Log.d('轨迹平滑度检查 - ${type.name} 平均角度变化: ${averageAngleDegrees.toStringAsFixed(2)}度', tag: 'Trajectory');
      
      if (averageAngleChange > 1.0) { // 约57度
        Log.d('轨迹平滑度检查 - ${type.name} 轨迹不平滑', tag: 'Trajectory');
        return false;
      }
    }
    
    Log.d('轨迹平滑度检查 - 所有关键点轨迹平滑', tag: 'Trajectory');
    return true;
  }
  
  // 检查轨迹稳定性
  bool _checkStabilityTrajectory(List<PoseLandmarkType> landmarkTypes) {
    Log.d('开始轨迹稳定性检查 - 关键点: ${landmarkTypes.map((t) => t.name).join(', ')}', tag: 'Trajectory');
    
    for (final type in landmarkTypes) {
      final trajectory = _trajectories[type];
      if (trajectory == null || trajectory.length < 5) {
        Log.d('轨迹稳定性检查 - ${type.name} 轨迹数据不足', tag: 'Trajectory');
        return false;
      }
      
      // 计算轨迹的稳定性（位置方差）
      double sumX = 0, sumY = 0;
      for (final point in trajectory) {
        sumX += point.dx;
        sumY += point.dy;
      }
      
      final avgX = sumX / trajectory.length;
      final avgY = sumY / trajectory.length;
      
      double variance = 0;
      for (final point in trajectory) {
        variance += pow(point.dx - avgX, 2) + pow(point.dy - avgY, 2);
      }
      variance /= trajectory.length;
      
      Log.d('轨迹稳定性检查 - ${type.name} 位置方差: ${variance.toStringAsFixed(6)}', tag: 'Trajectory');
      
      // 方差不应太大
      if (variance > 0.005) {
        Log.d('轨迹稳定性检查 - ${type.name} 轨迹不稳定', tag: 'Trajectory');
        return false;
      }
    }
    
    Log.d('轨迹稳定性检查 - 所有关键点轨迹稳定', tag: 'Trajectory');
    return true;
  }
  
  // 检查轨迹模式
  bool _checkTrajectoryPattern(List<PoseLandmarkType> landmarkTypes, String pattern) {
    switch (pattern) {
      case 'spread':
        // 检查展开模式：关键点向两侧移动
        return _checkSpreadPattern(landmarkTypes);
      case 'alternate':
        // 检查交替模式：关键点交替上下移动
        return _checkAlternatePattern(landmarkTypes);
      case 'sway':
        // 检查摆动模式：关键点左右摆动
        return _checkSwayPattern(landmarkTypes);
      case 'wave':
        // 检查波浪模式：关键点呈波浪式运动
        return _checkWavePattern(landmarkTypes);
      case 'stretch':
        // 检查伸展模式：关键点向远离身体中心方向移动
        return _checkStretchPattern(landmarkTypes);
      case 'martial':
        // 检查武术动作模式：关键点按照武术动作轨迹移动
        return _checkMartialPattern(landmarkTypes);
      default:
        return true;
    }
  }
  
  // 检查展开模式
  bool _checkSpreadPattern(List<PoseLandmarkType> landmarkTypes) {
    if (landmarkTypes.length < 2) return false;
    
    final firstType = landmarkTypes[0];
    final secondType = landmarkTypes[1];
    
    final firstTraj = _trajectories[firstType];
    final secondTraj = _trajectories[secondType];
    
    if (firstTraj == null || secondTraj == null || firstTraj.length < 5) return false;
    
    // 检查第一个点向左移动，第二个点向右移动
    final firstStart = firstTraj.first;
    final firstEnd = firstTraj.last;
    final secondStart = secondTraj.first;
    final secondEnd = secondTraj.last;
    
    return firstEnd.dx < firstStart.dx - 0.05 && 
           secondEnd.dx > secondStart.dx + 0.05;
  }
  
  // 检查交替模式
  bool _checkAlternatePattern(List<PoseLandmarkType> landmarkTypes) {
    if (landmarkTypes.length < 2) return false;
    
    final firstType = landmarkTypes[0];
    final secondType = landmarkTypes[1];
    
    final firstTraj = _trajectories[firstType];
    final secondTraj = _trajectories[secondType];
    
    if (firstTraj == null || secondTraj == null || firstTraj.length < 5) return false;
    
    // 检查两个点一个向上，一个向下
    final firstStart = firstTraj.first;
    final firstEnd = firstTraj.last;
    final secondStart = secondTraj.first;
    final secondEnd = secondTraj.last;
    
    return (firstEnd.dy < firstStart.dy - 0.05 && 
            secondEnd.dy > secondStart.dy + 0.05) ||
           (firstEnd.dy > firstStart.dy + 0.05 && 
            secondEnd.dy < secondStart.dy - 0.05);
  }
  
  // 检查摆动模式
  bool _checkSwayPattern(List<PoseLandmarkType> landmarkTypes) {
    for (final type in landmarkTypes) {
      final trajectory = _trajectories[type];
      if (trajectory == null || trajectory.length < 10) return false;
      
      // 检查轨迹是否有明显的左右摆动
      int directionChanges = 0;
      double prevDirection = 0;
      
      for (int i = 1; i < trajectory.length; i++) {
        final dx = trajectory[i].dx - trajectory[i-1].dx;
        final currentDirection = dx.sign;
        
        if (i > 1 && currentDirection != prevDirection && currentDirection != 0) {
          directionChanges++;
        }
        prevDirection = currentDirection;
      }
      
      // 至少有2次方向变化
      if (directionChanges < 2) return false;
    }
    
    return true;
  }
  
  // 检查波浪模式
  bool _checkWavePattern(List<PoseLandmarkType> landmarkTypes) {
    for (final type in landmarkTypes) {
      final trajectory = _trajectories[type];
      if (trajectory == null || trajectory.length < 8) return false;
      
      // 检查轨迹是否有波浪形变化
      List<double> yValues = trajectory.map((p) => p.dy).toList();
      
      // 计算局部极值点
      int extremaCount = 0;
      for (int i = 1; i < yValues.length - 1; i++) {
        if ((yValues[i] > yValues[i-1] && yValues[i] > yValues[i+1]) ||
            (yValues[i] < yValues[i-1] && yValues[i] < yValues[i+1])) {
          extremaCount++;
        }
      }
      
      // 至少有2个极值点
      if (extremaCount < 2) return false;
    }
    
    return true;
  }
  
  // 检查伸展模式
  bool _checkStretchPattern(List<PoseLandmarkType> landmarkTypes) {
    // 计算身体中心
    final leftHip = _trajectories[PoseLandmarkType.leftHip]?.last;
    final rightHip = _trajectories[PoseLandmarkType.rightHip]?.last;
    
    if (leftHip == null || rightHip == null) return false;
    
    final bodyCenter = Offset((leftHip.dx + rightHip.dx) / 2, (leftHip.dy + rightHip.dy) / 2);
    
    for (final type in landmarkTypes) {
      final trajectory = _trajectories[type];
      if (trajectory == null || trajectory.length < 5) return false;
      
      final start = trajectory.first;
      final end = trajectory.last;
      
      // 检查关键点是否向远离身体中心的方向移动
      final startDistance = (start - bodyCenter).distance;
      final endDistance = (end - bodyCenter).distance;
      
      if (endDistance <= startDistance) return false;
    }
    
    return true;
  }
  
  // 检查武术动作模式
  bool _checkMartialPattern(List<PoseLandmarkType> landmarkTypes) {
    // 武术动作通常有明确的起始和结束位置
    // 检查轨迹是否有明确的方向性和稳定性
    for (final type in landmarkTypes) {
      final trajectory = _trajectories[type];
      if (trajectory == null || trajectory.length < 5) return false;
      
      final start = trajectory.first;
      final end = trajectory.last;
      
      // 检查是否有明显的移动
      final distance = (end - start).distance;
      if (distance < 0.1) return false;
      
      // 检查轨迹是否平滑
      if (!_checkSmoothTrajectory([type])) return false;
    }
    
    return true;
  }
  
  // 检测正常上移
  bool _normalUpCheck(List<Offset> traj) {
    int length = traj.length - 1;
    int count = 0;
    for (int i = 0; i < length; i++) {
      if (traj[i].dy < traj[i + 1].dy) {
        count++;
      }
    }
    if (count > 5 || traj.first.dy > traj.last.dy) {
      Log.d('count: $count,',tag: '_checkWristRaiseTrajectory');
      return false;
    }
    return true;
  }
  
  // 检测正常下移
  bool _normalDownCheck(List<Offset> traj) {
    int length = traj.length - 1;
    int count = 0;
    for (int i = 0; i < length; i++) {
      if (traj[i].dy > traj[i + 1].dy) {
        count++;
      }
    }
    if (count > 3 || traj.first.dy > traj.last.dy) {
      return false;
    }
    return true;
  }
  
  // 检测正常左移
  bool _normalLeftCheck(List<Offset> traj) {
    int length = traj.length - 1;
    int count = 0;
    for (int i = 0; i < length; i++) {
      if (traj[i].dx < traj[i + 1].dx) {
        count++;
      }
    }
    if (count > 3 || traj.first.dx < traj.last.dx) {
      return false;
    }
    return true;
  }
  
  // 检测正常右移
  bool _normalRightCheck(List<Offset> traj) {
    int length = traj.length - 1;
    int count = 0;
    for (int i = 0; i < length; i++) {
      if (traj[i].dx > traj[i + 1].dx) {
        count++;
      }
    }
    if (count > 3 || traj.first.dx > traj.last.dx) {
      return false;
    }
    return true;
  }


  // 进入下一步
  bool nextStep() {
    if (_currentStepIndex < _actionSteps.length - 1) {
      _currentStepIndex++;
      _clearTrajectories();
      _clearHoldTimes();
      return true;
    } else {
      _isSequenceCompleted = true;
      return false;
    }
  }

  /// 当前 step 做错/偏差较大时，重置当前 step 的采样点集与开始检测状态，
  /// 让 UI 可以重新“开始采集轨迹 + 重新检测开始点/动作完成”。
  void retryCurrentStep() {
    _clearTrajectories();
    _clearHoldTimes();
    _canRecord = true; // 允许重新采集轨迹点
    Log.d('retryCurrentStep - 当前动作: ${currentStep.name}', tag: tag);
  }

  // 重置序列
  void reset() {
    _currentStepIndex = 0;
    _isSequenceCompleted = false;
    _clearTrajectories();
    _clearHoldTimes();
    _canRecord = true; // 重置记录状态
  }

  // 清除轨迹
  void _clearTrajectories() {
    _trajectories.clear();
  }

  // 清除保持时间
  void _clearHoldTimes() {
    _targetPositionHoldTime.clear();
    _startPositionHoldTime.clear();
    _hasDetectedStart = false;
    _startLandmarks = null;
  }
}