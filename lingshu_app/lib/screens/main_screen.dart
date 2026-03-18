import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      body: Expanded(child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Expanded(child: Column(
            children: [
              Expanded(
                child: _pages[_index],
              ),
              SizedBox(height: 80.h)
            ],
          )),
          SafeArea(
              child: Container(
                height: 88.h,
                decoration: BoxDecoration(
                  color: Colors.transparent,//const Color(0xFFF8F5ED),
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    // 背景和其他图标
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                          width: 84.w,
                          height: 84.w,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(42.r),
                              gradient: RadialGradient(
                                center: Alignment.center,
                                radius: 0.8,
                                  colors: [
                                    const Color(0xFFCCCCCC).withValues(alpha: 0.5),
                                    const Color(0xFFCCCCCC).withValues(alpha: 0.4),
                                    const Color(0xFFCCCCCC).withValues(alpha: 1),
                                    const Color(0xFFE3E3E3).withValues(alpha: 0.5),
                                    const Color(0xFFE3E3E3).withValues(alpha: 0.1),
                                    const Color(0xFFE3E3E3).withValues(alpha: 0.00),
                                  ]
                              )
                          )
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 3.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFFE3E3E3).withValues(alpha: 0.1),
                                const Color(0xFFE3E3E3).withValues(alpha: 0.2),
                                const Color(0xFFCCCCCC).withValues(alpha: 0.3),
                                const Color(0xFFCCCCCC).withValues(alpha: 0.4),
                                const Color(0xFFCCCCCC).withValues(alpha: 0.5),
                              ]
                            )
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: _buildNavItem(0, 'assets/images/home_icon.png', 'assets/images/home_selected_icon.png'),),
                            Expanded(child: _buildNavItem(1, 'assets/images/ask_icon.png', 'assets/images/ask_selected_icon.png'),),
                            Expanded(child: Container(
                              height: 56.h,
                              decoration: BoxDecoration(color: const Color(0xFFFCFBF6)),)),
                            Expanded(child: _buildNavItem(3, 'assets/images/mind_icon.png', 'assets/images/mind_selected_icon.png')),
                            Expanded(child: _buildNavItem(4, 'assets/images/sport_icon.png', 'assets/images/sport_selected_icon.png')),
                          ],
                        )
                      ],
                    ),
                    _buildCenterNavItem(2, 'assets/images/godness_icon.png', 'assets/images/godness_selected_icon.png')
                  ],
                ),
              )
          )
        ],
      )),
    );
  }

  Widget _buildCenterNavItem(int index, String icon, String selectedIcon) {
    final bool isSelected = _index == index;
    
    return GestureDetector(
      onTap: () => setState(() => _index = index),
      child: Container(
        width: 80.w,
        height: 80.w,
        decoration: BoxDecoration(
          color: const Color(0xFFFCFBF6),
          borderRadius: BorderRadius.circular(40.r),
        ),
        child: Center(
            child: Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(32.r),
              ),
              child: Center(
                child: Image.asset(
                  height: 48.h,
                  isSelected ? selectedIcon : icon,
                ),
              ),
            )
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String icon, String selectedIcon) {
    final bool isSelected = _index == index;
    
    // 非中间图标的处理
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFCFBF6),
      ),
      child: GestureDetector(
        onTap: () => setState(() => _index = index),
        child: AnimatedContainer(
          duration: isSelected ? const Duration(milliseconds: 260) : const Duration(microseconds: 0),
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          child: Image.asset(
            height: 48.h,
            isSelected ? selectedIcon : icon,
          ),
        )
      ),
    );
  }
}

