import 'package:flutter/material.dart';

import '../services/user_health_bridge_service.dart';
import '../widgets/app_header.dart';
import '../widgets/banner_landscape_decoration.dart';
import 'constitution_timeline_screen.dart';
import 'cycle_record_screen.dart';
import 'drink_recommend_screen.dart';
import 'wellness_social_screen.dart';

class GoddessScreen extends StatefulWidget {
  const GoddessScreen({super.key});

  @override
  State<GoddessScreen> createState() => _GoddessScreenState();
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF8B7D6B),
            fontFamily: 'STKaiti',
          ),
        ),
      ],
    );
  }
}

class _GoddessScreenState extends State<GoddessScreen> {
  int _selectedTab = 0;
  final UserHealthBridgeService _bridgeService =
      UserHealthBridgeService.instance;

  UnifiedHealthInsights? _insights;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      final data = await _bridgeService.getUnifiedInsights();
      if (!mounted) return;
      setState(() {
        _insights = data;
      });
    } catch (_) {
      // 使用静态兜底数据
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDFCF7),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: AppHeader()),
          SliverToBoxAdapter(child: _buildTopBanner()),
          SliverToBoxAdapter(child: _title()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(child: _tabs()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(child: _cycleCard()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(child: _calendarCard()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(child: _recommendCard()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(child: _tipsCard()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            sliver: SliverToBoxAdapter(child: _entryGrid()),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    return SizedBox(
      height: 270,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(80),
              bottomRight: Radius.circular(80),
            ),
            child: Image.asset(
              'assets/images/goddess_top_banner.png',
              width: double.infinity,
              height: 270,
              fit: BoxFit.cover,
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: -10,
            child: BannerLandscapeDecoration(
              asset: 'assets/images/ornament_goddess_teapot.png',
              height: 52,
              opacity: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _title() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: SizedBox(
        height: 60,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '女神专区',
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xFF2D4A3E),
                    fontFamily: 'STKaiti',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '基于生理周期的体质智能调理平台',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF8B7D6B),
                    fontFamily: 'STKaiti',
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: -10,
              child: Image.asset(
                'assets/images/ornament_goddess_teapot.png',
                width: 52,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    const labels = ['饮食方案', '运动计划', '护理建议'];
    return Container(
      height: 61,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF5F3ED), Color(0xFFECEAE0)],
        ),
        border: Border.all(color: const Color(0xFFE8DCC8), width: 1.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFFFFFEFB), Color(0xFFFDFCF7)],
                        )
                      : null,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF3C9566,
                            ).withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 14,
                    color: selected
                        ? const Color(0xFF2D4A3E)
                        : const Color(0xFF6B5D4F),
                    fontFamily: 'STKaiti',
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _cycleCard() {
    final phase = _insights?.cyclePhase ?? '卵泡期';
    final constitution = _insights?.latestReport?.constitution ?? '待分析';
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEEF3), Color(0xFFFFF5F8)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF8BBD0), width: 1.15),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF4D8C),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('📅', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前周期阶段',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8B7D6B),
                        fontFamily: 'STKaiti',
                      ),
                    ),
                    Text(
                      '$phase · $constitution',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2D4A3E),
                        fontFamily: 'STKaiti',
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF8BBD0), width: 1.15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CycleRecordScreen()),
                ),
                child: const Text(
                  '记录月经',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFFF4D8C),
                    fontFamily: 'STKaiti',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, .6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _insights?.goddessPlan.weeklyFocus ?? '处于卵泡期上升期，建议多摄取富含铁质的食材',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B5D4F),
                    fontFamily: 'STKaiti',
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: const LinearProgressIndicator(
                    value: .22,
                    minHeight: 6,
                    backgroundColor: Color(0xFFFFF0E8),
                    valueColor: AlwaysStoppedAnimation(Color(0xFFFF8E53)),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '距下次 20 天',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF8B7D6B),
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

  Widget _calendarCard() {
    const weekLabels = ['日', '一', '二', '三', '四', '五', '六'];

    Color bgForDay(int day) {
      if (day >= 1 && day <= 10) return const Color(0xFFF4DDE7);
      if (day >= 11 && day <= 13) return const Color(0xFFF4E8D4);
      if (day >= 14 && day <= 25) return const Color(0xFFE9DEEF);
      if (day >= 26 && day <= 31) return const Color(0xFFF1CDD9);
      return const Color(0xFFF4DDE7);
    }

    Color textForDay(int day) {
      if (day == 5) return Colors.white;
      if (day >= 1 && day <= 10) return const Color(0xFFF75A78);
      if (day >= 11 && day <= 13) return const Color(0xFFF29B19);
      if (day >= 14 && day <= 25) return const Color(0xFFAF4ACB);
      return const Color(0xFFFF2E55);
    }

    bool showDot(int day) => [1, 2, 26, 27, 28, 29, 30].contains(day);
    bool showStar(int day) => [11, 12, 13].contains(day);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCC8), width: 1.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '周期日历 - 3月',
            style: TextStyle(
              fontSize: 17,
              color: Color(0xFF2D4A3E),
              fontFamily: 'STKaiti',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekLabels
                .map(
                  (label) => Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B7D6B),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 31,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 58,
            ),
            itemBuilder: (context, index) {
              final day = index + 1;
              final isToday = day == 5;
              return Container(
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF3C9566) : bgForDay(day),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 17,
                        color: textForDay(day),
                        fontFamily: 'STKaiti',
                      ),
                    ),
                    if (showDot(day))
                      Text(
                        '●',
                        style: TextStyle(
                          fontSize: 9,
                          color: isToday
                              ? Colors.white
                              : const Color(0xFFFF2E55),
                          fontFamily: 'STKaiti',
                          height: 1,
                        ),
                      )
                    else if (showStar(day))
                      const Text(
                        '★',
                        style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFFF29B19),
                          fontFamily: 'STKaiti',
                          height: 1,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          const Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _LegendItem(color: Color(0xFFF1CDD9), text: '经期 (1-5天)'),
              _LegendItem(color: Color(0xFFF4DDE7), text: '卵泡期 (6-13天)'),
              _LegendItem(color: Color(0xFFF4E8D4), text: '排卵期 (14-16天)'),
              _LegendItem(color: Color(0xFFE9DEEF), text: '黄体期 (17-28天)'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recommendCard() {
    final mealPlans = _insights?.goddessPlan.dietaryPlan ?? const [];

    Widget meal(String t, String c, String d, String action) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF2D8A6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  t,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7B6E62),
                    fontFamily: 'STKaiti',
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F6F0),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: const Color(0xFFBFDEC7)),
                  ),
                  child: Text(
                    action,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF4D8F67),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              c,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF2D4A3E),
                fontFamily: 'STKaiti',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              d,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF7B6E62),
                fontFamily: 'STKaiti',
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFFDFCF7)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCC8), width: 1.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日养生推荐',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF2D4A3E),
              fontFamily: 'STKaiti',
            ),
          ),
          const SizedBox(height: 10),
          meal(
            '早餐',
            mealPlans.isNotEmpty ? mealPlans.first : '红枣莲子-木耳夹实-牛奶',
            '结合望闻问切与周期阶段生成',
            '智能推荐',
          ),
          meal(
            '午餐',
            mealPlans.length > 1 ? mealPlans[1] : '清炒冬瓜·木耳炒鸡丁·红米饭',
            '结合望闻问切与周期阶段生成',
            '查看详情',
          ),
          meal(
            '晚餐',
            mealPlans.length > 2 ? mealPlans[2] : '山药排骨汤·清炒时蔬·小米粥',
            '结合望闻问切与周期阶段生成',
            '查看详情',
          ),
        ],
      ),
    );
  }

  Widget _tipsCard() {
    final tips = _insights?.goddessPlan.wellnessRecommendation ?? const [];
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8F5F7), Color(0xFFF0F8F9)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFB2DFDB), width: 1.15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '本周饮食养生点',
            style: TextStyle(
              fontSize: 16,
              fontFamily: 'STKaiti',
              color: Color(0xFF2D4A3E),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '• ${tips.isNotEmpty ? tips[0] : '主旨为多艺这道食道的平时，红枣、莲子、大少红枣'}',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'STKaiti',
              color: Color(0xFF476052),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '• ${tips.length > 1 ? tips[1] : '在上血流量充盈的食用，主菜、水果粥、一般量'}',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'STKaiti',
              color: Color(0xFF476052),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '• ${tips.length > 2 ? tips[2] : '豆类适合各，别吃鱼、花生等，有水与不相同作用所营养'}',
            style: const TextStyle(
              fontSize: 12,
              fontFamily: 'STKaiti',
              color: Color(0xFF476052),
            ),
          ),
        ],
      ),
    );
  }

  Widget _entryGrid() {
    Widget card({
      required Color bg,
      required Color border,
      required String title,
      required String desc,
      required String iconEmoji,
      required String imagePath,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 126,
          padding: const EdgeInsets.fromLTRB(17, 14, 12, 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [bg, Colors.white]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1.15),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .08),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        iconEmoji,
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF2D4A3E),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF8B7D6B),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Image.asset(
                  imagePath,
                  width: 64,
                  height: 64,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: card(
                bg: const Color(0xFFFFEEF3),
                border: const Color(0xFFF8BBD0),
                title: '生理周期记录',
                desc: '智能预测周期变化',
                iconEmoji: '📅',
                imagePath: 'assets/images/goddess_new/entry_cycle.png',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CycleRecordScreen()),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: card(
                bg: const Color(0xFFE8F5E9),
                border: const Color(0xFFA5D6A7),
                title: '智能饮品推荐',
                desc: 'AI体质周期精准匹配',
                iconEmoji: '🍵',
                imagePath: 'assets/images/goddess_new/entry_drink.png',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DrinkRecommendScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: card(
                bg: const Color(0xFFE8EAF6),
                border: const Color(0xFF9FA8DA),
                title: '体质演化分析',
                desc: '可视化健康趋势预测',
                iconEmoji: '📊',
                imagePath: 'assets/images/goddess_new/entry_timeline.png',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConstitutionTimelineScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: card(
                bg: const Color(0xFFFFEBEE),
                border: const Color(0xFFEF9A9A),
                title: '养生社交',
                desc: '拼单监督礼物赠送',
                iconEmoji: '👭',
                imagePath: 'assets/images/goddess_new/entry_social.png',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WellnessSocialScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
