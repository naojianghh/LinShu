
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../models/user_calibration.dart';
import '../services/dtw_pose_matcher.dart';
import '../services/pose_analyse.dart';
import '../utils/log_util.dart';

// 关键点渲染器
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



class SportAiCorrectionScreen extends StatefulWidget {
  final String sportType;
  final CameraController? cameraController;

  const SportAiCorrectionScreen({
    super.key,
    required this.sportType,
    this.cameraController,
  });

  @override
  State<SportAiCorrectionScreen> createState() => _SportAiCorrectionScreenState();
}

class _SportAiCorrectionScreenState extends State<SportAiCorrectionScreen> {
  late PoseDetector _poseDetector;

  bool _isShowDialog = false;

  Pose? _currentPose;
  double _poseAccuracy = 0.0;
  Map<String, bool> _checkResults = {};
  String _currentSuggestion = '';

  // 用户校准和动作分析相关
  late UserCalibration _userCalibration;
  late ActionAnalyzer _actionAnalyzer;
  late UserProfile _userProfile;
  bool _isCalibrating = false;
  bool _isCalibrated = false;
  bool _isActionCompleted = false;
  String _calibrationMessage = '';

  // 运动序列管理
  late SportSequenceManager _sportSequenceManager;
  bool _isSequenceCompleted = false;

  // DTW（第1式：双手托天）比对
  late final DtwPoseMatcher _dtwMatcher;
  bool _dtwReady = false;

  // 当前 step 纠错：连续低准确度触发重置
  int _lowAccuracyStreak = 0;
  static const int _lowAccuracyFramesToRetry = 15; // 约半秒左右（取决于帧率）
  DateTime? _lastRetryTime;
  static const Duration _retryCooldown = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();

    _initializeCalibrationSystem();
    _initDetector();

    _dtwMatcher = DtwPoseMatcher();
    _initDtwTemplate();
  }

  Future<void> _initDtwTemplate() async {
    try {
      await _dtwMatcher.loadTemplateFromAsset(
        assetPath: 'assets/video/baduanjin_step1_dtw_template.json',
      );
      if (mounted) {
        setState(() => _dtwReady = true);
      }
      Log.d('DTW 模板加载成功', tag: 'DTW');
    } catch (e) {
      Log.e('DTW 模板加载失败: $e', tag: 'DTW');
    }
  }

  void _initializeCalibrationSystem() {
    // 初始化用户资料（实际应用中可以从存储或用户输入获取）
    _userProfile = UserProfile(
      height: 170, // 默认身高170cm
      armSpan: 170, // 默认臂展170cm
      gender: 'male',
    );

    // 初始化校准和分析器
    _userCalibration = UserCalibration();
    final thresholdManager = DynamicThresholdManager();
    _actionAnalyzer = ActionAnalyzer(_userCalibration, thresholdManager);

    // 初始化运动序列管理器
    _sportSequenceManager = _createSportSequenceManager();
    // 设置校准系统
    _sportSequenceManager.setUserCalibration(_userCalibration);

    // 开始校准流程
    _startCalibration();
  }

  // 创建运动序列管理器
  SportSequenceManager _createSportSequenceManager() {
    switch (widget.sportType) {
      case '八段锦':
        return SportSequenceManager([
          ActionStep(
            name: '双手托天理三焦',
            actionType: '双手托天',
            checkItems: ['手臂伸展', '腰背挺直', '呼吸自然'],
            description: '双脚与肩同宽，双手自小腹前举至胸前，翻掌上托，目视前方',
            targetPositions: {
              PoseLandmarkType.leftWrist: {
                'relativeTo': PoseLandmarkType.nose,
                'relation': 'above',
                'threshold': 0.05
              }, // 左手腕在鼻子上方
              PoseLandmarkType.rightWrist: {
                'relativeTo': PoseLandmarkType.nose,
                'relation': 'above',
                'threshold': 0.05
              }, // 右手腕在鼻子上方
              PoseLandmarkType.leftElbow: {
                'relativeTo': PoseLandmarkType.leftShoulder,
                'relation': 'above',
                'threshold': 0.03
              }, // 左肘在左肩上方
              PoseLandmarkType.rightElbow: {
                'relativeTo': PoseLandmarkType.rightShoulder,
                'relation': 'above',
                'threshold': 0.03
              }, // 右肘在右肩上方
            },
          ),
          ActionStep(
            name: '左右开弓似射雕',
            actionType: '左右开弓',
            checkItems: ['马步稳健', '手臂伸展', '转腰拧胯'],
            description: '左脚向左开步，成马步，双手拉弓如射雕状',
            targetPositions: {
              PoseLandmarkType.leftWrist: {
                'relativeTo': PoseLandmarkType.leftShoulder,
                'relation': 'left',
                'threshold': 0.1
              }, // 左手腕在左肩左侧
              PoseLandmarkType.rightWrist: {
                'relativeTo': PoseLandmarkType.rightShoulder,
                'relation': 'right',
                'threshold': 0.1
              }, // 右手腕在右肩右侧
              PoseLandmarkType.leftKnee: {
                'relativeTo': PoseLandmarkType.leftHip,
                'relation': 'below',
                'threshold': 0.15
              }, // 左膝在左髋下方（弯曲）
              PoseLandmarkType.rightKnee: {
                'relativeTo': PoseLandmarkType.rightHip,
                'relation': 'below',
                'threshold': 0.05
              }, // 右膝在右髋下方（微屈）
            },
          ),
          ActionStep(
            name: '调理脾胃须单举',
            actionType: '调理脾胃',
            checkItems: ['单臂上举', '另一臂下按', '意念脾胃'],
            description: '左手心向上托举，右手心向下按，左右交替',
            targetPositions: {
              PoseLandmarkType.leftWrist: {
                'relativeTo': PoseLandmarkType.leftShoulder,
                'relation': 'above',
                'threshold': 0.1
              }, // 左手腕在左肩上方
              PoseLandmarkType.rightWrist: {
                'relativeTo': PoseLandmarkType.rightShoulder,
                'relation': 'below',
                'threshold': 0.1
              }, // 右手腕在右肩下方
              PoseLandmarkType.leftElbow: {
                'relativeTo': PoseLandmarkType.leftShoulder,
                'relation': 'above',
                'threshold': 0.05
              }, // 左肘在左肩上方
              PoseLandmarkType.rightElbow: {
                'relativeTo': PoseLandmarkType.rightShoulder,
                'relation': 'below',
                'threshold': 0.05
              }, // 右肘在右肩下方
            },
          ),
          ActionStep(
            name: '摇头摆尾去心火',
            actionType: '摇头摆尾',
            checkItems: ['马步下蹲', '摇头摆尾', '呼吸协调'],
            description: '马步下蹲，上体前倾，左右摇头摆尾',
            targetPositions: {
              PoseLandmarkType.nose: {
                'relativeTo': PoseLandmarkType.leftHip,
                'relation': 'above',
                'threshold': 0.1
              }, // 头部在前倾位置
              PoseLandmarkType.leftKnee: {
                'relativeTo': PoseLandmarkType.leftHip,
                'relation': 'below',
                'threshold': 0.15
              }, // 左膝弯曲
              PoseLandmarkType.rightKnee: {
                'relativeTo': PoseLandmarkType.rightHip,
                'relation': 'below',
                'threshold': 0.15
              }, // 右膝弯曲
            },
          ),
        ],previewSize: widget.cameraController!.value.previewSize!);
      case '瑜伽':
        return SportSequenceManager([
          ActionStep(
            name: '山式',
            actionType: '瑜伽山式',
            checkItems: ['双脚并拢', '脊柱挺直', '手臂自然下垂'],
            description: '双脚并拢站立，脊柱伸直，双臂自然下垂',
            targetPositions: {
              PoseLandmarkType.leftShoulder: {
                'relativeTo': PoseLandmarkType.rightShoulder,
                'relation': 'left',
                'threshold': 0.1
              }, // 肩部水平
              PoseLandmarkType.leftWrist: {
                'relativeTo': PoseLandmarkType.leftShoulder,
                'relation': 'below',
                'threshold': 0.2
              }, // 手臂自然下垂
              PoseLandmarkType.rightWrist: {
                'relativeTo': PoseLandmarkType.rightShoulder,
                'relation': 'below',
                'threshold': 0.2
              }, // 手臂自然下垂
            },
          ),
          ActionStep(
            name: '猫牛式',
            actionType: '猫牛式',
            checkItems: ['脊柱起伏', '呼吸同步', '四肢支撑'],
            description: '四肢着地，吸气时抬头塌腰，呼气时低头弓背',
            targetPositions: {
              PoseLandmarkType.nose: {
                'relativeTo': PoseLandmarkType.leftWrist,
                'relation': 'above',
                'threshold': 0.1
              }, // 头部抬起
              PoseLandmarkType.leftWrist: {
                'relativeTo': PoseLandmarkType.leftKnee,
                'relation': 'above',
                'threshold': 0.2
              }, // 双手支撑
              PoseLandmarkType.rightWrist: {
                'relativeTo': PoseLandmarkType.rightKnee,
                'relation': 'above',
                'threshold': 0.2
              }, // 双手支撑
            },
          ),
          ActionStep(
            name: '下犬式',
            actionType: '下犬式',
            checkItems: ['身体呈倒V形', '脚跟落地', '手臂伸直'],
            description: '双手双脚着地，臀部向上抬起，身体呈倒V形',
            targetPositions: {
              PoseLandmarkType.nose: {
                'relativeTo': PoseLandmarkType.leftWrist,
                'relation': 'below',
                'threshold': 0.1
              }, // 头部向下
              PoseLandmarkType.leftWrist: {
                'relativeTo': PoseLandmarkType.leftAnkle,
                'relation': 'above',
                'threshold': 0.3
              }, // 双手撑地
              PoseLandmarkType.rightWrist: {
                'relativeTo': PoseLandmarkType.rightAnkle,
                'relation': 'above',
                'threshold': 0.3
              }, // 双手撑地
            },
          ),
          ActionStep(
            name: '树式',
            actionType: '树式',
            checkItems: ['单脚站立', '另一条腿弯曲', '手臂上举'],
            description: '单脚站立，另一条腿弯曲贴住大腿内侧，双手合十上举',
            targetPositions: {
              PoseLandmarkType.leftWrist: {
                'relativeTo': PoseLandmarkType.nose,
                'relation': 'above',
                'threshold': 0.1
              }, // 双手合十上举
              PoseLandmarkType.rightWrist: {
                'relativeTo': PoseLandmarkType.nose,
                'relation': 'above',
                'threshold': 0.1
              }, // 双手合十上举
              PoseLandmarkType.rightKnee: {
                'relativeTo': PoseLandmarkType.leftAnkle,
                'relation': 'above',
                'threshold': 0.2
              }, // 右腿弯曲
            },
          ),
        ],previewSize: widget.cameraController!.value.previewSize!);
      case '太极拳':
        return SportSequenceManager([
          ActionStep(
            name: '起势',
            actionType: '起势',
            checkItems: ['双脚开立', '双臂抬起', '呼吸自然'],
            description: '双脚与肩同宽，双臂缓慢抬起至胸前',
            targetPositions: {
              PoseLandmarkType.leftWrist: {
                'relativeTo': PoseLandmarkType.leftShoulder,
                'relation': 'below',
                'threshold': 0.1
              }, // 双手在胸前
              PoseLandmarkType.rightWrist: {
                'relativeTo': PoseLandmarkType.rightShoulder,
                'relation': 'below',
                'threshold': 0.1
              }, // 双手在胸前
            },
          ),
          ActionStep(
            name: '左右野马分鬃',
            actionType: '左右野马分鬃',
            checkItems: ['弓步迈出', '手臂分开', '转腰带动'],
            description: '左脚向前迈出成弓步，双手像野马分鬃一样分开',
            targetPositions: {
              PoseLandmarkType.leftWrist: {
                'relativeTo': PoseLandmarkType.leftShoulder,
                'relation': 'left',
                'threshold': 0.1
              }, // 左手向左前方
              PoseLandmarkType.rightWrist: {
                'relativeTo': PoseLandmarkType.rightShoulder,
                'relation': 'right',
                'threshold': 0.1
              }, // 右手向右后方
              PoseLandmarkType.leftKnee: {
                'relativeTo': PoseLandmarkType.leftHip,
                'relation': 'below',
                'threshold': 0.15
              }, // 左腿弓步
            },
          ),
          ActionStep(
            name: '白鹤亮翅',
            actionType: '白鹤亮翅',
            checkItems: ['虚步站立', '手臂展开', '重心稳定'],
            description: '右脚前脚掌点地，双手像白鹤亮翅一样展开',
            targetPositions: {
              PoseLandmarkType.leftWrist: {
                'relativeTo': PoseLandmarkType.leftShoulder,
                'relation': 'left',
                'threshold': 0.1
              }, // 左手向左上方
              PoseLandmarkType.rightWrist: {
                'relativeTo': PoseLandmarkType.rightShoulder,
                'relation': 'right',
                'threshold': 0.1
              }, // 右手向右下方
              PoseLandmarkType.rightAnkle: {
                'relativeTo': PoseLandmarkType.leftAnkle,
                'relation': 'above',
                'threshold': 0.1
              }, // 右脚虚点
            },
          ),
          ActionStep(
            name: '搂膝拗步',
            actionType: '搂膝拗步',
            checkItems: ['弓步迈出', '手臂搂膝', '另臂前推'],
            description: '向前迈出弓步，一手搂膝，另一手前推',
            targetPositions: {
              PoseLandmarkType.leftWrist: {
                'relativeTo': PoseLandmarkType.leftKnee,
                'relation': 'above',
                'threshold': 0.05
              }, // 左手搂膝
              PoseLandmarkType.rightWrist: {
                'relativeTo': PoseLandmarkType.rightShoulder,
                'relation': 'right',
                'threshold': 0.1
              }, // 右手前推
              PoseLandmarkType.leftKnee: {
                'relativeTo': PoseLandmarkType.leftHip,
                'relation': 'below',
                'threshold': 0.15
              }, // 左腿弓步
            },
          ),
        ],previewSize: widget.cameraController!.value.previewSize!);
      default:
        return SportSequenceManager([
          ActionStep(
            name: '双手托天理三焦',
            actionType: '双手托天',
            checkItems: ['手臂伸展', '腰背挺直'],
            description: '双脚与肩同宽，双手自小腹前举至胸前，翻掌上托',
            targetPositions: {
              PoseLandmarkType.leftWrist: {
                'relativeTo': PoseLandmarkType.nose,
                'relation': 'above',
                'threshold': 0.05
              }, // 左手腕在鼻子上方
              PoseLandmarkType.rightWrist: {
                'relativeTo': PoseLandmarkType.nose,
                'relation': 'above',
                'threshold': 0.05
              }, // 右手腕在鼻子上方
            },
          ),
        ],previewSize: widget.cameraController!.value.previewSize!);
    }
  }

  void _initDetector() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );
  }

  void _startCalibration() {
    setState(() {
      _isCalibrating = true;
      _calibrationMessage = '请自然站立，双脚与肩同宽，双臂自然下垂';
    });

    // 延迟3秒后捕获校准姿势
    Future.delayed(const Duration(seconds: 3), () {
      _captureCalibrationPose();
    });
  }

  // 捕获校准姿势
  Future<void> _captureCalibrationPose() async {
    try {
      if (widget.cameraController == null || !widget.cameraController!.value.isInitialized) {
        setState(() {
          _calibrationMessage = '相机未初始化，无法校准';
          _isCalibrating = false;
        });
        return;
      }

      // 开始3秒倒计时
      for (int i = 3; i > 0; i--) {
        setState(() {
          _calibrationMessage = '请保持姿势稳定\n$i';
        });
        await Future.delayed(const Duration(seconds: 1));
      }

      // 倒计时结束，开始捕获后三帧
      setState(() {
        _calibrationMessage = '正在捕获姿势...';
      });

      // 从相机流中获取后三帧用于校准
      List<Pose> capturedPoses = [];
      bool captureCompleted = false;
      
      await widget.cameraController!.startImageStream((CameraImage image) async {
        if (captureCompleted || capturedPoses.length >= 3) {
          widget.cameraController?.stopImageStream();
          return;
        }
        
        try {
          final inputImage = _convertCameraImage(image);
          if (inputImage != null) {
            final poses = await _poseDetector.processImage(inputImage);
            if (poses.isNotEmpty) {
              capturedPoses.add(poses.first);
              Log.d('捕获到第 ${capturedPoses.length}/3 帧姿势', tag: 'Calibration');
              
              // 捕获到3帧后完成
              if (capturedPoses.length >= 3) {
                captureCompleted = true;
                
                // 计算平均姿势作为标准姿势
                final standardPose = _calculateAveragePose(capturedPoses);
                _userCalibration.calibrate(standardPose);
                Log.d('标准姿势 - 关键点数量: ${standardPose.landmarks.length}', tag: 'Calibration');
                Log.d('鼻子位置: x=${standardPose.landmarks[PoseLandmarkType.nose]?.x ?? 'N/A'}, y=${standardPose.landmarks[PoseLandmarkType.nose]?.y ?? 'N/A'}', tag: 'Calibration');
                Log.d('左肩位置: x=${standardPose.landmarks[PoseLandmarkType.leftShoulder]?.x ?? 'N/A'}, y=${standardPose.landmarks[PoseLandmarkType.leftShoulder]?.y ?? 'N/A'}', tag: 'Calibration');
                Log.d('右肩位置: x=${standardPose.landmarks[PoseLandmarkType.rightShoulder]?.x ?? 'N/A'}, y=${standardPose.landmarks[PoseLandmarkType.rightShoulder]?.y ?? 'N/A'}', tag: 'Calibration');
                Log.d('左肘位置: x=${standardPose.landmarks[PoseLandmarkType.leftElbow]?.x ?? 'N/A'}, y=${standardPose.landmarks[PoseLandmarkType.leftElbow]?.y ?? 'N/A'}', tag: 'Calibration');
                Log.d('右肘位置: x=${standardPose.landmarks[PoseLandmarkType.rightElbow]?.x ?? 'N/A'}, y=${standardPose.landmarks[PoseLandmarkType.rightElbow]?.y ?? 'N/A'}', tag: 'Calibration');
                Log.d('左手腕位置: x=${standardPose.landmarks[PoseLandmarkType.leftWrist]?.x ?? 'N/A'}, y=${standardPose.landmarks[PoseLandmarkType.leftWrist]?.y ?? 'N/A'}', tag: 'Calibration');
                Log.d('右手腕位置: x=${standardPose.landmarks[PoseLandmarkType.rightWrist]?.x ?? 'N/A'}, y=${standardPose.landmarks[PoseLandmarkType.rightWrist]?.y ?? 'N/A'}', tag: 'Calibration');
                Log.d('左髋位置: x=${standardPose.landmarks[PoseLandmarkType.leftHip]?.x ?? 'N/A'}, y=${standardPose.landmarks[PoseLandmarkType.leftHip]?.y ?? 'N/A'}', tag: 'Calibration');
                Log.d('右髋位置: x=${standardPose.landmarks[PoseLandmarkType.rightHip]?.x ?? 'N/A'}, y=${standardPose.landmarks[PoseLandmarkType.rightHip]?.y ?? 'N/A'}', tag: 'Calibration');
                Log.d('左膝位置: x=${standardPose.landmarks[PoseLandmarkType.leftKnee]?.x ?? 'N/A'}, y=${standardPose.landmarks[PoseLandmarkType.leftKnee]?.y ?? 'N/A'}', tag: 'Calibration');
                Log.d('右膝位置: x=${standardPose.landmarks[PoseLandmarkType.rightKnee]?.x ?? 'N/A'}, y=${standardPose.landmarks[PoseLandmarkType.rightKnee]?.y ?? 'N/A'}', tag: 'Calibration');
                Log.d('左脚踝位置: x=${standardPose.landmarks[PoseLandmarkType.leftAnkle]?.x ?? 'N/A'}, y=${standardPose.landmarks[PoseLandmarkType.leftAnkle]?.y ?? 'N/A'}', tag: 'Calibration');
                Log.d('右脚踝位置: x=${standardPose.landmarks[PoseLandmarkType.rightAnkle]?.x ?? 'N/A'}, y=${standardPose.landmarks[PoseLandmarkType.rightAnkle]?.y ?? 'N/A'}', tag: 'Calibration');
                setState(() {
                  _isCalibrating = false;
                  _isCalibrated = true;
                  _calibrationMessage = '校准完成！';
                });

                // 校准完成后停止当前流并启动实时分析
                widget.cameraController?.stopImageStream();
                _startPoseDetectionStream();
              }
            }
          }
        } catch (e) {
          Log.e('校准错误: $e', tag: 'Calibration');
        }
      });

      // 超时处理
      Future.delayed(const Duration(seconds: 10), () {
        if (!captureCompleted) {
          setState(() {
            _calibrationMessage = '校准超时，请重试';
            _isCalibrating = false;
          });
          widget.cameraController?.stopImageStream();
        }
      });
    } catch (e) {
      setState(() {
        _calibrationMessage = '校准失败，请重试';
        _isCalibrating = false;
      });
    }
  }

  // 计算多帧姿势的平均值作为标准姿势
  Pose _calculateAveragePose(List<Pose> poses) {
    if (poses.isEmpty) {
      // 返回空姿势
      return Pose(landmarks: {});
    }

    // 计算每个关键点的平均值
    Map<PoseLandmarkType, List<PoseLandmark>> landmarkGroups = {};
    
    // 收集所有关键点
    for (final pose in poses) {
      for (final landmark in pose.landmarks.entries) {
        if (!landmarkGroups.containsKey(landmark.key)) {
          landmarkGroups[landmark.key] = [];
        }
        landmarkGroups[landmark.key]!.add(landmark.value);
      }
    }

    // 计算平均值
    Map<PoseLandmarkType, PoseLandmark> averageLandmarks = {};
    
    for (final entry in landmarkGroups.entries) {
      final type = entry.key;
      final landmarks = entry.value;
      
      if (landmarks.isEmpty) continue;

      double avgX = 0, avgY = 0, avgZ = 0, avgLikelihood = 0;
      
      for (final landmark in landmarks) {
        avgX += landmark.x;
        avgY += landmark.y;
        avgZ += landmark.z;
        avgLikelihood += landmark.likelihood;
      }

      final count = landmarks.length;
      averageLandmarks[type] = PoseLandmark(
        x: avgX / count,
        y: avgY / count,
        z: avgZ / count,
        type: type,
        likelihood: avgLikelihood / count,
      );
    }

    return Pose(landmarks: averageLandmarks);
  }

  void _startPoseDetectionStream() {
    if (widget.cameraController == null || !widget.cameraController!.value.isInitialized) {
      Log.d('启动动作检测流失败 widget.cameraController == null: ${widget.cameraController == null} !widget.cameraController!.value.isInitialized: ${!widget.cameraController!.value.isInitialized}', tag: 'analyzePose');
      return;
    }

    Log.d('启动动作检测流', tag: 'analyzePose');
    widget.cameraController!.startImageStream((CameraImage image) async {
      // 移除 _isDetecting 检查，让每一帧都处理
      // if (_isDetecting) return;
      // _isDetecting = true;

      try {
        final inputImage = _convertCameraImage(image);
        if (inputImage == null) return;

        final poses = await _poseDetector.processImage(inputImage);

        if (poses.isNotEmpty) {
          _currentPose = poses.first;
          _analyzePose(_currentPose!);
        } else {
          _currentPose = null;
        }

        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        Log.e('检测错误：$e', tag: 'Pose');
      } finally {
        // _isDetecting = false;
      }
    });
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = widget.cameraController?.description;
      Log.e('检测错误：${camera == null}', tag: 'camera');

      final sensorOrientation = camera?.sensorOrientation;

      InputImageRotation rotation;
      if (Platform.isIOS) {
        rotation = InputImageRotation.rotation90deg;
      } else {
        final isFrontCamera = camera?.lensDirection == CameraLensDirection.front;
        if (sensorOrientation == 90) {
          rotation = isFrontCamera ? InputImageRotation.rotation270deg : InputImageRotation.rotation90deg;
        } else if (sensorOrientation == 270) {
          rotation = isFrontCamera ? InputImageRotation.rotation90deg : InputImageRotation.rotation270deg;
        } else if (sensorOrientation == 0) {
          rotation = InputImageRotation.rotation0deg;
        } else {
          rotation = InputImageRotation.rotation180deg;
        }
      }

      InputImageFormat format;
      if (image.format.group == ImageFormatGroup.nv21) {
        format = InputImageFormat.nv21;
      } else {
        format = InputImageFormat.yuv_420_888;
      }

      final yPlane = image.planes[0];

      return InputImage.fromBytes(
        bytes: yPlane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: yPlane.bytesPerRow,
        ),
      );
    } catch (e) {
      Log.e('图像转换错误: $e', tag: 'Pose');
      return null;
    }
  }

  void _analyzePose(Pose pose) {
    if (!_isCalibrated) {
      _currentSuggestion = '请先完成校准';
      return;
    }

    // 检查序列是否已完成
    if (_isSequenceCompleted) {
      _currentSuggestion = '运动序列已完成！';
      return;
    }

    // DTW：仅对第1式（双手托天）使用模板比对
    final bool useDtw = _dtwReady && _sportSequenceManager.currentStep.actionType == '双手托天';
    if (useDtw) {
      final vec = _dtwMatcher.extractFeatureVector(pose);
      _checkResults = {};

      if (vec != null) {
        final leftWristRelYUp = vec[2];
        final rightWristRelYUp = vec[3];
        final shoulderYDiff = vec[4];
        final torsoCenterX = vec[5];

        // 轨迹检测：不用肘角，改用“手腕相对鼻子高度足够高”来近似判断伸展到位。
        _checkResults['手臂伸展'] = leftWristRelYUp > 0.05 && rightWristRelYUp > 0.05;
        _checkResults['腰背挺直'] = shoulderYDiff < 0.02;
        // 呼吸自然无法单帧可靠判断，这里用躯干稳定性做近似
        _checkResults['呼吸自然'] = torsoCenterX < 0.05;
      }

      // 在线匹配：出现足够匹配的片段就判定完成（不会再返回“不通过”）
      final dtwResult = _dtwMatcher.updateOnline(pose);
      // 没进入在线评估前，不展示 lastSimilarity，避免“没开始动作相似度就跳起来”
      final sim = _dtwMatcher.isOnlineStarted ? (_dtwMatcher.lastSimilarity ?? 0.0) : 0.0;
      _poseAccuracy = sim;
      _isActionCompleted = false;

      if (dtwResult != null) {
        _poseAccuracy = dtwResult.similarity;
        _isActionCompleted = dtwResult.passed;
        _currentSuggestion = '通过！相似度: ${dtwResult.similarity.toStringAsFixed(0)}%';

        if (dtwResult.passed) {
          Future.delayed(const Duration(seconds: 1), () {
            _nextActionStep();
          });
        }
      } else {
        _currentSuggestion = '匹配中... 相似度: ${sim.toStringAsFixed(0)}%';
      }

      Log.d('DTW: ready=$_dtwReady completed=$_isActionCompleted acc=$_poseAccuracy', tag: 'DTW');
      return;
    }

    // 使用新的动作分析系统（非第1式）
    // 先尽早检测“开始点”，便于在做错后可以重置并重新采集起点/终点。
    _sportSequenceManager.detectActionStart(pose);

    final result = _actionAnalyzer.analyzeAction(
      pose,
      _sportSequenceManager.currentStep.actionType,
      _userProfile,
    );

    _poseAccuracy = result.similarity * 100;
    
    // 分析轨迹是否完成当前动作
    _isActionCompleted = _sportSequenceManager.analyzeTrajectory(pose, result);

    // 如果动作偏差较大（准确度持续较低），且已经检测到开始点，则重置当前 step 的点集并重新检测
    final hasDetectedStart = _sportSequenceManager.startLandmarks != null;
    final bool shouldRetry = !_isActionCompleted &&
        hasDetectedStart &&
        _poseAccuracy < 50;

    if (shouldRetry) {
      _lowAccuracyStreak++;
      final now = DateTime.now();
      final cooldownOk = _lastRetryTime == null || now.difference(_lastRetryTime!) >= _retryCooldown;

      if (_lowAccuracyStreak >= _lowAccuracyFramesToRetry && cooldownOk) {
        _sportSequenceManager.retryCurrentStep();
        _lastRetryTime = now;
        _lowAccuracyStreak = 0;

        setState(() {
          _isActionCompleted = false;
          _currentSuggestion = '动作偏差较大，已重置，请重新开始 ${_sportSequenceManager.currentStep.name}';
        });
        return; // 退出，避免下面的默认建议覆盖本次“重置”提示
      }
    } else {
      _lowAccuracyStreak = 0;
    }

    // 更新检查结果
    _checkResults = {};
    if (result.angles.isNotEmpty) {
      // 根据角度结果更新检查项
      if (result.angles.containsKey('leftElbow') && result.angles.containsKey('rightElbow')) {
        final leftElbowAngle = result.angles['leftElbow']!;
        final rightElbowAngle = result.angles['rightElbow']!;
        _checkResults['手臂伸展'] = leftElbowAngle > 160 && rightElbowAngle > 160;
      }

      if (result.angles.containsKey('leftKnee') && result.angles.containsKey('rightKnee')) {
        final leftKneeAngle = result.angles['leftKnee']!;
        final rightKneeAngle = result.angles['rightKnee']!;
        _checkResults['双腿伸直'] = leftKneeAngle > 160 && rightKneeAngle > 160;
      }
    }

    // 更新建议
    if (_isActionCompleted) {
      _currentSuggestion = '动作完成！准备进入下一步...';
      // 延迟一秒后进入下一步
      Future.delayed(const Duration(seconds: 1), () {
        _nextActionStep();
      });
    } else if (_poseAccuracy >= 80) {
      _currentSuggestion = '姿势标准，继续保持！';
    } else if (_poseAccuracy >= 50) {
      _currentSuggestion = '姿势基本正确，可适当调整';
    } else {
      _currentSuggestion = '请调整姿势，按提示纠正';
    }

    Log.d('检查项: $_checkResults', tag: 'analyzePose');
    Log.d('准确度: ${_poseAccuracy.toStringAsFixed(1)}%', tag: 'analyzePose');
    Log.d('提示: $_currentSuggestion', tag: 'analyzePose');
    Log.d('当前动作: ${_sportSequenceManager.currentStep.name} (${_sportSequenceManager.currentStepIndex}/${_sportSequenceManager.totalSteps})', tag: 'analyzePose');
  }

  // 进入下一步动作
  void _nextActionStep() {
    if (!mounted) return;
    
    final hasNextStep = _sportSequenceManager.nextStep();
    
    if (hasNextStep) {
      setState(() {
        _isActionCompleted = false;
        _currentSuggestion = '请开始 ${_sportSequenceManager.currentStep.name}';
      });
      Log.d('进入下一步: ${_sportSequenceManager.currentStep.name}', tag: 'Sequence');
    } else {
      setState(() {
        _isSequenceCompleted = true;
        _currentSuggestion = '恭喜！运动序列已完成！';
      });
      Log.d('运动序列完成', tag: 'Sequence');
      if(!_isShowDialog) {
        _showCompletionDialog();
      }
    }
  }

  // 显示完成对话框
  void _showCompletionDialog() {
    _isShowDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('运动完成'),
        content: Text(
          '恭喜您完成了${widget.sportType}的所有动作！\n\n' 
          '完成动作数: ${_sportSequenceManager.totalSteps}\n' 
          '坚持练习，有益健康！',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭对话框
              Navigator.of(context).pop(); // 弹出当前纠错页
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.cameraController?.stopImageStream();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取当前动作步骤
    final currentStep = _sportSequenceManager.currentStep;
    final stepProgress = _sportSequenceManager.currentStepIndex / _sportSequenceManager.totalSteps;
    
    String actionName = currentStep.name;
    List<String> checkItems = currentStep.checkItems;
    String suggestion = _currentSuggestion.isNotEmpty ? _currentSuggestion : '请站到画面中央，准备开始 ${currentStep.name}';

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7),
      body: SafeArea(child: Stack(
        children: [
          // 相机背景
          if (widget.cameraController != null && widget.cameraController!.value.isInitialized)
            Positioned.fill(
              child: ClipRRect(
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: widget.cameraController!.value.previewSize!.height,
                      height: widget.cameraController!.value.previewSize!.width,
                      child: Stack(
                        children: [
                          CameraPreview(widget.cameraController!),
                          if (_currentPose != null)
                            Positioned.fill(
                              child: CustomPaint(
                                painter: PoseLandmarkPainter(
                                  pose: _currentPose,
                                  previewSize: widget.cameraController!.value.previewSize!,
                                  cameraLensDirection: widget.cameraController!.description.lensDirection,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Positioned.fill(child: Container(color: Colors.black)),
          
          // 校准状态覆盖层
          if (_isCalibrating)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 30),
                    Text(
                      _calibrationMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '请保持姿势稳定...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // 校准失败提示
          if (!_isCalibrating && !_isCalibrated && _calibrationMessage.isNotEmpty)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _calibrationMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _startCalibration,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3C9566),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('重新校准'),
                    ),
                  ],
                ),
              ),
            ),
          
          // UI 层
          if (_isCalibrated)
            Column(
              children: [
                _buildTopInfo(context, actionName, stepProgress),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showBottomSheet(context, actionName, checkItems, suggestion),
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '姿态准确度',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E2939),
                              ),
                            ),
                            Text(
                              '${_poseAccuracy.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: _isActionCompleted ? const Color(0xFF3C9566) : const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          suggestion,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      )),
    );
  }

  void _showBottomSheet(BuildContext context, String actionName, List<String> checkItems, String suggestion) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => SafeArea(child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: _buildCorrectionPanel(
            context,
            actionName,
            checkItems,
            _currentSuggestion,
            _poseAccuracy,
            _checkResults,
          ),
        )),
      ),
    );
  }

  Widget _buildTopInfo(BuildContext context, String actionName, double stepProgress) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                actionName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'STKaiti',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${_sportSequenceManager.currentStepIndex}/${_sportSequenceManager.totalSteps}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 120,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: stepProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF3C9566),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${(_sportSequenceManager.currentStepIndex / _sportSequenceManager.totalSteps * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionPanel(
      BuildContext context,
      String actionName,
      List<String> checkItems,
      String currentSuggestion,
      double poseAccuracy,
      Map<String, bool> checkResults,
      ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF3C9566), size: 20),
                  SizedBox(width: 8),
                  Text(
                    '姿态准确度',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2939),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                ],
              ),
              Text(
                '${poseAccuracy.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3C9566),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    currentSuggestion,
                    style: const TextStyle(
                      color: Color(0xFF92400E),
                      fontSize: 14,
                      fontFamily: 'STKaiti',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            actionName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2939),
              fontFamily: 'STKaiti',
            ),
          ),
          const SizedBox(height: 12),
          ...checkItems.asMap().entries.map((entry) {
            final isChecked = checkResults[entry.value] ?? false;
            return _checkItem(entry.value, isChecked);
          }),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // 返回到运动主页，即弹出纠错页和准备页
                Navigator.of(context).pop(); // 弹出当前纠错页
                Navigator.of(context).pop(); // 弹出准备页，回到主页
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3C9566),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '结束练习',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'STKaiti',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkItem(String text, bool checked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: checked ? const Color(0xFF3C9566) : Colors.black12,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: checked ? const Color(0xFF1E2939) : Colors.black38,
              fontFamily: 'STKaiti',
            ),
          ),
        ],
      ),
    );
  }
}