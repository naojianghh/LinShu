import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/banner_landscape_decoration.dart';
import 'sport_prep_screen.dart';

class SportMainScreen extends StatefulWidget {
  const SportMainScreen({super.key});

  @override
  State<SportMainScreen> createState() => _SportMainScreenState();
}

class _SportMainScreenState extends State<SportMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDFCF7),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        slivers: [
          // 1. 顶部 App Header
          const SliverToBoxAdapter(child: AppHeader()),

          // 2. 3D 运动 Banner
          SliverToBoxAdapter(child: _buildTopBanner()),

          // 3. 页面主标题
          SliverToBoxAdapter(child: _buildPageTitle()),

          // 4. 今日运动概览卡片
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: _buildSportOverviewCard()),
          ),

          // 5. 传统功法分类标题
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            sliver: SliverToBoxAdapter(child: _buildSectionTitle('传统功法分类')),
          ),

          // 6. 功法列表
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSportCard(
                  '八段锦',
                  '传统养生功法，调理脏腑',
                  ['15-20分钟', '初级', '8个动作'],
                  'assets/images/sport_icon_baduanjin.png',
                  const Color(0xFFF0F9F4),
                  const Color(0xFF3C9566),
                ),
                const SizedBox(height: 12),
                _buildSportCard(
                  '瑜伽',
                  '身心合一，柔韧性与力量训练',
                  ['20-30分钟', '中级', '12个动作'],
                  'assets/images/sport_icon_yoga.png',
                  const Color(0xFFFDF2F8),
                  const Color(0xFFEC4899),
                ),
                const SizedBox(height: 12),
                _buildSportCard(
                  '太极拳',
                  '以柔克刚，内外兼修',
                  ['25-30分钟', '中级', '24个动作'],
                  'assets/images/sport_icon_taiji.png',
                  const Color(0xFFEFF6FF),
                  const Color(0xFF3B82F6),
                ),
              ]),
            ),
          ),

          // 7. 练习记录模块
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
            sliver: SliverToBoxAdapter(child: _buildExerciseRecords()),
          ),

          // 8. 本周统计标题
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            sliver: SliverToBoxAdapter(child: _buildSectionTitle('本周统计')),
          ),

          // 9. 统计图表卡片
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverToBoxAdapter(child: _buildWeeklyStatsCard()),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    return SizedBox(
      height: 260,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 0,
            right: 0,
            bottom: -10,
            child: BannerLandscapeDecoration(
              asset: 'assets/images/ornament_sport_round.png',
              height: 56,
              opacity: 0.8,
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(80),
              bottomRight: Radius.circular(80),
            ),
            child: SizedBox(
              height: 260,
              width: double.infinity,
              child: Image.asset(
                'assets/images/sport_main_banner.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTitle() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: SizedBox(
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '智能运动纠错',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D4A3E),
                    fontFamily: 'STKaiti',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'AI实时姿态识别与纠正',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B5D4F),
                    fontFamily: 'STKaiti',
                  ),
                ),
              ],
            ),
            Positioned(
              right: 4,
              top: -6,
              child: Image.asset(
                'assets/images/ornament_sport_round.png',
                width: 42,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSportOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5ED).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD4EAD9), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3C9566).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildOverviewItem('5', '本周练习'),
          _buildOverviewDivider(),
          _buildOverviewItem('78', '总时长(min)'),
          _buildOverviewDivider(),
          _buildOverviewItem('89', '平均分数'),
        ],
      ),
    );
  }

  Widget _buildOverviewItem(String value, String label) {
    return Column(
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
            fontSize: 11,
            color: Color(0xFF6B5D4F),
            fontFamily: 'STKaiti',
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewDivider() {
    return Container(width: 1, height: 30, color: const Color(0xFFD4EAD9));
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

  Widget _buildSportCard(
    String title,
    String desc,
    List<String> tags,
    String iconAsset,
    Color bgColor,
    Color themeColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SportPrepScreen(sportType: title),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: themeColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B5D4F),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: tags
                        .map(
                          (tag) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 10,
                                color: themeColor,
                                fontFamily: 'STKaiti',
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            Image.asset(iconAsset, width: 66, height: 66),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseRecords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '练习记录',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF2D4A3E),
            fontFamily: 'STKaiti',
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 140,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFF3C9566),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        _buildExerciseRecordCard(
          badgeText: '八',
          badgeColor: const Color.fromRGBO(16, 185, 129, 0.13),
          badgeTextColor: const Color(0xFF3C9566),
          title: '八段锦',
          time: '今天 08:30',
          score: '92分',
          level: '优秀',
          scoreColor: const Color(0xFF3C9566),
        ),
        const SizedBox(height: 12),
        _buildExerciseRecordCard(
          badgeText: '瑜',
          badgeColor: const Color.fromRGBO(236, 72, 153, 0.13),
          badgeTextColor: const Color(0xFFEC4899),
          title: '瑜伽',
          time: '昨天 19:00',
          score: '88分',
          level: '良好',
          scoreColor: const Color(0xFFEC4899),
        ),
      ],
    );
  }

  Widget _buildExerciseRecordCard({
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String title,
    required String time,
    required String score,
    required String level,
    required Color scoreColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromRGBO(248, 246, 240, 0.5),
            Color.fromRGBO(255, 254, 251, 0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8DCC8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'STKaiti',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D4A3E),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B7D6B),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                  fontFamily: 'STKaiti',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                level,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B5D4F),
                  fontFamily: 'STKaiti',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '平均准确度变化',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5B21B6),
              fontFamily: 'STKaiti',
            ),
          ),
          const SizedBox(height: 20),
          // 模拟统计图表
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(0.4, '周一'),
              _buildBar(0.6, '周二'),
              _buildBar(0.5, '周三'),
              _buildBar(0.8, '周四'),
              _buildBar(0.9, '周五'),
              _buildBar(0.7, '周六'),
              _buildBar(0.85, '周日'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor, String day) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 80 * heightFactor,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
            ),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF6B5D4F),
            fontFamily: 'STKaiti',
          ),
        ),
      ],
    );
  }
}
