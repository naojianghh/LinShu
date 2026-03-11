import 'package:flutter/material.dart';

import '../services/user_health_bridge_service.dart';

class DrinkRecommendScreen extends StatefulWidget {
  const DrinkRecommendScreen({super.key});

  @override
  State<DrinkRecommendScreen> createState() => _DrinkRecommendScreenState();
}

class _DrinkRecommendScreenState extends State<DrinkRecommendScreen> {
  final UserHealthBridgeService _bridgeService =
      UserHealthBridgeService.instance;

  late List<(String, String, String, String)> drinks;
  UnifiedHealthInsights? _insights;

  @override
  void initState() {
    super.initState();
    drinks = const [
      (
        '姜枣暖宫茶',
        '温中散寒，暖宫调经，缓解痛经',
        '18',
        'assets/images/goddess_new/drink_1.png',
      ),
      ('百合银耳羹', '清润养阴，舒缓燥热不适', '8', 'assets/images/goddess_new/drink_2.png'),
      ('玫瑰花茶', '舒肝理气，帮助情绪平稳', '8', 'assets/images/goddess_new/drink_3.png'),
      ('桂圆红枣茶', '益气补血，温和调理体质', '5', 'assets/images/goddess_new/drink_4.png'),
    ];
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final insights = await _bridgeService.getUnifiedInsights();
      final generated = insights.goddessPlan.drinkRecommendations;
      if (!mounted) return;
      setState(() {
        _insights = insights;
        if (generated.isNotEmpty) {
          final imagePool = const [
            'assets/images/goddess_new/drink_1.png',
            'assets/images/goddess_new/drink_2.png',
            'assets/images/goddess_new/drink_3.png',
            'assets/images/goddess_new/drink_4.png',
          ];
          drinks = List.generate(generated.length, (index) {
            final item = generated[index];
            return (
              item['name'] ?? '智能饮品',
              item['description'] ?? '结合体质与周期推荐',
              item['price'] ?? '12',
              imagePool[index % imagePool.length],
            );
          });
        }
      });
    } catch (_) {
      // 保底使用静态数据
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFCF7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF244438)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '智能饮品推荐',
          style: TextStyle(
            color: Color(0xFF244438),
            fontFamily: 'STKaiti',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildAiCard(),
          const SizedBox(height: 18),
          const Text(
            '精准推荐',
            style: TextStyle(
              fontSize: 34 / 2,
              fontFamily: 'STKaiti',
              color: Color(0xFF244438),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _featuredCard(drinks[0]),
          const SizedBox(height: 18),
          const Text(
            '全部饮品',
            style: TextStyle(
              fontSize: 34 / 2,
              fontFamily: 'STKaiti',
              color: Color(0xFF244438),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: drinks.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              return _drinkItem(drinks[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAiCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FAF1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA9DCB3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✧ AI 智能分析',
            style: TextStyle(
              fontSize: 34 / 2,
              color: Color(0xFF244438),
              fontFamily: 'STKaiti',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '当前体质（来自望闻问切）',
            style: TextStyle(color: Color(0xFF6F6256), fontFamily: 'STKaiti'),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(_insights?.latestReport?.constitution ?? '宫寒', true),
              _Tag(_insights?.latestReport?.pattern ?? '阴虚火旺', false),
              const _Tag('气血两虚', false),
              const _Tag('气郁体质', false),
              const _Tag('湿热体质', false),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '生理周期阶段',
            style: TextStyle(color: Color(0xFF6F6256), fontFamily: 'STKaiti'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _Tag('经期', _insights?.cyclePhase == '经期', pink: true),
              ),
              const SizedBox(width: 8),
              Expanded(child: _Tag('卵泡期', _insights?.cyclePhase == '卵泡期')),
              const SizedBox(width: 8),
              Expanded(child: _Tag('排卵期', _insights?.cyclePhase == '排卵期')),
              const SizedBox(width: 8),
              Expanded(child: _Tag('黄体期', _insights?.cyclePhase == '黄体期')),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'ⓘ 您处于${_insights?.cyclePhase ?? '经期'}，体质为${_insights?.latestReport?.constitution ?? '宫寒'}，AI 为您精准匹配最适合的养生饮品。',
              style: const TextStyle(
                color: Color(0xFF5D6D67),
                fontFamily: 'STKaiti',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featuredCard((String, String, String, String) drink) {
    return InkWell(
      onTap: () => _showDetail(drink),
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFA9DCB3)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                drink.$4,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    drink.$1,
                    style: const TextStyle(
                      fontSize: 19,
                      color: Color(0xFF244438),
                      fontFamily: 'STKaiti',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    drink.$2,
                    style: const TextStyle(
                      color: Color(0xFF6F6256),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¥${drink.$3}',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Color(0xFFF54888),
                      fontFamily: 'STKaiti',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '查看详情 →',
                      style: TextStyle(
                        color: Color(0xFF4A9D68),
                        fontFamily: 'STKaiti',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drinkItem((String, String, String, String) drink) {
    return InkWell(
      onTap: () => _showDetail(drink),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8DCC8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              child: Image.asset(
                drink.$4,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Text(
                drink.$1,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF244438),
                  fontFamily: 'STKaiti',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
              child: Row(
                children: [
                  Text(
                    '¥${drink.$3}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFFF54888),
                      fontFamily: 'STKaiti',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.add_shopping_cart_outlined,
                    color: Color(0xFF4A9D68),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail((String, String, String, String) drink) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.86,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    child: Image.asset(
                      drink.$4,
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drink.$1,
                      style: const TextStyle(
                        fontSize: 40 / 2,
                        color: Color(0xFF244438),
                        fontFamily: 'STKaiti',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      drink.$2,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6F6256),
                        fontFamily: 'STKaiti',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '主要功效',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF244438),
                        fontFamily: 'STKaiti',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SmallTag('温暖子宫', Color(0xFFE7F7EB), Color(0xFF4A9D68)),
                        _SmallTag('缓解痛经', Color(0xFFE7F7EB), Color(0xFF4A9D68)),
                        _SmallTag('改善宫寒', Color(0xFFE7F7EB), Color(0xFF4A9D68)),
                        _SmallTag('补气养血', Color(0xFFE7F7EB), Color(0xFF4A9D68)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '价格',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6F6256),
                        fontFamily: 'STKaiti',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '¥${drink.$3}',
                      style: const TextStyle(
                        fontSize: 48 / 2,
                        color: Color(0xFFF54888),
                        fontFamily: 'STKaiti',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF8B5A), Color(0xFFF54888)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          '🛒 千问一键下单',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontFamily: 'STKaiti',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text(
                        '由于问生态提供物流配送服务',
                        style: TextStyle(
                          color: Color(0xFF7B6E62),
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
      },
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final bool selected;
  final bool pink;

  const _Tag(this.text, this.selected, {this.pink = false});

  @override
  Widget build(BuildContext context) {
    final activeColor = pink
        ? const Color(0xFFF54888)
        : const Color(0xFF2E9B68);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? activeColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8DCC8)),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6F6256),
            fontFamily: 'STKaiti',
          ),
        ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;

  const _SmallTag(this.text, this.bg, this.textColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontFamily: 'STKaiti'),
      ),
    );
  }
}
