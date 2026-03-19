import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/five_tone_track.dart';
import '../services/five_tone_service.dart';
import '../services/user_health_bridge_service.dart';
import '../widgets/app_header.dart';
import '../widgets/banner_landscape_decoration.dart';
import 'music_player_screen.dart';
import 'meditation_flow_screen.dart';

const List<Map<String, String>> _forestSteps = [
  {
    'title': '慢慢呼气',
    'subtitle': '放下纷扰',
    'instruction': '找一个安静舒适的地方坐下或躺下，让肩膀自然下沉。',
  },
  {
    'title': '慢慢吸气',
    'subtitle': '吸入清新',
    'instruction': '想象清晨的空气穿过林间，带着湿润与清香进入身体。',
  },
  {
    'title': '屏息凝神',
    'subtitle': '聆听自然',
    'instruction': '短暂停留，感受风穿过树叶的沙沙声，心也随之安静。',
  },
  {
    'title': '慢慢呼气',
    'subtitle': '释放压力',
    'instruction': '把烦恼随着呼气慢慢吐出，想象它们落在柔软的苔藓上。',
  },
  {
    'title': '慢慢吸气',
    'subtitle': '回到当下',
    'instruction': '再次吸气，让身体充满平和，轻轻睁开眼，带着宁静继续前行。',
  },
];

const List<Map<String, String>> _sunsetSteps = [
  {
    'title': '慢慢呼气',
    'subtitle': '放松下来',
    'instruction': '把注意力放到呼气上，想象海浪把紧绷一点点带走。',
  },
  {
    'title': '慢慢吸气',
    'subtitle': '迎接暖光',
    'instruction': '吸气时，想象夕阳的金色光线从胸口缓缓铺开，温柔而有力量。',
  },
  {
    'title': '屏息凝神',
    'subtitle': '凝望落日',
    'instruction': '短暂停留，感受时间变慢，天空的颜色层层晕染，心也被安放。',
  },
  {
    'title': '慢慢呼气',
    'subtitle': '交给海风',
    'instruction': '呼气时，把焦虑、疲惫交给海风，让它们随浪花散去。',
  },
  {
    'title': '慢慢吸气',
    'subtitle': '收回温柔',
    'instruction': '吸气，把温暖与柔软带回身体，感受内心变得轻盈而清澈。',
  },
];

const List<Map<String, String>> _mistSteps = [
  {
    'title': '慢慢呼气',
    'subtitle': '放下执念',
    'instruction': '呼气时，想象山谷里的薄雾轻轻散开，你也随之松开紧握的念头。',
  },
  {
    'title': '慢慢吸气',
    'subtitle': '吸入清凉',
    'instruction': '吸气，感受清凉的雾气在鼻尖流动，带来清醒与通透。',
  },
  {
    'title': '屏息凝神',
    'subtitle': '心随云起',
    'instruction': '短暂停留，感受云雾缠绕山间的流动感，让思绪像云一样飘远。',
  },
  {
    'title': '慢慢呼气',
    'subtitle': '雾散心明',
    'instruction': '呼气，把杂念吐出，想象雾气散去后，远山轮廓清晰浮现。',
  },
  {
    'title': '慢慢吸气',
    'subtitle': '回归平和',
    'instruction': '吸气，感受胸腔被温柔撑开，带着安定与清明回到当下。',
  },
];

class MeditationMainScreen extends StatefulWidget {
  const MeditationMainScreen({super.key});

  @override
  State<MeditationMainScreen> createState() => _MeditationMainScreenState();
}

class _MeditationMainScreenState extends State<MeditationMainScreen> {
  final FiveToneService _fiveToneService = FiveToneService();
  final UserHealthBridgeService _bridgeService =
      UserHealthBridgeService.instance;

  MindPlanData? _mindPlan;

  @override
  void initState() {
    super.initState();
    _loadMindPlan();
  }

  Future<void> _loadMindPlan() async {
    try {
      final insights = await _bridgeService.getUnifiedInsights();
      if (!mounted) return;
      setState(() {
        _mindPlan = insights.mindPlan;
      });
    } catch (_) {
      // 保持默认展示
    }
  }

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
          const SliverToBoxAdapter(child: AppHeader()),
          SliverToBoxAdapter(child: _buildTopBanner()),
          SliverToBoxAdapter(child: SizedBox(height: 12.h,),),
          SliverToBoxAdapter(child: _buildPageTitle()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            sliver: SliverToBoxAdapter(child: _buildMoodAssessmentCard()),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 0),
            sliver: SliverToBoxAdapter(
              child: Container(
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
                          '中医五音疗愈',
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
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Text(
                          '根据您的体质推荐',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF6B5D4F),
                            fontFamily: 'STKaiti',
                          ),
                        ),
                        const Expanded(child: SizedBox()),
                        Container(
                          height: 30.h,
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: Color(0xFFDDF2E8),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: const Color(0xFFA4D4B4)),
                          ),
                          child: Text(
                            '基于平和质',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Color(0xFF2D7450),
                              fontFamily: 'STKaiti',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h,),
                    _buildFiveToneItem(
                      '宫音',
                      '入脾', '缓解焦虑，补益中气', '适用于：晨起唤醒',
                      'assets/images/meditation_gong.png',
                    ),
                    const SizedBox(height: 12),
                    _buildFiveToneItem(
                      '商音',
                      '入肺','醒脑提神，清肺润燥','适用于：白天醒脑',
                      'assets/images/meditation_shang.png',
                    ),
                    const SizedBox(height: 12),
                    _buildFiveToneItem(
                      '角音',
                      '入肝', '疏肝理气，调畅气机','适用于：肝气舒缓',
                      'assets/images/meditation_jue.png',
                    ),
                    const SizedBox(height: 12),
                    _buildFiveToneItem(
                      '徵音',
                      '入心', '养心安神，清心降火','适用于：心神宁静',
                      'assets/images/meditation_zhi.png',
                    ),
                    const SizedBox(height: 12),
                    _buildFiveToneItem(
                      '羽音',
                      '入肾', '滋阴降火，宁心安神','适用于：仙境酣眠',
                      'assets/images/meditation_yu.png',
                    ),
                  ],
                )
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
            sliver: SliverToBoxAdapter(child: _buildSectionTitle('冥想引导')),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildMeditationGuideItem(
                  '森林疗愈',
                  '15分钟 · 在虚拟森林中漫步',
                  'assets/images/meditation_cover_forest.png',
                ),
                const SizedBox(height: 12),
                _buildMeditationGuideItem(
                  '海边日落',
                  '20分钟 · 伴着夕阳放空烦恼',
                  'assets/images/meditation_cover_sunset.png',
                ),
                const SizedBox(height: 12),
                _buildMeditationGuideItem(
                  '山间云雾',
                  '25分钟 · 体验心灵彻底之旅',
                  'assets/images/meditation_cover_mist.png',
                ),
              ]),
            ),
          ),
        ],
      ),
    ]));
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
            child: SizedBox(
              height: 270,
              width: double.infinity,
              child: Image.asset(
                'assets/images/meditation_main_banner.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: -10,
            child: BannerLandscapeDecoration(
              asset: 'assets/images/ornament_meditation_lotus.png',
              height: 56,
              opacity: 0.78,
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
                  '心灵栖息地',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF2D4A3E),
                    fontFamily: 'FZZJ-LongYTJW',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '中医五音疗愈与冥想引导',
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
              bottom: -20.h,
              child: Image.asset(
                'assets/images/meditation_lotus.png',
                width: 100.w,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodAssessmentCard() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 28.h,horizontal: 30.w),
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage('assets/images/calendar_bg.png'), fit: BoxFit.fill)
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '心理状态评估',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2D4A3E),
                  fontFamily: 'FZZJ-LongYTJW',
                ),
              ),
              const Expanded(child: SizedBox()),
              Container(
                height: 30.h,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                decoration: BoxDecoration(
                  color: Color(0xFFDDF2E8),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFA4D4B4)),
                ),
                child: Text(
                  '基于AI分析',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Color(0xFF2D7450),
                    fontFamily: 'STKaiti',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80.h,
            child: Row(
            children: [
              _buildAssessmentItem(
                '压力指数',
                (_mindPlan?.stressIndex ?? 68).toString(),
                const Color(0xFF2D4A3E),
                'assets/images/meditation_press.png',
              ),
              const SizedBox(width: 16),
              _buildAssessmentItem(
                '放松度',
                '${_mindPlan?.relaxPercent ?? 85}%',
                const Color(0xFF2D4A3E),
                'assets/images/meditation_relax.png',
              ),
            ],
          ),),

          const SizedBox(height: 16),
          Text(
            _mindPlan?.suggestion ?? '您今日的压力值偏高，建议聆听舒缓音乐或进行冥想练习',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF2D4A3E),
              fontFamily: 'STKaiti',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentItem(
    String label,
    String value,
    Color color,
    String svgPath,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
          border: BoxBorder.all(color: const Color(0xFFE8DCC8), width: 1.w)
        ),
        child: Row(
          children: [
            Image.asset(svgPath, width: 40.w, height: 40.w),
            const SizedBox(width: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: const Color(0xFF6B5D4F),
                    fontFamily: 'STKaiti',
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w400,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            color: Color(0xFF2D4A3E),
            fontWeight: FontWeight.w400,
            fontFamily: 'FZZJ-LongYTJW',
          ),
        ),
        Expanded(child: SizedBox()),
        Text(
          '查看全部',
          style: TextStyle(
            color: const Color(0xFF3C9566),
            fontSize: 14.sp,
            fontFamily: 'STKaiti'
          ),
        )
      ],
    );
  }

  Future<void> _openToneMusic(String name, String desc) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final tracks = await _fiveToneService.fetchTracksByTone(name);
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();

      final FiveToneTrack firstTrack = tracks.first;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MusicPlayerScreen(
            title: name,
            toneType: desc,
            tracks: tracks,
            initialIndex: 0,
            initialTrack: firstTrack,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _buildFiveToneItem(String name, String desc1, String desc2,String desc3, String svgPath) {
    return GestureDetector(
      onTap: () => _openToneMusic(name, desc1),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE8DCC8).withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Image.asset(svgPath, width: 64.w, height: 64.w),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                      name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF2D4A3E),
                        fontFamily: 'STKaiti',
                      ),
                    ),
                      SizedBox(width: 8.w,),
                      Text(
                        desc1,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Color(0xFF6B5D4F),
                          fontFamily: 'STKaiti',
                        ),
                      ),],
                  ),

                  Text(
                    desc2,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Color(0xFF6B5D4F),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                  Text(
                    desc3,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Color(0xFF6B5D4F),
                      fontFamily: 'STKaiti',
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

  Widget _buildMeditationGuideItem(String title, String desc, String imgPath) {
    return GestureDetector(
      onTap: () {
        final bg = switch (title) {
          '森林疗愈' => 'assets/images/meditation_forest_bg.png',
          '海边日落' => 'assets/images/meditation_sunset_bg.png',
          '山间云雾' => 'assets/images/meditation_mist_bg.png',
          _ => 'assets/images/meditation_forest_bg.png',
        };

        final steps = switch (title) {
          '森林疗愈' => _forestSteps,
          '海边日落' => _sunsetSteps,
          '山间云雾' => _mistSteps,
          _ => _forestSteps,
        };

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MeditationFlowScreen(
              title: title,
              backgroundAsset: bg,
              steps: steps,
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.only(left: 28.w,right: 28.w,top: 32.h,bottom: 16.h),
        decoration: BoxDecoration(
          image: DecorationImage(image: AssetImage('assets/images/meditation_bg.png'),fit: BoxFit.fill)
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                imgPath,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF2D4A3E),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc.split(' · ').last,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Color(0xFF6B5D4F),
                      fontFamily: 'STKaiti',
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        desc.split(' · ').first,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B7D6B),
                          fontFamily: 'STKaiti',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                            const Color(0xFF6FB08E),
                            const Color(0xFF83C6A2),
                          ]),
                          borderRadius: BorderRadius.circular(20),
                          border: BoxBorder.all(color: Color(0xFF2D7450),width: 1.r)
                        ),
                        child: const Text(
                          '开始体验',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
