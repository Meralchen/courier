import 'package:material_ui/material_ui.dart';

import '../core/theme.dart';
import 'components/glass.dart';
import 'components/ios_ui.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, this.signingOut = false});

  final bool signingOut;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: LiquidWallpaper(
              base: colors.chatBackdrop,
              dark: colors.dark,
              intensity: 0.9,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.86, end: 1),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutBack,
                  builder: (BuildContext context, double scale, Widget? child) =>
                      Transform.scale(scale: scale, child: child),
                  child: const BrandMark(size: 96),
                ),
                const SizedBox(height: 20),
                Text(
                  'Courier',
                  style: AppText.largeTitle.copyWith(
                    color: colors.textPrimary,
                    fontSize: 30,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  signingOut ? 'Signing out…' : 'Connecting to Telegram…',
                  style: AppText.subhead.copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
