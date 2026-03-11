import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String logoAsset;
  final String decorationAsset;
  final double height;

  const AppHeader({
    super.key,
    this.title = '灵枢 · AI',
    this.subtitle = '智能中医健康顾问',
    this.logoAsset = 'assets/images/home_logo.png',
    this.decorationAsset = 'assets/images/header_plum.png',
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      height: height + statusBarHeight,
      width: double.infinity,
      padding: EdgeInsets.only(top: statusBarHeight),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. 文字内容区域 - 与 Logo 水平排列
          Positioned(
            left: 20,
            bottom: 12,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo 容器
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE8DCC8),
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.white,
                    backgroundImage: AssetImage(logoAsset),
                  ),
                ),
                const SizedBox(width: 12),
                // 标题与副标题
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A0A0A),
                        letterSpacing: 1.2,
                        fontFamily: 'STXinwei',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8B7D6B),
                        letterSpacing: 1.5,
                        fontFamily: 'STKaiti',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. 梅花装饰 - 右上角对齐
          Positioned(
            right: 0,
            top: 0,
            child: Opacity(
              opacity: 0.8,
              child: Image.asset(
                decorationAsset,
                height: height,
                fit: BoxFit.contain,
                alignment: Alignment.topRight,
              ),
            ),
          ),

          // 3. 底部装饰线 (可选，根据设计稿调整)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFE8DCC8).withValues(alpha: 0),
                    const Color(0xFFE8DCC8),
                    const Color(0xFFE8DCC8).withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
