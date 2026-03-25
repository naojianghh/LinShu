import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_health_bridge_service.dart';

class DrinkRecommendScreen extends StatefulWidget {
  const DrinkRecommendScreen({super.key});

  @override
  State<DrinkRecommendScreen> createState() => _DrinkRecommendScreenState();
}

class _DrinkRecommendScreenState extends State<DrinkRecommendScreen> {
  final UserHealthBridgeService _bridgeService =
      UserHealthBridgeService.instance;

  late List<(String, String, String, String, String)> drinks;
  UnifiedHealthInsights? _insights;

  @override
  void initState() {
    super.initState();
    drinks = const [
      (
        '姜枣暖宫茶',
        '温中散寒，暖宫调经，缓解痛经',
        '18',
        'assets/images/goddess_tea1.png',
      'assets/images/goddess_new/drink_1.png',
      ),
      ('百合银耳羹', '清润养阴，舒缓燥热不适', '8', 'assets/images/goddess_tea2.png','assets/images/goddess_new/drink_2.png',),
      ('玫瑰花茶', '舒肝理气，帮助情绪平稳', '8', 'assets/images/goddess_tea3.png','assets/images/goddess_new/drink_3.png',),
      ('桂圆红枣茶', '益气补血，温和调理体质', '5', 'assets/images/goddess_tea4.png','assets/images/goddess_new/drink_4.png',),
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
          const teaImages = {
            1: 'assets/images/goddess_tea1.png',
            2: 'assets/images/goddess_tea2.png',
            3: 'assets/images/goddess_tea3.png',
            4: 'assets/images/goddess_tea4.png',
            5: 'assets/images/goddess_tea5.png',
          };

          int pickTeaNo(String rawName) {
            final name = rawName.replaceAll(' ', '');

            // 优先级按你的规则：枣 > 百合/银耳 > 玫瑰/花 > 桂圆；否则兜底茶5
            if (name.contains('枣')) return 1;
            if (name.contains('百合') || name.contains('银耳')) return 2;
            if (name.contains('玫瑰')) return 3;
            if (name.contains('桂圆')) return 4;
            return 5;
          }

          String pickTeaImage(String rawName) => teaImages[pickTeaNo(rawName)]!;
          drinks = List.generate(generated.length, (index) {
            final item = generated[index];
            final name = (item['name'] ?? '智能饮品').toString();
            return (
              name,
              (item['description'] ?? '结合体质与周期推荐').toString(),
              (item['price'] ?? '￥12').toString(),
              pickTeaImage(name),
              // 详情图同一套 tea1~tea5 资源
              pickTeaImage(name),
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
        centerTitle: false,
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
          Row(
            children: [
              Image.asset('assets/images/tea_recommend_icon.png',height: 28,),
              SizedBox(width: 4,),
              const Text(
                '精准推荐',
                style: TextStyle(
                  fontSize: 34 / 2,
                  fontFamily: 'STKaiti',
                  color: Color(0xFF244438),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _featuredCard(drinks[0]),
          const SizedBox(height: 18),
          const Text(
            '推荐饮品',
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
            itemCount: drinks.length - 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              return _drinkItem(drinks[index + 1]);
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
          Row(
            children: [
              Image.asset('assets/images/ai_analyze_icon.png',width: 20,),
              SizedBox(width: 8.w,),
              const Text(
                'AI 智能分析',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF244438),
                  fontFamily: 'STKaiti',
                  fontWeight: FontWeight.bold,
                ),
              )
            ],
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
              _tag(_insights?.latestReport?.constitution ?? '宫寒', true),
              _tag('阴虚火旺', false),
              _tag('气血两虚', false),
              _tag('气郁体质', false),
              _tag('湿热体质', false),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '生理周期阶段',
            style: TextStyle(color: Color(0xFF6F6256), fontFamily: 'STKaiti'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _tag('经期', false, pink: _insights?.cyclePhase == '经期'),
              _tag('卵泡期',false, pink:  _insights?.cyclePhase == '卵泡期'),
              _tag('排卵期',false, pink: _insights?.cyclePhase == '排卵期'),
              _tag('黄体期',false, pink: _insights?.cyclePhase == '黄体期'),
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
            child: Text.rich(
              TextSpan(
                text: 'ⓘ 您处于',
                style: TextStyle(fontSize: 10, color: Color(0xFF5D6D67)),
                children: [
                  TextSpan(
                    text: _insights?.cyclePhase ?? '经期',
                    style: TextStyle(fontSize: 10, color: Color(0xFFF54888)),
                  ),
                  TextSpan(
                    text: '，体质为',
                    style: TextStyle(fontSize: 10, color: Color(0xFF5D6D67)),
                  ),
                  TextSpan(
                    text: _insights?.latestReport?.constitution ?? '宫寒',
                    style: TextStyle(fontSize: 10, color: Color(0xFF2E9B68)),
                  ),
                  TextSpan(
                    text: '，AI 为您精准匹配最适合的养生饮品。',
                    style: TextStyle(fontSize: 10, color: Color(0xFF5D6D67)),
                  ),
                  ],
                ),
              )
          ),
        ],
      ),
    );
  }

  Widget _featuredCard((String, String, String, String, String) drink) {
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
                    drink.$3,
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

  Widget _drinkItem((String, String, String, String, String) drink) {
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
                    drink.$3,
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

  void _showDetail((String, String, String, String, String) drink) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            child:SizedBox(
              height: MediaQuery.of(context).size.height * 0.85,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Stack(
                    children: [
                      Image.asset(
                        drink.$5,
                        width: double.infinity,
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close,color: Color(0xFF0A0A0A),),
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
                            fontSize: 20,
                            color: Color(0xFF244438),
                            fontFamily: 'STKaiti',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          drink.$2,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6F6256),
                            fontFamily: 'STKaiti',
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '主要功效',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8B7D6B),
                            fontFamily: 'STKaiti',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Wrap(
                          spacing: 4,
                          runSpacing: 8,
                          children: [
                            _SmallTag('温暖子宫', Color(0xFFE7F7EB), Color(0xFF4A9D68)),
                            _SmallTag('缓解痛经', Color(0xFFE7F7EB), Color(0xFF4A9D68)),
                            _SmallTag('改善宫寒', Color(0xFFE7F7EB), Color(0xFF4A9D68)),
                            _SmallTag('补气养血', Color(0xFFE7F7EB), Color(0xFF4A9D68)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '配方成分',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8B7D6B),
                            fontFamily: 'STKaiti',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Wrap(
                          spacing: 4,
                          runSpacing: 8,
                          children: [
                            _SmallTag('生姜', Color(0xFFFFF9E6),Color(0xFF8B7D6B), type: 2,),
                            _SmallTag('红枣', Color(0xFFFFF9E6),Color(0xFF8B7D6B), type: 2),
                            _SmallTag('红糖', Color(0xFFFFF9E6),Color(0xFF8B7D6B), type: 2),
                            _SmallTag('桂圆', Color(0xFFFFF9E6),Color(0xFF8B7D6B), type: 2),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '适合体质',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8B7D6B),
                            fontFamily: 'STKaiti',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Wrap(
                          spacing: 4,
                          runSpacing: 8,
                          children: [
                            _SmallTag('生姜', Color(0xFFFFEEF3),Color(0xFFFF4D8C)),
                            _SmallTag('红枣', Color(0xFFFFEEF3),Color(0xFFFF4D8C)),
                            _SmallTag('红糖', Color(0xFFFFEEF3),Color(0xFFFF4D8C)),
                            _SmallTag('桂圆', Color(0xFFFFEEF3),Color(0xFFFF4D8C)),
                          ],
                        ),
                        const SizedBox(height: 16,),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(16),
                          border:BoxBorder.all(color: const Color(0xFFFFE0B2)),
                        ),
                        child: Text(
                          '⚠️ 不适宜：阴虚火旺',
                          style: TextStyle(color: const Color(0xFF8B7D6B), fontFamily: 'STKaiti', fontSize: 11),
                        ),
                      ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: 80.h,
                          width: double.infinity,
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  SizedBox(height: 12.h,),
                                  const Text(
                                    '价格',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6F6256),
                                      fontFamily: 'STKaiti',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    drink.$3,
                                    style: const TextStyle(
                                      fontSize: 48 / 2,
                                      color: Color(0xFFF54888),
                                      fontFamily: 'STKaiti',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                ],
                              ),
                              const Expanded(child: SizedBox()),
                              Container(
                                width: 196.w,
                                decoration: BoxDecoration(
                                    image: DecorationImage(image: AssetImage('assets/images/buy_button_bg.png'), fit: BoxFit.fill)
                                ),
                                child: const Center(
                                  child: Text(
                                    '一键下单',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF6B5D4F),
                                      fontFamily: 'STKaiti',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            '由千问生态提供物流配送服务',
                            style: TextStyle(
                              fontSize: 10,
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
            ),
          ),
        );
      },
    );
  }

  Widget _tag (String text ,bool selected,{bool pink = false}) {
    final activeColor = pink
        ? const Color(0xFFF54888)
        : const Color(0xFF2E9B68);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: selected ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF6FB08E),
            const Color(0xFF83C6A2)
          ]
        ) : null,
        color: pink ? activeColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: selected ? Border.all(color: Colors.transparent) : Border.all(color: const Color(0xFFE8DCC8)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected || pink ? Colors.white : const Color(0xFF6F6256),
          fontFamily: 'STKaiti',
        ),
      ),
    );
  }
}


class _SmallTag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color textColor;
  final int type;

  const _SmallTag(this.text, this.bg, this.textColor, {this.type = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: type == 2 ? BoxBorder.all(color: const Color(0xFFFFE0B2)) : null,
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor, fontFamily: 'STKaiti', fontSize: 11),
      ),
    );
  }
}
