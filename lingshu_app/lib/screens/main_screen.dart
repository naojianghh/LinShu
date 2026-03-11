import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'home_screen.dart';
import 'ai_diagnosis_screen.dart';
import 'goddess_screen.dart';
import 'meditation_main_screen.dart';
import 'sport_main_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  List<Widget> get _pages => <Widget>[
    HomeScreen(onFeatureTap: _onFeatureTap),
    const AiDiagnosisScreen(),
    const GoddessScreen(),
    const MeditationMainScreen(),
    const SportMainScreen(),
  ];

  void _onFeatureTap(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: Container(
        height: 88,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F5ED),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B7D6B).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, '首页', 'assets/images/icon_nav_home.svg'),
              _buildNavItem(1, '望闻问切', 'assets/images/icon_nav_diagnosis.svg'),
              _buildNavItem(2, '女神专区', 'assets/images/icon_nav_goddess.svg'),
              _buildNavItem(3, '心灵栖息', 'assets/images/icon_nav_meditation.svg'),
              _buildNavItem(4, '智能运动', 'assets/images/icon_nav_sport.svg'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String icon) {
    final bool isSelected = _index == index;

    return SizedBox(
      width: 72,
      child: InkResponse(
        onTap: () => setState(() => _index = index),
        radius: 36,
        splashColor: const Color(0xFF3C9566).withValues(alpha: 0.10),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFE8F5ED)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF3C9566,
                            ).withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : const [],
                ),
                child: SvgPicture.asset(
                  icon,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? const Color(0xFF3C9566)
                        : const Color(0xFF8B7D6B),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontFamily: 'STKaiti',
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? const Color(0xFF3C9566)
                      : const Color(0xFF8B7D6B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
