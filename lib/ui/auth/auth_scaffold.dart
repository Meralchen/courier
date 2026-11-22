import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../state/scopes.dart';
import '../components/glass.dart';
import '../components/ios_ui.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.showBrand = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final bool showBrand;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final String version = TelegramScope.of(context).tdlibVersion;
    return Scaffold(
      backgroundColor: colors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: LiquidWallpaper(
              base: colors.chatBackdrop,
              dark: colors.dark,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (showBrand) ...<Widget>[
                        const Center(child: BrandMark(size: 66)),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppText.largeTitle.copyWith(
                          color: colors.textPrimary,
                          fontSize: 29,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: AppText.subhead.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 22),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        radius: 22,
                        tintAmount: colors.dark ? 52 : 40,
                        child: child,
                      ),
                      if (footer != null) ...<Widget>[
                        const SizedBox(height: 18),
                        footer!,
                      ],
                      const SizedBox(height: 24),
                      Text(
                        version.isEmpty
                            ? 'Secure messenger · TDLib'
                            : 'Secure messenger · TDLib $version',
                        textAlign: TextAlign.center,
                        style: AppText.caption.copyWith(
                          color: colors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
