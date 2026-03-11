import 'package:flutter/material.dart';

/// 顶部大 Banner 下方的山水插画装饰。
///
/// 设计目标：
/// - 水平铺满（按屏幕宽度缩放）
/// - 贴合在 Banner 底部边缘（不影响 Banner 的圆角裁切）
/// - 轻透明度，不遮挡主体内容
class BannerLandscapeDecoration extends StatelessWidget {
  final String asset;
  final double height;
  final double opacity;

  const BannerLandscapeDecoration({
    super.key,
    this.asset = 'assets/images/home_decoration_bg.png',
    this.height = 60,
    this.opacity = 0.9,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Image.asset(
            asset,
            fit: BoxFit.fitWidth,
            alignment: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}
