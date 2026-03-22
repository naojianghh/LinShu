import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:lingshu_app/screens/sport_ai_correction_screen.dart';
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
  late PoseDetector _poseDetector;
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

      }
    } catch (e) {
      Log.e('初始化相机失败: $e', tag: 'Camera');
      if (mounted) setState(() {});
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
