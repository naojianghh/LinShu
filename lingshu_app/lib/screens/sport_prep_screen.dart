import 'package:flutter/material.dart';

class SportPrepScreen extends StatefulWidget {
  final String sportType;

  const SportPrepScreen({super.key, required this.sportType});

  @override
  State<SportPrepScreen> createState() => _SportPrepScreenState();
}

class _SportPrepScreenState extends State<SportPrepScreen> {
  int _selectedTab = 0; // 0: 动作要领, 1: 准备提示

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
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Column(
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
    );
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

class SportAiCorrectionScreen extends StatelessWidget {
  final String sportType;

  const SportAiCorrectionScreen({super.key, required this.sportType});

  @override
  Widget build(BuildContext context) {
    // 根据运动类型定义内容
    String actionName = '双手托天理三焦';
    List<String> checkItems = ['手臂伸直', '目视手背', '腰背挺直'];
    String suggestion = '注意保持腰背挺直，手臂伸展更充分';

    if (sportType == '瑜伽') {
      actionName = '猫牛式伸展';
      checkItems = ['脊柱律动', '呼吸同步', '四肢支撑'];
      suggestion = '注意脊柱节律性延展，保持呼吸深长均匀';
    } else if (sportType == '太极拳') {
      actionName = '左右野马分鬃';
      checkItems = ['虚实分明', '转腰带动', '气沉丹田'];
      suggestion = '注意重心转换的平稳，转腰带动双臂拨动';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7),
      body: Stack(
        children: [
          // 模拟相机背景
          Positioned.fill(child: Container(color: Colors.black)),
          // UI 层
          SafeArea(
            child: Column(
              children: [
                _buildTopInfo(context, actionName),
                const Spacer(),
                _buildCorrectionPanel(
                  context,
                  actionName,
                  checkItems,
                  suggestion,
                ),
              ],
            ),
          ),
        ],
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
    String suggestion,
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
              const Text(
                '42%',
                style: TextStyle(
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
                    suggestion,
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
          _checkItem(checkItems[0], true),
          _checkItem(checkItems[1], false),
          _checkItem(checkItems[2], false),
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
