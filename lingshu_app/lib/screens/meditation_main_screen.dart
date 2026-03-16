import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        slivers: [
          const SliverToBoxAdapter(child: AppHeader()),
          SliverToBoxAdapter(child: _buildTopBanner()),
          SliverToBoxAdapter(child: _buildPageTitle()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(child: _buildMoodAssessmentCard()),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
            sliver: SliverToBoxAdapter(child: _buildSectionTitle('中医五音疗愈')),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildFiveToneItem(
                  '宫音',
                  '入脾 · 缓解焦虑，补益中气',
                  'assets/images/meditation_icon_gong.svg',
                ),
                const SizedBox(height: 12),
                _buildFiveToneItem(
                  '商音',
                  '入肺 · 醒脑提神，清肺润燥',
                  'assets/images/meditation_icon_shang.svg',
                ),
                const SizedBox(height: 12),
                _buildFiveToneItem(
                  '角音',
                  '入肝 · 疏肝理气，调畅气机',
                  'assets/images/meditation_icon_jue.svg',
                ),
                const SizedBox(height: 12),
                _buildFiveToneItem(
                  '徵音',
                  '入心 · 养心安神，清心降火',
                  'assets/images/meditation_icon_zhi.svg',
                ),
                const SizedBox(height: 12),
                _buildFiveToneItem(
                  '羽音',
                  '入肾 · 滋阴降火，宁心安神',
                  'assets/images/meditation_icon_yu.svg',
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
            sliver: SliverToBoxAdapter(child: _buildSectionTitle('冥想引导')),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
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
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D4A3E),
                    fontFamily: 'STKaiti',
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
              right: 2,
              bottom: -8,
              child: Image.asset(
                'assets/images/ornament_meditation_lotus.png',
                width: 54,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
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
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5B21B6),
                  fontFamily: 'STKaiti',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDDD6FE)),
                ),
                child: const Text(
                  '基于AI分析',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF5B21B6),
                    fontFamily: 'STKaiti',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildAssessmentItem(
                '压力指数',
                (_mindPlan?.stressIndex ?? 68).toString(),
                const Color(0xFFC75B7A),
                'assets/images/meditation_eval_stress.svg',
              ),
              const SizedBox(width: 16),
              _buildAssessmentItem(
                '放松度',
                '${_mindPlan?.relaxPercent ?? 85}%',
                const Color(0xFF6366F1),
                'assets/images/meditation_eval_relax.svg',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _mindPlan?.suggestion ?? '您今日的压力值偏高，建议聆听舒缓音乐或进行冥想练习',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF5B21B6),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(svgPath, width: 18, height: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B5D4F),
                    fontFamily: 'STKaiti',
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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

  Widget _buildFiveToneItem(String name, String desc, String svgPath) {
    return GestureDetector(
      onTap: () => _openToneMusic(name, desc),
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
            SvgPicture.asset(svgPath, width: 40, height: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D4A3E),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B5D4F),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.play_circle_outline,
              color: Color(0xFF3C9566),
              size: 28,
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(255, 254, 251, 0.95),
              Color.fromRGBO(248, 246, 240, 0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D4A3E),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc.split(' · ').last,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B5D4F),
                      fontFamily: 'STKaiti',
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
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
                          color: const Color(0xFF3C9566),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF3C9566,
                              ).withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
