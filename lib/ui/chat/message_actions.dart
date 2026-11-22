import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../telegram/models.dart';
import '../components/pressable.dart';

Future<String?> showEditMessageDialog(
  BuildContext context,
  Message message,
) async {
  final TextEditingController controller = TextEditingController(
    text: message.text,
  );
  final String? result = await showCupertinoDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) => CupertinoAlertDialog(
      title: const Text('Edit message'),
      content: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: CupertinoTextField(
          controller: controller,
          autofocus: true,
          minLines: 1,
          maxLines: 5,
          padding: const EdgeInsets.all(10),
        ),
      ),
      actions: <Widget>[
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        CupertinoDialogAction(
          onPressed: () => Navigator.of(dialogContext).pop(controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (result == null) return null;
  final String trimmed = result.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// The emoji strip iOS shows above a message's context menu. The caller passes
/// the reactions TDLib offers for this message, so it matches the account's
/// available reactions instead of a hardcoded set.
Future<String?> showReactionPicker(
  BuildContext context,
  List<String> emojis,
) async {
  if (emojis.isEmpty) return null;
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.25),
    builder: (BuildContext sheetContext) {
      final AppColors colors = AppColors.of(sheetContext);
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 2,
              children: <Widget>[
                for (final String emoji in emojis)
                  Pressable(
                    onTap: () => Navigator.of(sheetContext).pop(emoji),
                    scale: 0.8,
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> copyMessageText(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Copied to clipboard'),
      duration: Duration(milliseconds: 1400),
    ),
  );
}
