import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/app_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onFeatureTap});

  final ValueChanged<int>? onFeatureTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDFCF7),
      child: Stack(
        children: [
          // 顶部背景渐变
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 250,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8F6F0), Color(0xFFFDFCF7)],
                ),
              ),
            ),
          ),
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: ClampingScrollPhysics(),
            ),
            slivers: [
              // 1. Header
              const SliverToBoxAdapter(child: AppHeader()),

              // 2. 欢迎卡片
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverToBoxAdapter(child: _buildWelcomeCard(context)),
              ),

              // 3. 节气海报
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(child: _buildSolarTermCard(context)),
              ),

              // 4. 今日健康概览标题
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                sliver: SliverToBoxAdapter(child: _buildSectionTitle('今日健康概览')),
              ),

              // 5. 健康网格
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.9,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildHealthCard(
                      '睡眠质量',
                      '良好',
                      const Color(0xFFE3F2FD),
                      const Color(0xFF4A7C9E),
                      'assets/images/icon_sleep.svg',
                    ),
                    _buildHealthCard(
                      '心率变异',
                      '正常',
                      const Color(0xFFFDEEF1),
                      const Color(0xFFC75B7A),
                      'assets/images/icon_heart.svg',
                    ),
                    _buildHealthCard(
                      '体质类型',
                      '平和质',
                      const Color(0xFFFFF9E6),
                      const Color(0xFFD4A574),
                      'assets/images/icon_sun.svg',
                    ),
                    _buildHealthCard(
                      '饮水量',
                      '1.2L',
                      const Color(0xFFE8F5E9),
                      const Color(0xFF3C9566),
                      'assets/images/icon_water.svg',
                    ),
                  ]),
                ),
              ),

              // 6. 核心功能标题
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                sliver: SliverToBoxAdapter(child: _buildSectionTitle('核心功能')),
              ),

              // 7. 功能列表
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildFeatureCard(
                      'AI 望闻问切',
                      '面部舌象分析 · 智能体质辨识',
                      'assets/images/home_feature_ai.png',
                      const Color(0xFFF0EFEA),
                      onTap: () => onFeatureTap?.call(1),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      '女神专区',
                      '周期性调理 · 个性化方案',
                      'assets/images/home_feature_goddess.png',
                      const Color(0xFFF6F2E6),
                      onTap: () => onFeatureTap?.call(2),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      '心灵栖息地',
                      '五音疗愈 · 冥想引导',
                      'assets/images/home_feature_meditation.png',
                      const Color(0xFFF1F0EB),
                      onTap: () => onFeatureTap?.call(3),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      '智能运动纠错',
                      '八段锦 · 瑜伽姿态识别',
                      'assets/images/home_feature_sport.png',
                      const Color(0xFFF6F3E4),
                      onTap: () => onFeatureTap?.call(4),
                    ),
                    const SizedBox(height: 100), // 确保底部内容能完全滑出
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF3C9566),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            color: Color(0xFF2D4A3E),
            fontWeight: FontWeight.bold,
            fontFamily: 'STKaiti',
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      height: 146,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(255, 254, 251, 1),
            Color.fromRGBO(248, 246, 240, 1),
            Color.fromRGBO(240, 248, 244, 1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4EAD9), width: 1.13),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C9566).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge, // 确保人物图片超出部分被卡片圆角裁切
        children: [
          // 背景装饰 SVG 可以按需添加，目前主要处理文字和人物
          Positioned(
            left: 25,
            top: 25,
            bottom: 25,
            right: 25,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '欢迎回来!',
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFF2D4A3E),
                    fontFamily: 'STXinwei',
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 210, // 限制宽度，防止文字被人物图片完全覆盖
                  child: const Text(
                    '今天感觉怎么样？让我们一起关注您的健康',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B5D4F),
                      height: 1.45,
                      fontFamily: 'STKaiti',
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 人物图片 - 使用 home_welcome_character(1).png 半身图
          Positioned(
            right: 0,
            bottom: 0, // 底部对齐卡片边缘
            width: 174,
            height: 138, // 根据 Figma 节点 1:74 的尺寸调整
            child: Image.asset(
              'assets/images/home_welcome_character_v2.png',
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolarTermCard(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/images/home_solar_term_poster.png'),
          fit: BoxFit.cover,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE8DCC8), width: 0.5),
              ),
              child: const Text(
                '2月10日',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF2D4A3E),
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

  Widget _buildHealthCard(
    String title,
    String value,
    Color bgColor,
    Color iconColor,
    String svgPath,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              svgPath,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              width: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B5D4F),
                    fontFamily: 'STKaiti',
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                    fontFamily: 'STKaiti',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    String title,
    String desc,
    String imagePath,
    Color bgColor, {
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D4A3E),
                        fontFamily: 'STKaiti',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF6B5D4F).withValues(alpha: 0.7),
                        fontFamily: 'STKaiti',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(imagePath, width: 85, fit: BoxFit.contain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
