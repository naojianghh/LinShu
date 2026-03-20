import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingshu_app/utils/log_util.dart';

class ConstitutionTimelineScreen extends StatelessWidget {
  const ConstitutionTimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFCF7),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF244438)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
        title: const Text(
          '体质演化时间轴',
          style: TextStyle(
            color: Color(0xFF244438),
            fontFamily: 'STKaiti',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            SizedBox(
              height: 36.h,
              child: Row(
                children: [
                  Expanded(child: _switchBtn('月度报告', true)),
                  const SizedBox(width: 10),
                  Expanded(child: _switchBtn('季度报告', false)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _radarCard(),
            const SizedBox(height: 14),
            _achievementCard(),
            const SizedBox(height: 14),
            _trendCard(),
            const SizedBox(height: 14),
            _aiPredictCard(),
          ],
        ),
      ),
    );
  }

  Widget _switchBtn(String title, bool selected) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFF0DCA9) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? const Color(0xFFF0DCA9) : const Color(0xFFE8DCC8)),
        boxShadow: selected
            ? [
                BoxShadow(
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                  color: Colors.grey
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF6F6256),
            fontFamily: 'STKaiti',
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _radarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8DCC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '体质雷达图',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF244438),
              fontFamily: 'STKaiti',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(8.r),
            height: 280,
            child: ConstitutionRadarChart(
              labels: ['寒气', '湿气', '气血', '气郁', '瘀滞'],
              values: [0.38, 0.22, 0.62, 0.27, 0.35],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Expanded(child: _MetricItem('寒气值', '35',false,'20')),
              SizedBox(width: 10),
              Expanded(child: _MetricItem('湿气值', '45',false,'5')),
              SizedBox(width: 10),
              Expanded(child: _MetricItem('气血值', '75',true, '20')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _achievementCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FAF1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA9DCB3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset('assets/images/award_icon.png', width: 20.w,),
              SizedBox(width: 8.w,),
              const Text(
                '养生成就',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF244438),
                  fontFamily: 'STKaiti',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _achieveItem(
            '🎯 宫寒指数下降 20%',
            '本月你坚持饮用了15次“姜枣茶”，数据显示你的宫寒指数从55降至35，痛经评分从8分降至3分。继续保持！',
            const Color(0xFF3C9566),
            '-20%',
          ),
          const SizedBox(height: 10),
          _achieveItem(
            '💪 气血充盈度提升 20%',
            '坚持记录周期并按建议饮食，气血水平从55提升至75，整体精神状态明显改善。',
            const Color(0xFFF09B3F),
            '+20%',
          ),
        ],
      ),
    );
  }

  Widget _achieveItem(
    String title,
    String desc,
    Color progressColor,
    String tag,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF244438),
              fontFamily: 'STKaiti',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6F6256),
              fontFamily: 'STKaiti',
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.65,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEDEBE6),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                tag,
                style: TextStyle(
                  color: progressColor,
                  fontFamily: 'STKaiti',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trendCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8DCC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '月度趋势',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF244438),
              fontFamily: 'STKaiti',
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                _MonthBar(month: '12月', top: 0.45, bottom: 0.35),
                _MonthBar(month: '1月', top: 0.5, bottom: 0.3),
                _MonthBar(month: '2月', top: 0.55, bottom: 0.28),
                _MonthBar(month: '3月', top: 0.72, bottom: 0.18),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: Color(0xFF3EA76E), text: '气血值'),
              SizedBox(width: 16),
              _Legend(color: Color(0xFF4CA9F0), text: '寒气值'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aiPredictCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1DCA6)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔮 AI 健康预测',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF244438),
              fontFamily: 'STKaiti',
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          _PredictLine('📈 按照当前趋势，预计下个月你的整体气血水平将达到 "优良" 等级。'),
          SizedBox(height: 10),
          _PredictLine('💡 建议继续保持当前的饮食和作息习惯，下次经期可能不会出现明显痛经症状。'),
          SizedBox(height: 10),
          _PredictLine('🌸 预计 4月中旬进入最佳受孕期，身体状态最佳。'),
        ],
      ),
    );
  }
}

class ConstitutionRadarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;

  const ConstitutionRadarChart({
    super.key,
    required this.labels,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            children: [
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: CustomPaint(painter: _RadarPainter(values: values)),
                ),
              ),
              ...List.generate(labels.length, (index) {
                final angle =
                    -math.pi / 2 + (2 * math.pi / labels.length) * index;
                final radius = size / 2 - 8;
                final labelRadius = radius;
                final cx = constraints.maxWidth / 2;
                final cy = constraints.maxHeight / 2;
                final x = cx + labelRadius * math.cos(angle);
                final y = cy + labelRadius * math.sin(angle);
                Log.d('index: $index labels: ${labels[index]} x: $x y: $y');

                return Positioned(
                  left: x - 28,
                  top: y - 12,
                  child: SizedBox(
                    width: 56,
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF6F6256),
                        fontFamily: 'STKaiti',
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _RadarPainter extends CustomPainter {
  final List<double> values;

  _RadarPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 36;
    const axes = 5;

    final gridPaint = Paint()
      ..color = const Color(0xFFDCCFB8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final axisPaint = Paint()
      ..color = const Color(0xFFDCCFB8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    for (int level = 1; level <= 4; level++) {
      final r = radius * level / 4;
      canvas.drawCircle(center, r, gridPaint);
    }

    for (int i = 0; i < axes; i++) {
      final angle = -math.pi / 2 + (2 * math.pi / axes) * i;
      final p = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, p, axisPaint);
    }

    final points = <Offset>[];
    for (int i = 0; i < axes; i++) {
      final value = values[i].clamp(0.0, 1.0);
      final angle = -math.pi / 2 + (2 * math.pi / axes) * i;
      final p = Offset(
        center.dx + radius * value * math.cos(angle),
        center.dy + radius * value * math.sin(angle),
      );
      points.add(p);
    }

    final dataPath = Path()..addPolygon(points, true);

    final fillPaint = Paint()
      ..color = const Color(0xFF78B593).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF3F9A6A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawPath(dataPath, fillPaint);
    canvas.drawPath(dataPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _MetricItem extends StatelessWidget {
  final String title;
  final String value;
  final bool isUp;
  final String change;

  const _MetricItem(this.title, this.value, this.isUp,this.change);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAF8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF7A6C60),
              fontFamily: 'STKaiti',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFF244438),
                  fontFamily: 'STKaiti',
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isUp ? '↗' : '↘',
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF3C9566),
                ),
              ),
              Text(
                change,
                style: const TextStyle(
                  fontSize: 10,
                  color: Color(0xFF3C9566),
                ),
              )

            ],
          ),
        ],
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  final String month;
  final double top;
  final double bottom;

  const _MonthBar({
    required this.month,
    required this.top,
    required this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: double.infinity,
              height: 170,
              decoration: BoxDecoration(
                color: const Color(0xFFF6F6F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  FractionallySizedBox(
                    heightFactor: top,
                    widthFactor: 1,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2E9B68), Color(0xFF61C173)],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  FractionallySizedBox(
                    heightFactor: bottom,
                    widthFactor: 1,
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4AA5EC), Color(0xFF79C0FF)],
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              month,
              style: const TextStyle(
                color: Color(0xFF7A6C60),
                fontFamily: 'STKaiti',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 7, backgroundColor: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF7A6C60),
            fontFamily: 'STKaiti',
          ),
        ),
      ],
    );
  }
}

class _PredictLine extends StatelessWidget {
  final String text;

  const _PredictLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF6F6256),
          fontFamily: 'STKaiti',
          height: 1.45,
        ),
      ),
    );
  }
}
