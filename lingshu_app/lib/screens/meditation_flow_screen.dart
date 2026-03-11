import 'package:flutter/material.dart';
import 'meditation_result_screen.dart';

class MeditationFlowScreen extends StatefulWidget {
  final String title;
  final String backgroundAsset;
  final List<Map<String, String>> steps;

  const MeditationFlowScreen({
    super.key,
    required this.title,
    required this.backgroundAsset,
    required this.steps,
  });

  @override
  State<MeditationFlowScreen> createState() => _MeditationFlowScreenState();
}

class _MeditationFlowScreenState extends State<MeditationFlowScreen>
    with TickerProviderStateMixin {
  int _currentStep = 1;
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length) {
      setState(() {
        _currentStep++;
      });
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MeditationResultScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stepData = widget.steps[_currentStep - 1];

    return Scaffold(
      body: Stack(
        children: [
          // 1. 全屏背景 (动态)
          Positioned.fill(
            child: Image.asset(widget.backgroundAsset, fit: BoxFit.cover),
          ),

          // ... 遮罩保持不变

          // 2. 黑色渐变遮罩（增强文字可读性）
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),

          // 3. 顶部返回
          Positioned(
            top: 50,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // 4. 核心呼吸环
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _breathAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 200 * _breathAnimation.value,
                      height: 200 * _breathAnimation.value,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 160 * _breathAnimation.value,
                          height: 160 * _breathAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  stepData['title']!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'STXinwei',
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  stepData['subtitle']!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    fontFamily: 'STKaiti',
                  ),
                ),
              ],
            ),
          ),

          // 5. 底部引导卡片
          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3C9566),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$_currentStep',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            '引导词',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'STKaiti',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        stepData['instruction']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.6,
                          fontFamily: 'STKaiti',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          '结束练习',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3C9566),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _nextStep,
                        child: Text(
                          _currentStep == widget.steps.length ? '完成冥想' : '下一步',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
