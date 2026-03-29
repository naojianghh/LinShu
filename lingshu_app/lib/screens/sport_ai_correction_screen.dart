
import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_player/video_player.dart';

import '../models/user_calibration.dart';
import '../services/dtw_pose_matcher.dart';
import '../services/pose_analyse.dart';
import '../utils/log_util.dart';
//import '../utils/pose_landmark_painter.dart';

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
  late VideoPlayerController _demoVideoController;
  bool _isDemoVideoReady = false;
  String? _demoVideoError;

  Pose? _currentPose;
  double _poseAccuracy = 0.0;
  Map<String, bool> _checkResults = {};
  String _currentSuggestion = '';

  // 用户校准和动作分析相关
  late UserCalibration _userCalibration;
  // late ActionAnalyzer _actionAnalyzer;
  // late UserProfile _userProfile;
  bool _isCalibrating = false;
  bool _isCalibrated = false;
  bool _isActionCompleted = false;
  String _calibrationMessage = '';

  // 运动序列管理
  late SportSequenceManager _sportSequenceManager;
  bool _isSequenceCompleted = false;

  // camera 图像流控制：用“会话 token”解决校准/检测切换时的竞态，
  // 用“并发闸门”解决每帧 processImage 的重入与结果乱序。
  bool _disposed = false;
  int _streamSessionId = 0; // 每次开始一段流会话就递增
  bool _isPoseStreamRunning = false;
  bool _isProcessingFrame = false;

  /// 演示视频异步加载序号，避免快速切换「第N式」时旧请求覆盖新状态。
  int _demoVideoLoadGeneration = 0;

  // DTW（第1式 + 第2式左/右）比对
  late final DtwPoseMatcher _dtwMatcherStep1;
  late final DtwPoseMatcher _dtwMatcherStep2Left;
  late final DtwPoseMatcher _dtwMatcherStep2Right;
  late final DtwPoseMatcher _dtwMatcherStep3Left;
  late final DtwPoseMatcher _dtwMatcherStep3Right;
  late final DtwPoseMatcher _dtwMatcherStep4Left;
  late final DtwPoseMatcher _dtwMatcherStep4Right;
  bool _dtwReadyStep1 = false;
  bool _dtwReadyStep2Left = false;
  bool _dtwReadyStep2Right = false;
  bool _dtwReadyStep3Left = false;
  bool _dtwReadyStep3Right = false;
  bool _dtwReadyStep4Left = false;
  bool _dtwReadyStep4Right = false;

  // // 当前 step 纠错：连续低准确度触发重置
  // int _lowAccuracyStreak = 0;
  // static const int _lowAccuracyFramesToRetry = 15; // 约半秒左右（取决于帧率）
  // DateTime? _lastRetryTime;
  // static const Duration _retryCooldown = Duration(seconds: 2);

  /// 为 true 时关闭 DTW「低位武装 + 起势」门控，特征有效即在线算相似度（更易误报，仅调试用）。
  static const bool _kDtwDirectOnlineNoStartGate = false;

  void _applyDtwOnlineStartGatePreference() {
    if (!_kDtwDirectOnlineNoStartGate) return;
    _dtwMatcherStep1.setOnlineUseStartGating(false);
    _dtwMatcherStep2Left.setOnlineUseStartGating(false);
    _dtwMatcherStep2Right.setOnlineUseStartGating(false);
    _dtwMatcherStep3Left.setOnlineUseStartGating(false);
    _dtwMatcherStep3Right.setOnlineUseStartGating(false);
    _dtwMatcherStep4Left.setOnlineUseStartGating(false);
    _dtwMatcherStep4Right.setOnlineUseStartGating(false);
  }

  @override
  void initState() {
    super.initState();

    _initializeCalibrationSystem();
    unawaited(_reloadDemoVideoForCurrentGuideTab());
    _initDetector();

    _dtwMatcherStep1 = DtwPoseMatcher();
    _dtwMatcherStep2Left = DtwPoseMatcher();
    _dtwMatcherStep2Right = DtwPoseMatcher();
    _dtwMatcherStep3Left = DtwPoseMatcher();
    _dtwMatcherStep3Right = DtwPoseMatcher();
    _dtwMatcherStep4Left = DtwPoseMatcher();
    _dtwMatcherStep4Right = DtwPoseMatcher();
    _dtwMatcherStep1.setFeatureMode(DtwFeatureMode.keypoints6);
    _dtwMatcherStep2Left.setFeatureMode(DtwFeatureMode.keypoints6);
    _dtwMatcherStep2Right.setFeatureMode(DtwFeatureMode.keypoints6);
    _dtwMatcherStep3Left.setFeatureMode(DtwFeatureMode.keypoints6);
    _dtwMatcherStep3Right.setFeatureMode(DtwFeatureMode.keypoints6);
    _dtwMatcherStep4Left.setFeatureMode(DtwFeatureMode.keypoints6);
    _dtwMatcherStep4Right.setFeatureMode(DtwFeatureMode.keypoints6);
    _applyDtwOnlineStartGatePreference();
    _initDtwTemplates();
  }

  Future<void> _initDtwTemplates() async {
    try {
      await _dtwMatcherStep1.loadTemplateFromAsset(
        assetPath: 'assets/template/baduanjin_step1_dtw_template.json',
      );
      await _dtwMatcherStep2Left.loadTemplateFromAsset(
        assetPath: 'assets/template/baduanjin_step2_left_dtw_template.json',
      );
      await _dtwMatcherStep2Right.loadTemplateFromAsset(
        assetPath: 'assets/template/baduanjin_step2_right_dtw_template.json',
      );
      await _dtwMatcherStep3Left.loadTemplateFromAsset(
        assetPath: 'assets/template/baduanjin_step3_left_dtw_template.json',
      );
      await _dtwMatcherStep3Right.loadTemplateFromAsset(
        assetPath: 'assets/template/baduanjin_step3_right_dtw_template.json',
      );
      await _dtwMatcherStep4Left.loadTemplateFromAsset(
        assetPath: 'assets/template/baduanjin_step4_left_dtw_template.json',
      );
      await _dtwMatcherStep4Right.loadTemplateFromAsset(
        assetPath: 'assets/template/baduanjin_step4_right_dtw_template.json',
      );
      if (mounted) {
        setState(() {
          _dtwReadyStep1 = true;
          _dtwReadyStep2Left = true;
          _dtwReadyStep2Right = true;
          _dtwReadyStep3Left = true;
          _dtwReadyStep3Right = true;
          _dtwReadyStep4Left = true;
          _dtwReadyStep4Right = true;
        });
      }
      Log.d('DTW 模板加载成功: step1 + step2_left + step2_right + step3 + step4', tag: 'DTW');
    } catch (e) {
      Log.e('DTW 模板加载失败: $e', tag: 'DTW');
    }
  }

  void _initializeCalibrationSystem() {
    // 初始化用户资料（实际应用中可以从存储或用户输入获取）
    // _userProfile = UserProfile(
    //   height: 170, // 默认身高170cm
    //   armSpan: 170, // 默认臂展170cm
    //   gender: 'male',
    // );

    // 初始化校准和分析器
    _userCalibration = UserCalibration();
    //final thresholdManager = DynamicThresholdManager();
    //_actionAnalyzer = ActionAnalyzer(_userCalibration, thresholdManager);

    // 初始化运动序列管理器
    _sportSequenceManager = _createSportSequenceManager();
    // 设置校准系统
    //_sportSequenceManager.setUserCalibration(_userCalibration);

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
            name: '调理脾胃须单举-左',
            actionType: '调理脾胃-左',
            checkItems: ['单臂上举', '另一臂下按', '意念脾胃'],
            description: '左手心向上托举，右手心向下按，左右交替',
          ),
          ActionStep(
            name: '调理脾胃须单举-右',
            actionType: '调理脾胃-右',
            checkItems: ['单臂上举', '另一臂下按', '意念脾胃'],
            description: '左手心向上托举，右手心向下按，左右交替',
          ),
          ActionStep(
            name: '摇头摆尾去心火-左',
            actionType: '摇头摆尾-左',
            checkItems: ['马步下蹲', '摇头摆尾', '呼吸协调'],
            description: '马步下蹲，上体前倾，左右摇头摆尾',
          ),
          ActionStep(
            name: '摇头摆尾去心火-右',
            actionType: '摇头摆尾-右',
            checkItems: ['马步下蹲', '摇头摆尾', '呼吸协调'],
            description: '马步下蹲，上体前倾，左右摇头摆尾',
          ),
          ActionStep(
            name: '左右开弓似射雕-左',
            actionType: '左右开弓-左',
            checkItems: ['马步稳健', '手臂伸展', '转腰拧胯'],
            description: '左式：左脚向左开步，成马步，双手拉弓如射雕状',
          ),
          ActionStep(
            name: '左右开弓似射雕-右',
            actionType: '左右开弓-右',
            checkItems: ['马步稳健', '手臂伸展', '转腰拧胯'],
            description: '右式：与左式方向相反，完成另一侧开弓',
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
          ),
        ],previewSize: widget.cameraController!.value.previewSize!);
    }
  }

  void _initDetector() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );
  }

  void _stopCameraImageStream() {
    if (_disposed) return;
    if (!_isPoseStreamRunning) return;
    try {
      widget.cameraController?.stopImageStream();
    } catch (_) {}
    _isPoseStreamRunning = false;
  }

  void _startCalibration() {
    if (_disposed) return;

    // 新开启一次校准会话：让任何旧的回调全部失效
    _streamSessionId++;
    final sessionId = _streamSessionId;

    // 避免“实时检测流”和“校准流”重复 startImageStream
    _stopCameraImageStream();

    if (mounted) {
      setState(() {
        _isCalibrating = true;
        _isCalibrated = false;
        _calibrationMessage = '请自然站立，双脚与肩同宽，双臂自然下垂';
      });
    }

    // 延迟3秒后捕获校准姿势（带会话 token 校验）
    Future.delayed(const Duration(seconds: 3), () {
      if (_disposed || !mounted || sessionId != _streamSessionId) return;
      _captureCalibrationPose(sessionId);
    });
  }

  // 捕获校准姿势
  Future<void> _captureCalibrationPose(int sessionId) async {
    try {
      if (_disposed || !mounted || sessionId != _streamSessionId) return;

      if (widget.cameraController == null || !widget.cameraController!.value.isInitialized) {
        if (mounted && sessionId == _streamSessionId) {
          setState(() {
            _calibrationMessage = '相机未初始化，无法校准';
            _isCalibrating = false;
          });
        }
        return;
      }

      // 再次停止流，确保只存在一个 imageStream
      _stopCameraImageStream();

      // 开始3秒倒计时
      for (int i = 3; i > 0; i--) {
        if (_disposed || sessionId != _streamSessionId) return;
        if (mounted) {
          setState(() {
            _calibrationMessage = '请保持姿势稳定\n$i';
          });
        }
        await Future.delayed(const Duration(seconds: 1));
      }

      // 倒计时结束，开始捕获后三帧
      if (_disposed || sessionId != _streamSessionId) return;
      if (mounted) {
        setState(() {
          _calibrationMessage = '正在捕获姿势...';
        });
      }

      // 从相机流中获取后三帧用于校准
      List<Pose> capturedPoses = [];
      bool captureCompleted = false;
      
      _isPoseStreamRunning = true;
      await widget.cameraController!.startImageStream((CameraImage image) async {
        // 只允许当前会话的流回调生效
        if (_disposed || sessionId != _streamSessionId) {
          _stopCameraImageStream();
          return;
        }

        if (captureCompleted || capturedPoses.length >= 3) {
          _stopCameraImageStream();
          return;
        }
        
        try {
          final inputImage = _convertCameraImage(image);
          if (inputImage != null) {
            final poses = await _poseDetector.processImage(inputImage);
            // processImage 可能较慢：await 之后再校验一次会话/生命周期
            if (_disposed || sessionId != _streamSessionId || !mounted) return;
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
                if (mounted && sessionId == _streamSessionId) {
                  setState(() {
                    _isCalibrating = false;
                    _isCalibrated = true;
                    _calibrationMessage = '校准完成！';
                  });
                }

                // 校准完成后停止当前流并启动实时分析（同一会话 token）
                _stopCameraImageStream();
                if (!_disposed && mounted && sessionId == _streamSessionId) {
                  _startPoseDetectionStream(sessionId);
                }
              }
            }
          }
        } catch (e) {
          Log.e('校准错误: $e', tag: 'Calibration');
        }
      });

      // 超时处理
      Future.delayed(const Duration(seconds: 10), () {
        if (_disposed || !mounted || sessionId != _streamSessionId) return;
        if (!captureCompleted) {
          setState(() {
            _calibrationMessage = '校准超时，请重试';
            _isCalibrating = false;
          });
          _stopCameraImageStream();
        }
      });
    } catch (e) {
      if (mounted && sessionId == _streamSessionId) {
        setState(() {
          _calibrationMessage = '校准失败，请重试';
          _isCalibrating = false;
        });
      }
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

  void _startPoseDetectionStream(int sessionId) {
    if (widget.cameraController == null || !widget.cameraController!.value.isInitialized) {
      Log.d('启动动作检测流失败 widget.cameraController == null: ${widget.cameraController == null} !widget.cameraController!.value.isInitialized: ${!widget.cameraController!.value.isInitialized}', tag: 'analyzePose');
      return;
    }

    // 避免重复启动
    if (_isPoseStreamRunning) return;

    _isPoseStreamRunning = true;

    Log.d('启动动作检测流', tag: 'analyzePose');
    widget.cameraController!.startImageStream((CameraImage image) async {
      if (_disposed || sessionId != _streamSessionId) {
        _stopCameraImageStream();
        return;
      }
      if (!mounted) return;

      // 并发闸门：同一时刻只处理一帧，避免 processImage 重入导致结果乱序
      if (_isProcessingFrame) return;
      _isProcessingFrame = true;

      try {
        final inputImage = _convertCameraImage(image);
        if (inputImage == null) return;

        final poses = await _poseDetector.processImage(inputImage);

        if (_disposed || sessionId != _streamSessionId || !mounted) return;

        if (poses.isNotEmpty) {
          _currentPose = poses.first;
          _analyzePose(_currentPose!);
        } else {
          _currentPose = null;
        }

        if (mounted && sessionId == _streamSessionId) setState(() {});
      } catch (e) {
        Log.e('检测错误：$e', tag: 'Pose');
      } finally {
        _isProcessingFrame = false;
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

    // DTW：第1式 + 第2式左/右 + 第3式 + 第4式都走模板比对
    final actionType = _sportSequenceManager.currentStep.actionType;
    final bool useDtwStep1 = _dtwReadyStep1 && actionType == '双手托天';
    final bool useDtwStep2Left = _dtwReadyStep2Left && actionType == '左右开弓-左';
    final bool useDtwStep2Right = _dtwReadyStep2Right && actionType == '左右开弓-右';
    final bool useDtwStep3Left = _dtwReadyStep3Left && actionType == '调理脾胃-左';
    final bool useDtwStep3Right = _dtwReadyStep3Right && actionType == '调理脾胃-右';
    final bool useDtwStep4Left = _dtwReadyStep4Left && actionType == '摇头摆尾-左';
    final bool useDtwStep4Right = _dtwReadyStep4Right && actionType == '摇头摆尾-右';
    final bool useDtw = true;
    if (useDtw) {
      final activeMatcher = useDtwStep1
          ? _dtwMatcherStep1
          : (useDtwStep2Left
              ? _dtwMatcherStep2Left
              : (useDtwStep2Right
                  ? _dtwMatcherStep2Right
                  : (useDtwStep3Left
                    ? _dtwMatcherStep3Left
                    : (useDtwStep3Right
                      ? _dtwMatcherStep3Right
                      : (useDtwStep4Left
                        ? _dtwMatcherStep4Left : _dtwMatcherStep4Right)))));
      activeMatcher.setActionType(actionType);
      final vec = activeMatcher.extractFeatureVector(pose);
      _checkResults = {};

      if (vec != null && useDtwStep1) {
        // 第一式保留原有显示语义
        _checkResults['手臂伸展'] = true;
        _checkResults['腰背挺直'] = true;
        _checkResults['呼吸自然'] = true;
      } else if (vec != null && (useDtwStep2Left || useDtwStep2Right)) {
        // 第二式改为 DTW 主判定；逐项提示先给稳定占位
        _checkResults['马步稳健'] = true;
        _checkResults['手臂伸展'] = true;
        _checkResults['转腰拧胯'] = true;
      } else if (vec != null && useDtwStep3Right || useDtwStep3Left) {
        // 第三式改为 DTW 主判定；逐项提示先给稳定占位
        _checkResults['单臂上举'] = true;
        _checkResults['另一臂下按'] = true;
        _checkResults['意念脾胃'] = true;
      } else if (vec != null && useDtwStep4Left || useDtwStep4Right) {
        // 第四式改为 DTW 主判定；逐项提示先给稳定占位
        _checkResults['马步下蹲'] = true;
        _checkResults['摇头摆尾'] = true;
        _checkResults['呼吸协调'] = true;
      }

      // 在线匹配：出现足够匹配的片段就判定完成（不会再返回“不通过”）
      final dtwResult = activeMatcher.updateOnline(pose);
      // 没进入在线评估前，不展示 lastSimilarity，避免“没开始动作相似度就跳起来”
      final sim = activeMatcher.isOnlineStarted ? (activeMatcher.lastSimilarity ?? 0.0) : 0.0;
      _poseAccuracy = sim;
      _isActionCompleted = false;

      if (dtwResult != null) {
        _poseAccuracy = dtwResult.similarity;
        _isActionCompleted = dtwResult.passed;
        _currentSuggestion = '通过！相似度: ${dtwResult.similarity.toStringAsFixed(0)}%';

        if (dtwResult.passed) {
          // 不自动进入下一步：由用户在下方「第N式」标签手动切换
          _currentSuggestion =
              '本式已通过！请手动切换下方「第1式」～「第4式」标签继续练习。';
        }
      } else {
        _currentSuggestion = '匹配中... 相似度: ${sim.toStringAsFixed(0)}%';
      }

      Log.d(
        'DTW: action=$actionType ready1=$_dtwReadyStep1 ready2L=$_dtwReadyStep2Left ready2R=$_dtwReadyStep2Right ready3L=$_dtwReadyStep3Left ready3R=$_dtwReadyStep3Right ready4L=$_dtwReadyStep4Left ready4R=$_dtwReadyStep4Right '
        'completed=$_isActionCompleted acc=$_poseAccuracy',
        tag: 'DTW',
      );
      return;
    }

    // // 使用新的动作分析系统（非第1式）
    // // 先尽早检测“开始点”，便于在做错后可以重置并重新采集起点/终点。
    // _sportSequenceManager.detectActionStart(pose);
    //
    // final result = _actionAnalyzer.analyzeAction(
    //   pose,
    //   _sportSequenceManager.currentStep.actionType,
    //   _userProfile,
    // );
    //
    // _poseAccuracy = result.similarity * 100;
    //
    // // 分析轨迹是否完成当前动作
    // _isActionCompleted = _sportSequenceManager.analyzeTrajectory(pose, result);
    //
    // // 如果动作偏差较大（准确度持续较低），且已经检测到开始点，则重置当前 step 的点集并重新检测
    // final hasDetectedStart = _sportSequenceManager.startLandmarks != null;
    // final bool shouldRetry = !_isActionCompleted &&
    //     hasDetectedStart &&
    //     _poseAccuracy < 50;
    //
    // if (shouldRetry) {
    //   _lowAccuracyStreak++;
    //   final now = DateTime.now();
    //   final cooldownOk = _lastRetryTime == null || now.difference(_lastRetryTime!) >= _retryCooldown;
    //
    //   if (_lowAccuracyStreak >= _lowAccuracyFramesToRetry && cooldownOk) {
    //     _sportSequenceManager.retryCurrentStep();
    //     _lastRetryTime = now;
    //     _lowAccuracyStreak = 0;
    //
    //     setState(() {
    //       _isActionCompleted = false;
    //       _currentSuggestion = '动作偏差较大，已重置，请重新开始 ${_sportSequenceManager.currentStep.name}';
    //     });
    //     return; // 退出，避免下面的默认建议覆盖本次“重置”提示
    //   }
    // } else {
    //   _lowAccuracyStreak = 0;
    // }
    //
    // // 更新检查结果
    // _checkResults = {};
    // if (result.angles.isNotEmpty) {
    //   // 根据角度结果更新检查项
    //   if (result.angles.containsKey('leftElbow') && result.angles.containsKey('rightElbow')) {
    //     final leftElbowAngle = result.angles['leftElbow']!;
    //     final rightElbowAngle = result.angles['rightElbow']!;
    //     _checkResults['手臂伸展'] = leftElbowAngle > 160 && rightElbowAngle > 160;
    //   }
    //
    //   if (result.angles.containsKey('leftKnee') && result.angles.containsKey('rightKnee')) {
    //     final leftKneeAngle = result.angles['leftKnee']!;
    //     final rightKneeAngle = result.angles['rightKnee']!;
    //     _checkResults['双腿伸直'] = leftKneeAngle > 160 && rightKneeAngle > 160;
    //   }
    // }
    //
    // // 更新建议
    // if (_isActionCompleted) {
    //   _currentSuggestion = '动作完成！准备进入下一步...';
    //   // 延迟一秒后进入下一步
    //   Future.delayed(const Duration(seconds: 1), () {
    //     _nextActionStep();
    //   });
    // } else if (_poseAccuracy >= 80) {
    //   _currentSuggestion = '姿势标准，继续保持！';
    // } else if (_poseAccuracy >= 50) {
    //   _currentSuggestion = '姿势基本正确，可适当调整';
    // } else {
    //   _currentSuggestion = '请调整姿势，按提示纠正';
    // }
    //
    // Log.d('检查项: $_checkResults', tag: 'analyzePose');
    // Log.d('准确度: ${_poseAccuracy.toStringAsFixed(1)}%', tag: 'analyzePose');
    // Log.d('提示: $_currentSuggestion', tag: 'analyzePose');
    // Log.d('当前动作: ${_sportSequenceManager.currentStep.name} (${_sportSequenceManager.currentStepIndex}/${_sportSequenceManager.totalSteps})', tag: 'analyzePose');
  }

  void _resetDtwMatchers() {
    _dtwMatcherStep1.resetRecording();
    _dtwMatcherStep2Left.resetRecording();
    _dtwMatcherStep2Right.resetRecording();
    _dtwMatcherStep3Left.resetRecording();
    _dtwMatcherStep3Right.resetRecording();
    _dtwMatcherStep4Left.resetRecording();
    _dtwMatcherStep4Right.resetRecording();
  }

  /// 与 UI「第1式～第4式」标签对应的序列下标（八段锦纠错页为 4 式演示，每式取左式作为当前识别步骤）。
  int _baduanjinGuideTabToSequenceIndex(int tabIndex) {
    const mapping = <int, int>{
      0: 0, // 两手托天理三焦 -> 双手托天
      1: 5, // 左右开弓似射雕 -> 左右开弓-左
      2: 1, // 调理脾胃须单举 -> 调理脾胃-左
      3: 3, // 与模板中「摇头摆尾」对应（演示为单式左）
    };
    return mapping[tabIndex] ?? 0;
  }

  void _onGuideTabSelected(int index) {
    if (widget.sportType == '八段锦') {
      _resetDtwMatchers();
      _sportSequenceManager.setStepIndex(_baduanjinGuideTabToSequenceIndex(index));
      setState(() {
        _selectedGuideTab = index;
        _isActionCompleted = false;
        _poseAccuracy = 0;
        _currentSuggestion = '请开始 ${_sportSequenceManager.currentStep.name}';
      });
      unawaited(_reloadDemoVideoForCurrentGuideTab());
    } else {
      setState(() => _selectedGuideTab = index);
    }
  }

  List<String> _demoVideoCandidatePaths() {
    if (widget.sportType == '太极拳') {
      return const [
        'assets/video/taiji_safe.mp4',
        'assets/video/taiji_480p.mp4',
        'assets/video/taiji.mp4',
      ];
    }
    if (widget.sportType == '八段锦') {
      return [
        'assets/video/baduanjin_sport_1.mp4',
        'assets/video/baduanjin_sport_2_all.mp4',
        'assets/video/baduanjin_sport_3_all.mp4',
        'aassets/video/baduanjin_sport_4_all.mp4',
      ];
    }
    return const ['assets/video/baduanjin_sport_2_all.mp4'];
  }

  Future<void> _reloadDemoVideoForCurrentGuideTab() async {
    final gen = ++_demoVideoLoadGeneration;
    final candidates = _demoVideoCandidatePaths();
    Object? lastError;

    final targetAsset = candidates[_selectedGuideTab];

    if (!mounted || gen != _demoVideoLoadGeneration) return;
    try {
      final controller = VideoPlayerController.asset(targetAsset);
      await controller.initialize();
      if (!mounted || gen != _demoVideoLoadGeneration) {
        await controller.dispose();
        return;
      }
      controller.setLooping(true);

      if (_isDemoVideoReady) {
        _demoVideoController.dispose();
      }
      _demoVideoController = controller;
      setState(() {
        _isDemoVideoReady = true;
        _demoVideoError = null;
      });
      Log.d('演示视频加载成功: $targetAsset', tag: 'DemoVideo');
      return;
    } catch (e) {
      lastError = e;
      Log.e('演示视频加载失败($targetAsset): $e', tag: 'DemoVideo');
    }

    if (!mounted || gen != _demoVideoLoadGeneration) return;
    setState(() {
      if (_isDemoVideoReady) {
        _demoVideoError = '切换分式演示视频失败，已沿用上一段';
      } else {
        _isDemoVideoReady = false;
        _demoVideoError = '视频加载失败，请检查 assets/video 下对应 mp4';
      }
    });
    Log.e('演示视频全部候选加载失败: $lastError', tag: 'DemoVideo');
  }

  @override
  void dispose() {
    _disposed = true;
    _streamSessionId++; // 使得任何挂起的延迟/回调全部失效
    _isProcessingFrame = false;
    _isPoseStreamRunning = false;
    if (_isDemoVideoReady) {
      _demoVideoController.dispose();
    }

    _stopCameraImageStream();
    _poseDetector.close(); // 释放 MLKit 资源
    super.dispose();
  }

  // @override
  // Widget build(BuildContext context) {
  //   // 获取当前动作步骤
  //   final currentStep = _sportSequenceManager.currentStep;
  //   final stepProgress = _sportSequenceManager.currentStepIndex / _sportSequenceManager.totalSteps;
  //
  //   String actionName = currentStep.name;
  //   List<String> checkItems = currentStep.checkItems;
  //   String suggestion = _currentSuggestion.isNotEmpty ? _currentSuggestion : '请站到画面中央，准备开始 ${currentStep.name}';
  //
  //   return Scaffold(
  //     backgroundColor: const Color(0xFFFDFCF7),
  //     body: SafeArea(child: Stack(
  //       children: [
  //         // 相机背景
  //         if (widget.cameraController != null && widget.cameraController!.value.isInitialized)
  //           Positioned.fill(
  //             child: ClipRRect(
  //               child: SizedBox(
  //                 width: double.infinity,
  //                 height: double.infinity,
  //                 child: FittedBox(
  //                   fit: BoxFit.cover,
  //                   child: SizedBox(
  //                     width: widget.cameraController!.value.previewSize!.height,
  //                     height: widget.cameraController!.value.previewSize!.width,
  //                     child: Stack(
  //                       children: [
  //                         CameraPreview(widget.cameraController!),
  //                         if (_currentPose != null)
  //                           Positioned.fill(
  //                             child: CustomPaint(
  //                               painter: PoseLandmarkPainter(
  //                                 pose: _currentPose,
  //                                 previewSize: widget.cameraController!.value.previewSize!,
  //                                 cameraLensDirection: widget.cameraController!.description.lensDirection,
  //                               ),
  //                             ),
  //                           ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           )
  //         else
  //           Positioned.fill(child: Container(color: Colors.black)),
  //
  //         // 校准状态覆盖层
  //         if (_isCalibrating)
  //           Positioned.fill(
  //             child: Container(
  //               color: Colors.black.withValues(alpha: 0.7),
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   const CircularProgressIndicator(color: Colors.white),
  //                   const SizedBox(height: 30),
  //                   Text(
  //                     _calibrationMessage,
  //                     style: const TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                     textAlign: TextAlign.center,
  //                   ),
  //                   const SizedBox(height: 20),
  //                   const Text(
  //                     '请保持姿势稳定...',
  //                     style: TextStyle(
  //                       color: Colors.white70,
  //                       fontSize: 14,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //
  //         // 校准失败提示
  //         if (!_isCalibrating && !_isCalibrated && _calibrationMessage.isNotEmpty)
  //           Positioned.fill(
  //             child: Container(
  //               color: Colors.black.withValues(alpha: 0.7),
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   const Icon(
  //                     Icons.error_outline,
  //                     color: Colors.red,
  //                     size: 60,
  //                   ),
  //                   const SizedBox(height: 20),
  //                   Text(
  //                     _calibrationMessage,
  //                     style: const TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 18,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                     textAlign: TextAlign.center,
  //                   ),
  //                   const SizedBox(height: 30),
  //                   ElevatedButton(
  //                     onPressed: _startCalibration,
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: const Color(0xFF3C9566),
  //                       foregroundColor: Colors.white,
  //                       padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
  //                       shape: RoundedRectangleBorder(
  //                         borderRadius: BorderRadius.circular(10),
  //                       ),
  //                     ),
  //                     child: const Text('重新校准'),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //
  //         // UI 层
  //         if (_isCalibrated)
  //           Column(
  //             children: [
  //               _buildTopInfo(context, actionName, stepProgress),
  //               const Spacer(),
  //               GestureDetector(
  //                 onTap: () => _showBottomSheet(context, actionName, checkItems, suggestion),
  //                 child: Container(
  //                   margin: const EdgeInsets.all(20),
  //                   padding: const EdgeInsets.all(20),
  //                   decoration: BoxDecoration(
  //                     color: Colors.white.withValues(alpha: 0.6),
  //                     borderRadius: BorderRadius.circular(24),
  //                   ),
  //                   child: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     children: [
  //                       Container(
  //                         width: 40,
  //                         height: 4,
  //                         decoration: BoxDecoration(
  //                           color: Colors.grey[300],
  //                           borderRadius: BorderRadius.circular(2),
  //                         ),
  //                       ),
  //                       const SizedBox(height: 16),
  //                       Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                         children: [
  //                           const Text(
  //                             '姿态准确度',
  //                             style: TextStyle(
  //                               fontSize: 16,
  //                               fontWeight: FontWeight.bold,
  //                               color: Color(0xFF1E2939),
  //                             ),
  //                           ),
  //                           Text(
  //                             '${_poseAccuracy.toStringAsFixed(0)}%',
  //                             style: TextStyle(
  //                               fontSize: 24,
  //                               fontWeight: FontWeight.bold,
  //                               color: _isActionCompleted ? const Color(0xFF3C9566) : const Color(0xFFF59E0B),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 8),
  //                       Text(
  //                         suggestion,
  //                         style: const TextStyle(
  //                           fontSize: 12,
  //                           color: Colors.grey,
  //                         ),
  //                         textAlign: TextAlign.center,
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //       ],
  //     )),
  //   );
  // }

  int _selectedGuideTab = 0;

  @override
  Widget build(BuildContext context) {
    String actionName = '双手托天理三焦';
    List<String> checkItems = ['手臂伸直', '目视手背', '腰背挺直'];
    String suggestion = _currentSuggestion.isNotEmpty
        ? _currentSuggestion
        : '注意保持腰背挺直，手臂伸展更充分';

    if (widget.sportType == '八段锦') {
      final baduanjinConfigs = _buildCorrectionBaduanjinActionConfigs();
      final currentIndex = _selectedGuideTab.clamp(
        0,
        baduanjinConfigs.length - 1,
      );
      final currentAction = baduanjinConfigs[currentIndex];
      actionName = currentAction['title'] as String;
      checkItems = currentAction['guides'] as List<String>;
    } else if (widget.sportType == '瑜伽') {
      actionName = '猫牛式伸展';
      checkItems = ['脊柱律动', '呼吸同步', '四肢支撑'];
      suggestion = _currentSuggestion.isNotEmpty
          ? _currentSuggestion
          : '保持呼吸平稳，脊柱自然延展';
    } else if (widget.sportType == '太极拳') {
      actionName = '左右野马分鬃';
      checkItems = ['虚实分明', '转腰带动', '气沉丹田'];
      suggestion = _currentSuggestion.isNotEmpty
          ? _currentSuggestion
          : '注意重心转换，保持身体稳定';
    }

    const progress = 0.13;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7),
      body: SafeArea(
        child: Column(
          children: [
            _buildCorrectionAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('智能运动纠错', 'AI实时姿态识别与纠正'),
                    const SizedBox(height: 20),
                    if (_isCalibrated) ...[
                      _buildProgressCard(actionName, progress),
                      const SizedBox(height: 24),
                      _buildDemoVideoSection(),
                      const SizedBox(height: 24),
                    ],
                    _buildAiPreviewCard(),
                    const SizedBox(height: 16),
                    if (_isCalibrated) ...[
                      _buildAccuracyCard(suggestion),
                      const SizedBox(height: 16),
                      _buildEndPracticeButton(context),
                      const SizedBox(height: 16),
                      _buildGuideCard(actionName, checkItems),
                      const SizedBox(height: 40),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Text(
                          _isCalibrating
                              ? '请面向上方相机框完成姿态校准。'
                              : '校准未完成：请查看相机框内提示，或点击「重新校准」。',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B5D4F),
                            fontFamily: 'STKaiti',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 仅覆盖相机预览区域：校准进行中
  Widget _buildCalibratingOverlayInCamera() {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _calibrationMessage,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            '请保持姿势稳定',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  /// 仅覆盖相机预览区域：校准失败 + 重新校准
  Widget _buildCalibrationFailedOverlayInCamera() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.redAccent,
            size: 36,
          ),
          const SizedBox(height: 8),
          Text(
            _calibrationMessage,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: _startCalibration,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3C9566),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                textStyle: const TextStyle(fontSize: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('重新校准'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String actionName, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFEFB), Color(0xFFFDFCF7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCC8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C9566).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  actionName,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF1E2939),
                    fontFamily: 'STKaiti',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromRGBO(239, 246, 255, 0.8),
                      Color.fromRGBO(219, 234, 254, 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFA4C4E8)),
                ),
                child: const Text(
                  '1/8',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1E40AF),
                    fontFamily: 'STKaiti',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B5D4F),
                fontFamily: 'STKaiti',
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F3ED),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFE8DCC8)),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4B896), Color(0xFFC9AA7D)],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFEFB), Color(0xFFFDFCF7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCC8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C9566).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 188,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(color: const Color(0xFF101828)),
              if (widget.cameraController != null &&
                  widget.cameraController!.value.isInitialized)
                Positioned.fill(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: widget.cameraController!.value.previewSize!.height,
                      height: widget.cameraController!.value.previewSize!.width,
                      child: CameraPreview(widget.cameraController!),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  color: const Color(0xFF0A1A3A).withValues(alpha: 0.45),
                ),
              ),
              SizedBox(
                width: 96,
                height: 192,
                child: Stack(
                  children: [
                    Positioned(top: 0, left: 44, child: _pointDot()),
                    Positioned(
                      top: 32,
                      left: 47,
                      child: Container(
                        width: 2,
                        height: 96,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                    Positioned(
                      top: 64,
                      left: 0,
                      child: Container(
                        width: 96,
                        height: 2,
                        color: const Color(0xFF22C55E),
                      ),
                    ),
                    Positioned(top: 60, left: 0, child: _pointDot()),
                    Positioned(top: 60, right: 0, child: _pointDot()),
                    Positioned(top: 60, left: 44, child: _pointDot()),
                    Positioned(bottom: 0, left: 32, child: _pointDot()),
                    Positioned(bottom: 0, right: 32, child: _pointDot()),
                  ],
                ),
              ),
              const Icon(
                Icons.photo_camera_outlined,
                color: Colors.white70,
                size: 52,
              ),
              if (_isCalibrated)
                const Positioned(
                  bottom: 34,
                  child: Text(
                    'AI正在识别姿态...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'STKaiti',
                    ),
                  ),
                ),
              if (_isCalibrating)
                Positioned.fill(
                  child: _buildCalibratingOverlayInCamera(),
                ),
              if (!_isCalibrating &&
                  !_isCalibrated &&
                  _calibrationMessage.isNotEmpty)
                Positioned.fill(
                  child: _buildCalibrationFailedOverlayInCamera(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pointDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFF22C55E),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildAccuracyCard(String suggestion) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(232, 245, 237, 0.4),
            Color.fromRGBO(240, 250, 244, 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4EAD9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.check, color: Color(0xFF3C9566), size: 20),
              const SizedBox(width: 8),
              const Text(
                '姿态准确度',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF1E2939),
                  fontFamily: 'STKaiti',
                ),
              ),
              const Spacer(),
              Text(
                '${_poseAccuracy.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 36,
                  color: Color(0xFF3C9566),
                  fontFamily: 'STKaiti',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_poseAccuracy / 100).clamp(0, 1),
            minHeight: 10,
            backgroundColor: const Color(0xFFE8F5ED),
            borderRadius: BorderRadius.circular(999),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3C9566)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFFB45309),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    suggestion,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF92400E),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEndPracticeButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFFFEFB),
          side: const BorderSide(color: Color(0xFFE8DCC8)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          '结束练习',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF2D4A3E),
            fontFamily: 'STKaiti',
          ),
        ),
      ),
    );
  }

  List<Map<String, Object>> _buildCorrectionBaduanjinActionConfigs() {
    return [
      {
        'title': '两手托天理三焦',
        'guides': ['两掌上托，手臂伸直', '掌心向上，目视手背', '腰背中正，呼吸均匀'],
      },
      {
        'title': '左右开弓似射雕',
        'guides': ['马步下沉，重心稳定', '一手推掌，一手拉弓', '目视前手指尖，沉肩坠肘'],
      },
      {
        'title': '调理脾胃须单举',
        'guides': ['一手上托，一手下按', '双掌上下对拉，力达指端', '脊柱中正，动作舒缓连贯'],
      },
      {
        'title': '五劳七伤往后瞧',
        'guides': ['头颈缓慢后转，幅度适中', '目随视线看后方', '双肩放松，躯干保持稳定'],
      },
    ];
  }

  Widget _buildGuideCard(String actionName, List<String> checkItems) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFEFB), Color(0xFFFDFCF7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCC8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C9566).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '动作要领',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF2D4A3E),
              fontFamily: 'STKaiti',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 128,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF3C9566),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFF5F3ED), Color(0xFFECEAE0)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8DCC8)),
            ),
            child: Row(
              children: List.generate(4, (index) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onGuideTabSelected(index),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedGuideTab == index
                            ? Colors.white
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: _selectedGuideTab == index
                            ? Border.all(color: const Color(0xFFD4EAD9))
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '第${index + 1}式',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedGuideTab == index
                                ? const Color(0xFF2D4A3E)
                                : const Color(0xFF6B5D4F),
                            fontFamily: 'STKaiti',
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            actionName,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF1E2939),
              fontFamily: 'STKaiti',
            ),
          ),
          const SizedBox(height: 10),
          ...checkItems.map(
                (item) => _checkItem(item, _checkResults[item] ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionAppBar(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: Color(0xFF8B7D6B),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '灵枢 · AI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'STXinwei',
                        ),
                      ),
                      Text(
                        '智能中医健康顾问',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF8B7D6B),
                          letterSpacing: 1.5,
                          fontFamily: 'STKaiti',
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: -50,
            child: Opacity(
              opacity: 0.65,
              child: Image.asset(
                'assets/images/header_plum.png',
                height: 100,
                fit: BoxFit.contain,
                alignment: Alignment.topRight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D4A3E),
            fontFamily: 'STKaiti',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B5D4F),
            fontFamily: 'STKaiti',
          ),
        ),
      ],
    );
  }

  Widget _buildDemoVideoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFEFB), Color(0xFFFDFCF7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCC8), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C9566).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '动作演示视频',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF2D4A3E),
              fontFamily: 'STKaiti',
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              if (!_isDemoVideoReady) return;
              setState(() {
                if (_demoVideoController.value.isPlaying) {
                  _demoVideoController.pause();
                } else {
                  _demoVideoController.play();
                }
              });
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                height: 180,
                color: Colors.black,
                child: _isDemoVideoReady
                    ? Stack(
                  fit: StackFit.expand,
                  children: [
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _demoVideoController.value.size.width,
                        height: _demoVideoController.value.size.height,
                        child: VideoPlayer(_demoVideoController),
                      ),
                    ),
                    if (!_demoVideoController.value.isPlaying)
                      Container(
                        color: Colors.black.withValues(alpha: 0.35),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  width: 1.1,
                                ),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '点击播放标准动作演示',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(
                                  alpha: 0.9,
                                ),
                                fontFamily: 'STKaiti',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                )
                    : Center(
                  child: _demoVideoError != null
                      ? Text(
                    _demoVideoError!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontFamily: 'STKaiti',
                    ),
                  )
                      : const CircularProgressIndicator(
                    color: Colors.white70,
                  ),
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

  // void _showBottomSheet(BuildContext context, String actionName, List<String> checkItems, String suggestion) {
  //   showModalBottomSheet(
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     isScrollControlled: true,
  //     isDismissible: true,
  //     enableDrag: true,
  //     barrierColor: Colors.black54,
  //     builder: (context) => StatefulBuilder(
  //       builder: (context, setState) => SafeArea(child: Container(
  //         decoration: const BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.only(
  //             topLeft: Radius.circular(32),
  //             topRight: Radius.circular(32),
  //           ),
  //         ),
  //         child: _buildCorrectionPanel(
  //           context,
  //           actionName,
  //           checkItems,
  //           _currentSuggestion,
  //           _poseAccuracy,
  //           _checkResults,
  //         ),
  //       )),
  //     ),
  //   );
  // }
  //
  // Widget _buildTopInfo(BuildContext context, String actionName, double stepProgress) {
  //   return Padding(
  //     padding: const EdgeInsets.all(20),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               actionName,
  //               style: const TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //                 fontFamily: 'STKaiti',
  //               ),
  //             ),
  //             const SizedBox(height: 4),
  //             Row(
  //               children: [
  //                 Text(
  //                   '${_sportSequenceManager.currentStepIndex}/${_sportSequenceManager.totalSteps}',
  //                   style: const TextStyle(color: Colors.white70, fontSize: 12),
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Container(
  //                   width: 120,
  //                   height: 4,
  //                   decoration: BoxDecoration(
  //                     color: Colors.white24,
  //                     borderRadius: BorderRadius.circular(2),
  //                   ),
  //                   child: FractionallySizedBox(
  //                     alignment: Alignment.centerLeft,
  //                     widthFactor: stepProgress,
  //                     child: Container(
  //                       decoration: BoxDecoration(
  //                         color: const Color(0xFF3C9566),
  //                         borderRadius: BorderRadius.circular(2),
  //                       ),
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //           decoration: BoxDecoration(
  //             color: Colors.white24,
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //           child: Text(
  //             '${(_sportSequenceManager.currentStepIndex / _sportSequenceManager.totalSteps * 100).toStringAsFixed(0)}%',
  //             style: const TextStyle(
  //               color: Colors.white,
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget _buildCorrectionPanel(
  //     BuildContext context,
  //     String actionName,
  //     List<String> checkItems,
  //     String currentSuggestion,
  //     double poseAccuracy,
  //     Map<String, bool> checkResults,
  //     ) {
  //   return Container(
  //     padding: const EdgeInsets.all(24),
  //     decoration: const BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.only(
  //         topLeft: Radius.circular(32),
  //         topRight: Radius.circular(32),
  //       ),
  //     ),
  //     child: Column(
  //       mainAxisSize: MainAxisSize.min,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             const Row(
  //               children: [
  //                 Icon(Icons.check_circle, color: Color(0xFF3C9566), size: 20),
  //                 SizedBox(width: 8),
  //                 Text(
  //                   '姿态准确度',
  //                   style: TextStyle(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold,
  //                     color: Color(0xFF1E2939),
  //                     fontFamily: 'STKaiti',
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             Text(
  //               '${poseAccuracy.toStringAsFixed(0)}%',
  //               style: const TextStyle(
  //                 fontSize: 24,
  //                 fontWeight: FontWeight.bold,
  //                 color: Color(0xFF3C9566),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Container(
  //           padding: const EdgeInsets.all(16),
  //           decoration: BoxDecoration(
  //             color: const Color(0xFFFFF9E6),
  //             borderRadius: BorderRadius.circular(16),
  //             border: Border.all(color: const Color(0xFFFDE68A)),
  //           ),
  //           child: Row(
  //             children: [
  //               const Icon(
  //                 Icons.info_outline,
  //                 color: Color(0xFFD97706),
  //                 size: 20,
  //               ),
  //               const SizedBox(width: 12),
  //               Expanded(
  //                 child: Text(
  //                   currentSuggestion,
  //                   style: const TextStyle(
  //                     color: Color(0xFF92400E),
  //                     fontSize: 14,
  //                     fontFamily: 'STKaiti',
  //                   ),
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(height: 24),
  //         Text(
  //           actionName,
  //           style: const TextStyle(
  //             fontSize: 18,
  //             fontWeight: FontWeight.bold,
  //             color: Color(0xFF1E2939),
  //             fontFamily: 'STKaiti',
  //           ),
  //         ),
  //         const SizedBox(height: 12),
  //         ...checkItems.asMap().entries.map((entry) {
  //           final isChecked = checkResults[entry.value] ?? false;
  //           return _checkItem(entry.value, isChecked);
  //         }),
  //         const SizedBox(height: 24),
  //         SizedBox(
  //           width: double.infinity,
  //           height: 50,
  //           child: ElevatedButton(
  //             onPressed: () {
  //               // 返回到运动主页，即弹出纠错页和准备页
  //               Navigator.of(context).pop(); // 弹出当前纠错页
  //               Navigator.of(context).pop(); // 弹出准备页，回到主页
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: const Color(0xFF3C9566),
  //               foregroundColor: Colors.white,
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //             ),
  //             child: const Text(
  //               '结束练习',
  //               style: TextStyle(
  //                 fontWeight: FontWeight.bold,
  //                 fontFamily: 'STKaiti',
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
}