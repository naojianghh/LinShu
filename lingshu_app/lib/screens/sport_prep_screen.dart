import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/log_util.dart';

class SportPrepScreen extends StatefulWidget {
  final String sportType;

  const SportPrepScreen({super.key, required this.sportType});

  @override
  State<SportPrepScreen> createState() => _SportPrepScreenState();
}

class _SportPrepScreenState extends State<SportPrepScreen> {
  int _selectedTab = 0;

  CameraController? _cameraController;
  CameraDescription? _selectedCamera;
  late PoseDetector _poseDetector;
  bool _isDetecting = false;
  List<CameraDescription>? _cameras;
  bool hasInit = false;

  int count = 0;

  @override
  void initState() {
    super.initState();
    _initDetectorAndCamera();
  }

  Future<void> _initDetectorAndCamera() async {
    try {
      Log.d('1. 检查相机权限', tag: 'Camera');
      final status = await Permission.camera.request();
      if (status.isGranted) {
        Log.d('相机权限已授予', tag: 'Camera');
      } else {
        Log.d('相机权限被拒绝', tag: 'Camera');
        if (mounted) setState(() {});
        return;
      }

      Log.d('2. 初始化姿势检测器', tag: 'Camera');
      _poseDetector = PoseDetector(
        options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
      );

      Log.d('3. 获取相机列表', tag: 'Camera');
      _cameras = await availableCameras();

      Log.d('条件判断：${_cameras != null && _cameras!.isNotEmpty}', tag: 'Camera');
      if (_cameras != null && _cameras!.isNotEmpty) {
        // 查找前置摄像头
        CameraDescription? frontCamera;
        for (final camera in _cameras!) {
          if (camera.lensDirection == CameraLensDirection.front) {
            frontCamera = camera;
            break;
          }
        }
        // 如果没有前置摄像头，使用第一个摄像头
        final selectedCamera = frontCamera ?? _cameras!.first;
        _selectedCamera = selectedCamera;
        
        Log.d('选择的相机方向: ${selectedCamera.lensDirection}', tag: 'Camera');
        
        _cameraController = CameraController(
          selectedCamera,
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
        );

        await _cameraController!.initialize();
        Log.d('4. 初始化相机成功', tag: 'Camera');
        if (mounted) {
          setState(() {
          hasInit = true;
        });
        }

        Log.d('5. 启动相机流检测', tag: 'Camera');
        _startPoseDetectionStream();
      }
    } catch (e) {
      Log.e('初始化相机失败: $e', tag: 'Camera');
      if (mounted) setState(() {});
    }
  }

  void _startPoseDetectionStream() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    _cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      try {
        final inputImage = _convertCameraImage(image);
        if (inputImage == null) {
          Log.d("图像转换失败，跳过该帧", tag: 'Pose');
          return;
        }
        
        final poses = await _poseDetector.processImage(inputImage);

        if (poses.isNotEmpty) {
          Log.d("检测到 ${poses.length} 人", tag: 'Pose');
        }
      } catch (e) {
        Log.e("检测错误：$e", tag: 'Pose');
      } finally {
        _isDetecting = false;
      }
    });
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _selectedCamera;
      
      if (camera == null) {
        Log.e('未选择相机', tag: 'Pose');
        return null;
      }
      
      final sensorOrientation = camera.sensorOrientation;
      Log.d('相机传感器方向: $sensorOrientation', tag: 'Pose');
      
      InputImageRotation rotation;
      if (Platform.isIOS) {
        rotation = InputImageRotation.rotation90deg;
      } else {
        final isFrontCamera = camera.lensDirection == CameraLensDirection.front;
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
      
      // 确定图像格式
      InputImageFormat format;
      if (image.format.group == ImageFormatGroup.nv21) {
        format = InputImageFormat.nv21;
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        format = InputImageFormat.bgra8888;
      } else {
        format = InputImageFormat.yuv_420_888;
      }
      
      Log.d('图像信息: 宽=${image.width}, 高=${image.height}, 旋转=$rotation, 格式=$format', tag: 'Pose');
      
      // 直接使用camera包提供的planes[0].bytes
      final yPlane = image.planes[0];
      final bytes = yPlane.bytes;
      final bytesPerRow = yPlane.bytesPerRow;
      
      Log.d('Y平面: bytesPerRow=$bytesPerRow, 长度=${bytes.length}', tag: 'Pose');
      
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: bytesPerRow,
        ),
      );
      
      Log.d('创建 InputImage 成功', tag: 'Pose');
      return inputImage;
    } catch (e) {
      Log.e('图像转换错误: $e', tag: 'Pose');
      return null;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose(); // 页面关闭自动释放相机
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('智能运动纠错', 'AI实时姿态识别与纠正'),
                    const SizedBox(height: 20),
                    _buildPrepCard(),
                    const SizedBox(height: 24),
                    _buildCameraPreview(),
                    const SizedBox(height: 24),
                    _buildActionGuides(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
            top: -50, // 抵消父级 SafeArea 的影响，使梅花贴顶
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

  Widget _buildPrepCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F4).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3C9566).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '准备开始 - ${widget.sportType}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              fontFamily: 'STKaiti',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '请确保摄像头可以清晰看到您的全身，站在画面中央',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              fontFamily: 'STKaiti',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTag('8个动作'),
              const SizedBox(width: 8),
              _buildTag('15-20分钟'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD8D0BC), width: 0.5),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF5A5242),
          fontFamily: 'STKaiti',
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF101828),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasInit)
              LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _cameraController!.value.previewSize!.height,
                        height: _cameraController!.value.previewSize!.width,
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  );
                },
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam_outlined, color: Colors.white54, size: 48),
              SizedBox(height: 12),
              Text(
                '摄像头预览',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'STKaiti',
                ),
              ),
              Text(
                '请站在框内',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'STKaiti',
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SportAiCorrectionScreen(
                          sportType: widget.sportType,
                          cameraController: _cameraController,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3C9566),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '开始练习',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'STKaiti',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white24),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      '取消',
                      style: TextStyle(fontFamily: 'STKaiti'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildActionGuides() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '动作要领',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D4A3E),
            fontFamily: 'STKaiti',
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3ED),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildGuideTab(0, '第1式'),
              _buildGuideTab(1, '第2式'),
              _buildGuideTab(2, '第3式'),
              _buildGuideTab(3, '第4式'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '双手托天理三焦',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E2939),
            fontFamily: 'STKaiti',
          ),
        ),
        const SizedBox(height: 12),
        _buildGuideItem('手臂伸直'),
        _buildGuideItem('目视手背'),
        _buildGuideItem('腰背挺直'),
      ],
    );
  }

  Widget _buildGuideTab(int index, String title) {
    bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: isSelected
                    ? const Color(0xFF2D4A3E)
                    : const Color(0xFF6B5D4F),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'STKaiti',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Color(0xFF3C9566)),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF364153),
              fontFamily: 'STKaiti',
            ),
          ),
        ],
      ),
    );
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
  bool _isDetecting = false;
  
  Pose? _currentPose;
  double _poseAccuracy = 0.0;
  Map<String, bool> _checkResults = {};
  String _currentSuggestion = '';
  
  @override
  void initState() {
    super.initState();
    _initDetector();
  }
  
  void _initDetector() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );
    Log.d('启动动作检测流', tag: 'analyzePose');
    _startPoseDetectionStream();
  }
  
  void _startPoseDetectionStream() {
    if (widget.cameraController == null || !widget.cameraController!.value.isInitialized) {
      Log.d('启动动作检测流失败 widget.cameraController == null: ${widget.cameraController == null} !widget.cameraController!.value.isInitialized: ${!widget.cameraController!.value.isInitialized}', tag: 'analyzePose');
      return;
    }
    
    widget.cameraController!.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;
      
      try {
        final inputImage = _convertCameraImage(image);
        if (inputImage == null) return;
        
        final poses = await _poseDetector.processImage(inputImage);
        
        if (poses.isNotEmpty) {
          _currentPose = poses.first;
          Log.d('开始分析动作', tag: 'analyzePose');
          _analyzePose(_currentPose!);
        } else {
          _currentPose = null;
        }
        
        if (mounted) setState(() {});
      } catch (e) {
        Log.e('检测错误：$e', tag: 'Pose');
      } finally {
        _isDetecting = false;
      }
    });
  }
  
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = widget.cameraController!.description;
      
      final sensorOrientation = camera.sensorOrientation;
      
      InputImageRotation rotation;
      if (Platform.isIOS) {
        rotation = InputImageRotation.rotation90deg;
      } else {
        final isFrontCamera = camera.lensDirection == CameraLensDirection.front;
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
    _checkResults = {};
    double totalScore = 0;
    int checkCount = 0;
    
    // 获取关键点
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final nose = pose.landmarks[PoseLandmarkType.nose];
    
    Log.d('运动类型: ${widget.sportType}', tag: 'analyzePose');
    Log.d('左肩膀: ${leftShoulder?.x}, ${leftShoulder?.y}', tag: 'analyzePose');
    Log.d('右肩膀: ${rightShoulder?.x}, ${rightShoulder?.y}', tag: 'analyzePose');
    Log.d('左手腕: ${leftWrist?.x}, ${leftWrist?.y}', tag: 'analyzePose');
    Log.d('右手腕: ${rightWrist?.x}, ${rightWrist?.y}', tag: 'analyzePose');
    Log.d('鼻子: ${nose?.x}, ${nose?.y}', tag: 'analyzePose');
    
    // 根据运动类型分析
    if (widget.sportType == '八段锦') {
      // 双手托天理三焦
      if (leftWrist != null && rightWrist != null && leftShoulder != null && rightShoulder != null) {
        final wristY = (leftWrist.y + rightWrist.y) / 2;
        final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
        final isArmsUp = wristY < shoulderY;
        _checkResults['手臂伸展'] = isArmsUp;
        totalScore += isArmsUp ? 1.0 : 0.3;
        checkCount++;
        Log.d('手臂伸展: $isArmsUp, 手腕Y=$wristY, 肩膀Y=$shoulderY', tag: 'analyzePose');
      }
      
      if (nose != null && leftShoulder != null && rightShoulder != null) {
        final shoulderCenterX = (leftShoulder.x + rightShoulder.x) / 2;
        final isStraight = (nose.x - shoulderCenterX).abs() < 50;
        _checkResults['腰背挺直'] = isStraight;
        totalScore += isStraight ? 1.0 : 0.5;
        checkCount++;
        Log.d('腰背挺直: $isStraight, 鼻子X=${nose.x}, 肩膀中心X=$shoulderCenterX', tag: 'analyzePose');
      }
    } else if (widget.sportType == '瑜伽') {
      if (leftElbow != null && rightElbow != null && leftWrist != null && rightWrist != null) {
        _checkResults['四肢支撑'] = true;
        totalScore += 1.0;
        checkCount++;
        Log.d('四肢支撑: true', tag: 'analyzePose');
      }
    } else if (widget.sportType == '太极拳') {
      if (leftShoulder != null && rightShoulder != null) {
        _checkResults['转腰带动'] = true;
        totalScore += 1.0;
        checkCount++;
        Log.d('转腰带动: true', tag: 'analyzePose');
      }
    }
    
    _poseAccuracy = checkCount > 0 ? (totalScore / checkCount) * 100 : 0;
    
    Log.d('检查项: $_checkResults', tag: 'analyzePose');
    Log.d('准确度: ${_poseAccuracy.toStringAsFixed(1)}%', tag: 'analyzePose');
    
    if (_poseAccuracy >= 80) {
      _currentSuggestion = '姿势标准，继续保持！';
    } else if (_poseAccuracy >= 50) {
      _currentSuggestion = '姿势基本正确，可适当调整';
    } else {
      _currentSuggestion = '请调整姿势，按提示纠正';
    }
    
    Log.d('提示: $_currentSuggestion', tag: 'analyzePose');
  }
  
  @override
  void dispose() {
    widget.cameraController?.stopImageStream();
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 根据运动类型定义内容
    String actionName = '双手托天理三焦';
    List<String> checkItems = ['手臂伸展', '腰背挺直'];
    String suggestion = _currentSuggestion.isNotEmpty ? _currentSuggestion : '请站到画面中央';

    if (widget.sportType == '瑜伽') {
      actionName = '猫牛式伸展';
      checkItems = ['脊柱律动', '呼吸同步', '四肢支撑'];
      suggestion = _currentSuggestion.isNotEmpty ? _currentSuggestion : '请调整姿势';
    } else if (widget.sportType == '太极拳') {
      actionName = '左右野马分鬃';
      checkItems = ['虚实分明', '转腰带动', '气沉丹田'];
      suggestion = _currentSuggestion.isNotEmpty ? _currentSuggestion : '请调整姿势';
    }

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
                      child: CameraPreview(widget.cameraController!),
                    ),
                  ),
                ),
              ),
            )
          else
            Positioned.fill(child: Container(color: Colors.black)),
          // UI 层
          Column(
            children: [
              _buildTopInfo(context, actionName),
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
                              color: Color(0xFF3C9566),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '点击查看详情',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
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

  Widget _buildTopInfo(BuildContext context, String actionName) {
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
                  const Text(
                    '13%',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
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
                      widthFactor: 0.13,
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
            child: const Text(
              '1/8',
              style: TextStyle(
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
