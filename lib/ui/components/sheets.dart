import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import 'glass.dart';
import 'pressable.dart';

class SheetAction<T> {
  const SheetAction({
    required this.label,
    this.icon,
    this.value,
    this.destructive = false,
  });

  final String label;
  final IconData? icon;
  final T? value;
  final bool destructive;
}

Future<T?> showActionSheet<T>(
  BuildContext context, {
  required String title,
  required List<SheetAction<T>> actions,
}) {
  return showModalBottomSheet<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.30),
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) {
      final AppColors colors = AppColors.of(sheetContext);
      return Padding(
        padding: EdgeInsets.fromLTRB(
          10,
          0,
          10,
          // `useSafeArea` only clears the status bar; an action sheet still has
          // to sit above the home indicator or its last row is unreachable.
          10 + MediaQuery.viewPaddingOf(sheetContext).bottom,
        ),
        child: GlassCard(
          radius: GlassRadius.sheet,
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
          tintAmount: colors.dark ? 62 : 48,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
                child: Text(
                  title,
                  style: AppText.footnote.copyWith(color: colors.textSecondary),
                ),
              ),
              for (final SheetAction<T> action in actions)
                Pressable(
                  onTap: () => Navigator.of(sheetContext).pop(action.value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      children: <Widget>[
                        if (action.icon != null) ...<Widget>[
                          Icon(
                            action.icon,
                            size: 19,
                            color: action.destructive
                                ? colors.danger
                                : colors.textPrimary,
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: Text(
                            action.label,
                            style: AppText.body.copyWith(
                              fontSize: 16.5,
                              color: action.destructive
                                  ? colors.danger
                                  : colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              Pressable(
                onTap: () => Navigator.of(sheetContext).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  child: Text(
                    'Cancel',
                    style: AppText.title.copyWith(color: colors.accent),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<bool> showGlassConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Continue',
  bool destructive = false,
}) async {
  final AppColors colors = AppColors.of(context);
  final bool? result = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(message),
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            confirmLabel,
            style: TextStyle(
              color: destructive ? colors.danger : colors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  if (result == true) Haptics.medium();
  return result ?? false;
}
