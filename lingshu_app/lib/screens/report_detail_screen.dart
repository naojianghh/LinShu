import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/diagnosis_report.dart';
import '../widgets/app_header.dart';

class ReportDetailScreen extends StatefulWidget {
  final DiagnosisReport report;
  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  int _selectedTab = 0;

  String _buildSummary() {
    final r = widget.report;
    final dietary = r.dietaryAdvice.isEmpty ? '无' : r.dietaryAdvice.join('；');
    final lifestyle = r.lifestyleAdvice.isEmpty
        ? '无'
        : r.lifestyleAdvice.join('；');
    final exercise = r.exerciseAdvice.isEmpty
        ? '无'
        : r.exerciseAdvice.join('；');

    return '''【灵枢·AI 报告摘要】
体质结论：${r.constitution}
证型倾向：${r.pattern}

饮食建议：$dietary
作息建议：$lifestyle
运动建议：$exercise

风险提示：${r.riskWarning}
（仅供健康管理参考，不作为医疗诊断依据）''';
  }

  Future<void> _copySummary() async {
    final text = _buildSummary();
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('摘要已复制，可直接粘贴到微信/文档。')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
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
          SafeArea(
            child: Column(
              children: [
                const AppHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('AI 望闻问切', '通过智能分析，深度了解您的体质状况'),
                          const SizedBox(height: 20),
                          _buildAnalysisCompleteCard(),
                          const SizedBox(height: 24),
                          _buildConstitutionInfo(),
                          const SizedBox(height: 20),
                          _buildTabSwitcher(),
                          const SizedBox(height: 20),
                          _buildTabContent(),
                          const SizedBox(height: 32),
                          _buildBottomActions(context),
                          const SizedBox(height: 40),
                        ],
                      ),
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

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D4A3E),
            fontFamily: 'STKaiti',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B5D4F),
            fontFamily: 'STKaiti',
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCompleteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5ED).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4EAD9), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFF3C9566),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '分析完成',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D4A3E),
                  fontFamily: 'STKaiti',
                ),
              ),
              Text(
                '您的体质评估报告已生成',
                style: TextStyle(
                  fontSize: 13,
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

  Widget _buildConstitutionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '体质类型',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D4A3E),
            fontFamily: 'STKaiti',
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE8F5ED), Color(0xFFD4EAD9)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFA4D4B4), width: 1),
              ),
              child: Text(
                widget.report.constitution,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D7450),
                  fontFamily: 'STKaiti',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFA4D4B4),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  widget.report.pattern,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2D7450),
                    fontFamily: 'STKaiti',
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3ED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabButton(0, '调理建议'),
          _buildTabButton(1, '饮食指导'),
          _buildTabButton(2, '运动建议'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xFF2D4A3E)
                    : const Color(0xFF6B5D4F),
                fontFamily: 'STKaiti',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildSuggestionsTab();
      case 1:
        return _buildDietTab();
      case 2:
        return _buildExerciseTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildSuggestionsTab() {
    return Column(
      children: widget.report.lifestyleAdvice
          .map((s) => _buildSuggestionItem(s))
          .toList(),
    );
  }

  Widget _buildDietTab() {
    return Column(
      children: widget.report.dietaryAdvice
          .map((s) => _buildSuggestionItem(s, isDiet: true))
          .toList(),
    );
  }

  Widget _buildExerciseTab() {
    return Column(
      children: widget.report.exerciseAdvice
          .map((s) => _buildSuggestionItem(s, isExercise: true))
          .toList(),
    );
  }

  Widget _buildSuggestionItem(
    String text, {
    bool isDiet = false,
    bool isExercise = false,
  }) {
    var themeColor = const Color(0xFF3C9566);
    if (isDiet) themeColor = const Color(0xFFD4A520);
    if (isExercise) themeColor = const Color(0xFF1447E6);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: themeColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF2C3E50),
                height: 1.6,
                fontFamily: 'STKaiti',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Column(
      children: [
        if (widget.report.riskWarning.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9E6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE58F), width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFFD4A520),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.report.riskWarning,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF856404),
                      fontFamily: 'STKaiti',
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3C9566),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text(
                  '完成',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'STKaiti',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copySummary,
                icon: const Icon(Icons.copy, size: 18),
                label: const Text(
                  '一键复制摘要',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'STKaiti',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D4A3E),
                  side: const BorderSide(color: Color(0xFFCAD5CC)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
