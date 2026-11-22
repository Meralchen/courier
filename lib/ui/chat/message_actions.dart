import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../telegram/models.dart';

Future<String?> showEditMessageDialog(
  BuildContext context,
  Message message,
) async {
  final TextEditingController controller =
      TextEditingController(text: message.text);
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
