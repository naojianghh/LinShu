import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../widgets/app_header.dart';
import '../widgets/banner_landscape_decoration.dart';
import 'sport_prep_screen.dart';

class SportMainScreen extends StatefulWidget {
  const            SportMainScreen({super.key});

  @override
  State<SportMainScreen> createState() => _SportMainScreenState();
}

class _SportMainScreenState extends State<SportMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDFCF7),
      child: Stack(
        children: [
      Positioned.fill(
      child: SizedBox(
      width: double.infinity,
        height: double.infinity,
        child: Image.asset(
          'assets/images/home_bg_1.png',
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    ),
      CustomScrollView(
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

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 32, 0, 0),
            sliver: SliverToBoxAdapter(child: _buildExerciseRecords()),
          ),

          // 8. 本周统计标题
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0,16 ,0,64),
            sliver: SliverToBoxAdapter(child: _buildSportOverviewCard()),
          ),
        ],
      )]),
    );
  }

  Widget _buildTopBanner() {
    return SizedBox(
      height: 270,
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
              height: 270,
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
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: SizedBox(
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Text(
                      '智能运动纠错',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF2D4A3E),
                        fontFamily: 'FZZJ-LongYTJW',
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Image.asset('assets/images/sport_decoration.png',width: 152.w,),)
                  ],
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
              right: 0,
              bottom: -24,
              child: Image.asset(
                'assets/images/ornament_sport_round.png',
                width: 94.w,
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
      height: 140.h,
      padding: EdgeInsets.fromLTRB(24.w,36.h,24.w,16.h),
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/images/meditation_bg.png'),fit: BoxFit.fill)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '本周统计',
            style: TextStyle(
              color: Color(0xFF2D4A3E),
              fontFamily: 'FZZJ-LongYTJW',
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height:8.h,),
          SizedBox(
            width: 352.w,
              height: 52.h,
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildOverviewItem('5', '本周练习'),
              _buildOverviewItem('78', '总时长(min)'),
              _buildOverviewItem('89', '平均分数'),
            ],
          ))
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
            fontWeight: FontWeight.w400,
            color: Color(0xFF3C9566),
            fontFamily: 'STKaiti'
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
        padding: EdgeInsets.fromLTRB(16.w,24.h,16.w,24.h),
        height: 160.h,
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/ai_function_bg.png'),fit: BoxFit.fill)
        ),
        child: Row(
          children: [
            Image.asset(iconAsset, width: 100.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h,),
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
                      fontSize: 14,
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
                              color: const Color(0xFFF7EBD6),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF5A5242),
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
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseRecords() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 36.h,horizontal: 32.w),
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/images/calendar_bg.png'),fit: BoxFit.fill)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '练习记录',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2D4A3E),
                  fontFamily: 'FZZJ-LongYTJW',
                ),
              ),
              Image.asset('assets/images/meditation_decoration.png',width: 128.w,)
            ],
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
      ),
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
              SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: badgeText == '八' ? Image.asset('assets/images/sport_icon_baduanjin2.png') : Image.asset('assets/images/sport_icon_yoga2.png')
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
                  color: const Color(0xFF6FB08E),
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
}
