import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/diagnosis_report.dart';
import '../services/diagnosis_report_db.dart';
import 'report_detail_screen.dart';

class AnalysisProgressScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<DiagnosisReport> Function() analyzeTask;

  const AnalysisProgressScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.analyzeTask,
  });

  @override
  State<AnalysisProgressScreen> createState() => _AnalysisProgressScreenState();
}

class _AnalysisProgressScreenState extends State<AnalysisProgressScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathController;

  double _progress = 0.0;
  bool _completed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _start();
  }

  Future<void> _start() async {
    _simulateProgress();
    try {
      final report = await widget.analyzeTask();
      if (!mounted) return;

      setState(() {
        _progress = 1.0;
        _completed = true;
      });

      await DiagnosisReportDb.instance.insertReport(report);
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ReportDetailScreen(report: report),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  void _simulateProgress() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 90));
      if (!mounted || _completed || _error != null) return false;
      setState(() {
        if (_progress < 0.92) {
          _progress += 0.012;
        }
      });
      return _progress < 0.92;
    });
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -5,
              right: -5,
              child: Opacity(
                opacity: 0.35,
                child: Image.asset(
                  'assets/images/header_plum.png',
                  height: 70,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCard(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.10),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildBreathingCamera(),
          const SizedBox(height: 18),
          Text(
            _error == null ? widget.title : '分析失败',
            style: const TextStyle(
              fontSize: 18,
              fontFamily: 'STKaiti',
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D4A3E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _error == null ? widget.subtitle : (_error ?? ''),
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'STKaiti',
              color: _error == null ? const Color(0xFF6B5D4F) : Colors.red,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          if (_error == null) ...[
            _ProgressBar(progress: _progress),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).round()}%',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'STKaiti',
                color: Color(0xFF6B7282),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 38,
            width: 106,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.black.withValues(alpha: 0.10)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0A0A0A),
                textStyle: const TextStyle(fontSize: 14, fontFamily: 'STKaiti'),
              ),
              onPressed: () {
                Navigator.of(context).maybePop();
              },
              child: Text(_error == null ? '取消分析' : '返回'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingCamera() {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        final t = _breathController.value;
        final scale = 0.98 + 0.04 * t;
        final shadowOpacity = 0.22 + 0.10 * t;
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: shadowOpacity * 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/analysis_progress_camera_circle.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;

  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/analysis_progress_bar_bg.png',
                fit: BoxFit.fill,
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final filled = math.max(0.0, width * p);

                return Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: filled,
                    child: Image.asset(
                      'assets/images/analysis_progress_bar_fill.png',
                      fit: BoxFit.fill,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
