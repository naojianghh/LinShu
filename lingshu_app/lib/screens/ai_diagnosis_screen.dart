import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../models/diagnosis_report.dart';
import '../services/diagnosis_report_db.dart';
import '../services/qwen_service.dart';
import '../widgets/app_header.dart';
import '../widgets/banner_landscape_decoration.dart';
import 'analysis_progress_screen.dart';
import 'report_detail_screen.dart';
import 'text_chat_screen.dart';

class AiDiagnosisScreen extends StatefulWidget {
  const AiDiagnosisScreen({super.key});

  @override
  State<AiDiagnosisScreen> createState() => _AiDiagnosisScreenState();
}

class _AiDiagnosisScreenState extends State<AiDiagnosisScreen> {
  final ImagePicker _picker = ImagePicker();
  final QwenService _qwenService = QwenService();

  List<DiagnosisReport> _historyReports = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistoryReports();
  }

  Future<void> _loadHistoryReports() async {
    setState(() => _loadingHistory = true);
    try {
      final reports = await DiagnosisReportDb.instance.getReports(limit: 20);
      if (!mounted) return;
      setState(() {
        _historyReports = reports;
        _loadingHistory = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _historyReports = [];
        _loadingHistory = false;
      });
    }
  }

  Future<void> _startDiagnosis(BuildContext context, String type) async {
    final String title = type == 'tongue' ? '拍摄舌象' : '拍摄面部';
    final String analysisTitle = type == 'tongue'
        ? '正在分析舌象特征...'
        : '正在分析面部特征...';

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'STKaiti',
                  color: Color(0xFF2D4A3E),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF3C9566)),
                title: const Text(
                  '拍照',
                  style: TextStyle(fontFamily: 'STKaiti'),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF3C9566),
                ),
                title: const Text(
                  '从相册选择',
                  style: TextStyle(fontFamily: 'STKaiti'),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '取消',
                  style: TextStyle(
                    color: Color(0xFF6B5D4F),
                    fontFamily: 'STKaiti',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null || !context.mounted) return;

      final file = File(pickedFile.path);

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AnalysisProgressScreen(
            title: analysisTitle,
            subtitle: 'AI正在深度学习您的健康数据，请稍候',
            analyzeTask: () =>
                _qwenService.analyzeImage(imageFile: file, type: type),
          ),
        ),
      );

      await _loadHistoryReports();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '选择图片失败: $e',
              style: const TextStyle(fontFamily: 'STKaiti'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFDFCF7),
      child: RefreshIndicator(
        onRefresh: _loadHistoryReports,
        child: Stack(
          children: [
            Positioned.fill(
            child: SizedBox(
            width: double.infinity,
              height: double.infinity,
              child: Expanded(
                child: Image.asset(
                  'assets/images/home_bg_1.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              slivers: [
                const SliverToBoxAdapter(child: AppHeader()),
                SliverToBoxAdapter(child: _buildBanner(context)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: SizedBox(
                      height: 56,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI 望闻问切',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'FZZJ-LongYTJW',
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF2D4A3E),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '通过智能分析，深度了解您的体质状况',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'STKaiti',
                                  color: Color(0xFF6B5D4F),
                                ),
                              ),
                            ],
                          ),
                          Positioned(
                            right: 20,
                            bottom: -4,
                            child: Image.asset(
                              'assets/images/ornament_ai_book.png',
                              width: 170,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildDiagnosisCard(
                        onTap: () => _startDiagnosis(context, 'face'),
                        title: '面部望诊',
                        desc: '通过AI视觉分析面部气色、光泽度和五官特征，评估气血状况',
                        tags: const ['非接触式', '2分钟'],
                        iconAsset: 'assets/images/ai_function_camera.png',
                        bgGradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0x143C9566), Color(0x1F3C9566)],
                        ),
                        borderColor: const Color(0x4D3C9566),
                      ),
                      const SizedBox(height: 12),
                      _buildDiagnosisCard(
                        onTap: () => _startDiagnosis(context, 'tongue'),
                        title: '舌象分析',
                        desc: '识别舌苔颜色、厚度、舌体形态，精准判断脏腑功能状态',
                        tags: const ['高精度', '1分钟'],
                        iconAsset: 'assets/images/ai_function_tongue.png',
                        bgGradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFF1F2), Color(0xFFFDF2F8)],
                        ),
                        borderColor: const Color(0xFFFFCCD3),
                      ),
                      const SizedBox(height: 12),
                      _buildDiagnosisCard(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const TextChatScreen(),
                            ),
                          );
                        },
                        title: '文本问答',
                        desc: 'AI对话式问诊，输入症状、作息与饮食情况，获得个性化调理建议',
                        tags: const ['多轮对话', '即时回复'],
                        iconAsset: 'assets/images/ai_function_chart.png',
                        bgGradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFEFF6FF), Color(0xFFECFEFF)],
                        ),
                        borderColor: const Color(0xFFBEDBFF),
                      ),
                    ]),
                  ),
                ),
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, 28, 16, 12),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      '历史报告',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'STKaiti',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D4A3E),
                      ),
                    ),
                  ),
                ),
                if (_loadingHistory)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (_historyReports.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                      child: Text(
                        '暂无历史报告，快去做一次望闻问切吧。',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'STKaiti',
                          color: Color(0xFF6B5D4F),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final report = _historyReports[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == _historyReports.length - 1 ? 100 : 12,
                          ),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ReportDetailScreen(report: report),
                                ),
                              );
                            },
                            child: _buildHistoryItem(
                              title: report.type == 'tongue' ? '舌象分析报告' : '面部望诊报告',
                              date:
                                  '${report.date.year}年${report.date.month}月${report.date.day}日',
                              tag: report.constitution,
                              tagBg: report.type == 'tongue'
                                  ? const Color(0xFFDBEAFE)
                                  : const Color(0x333C9566),
                              tagFg: report.type == 'tongue'
                                  ? const Color(0xFF1447E6)
                                  : const Color(0xFF2D7450),
                              leadingSvg: report.type == 'tongue'
                                  ? 'assets/images/diagnosis_history_report_blue.svg'
                                  : 'assets/images/diagnosis_history_report_green.svg',
                            ),
                          ),
                        );
                      }, childCount: _historyReports.length),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: SizedBox(height: 40.h,),
                )
              ],
            ),
          ]
        )
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
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
                'assets/images/diagnosis_banner.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: -18,
            child: BannerLandscapeDecoration(height: 56, opacity: 0.82),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard({
    VoidCallback? onTap,
    required String title,
    required String desc,
    required List<String> tags,
    required String iconAsset,
    required LinearGradient bgGradient,
    required Color borderColor,
  }) {
    final card = Container(
      height: 160.h,
      padding: EdgeInsets.symmetric(horizontal: 25.w,vertical: 25.w),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/ai_function_bg.png'),
          fit: BoxFit.fill
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(iconAsset, width: 60.w),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'STKaiti',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D4A3E),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'STKaiti',
                    color: Color(0xFF6B5D4F),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7EBD6),
                            borderRadius: BorderRadius.circular(32.r),
                          ),
                          child: Text(
                            t,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'STKaiti',
                              color: Color(0xFF030213),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(onTap: onTap, child: card);
  }

  Widget _buildHistoryItem({
    required String title,
    required String date,
    required String tag,
    required Color tagBg,
    required Color tagFg,
    required String leadingSvg,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: SvgPicture.asset(
                leadingSvg,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(tagFg, BlendMode.srcIn),
              ),
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
                    fontSize: 14,
                    fontFamily: 'STKaiti',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D4A3E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'STKaiti',
                    color: Color(0xFF6B5D4F),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: tagBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 12,
                fontFamily: 'STKaiti',
                fontWeight: FontWeight.bold,
                color: tagFg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
