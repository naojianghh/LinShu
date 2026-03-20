import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CycleRecordScreen extends StatefulWidget {
  const CycleRecordScreen({super.key});

  @override
  State<CycleRecordScreen> createState() => _CycleRecordScreenState();
}

class _CycleRecordScreenState extends State<CycleRecordScreen> {
  DateTime? _periodStartDate;
  DateTime? _periodEndDate;

  final List<String> _symptoms = const [
    '痛经',
    '腰酸',
    '头痛',
    '情绪波动',
    '疲劳',
    '乳房胀痛',
    '腹胀',
    '失眠',
  ];
  final Set<String> _selectedSymptoms = {'痛经', '腰酸'};
  int _flowIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCF7),
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: const Color(0xFFFDFCF7),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B5D4F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '生理周期记录',
          style: TextStyle(
            color: Color(0xFF244438),
            fontFamily: 'STKaiti',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: FilledButton.icon(
              onPressed: _showRecordDialog,
              style: FilledButton.styleFrom(
                fixedSize: Size(74.w, 34.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                backgroundColor: const Color(0xFFF54888),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add, size: 14),
              label: Text(
                '记录',
                style: TextStyle(fontSize: 12.sp, fontFamily: 'STKaiti'),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            _buildStatsCard(),
            const SizedBox(height: 22),
            const Text(
              '记录历史',
              style: TextStyle(
                fontSize: 36 / 2,
                color: Color(0xFF244438),
                fontFamily: 'STKaiti',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _historyCard('2月25日', '5天', {'轻微痛经', '疲劳'}, '第一天状态尚可，第二天有些疲倦'),
            const SizedBox(height: 14),
            _historyCard('1月28日', '6天', {'痛经', '腰酸'}, '需要注意保暖'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F6FB),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFA6DBE8)),
              ),
              child: const Text(
                'AI 智能分析\n\n您的周期较为规律（平均28天），经期约6天。建议在经期前3天开始饮用姜枣茶，可有效缓解痛经症状。预计下次经期将在21天后到来。',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF3C4B46),
                  height: 1.6,
                  fontFamily: 'STKaiti',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF6B7CC)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '周期统计',
            style: TextStyle(
              fontSize: 20,
              color: Color(0xFF244438),
              fontFamily: 'STKaiti',
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(num: '28', label: '平均周期(天)', color: Color(0xFFF54888)),
              _StatItem(num: '6', label: '经期天数', color: Color(0xFFFB729C)),
              _StatItem(num: '21', label: '距下次(天)', color: Color(0xFF3C9566)),
            ],
          ),
          Divider(height: 30, color: Color(0xFFF7D7E3)),
          Text(
            '上次经期开始',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6F6256),
              fontFamily: 'STKaiti',
            ),
          ),
          SizedBox(height: 8),
          Text(
            '2026年2月25日',
            style: TextStyle(
              fontSize: 22,
              color: Color(0xFF244438),
              fontFamily: 'STKaiti',
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCard(
    String date,
    String duration,
    Set<String> tags,
    String desc,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DCC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: Color(0xFFF54888),
              ),
              const SizedBox(width: 8),
              Text(
                '$date($duration)',
                style: const TextStyle(
                  fontSize: 17,
                  color: Color(0xFF244438),
                  fontFamily: 'STKaiti',
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDD8E7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '中量',
                  style: TextStyle(
                    color: Color(0xFFF54888),
                    fontFamily: 'STKaiti',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tags
                .map(
                  (t) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F3EF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6F6256),
                        fontFamily: 'STKaiti',
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6F6256),
              fontFamily: 'STKaiti',
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({
    required bool isStart,
    required StateSetter setInnerState,
  }) async {
    final now = DateTime.now();
    final initialDate = isStart
        ? (_periodStartDate ?? now)
        : (_periodEndDate ?? _periodStartDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('zh'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: TextTheme(
              displayLarge: TextStyle(fontFamily: 'STKaiti'),
              displayMedium: TextStyle(fontFamily: 'STKaiti'),
              displaySmall: TextStyle(fontFamily: 'STKaiti'),
              headlineLarge: TextStyle(fontFamily: 'STKaiti'),
              headlineMedium: TextStyle(fontSize: 20, fontFamily: 'STKaiti'),
              headlineSmall: TextStyle(fontFamily: 'STKaiti'),
              titleLarge: TextStyle(fontFamily: 'STKaiti'),
              titleMedium: TextStyle(fontFamily: 'STKaiti'),
              titleSmall: TextStyle(fontFamily: 'STKaiti'),
              bodyLarge: TextStyle(fontSize: 14, fontFamily: 'STKaiti'),
              bodyMedium: TextStyle(fontSize: 12, fontFamily: 'STKaiti'),
              bodySmall: TextStyle(fontFamily: 'STKaiti'),
              labelLarge: TextStyle(fontFamily: 'STKaiti'),
              labelMedium: TextStyle(fontFamily: 'STKaiti'),
              labelSmall: TextStyle(fontFamily: 'STKaiti'),
            ),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFF54888),
              onPrimary: Colors.white,
              onSurface: Color(0xFF244438),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setInnerState(() {
      if (isStart) {
        _periodStartDate = picked;
        if (_periodEndDate != null && _periodEndDate!.isBefore(picked)) {
          _periodEndDate = null;
        }
      } else {
        _periodEndDate = picked;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}年${date.month}月${date.day}日';
  }

  Widget _datePickerField({
    required String text,
    required String hint,
    required VoidCallback onTap,
    bool requiredField = false,
  }) {
    final isEmpty = text.isEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 37.h,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCFCFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: requiredField && isEmpty
                ? const Color(0xFFF54888)
                : const Color(0xFFE8DCC8),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                isEmpty ? hint : text,
                style: TextStyle(
                  fontSize: 12,
                  color: isEmpty
                      ? const Color(0xFF9D9287)
                      : const Color(0xFF244438),
                  fontFamily: 'STKaiti',
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: Color(0xFF9D9287),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 16.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            height: 600.h,
            child: StatefulBuilder(
              builder: (context, setInnerState) {
                return Padding(
                  padding: EdgeInsets.all(
                    16.r
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '记录经期',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF244438),
                            fontFamily: 'STKaiti',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Row(
                          children: [
                            Text(
                              '经期开始日期',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'STKaiti',
                                color: Color(0xFF6F6256),
                              ),
                            ),
                            Text(
                              ' *',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'STKaiti',
                                color: Color(0xFFFF4D8C),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 7),
                        _datePickerField(
                          text: _formatDate(_periodStartDate),
                          hint: '请选择开始日期',
                          requiredField: true,
                          onTap: () => _pickDate(
                            isStart: true,
                            setInnerState: setInnerState,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '经期结束日期（可选）',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'STKaiti',
                            color: Color(0xFF6F6256),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _datePickerField(
                          text: _formatDate(_periodEndDate),
                          hint: '请选择结束日期',
                          onTap: () => _pickDate(
                            isStart: false,
                            setInnerState: setInnerState,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '流量',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'STKaiti',
                            color: Color(0xFF6F6256),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 32.h,
                          child: Row(
                            children: List.generate(3, (i) {
                              final labels = ['少量', '中量', '大量'];
                              final selected = _flowIndex == i;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                                  child: FilledButton(
                                    onPressed: () =>
                                        setInnerState(() => _flowIndex = i),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: selected
                                          ? const Color(0xFFF54888)
                                          : const Color(0xFFF4F3EF),
                                      foregroundColor: selected
                                          ? Colors.white
                                          : const Color(0xFF6F6256),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      labels[i],
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'STKaiti',
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '症状（多选）',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'STKaiti',
                            color: Color(0xFF6F6256),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 0,
                          children: _symptoms
                              .map(
                                (s) => ChoiceChip(
                              label: Text(
                                s,
                                style: const TextStyle(fontFamily: 'STKaiti',fontSize: 10),
                              ),
                              selected: _selectedSymptoms.contains(s),
                              selectedColor: const Color(0xFFFDD8E7),
                              backgroundColor: const Color(0xFFF4F3EF),
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              onSelected: (selected) {
                                setInnerState(() {
                                  if (selected) {
                                    _selectedSymptoms.add(s);
                                  } else {
                                    _selectedSymptoms.remove(s);
                                  }
                                });
                              },
                            ),
                          )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '备注',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'STKaiti',
                            color: Color(0xFF6F6256),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _inputBox('记录今天的感受...', maxLines: 4),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () => Navigator.pop(context),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 36),
                                  backgroundColor: const Color(0xFFF4F3EF),
                                  foregroundColor: const Color(0xFF6F6256),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  '取消',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'STKaiti',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () => Navigator.pop(context),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 36),
                                  backgroundColor: const Color(0xFFF54888),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  '保存',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'STKaiti',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        );
      },
    );
  }

  Widget _inputBox(String hint, {int maxLines = 1}) {
    return SizedBox(
      height: 80.h,
      child: TextField(
        cursorColor: const Color(0xFFF54888),
        maxLines: maxLines,
        style: TextStyle(
            fontSize: 12
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 12,
            fontFamily: 'STKaiti',
            color: Color(0xFF9D9287),
          ),
          filled: true,
          fillColor: const Color(0xFFFCFCFA),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE8DCC8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFF54888)),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String num;
  final String label;
  final Color color;

  const _StatItem({
    required this.num,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          num,
          style: TextStyle(
            fontSize: 24,
            color: color,
            fontFamily: 'STKaiti',
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6F6256),
            fontFamily: 'STKaiti',
          ),
        ),
      ],
    );
  }
}
