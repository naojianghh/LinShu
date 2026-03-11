import 'package:flutter/material.dart';

class SportFlowScreen extends StatelessWidget {
  const SportFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101828), // 模拟摄像头预览深色背景
      body: Stack(
        children: [
          // 1. 模拟摄像头预览区域
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: const Center(
                child: Text(
                  '摄像头预览区域',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                    fontFamily: 'STKaiti',
                  ),
                ),
              ),
            ),
          ),

          // 2. 引导遮罩/边框 (还原 Figma 3-2229)
          Center(
            child: Container(
              width: 300,
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFF3C9566).withValues(alpha: 0.5),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Stack(
                children: [
                  // 四角装饰
                  _buildCorner(0, 0),
                  _buildCorner(null, 0),
                  _buildCorner(0, null),
                  _buildCorner(null, null),
                ],
              ),
            ),
          ),

          // 3. 顶部信息与返回
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        '准备开始 - 八段锦',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'STKaiti',
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '请确保摄像头可以清晰看到您的全身',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'STKaiti',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. 底部动作说明卡片
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '第1式：双手托天理三焦',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D4A3E),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '动作要领：两掌五指分开，由小腹前抬起，翻掌上托，目视掌背。',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B5D4F),
                      height: 1.6,
                      fontFamily: 'STKaiti',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3C9566),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      '开始识别',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildCorner(double? top, double? left) {
    return Positioned(
      top: top,
      left: left,
      right: left == null ? 0 : null,
      bottom: top == null ? 0 : null,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: top == 0
                ? const BorderSide(color: Color(0xFF3C9566), width: 4)
                : BorderSide.none,
            left: left == 0
                ? const BorderSide(color: Color(0xFF3C9566), width: 4)
                : BorderSide.none,
            bottom: top == null
                ? const BorderSide(color: Color(0xFF3C9566), width: 4)
                : BorderSide.none,
            right: left == null
                ? const BorderSide(color: Color(0xFF3C9566), width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
