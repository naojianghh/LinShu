import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MeditationResultScreen extends StatelessWidget {
  const MeditationResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7),
      body: Stack(
        children: [
          // 顶部装饰
          Positioned(
            top: 0,
            right: -20,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset('assets/images/header_plum.png', height: 180),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildSuccessCard(),
                        const SizedBox(height: 24),
                        _buildDataGrid(),
                        const SizedBox(height: 24),
                        _buildEffectCard(),
                        const SizedBox(height: 40),
                        _buildActionButtons(context),
                      ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: const Center(
        child: Column(
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
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // 还原深绿色圆底与白色星星图标 (Figma 17:630)
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF3C9566),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/images/meditation_star_white.svg',
                width: 48,
                height: 48,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '冥想完成',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D4A3E),
              fontFamily: 'STKaiti',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '恭喜您完成今天的练习',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B5D4F),
              fontFamily: 'STKaiti',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataGrid() {
    return Row(
      children: [
        _buildDataItem('02:14', '本次时长'),
        const SizedBox(width: 16),
        _buildDataItem('5', '成就点数'),
      ],
    );
  }

  Widget _buildDataItem(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8DCC8).withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3C9566),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B5D4F),
                fontFamily: 'STKaiti',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFA4D4B4)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本次练习效果',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D7450),
              fontFamily: 'STKaiti',
            ),
          ),
          SizedBox(height: 12),
          _EffectItem('内心宁静度提升 15%'),
          _EffectItem('压力值降低 12%'),
          _EffectItem('专注力有所增强'),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3C9566),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text(
              '回到主页',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('再练一次', style: TextStyle(color: Color(0xFF3C9566))),
        ),
      ],
    );
  }
}

class _EffectItem extends StatelessWidget {
  final String text;
  const _EffectItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Color(0xFF3C9566),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2D7450),
              fontFamily: 'STKaiti',
            ),
          ),
        ],
      ),
    );
  }
}
