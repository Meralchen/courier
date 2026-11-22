import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/theme.dart';
import '../../telegram/models.dart';
import '../components/pressable.dart';

/// Telegram-iOS puts a QR button in the settings bar. The code encodes the
/// account's public link, which is what the iOS sheet does too.
Future<void> showProfileQr(BuildContext context, Profile? me) async {
  final String link = me == null
      ? 'https://t.me'
      : (me.username.isNotEmpty
            ? 'https://t.me/${me.username}'
            : 'tg://user?id=${me.id}');
  final AppColors colors = AppColors.of(context);
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        26,
        0,
        26,
        26 + MediaQuery.viewPaddingOf(sheetContext).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              me?.name ?? 'Courier user',
              style: AppText.headline.copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              me == null
                  ? 'Sign in to show your code'
                  : (me.username.isNotEmpty
                        ? '@${me.username}'
                        : (me.phone.isEmpty ? 'Telegram account' : me.phone)),
              style: AppText.subhead.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: QrImageView(
                data: link,
                version: QrVersions.auto,
                size: 218,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF000000),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF000000),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              link,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 14),
            Pressable(
              onTap: () => Navigator.of(sheetContext).pop(),
              child: Text(
                'Done',
                style: AppText.title.copyWith(color: colors.accent),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
