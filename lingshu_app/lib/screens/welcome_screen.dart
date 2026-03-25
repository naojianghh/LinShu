import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'main_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const _videoAsset = 'assets/video/welcome_intro.mp4';
  static const _fallbackImageAsset =
      'assets/images/home_welcome_character_v2.png';

  static const _backgroundImageAsset = 'assets/images/home_welcome_bg.png';
  static const _titleImageAsset = 'assets/images/welcome_title.png';
  static const _subtitleImageAsset = 'assets/images/welcome_subtitle.png';

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _titleSlideAnimation;
  late final Animation<double> _subtitleFadeAnimation;

  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _hasNavigated = false;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0, 0.72, curve: Curves.easeOutCubic),
    );
    _titleSlideAnimation = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.08, 0.66, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.34, 0.92, curve: Curves.easeOut),
    );

    _animationController.forward();
    _initVideo();

    _fallbackTimer = Timer(const Duration(milliseconds: 8600), _navigateToMain);
  }

  Future<void> _initVideo() async {
    final controller = VideoPlayerController.asset(_videoAsset);
    _videoController = controller;

    try {
      await controller.initialize();
      await controller.setLooping(false);

      if (mounted) {
        setState(() => _videoReady = true);
      }

      await controller.play();

      controller.addListener(() {
        if (_hasNavigated) return;
        final value = controller.value;
        if (!value.isInitialized) return;

        final duration = value.duration;
        final position = value.position;

        if (duration > Duration.zero &&
            position >= duration - const Duration(milliseconds: 120)) {
          _navigateToMain();
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _videoReady = false);
      }
      _navigateToMain();
    }
  }

  void _navigateToMain() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (_, __, ___) => const MainScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          final scale = Tween<double>(
            begin: 0.985,
            end: 1,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return FadeTransition(
            opacity: fade,
            child: ScaleTransition(scale: scale, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    _animationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_backgroundImageAsset),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;

              final titleTop = (screenH * 0.015).clamp(8.0, 16.0);
              final titleWidth = (screenW * 0.88).clamp(300.0, 390.0);
              final subtitleTopGap = (screenH * 0.01).clamp(6.0, 14.0);
              final subtitleWidth = (screenW * 0.72).clamp(255.0, 320.0);

              final circleSize = (screenW * 0.79).clamp(280.0, 352.0);
              final circleTopGap = (screenH * 0.09).clamp(56.0, 92.0);
              final bottomSafeGap = (screenH * 0.06).clamp(34.0, 62.0);

              return FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: screenH),
                    child: Column(
                      children: [
                        SizedBox(height: titleTop),
                        AnimatedBuilder(
                          animation: _titleSlideAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _titleSlideAnimation.value),
                              child: child,
                            );
                          },
                          child: Image.asset(
                            _titleImageAsset,
                            width: titleWidth,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: subtitleTopGap),
                        FadeTransition(
                          opacity: _subtitleFadeAnimation,
                          child: Image.asset(
                            _subtitleImageAsset,
                            width: subtitleWidth,
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: circleTopGap),
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0.94, end: 1.0),
                          duration: const Duration(milliseconds: 1300),
                          curve: Curves.easeOutBack,
                          builder: (context, scale, child) {
                            return Transform.scale(scale: scale, child: child);
                          },
                          child: Container(
                            width: circleSize,
                            height: circleSize,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x1F8B7D6B),
                                  blurRadius: 20,
                                  offset: Offset(0, 9),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: ColoredBox(
                                color: Color(0xFFF4F1E8),
                                child: _videoReady && _videoController != null
                                    ? SizedBox.expand(
                                  child: ClipRect(
                                    child: Transform.scale(
                                      // 源视频是横向并带黑边，放大后做中心裁切以保证圆内全画面
                                      scale: 2.7,
                                      child: Transform.translate(
                                        offset: const Offset(0, 18),
                                        child: FittedBox(
                                          fit: BoxFit.cover,
                                          clipBehavior: Clip.hardEdge,
                                          child: SizedBox(
                                            width: _videoController!
                                                .value
                                                .size
                                                .width,
                                            height: _videoController!
                                                .value
                                                .size
                                                .height,
                                            child: VideoPlayer(
                                              _videoController!,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                    : Image.asset(
                                  _fallbackImageAsset,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: bottomSafeGap),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
