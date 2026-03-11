import 'package:flutter/material.dart';

class WellnessSocialScreen extends StatefulWidget {
  const WellnessSocialScreen({super.key});

  @override
  State<WellnessSocialScreen> createState() => _WellnessSocialScreenState();
}

class _WellnessSocialScreenState extends State<WellnessSocialScreen> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFCF7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF244438)),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: const Text(
          '养生社交',
          style: TextStyle(
            color: Color(0xFF244438),
            fontFamily: 'STKaiti',
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          _tabs(),
          const SizedBox(height: 14),
          if (tab == 0) ...[
            _tipCard(
              'AI智能匹配',
              '系统识别到与您相似体质（宫寒）的用户正在组团购买，智能推荐拼单机会，降低购买成本！',
              const Color(0xFFF1FAF1),
              const Color(0xFFA9DCB3),
            ),
            const SizedBox(height: 12),
            _groupCard(
              '姜枣暖宫茶礼盒',
              '宫寒',
              '北京朝阳区',
              '88',
              '128',
              '40',
              0.6,
              '3/5人',
              '还差2人',
              'assets/images/goddess_new/gift_1.jpg',
            ),
            const SizedBox(height: 12),
            _groupCard(
              '百合银耳养生礼盒',
              '阴虚火旺',
              '上海浦东区',
              '68',
              '98',
              '30',
              0.8,
              '4/5人',
              '还差1人',
              'assets/images/goddess_new/gift_2.jpg',
            ),
          ] else if (tab == 1) ...[
            _tipCard(
              '闺蜜监督',
              '和闺蜜互相监督每日饮食和记录，完成7日连续打卡可获得专属体质徽章。',
              const Color(0xFFF1F8FF),
              const Color(0xFFA7CBEF),
            ),
            const SizedBox(height: 12),
            _simpleCard('今日监督任务', '和小晴互发饮食记录（已完成 1/2）'),
            const SizedBox(height: 10),
            _simpleCard('连续打卡', '你已连续打卡 5 天，再坚持 2 天可领取奖励'),
          ] else ...[
            _tipCard(
              '暖心礼物',
              '一键发送养生礼盒给好友，附带AI生成的定制暖心贺卡！ 由于问生态提供配送服务。',
              const Color(0xFFFFF8E9),
              const Color(0xFFF1DCA6),
            ),
            const SizedBox(height: 12),
            _giftMainCard(),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _giftChoice(
                    '气血双补礼盒',
                    '168',
                    'assets/images/goddess_new/drink_4.jpg',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _giftChoice(
                    '清热降火礼盒',
                    '148',
                    'assets/images/goddess_new/drink_2.jpg',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabs() {
    final labels = ['体质拼单', '闺蜜监督', '礼物赠送'];
    final icons = [
      Icons.shopping_bag_outlined,
      Icons.groups_2_outlined,
      Icons.card_giftcard,
    ];
    return Row(
      children: List.generate(3, (index) {
        final selected = tab == index;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => tab = index),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF3C9566) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8DCC8)),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF3C9566,
                            ).withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      color: selected ? Colors.white : const Color(0xFF6F6256),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      labels[index],
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF6F6256),
                        fontFamily: 'STKaiti',
                        fontSize: 16,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _tipCard(String title, String desc, Color bg, Color border) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF244438),
              fontFamily: 'STKaiti',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF5A605C),
              fontFamily: 'STKaiti',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _groupCard(
    String title,
    String tag,
    String location,
    String price,
    String oldPrice,
    String save,
    double progress,
    String people,
    String remain,
    String image,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8DCC8)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  image,
                  width: 112,
                  height: 112,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xFF244438),
                        fontFamily: 'STKaiti',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8F1),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Color(0xFFF54888),
                              fontFamily: 'STKaiti',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '📍 $location',
                            style: const TextStyle(
                              color: Color(0xFF6F6256),
                              fontFamily: 'STKaiti',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '¥$price',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Color(0xFFF54888),
                            fontFamily: 'STKaiti',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '¥$oldPrice',
                          style: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            color: Color(0xFF8B7D6B),
                            fontFamily: 'STKaiti',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF54888),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            '省¥$save',
                            style: const TextStyle(
                              color: Colors.white,
                              fontFamily: 'STKaiti',
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFF0EFEB),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF44AF6E),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                people,
                style: const TextStyle(
                  color: Color(0xFF6F6256),
                  fontFamily: 'STKaiti',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3EA76E), Color(0xFF5AC273)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3EA76E).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '立即参团（$remain）',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'STKaiti',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _simpleCard(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              color: Color(0xFF244438),
              fontFamily: 'STKaiti',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6F6256),
              fontFamily: 'STKaiti',
            ),
          ),
        ],
      ),
    );
  }

  Widget _giftMainCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8DCC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/goddess_new/gift_1.jpg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '暖心养生礼盒',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF244438),
                        fontFamily: 'STKaiti',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      '包含：姜枣茶×3、红糖姜茶×3、艾灸贴×5、暖宫贴×10',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6F6256),
                        fontFamily: 'STKaiti',
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '¥188  ¥258',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFFF54888),
                        fontFamily: 'STKaiti',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3F8),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF6B7CC)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 定制贺卡预览',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6F6256),
                    fontFamily: 'STKaiti',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '亲爱的，知道你最近有点宫寒困扰，特地为你准备了这份养生礼盒。希望这些温暖的茶饮能陪伴你度过每一个经期，让你远离痛经的烦恼。记得要好好照顾自己哦！💕',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF244438),
                    fontFamily: 'STKaiti',
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '自定义贺卡内容 →',
                  style: TextStyle(
                    color: Color(0xFF3EA76E),
                    fontFamily: 'STKaiti',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8B5A), Color(0xFFF54888)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text(
                '赠送给好友',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'STKaiti',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _giftChoice(String title, String price, String image) {
    return Container(
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
              image,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF244438),
                fontFamily: 'STKaiti',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Text(
                  '¥$price',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Color(0xFFF54888),
                    fontFamily: 'STKaiti',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Text(
                  '选择',
                  style: TextStyle(
                    color: Color(0xFF3EA76E),
                    fontFamily: 'STKaiti',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
