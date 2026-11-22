import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../telegram/models.dart';
import '../components/glass.dart';
import '../components/pressable.dart';

class Composer extends StatefulWidget {
  const Composer({
    super.key,
    required this.controller,
    required this.replyTo,
    required this.onCancelReply,
    required this.onSend,
    required this.onPickPhoto,
    required this.onTyping,
    this.sendingPhoto = false,
  });

  final TextEditingController controller;
  final Message? replyTo;
  final VoidCallback onCancelReply;
  final ValueChanged<String> onSend;
  final VoidCallback onPickPhoto;
  final ValueChanged<bool> onTyping;
  final bool sendingPhoto;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  Timer? _typingTimer;
  bool _typing = false;

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  void _changed(String value) {
    if (value.trim().isEmpty) {
      _stopTyping();
      return;
    }
    if (!_typing) {
      _typing = true;
      widget.onTyping(true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 2600), _stopTyping);
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    if (_typing) {
      _typing = false;
      widget.onTyping(false);
    }
  }

  void _send() {
    final String text = widget.controller.text.trim();
    if (text.isEmpty) return;
    _stopTyping();
    widget.onSend(text);
  }

  Future<void> _emojiGrid() async {
    const List<String> emoji = <String>[
      '😀', '😂', '🥹', '😍', '😘', '😎', '🤔', '😴',
      '👍', '👏', '🙏', '💪', '🔥', '💙', '🎉', '✨',
      '❤️', '😭', '😅', '🤯', '🥳', '😇', '🤝', '👀',
    ];
    final String? picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (BuildContext sheetContext) {
        final AppColors colors = AppColors.of(sheetContext);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: GlassCard(
              radius: 26,
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: <Widget>[
                  for (final String item in emoji)
                    Pressable(
                      onTap: () => Navigator.of(sheetContext).pop(item),
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: colors.card.withValues(alpha: 0.25),
                        ),
                        child: Text(item, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (picked == null || !mounted) return;
    final TextEditingValue value = widget.controller.value;
    final TextSelection selection = value.selection;
    final int start = selection.isValid ? selection.start : value.text.length;
    final int end = selection.isValid ? selection.end : value.text.length;
    final String text = value.text.replaceRange(start, end, picked);
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + picked.length),
    );
    _changed(text);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        4,
        8,
        MediaQuery.paddingOf(context).bottom + 6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (widget.replyTo != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GlassCard(
                radius: 16,
                padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 2.5,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.replyTo!.outgoing
                                ? 'Reply to yourself'
                                : (widget.replyTo!.sender.isEmpty
                                    ? 'Reply'
                                    : widget.replyTo!.sender),
                            style: AppText.caption.copyWith(
                              color: colors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            widget.replyTo!.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onCancelReply,
                      icon: Icon(Icons.close, size: 17, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          GlassBar(
            radius: 25,
            tintAmount: colors.dark ? 65 : 52,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                IconButton(
                  onPressed: widget.sendingPhoto ? null : widget.onPickPhoto,
                  icon: widget.sendingPhoto
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colors.accent,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.attach_file,
                          color: colors.textSecondary,
                          size: 21,
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: TextField(
                      controller: widget.controller,
                      onChanged: _changed,
                      minLines: 1,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      keyboardType: TextInputType.multiline,
                      style: AppText.body.copyWith(
                        color: colors.textPrimary,
                        fontSize: 16,
                      ),
                      cursorColor: colors.accent,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Message',
                        hintStyle: AppText.body.copyWith(
                          color: colors.textSecondary,
                          fontSize: 16,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _emojiGrid,
                  icon: Icon(
                    Icons.emoji_emotions_outlined,
                    color: colors.textSecondary,
                    size: 21,
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller,
                  builder: (BuildContext context, TextEditingValue value, _) {
                    final bool hasText = value.text.trim().isNotEmpty;
                    return GestureDetector(
                      onTap: hasText
                          ? () {
                              Haptics.light();
                              _send();
                            }
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Voice messages are not part of this build yet.',
                                  ),
                                ),
                              ),
                      child: AnimatedContainer(
                        duration: Motion.fast,
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(left: 1, bottom: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasText
                              ? colors.accent
                              : colors.textSecondary.withValues(alpha: 0.16),
                        ),
                        child: Icon(
                          hasText ? Icons.arrow_upward : Icons.mic_none,
                          color: hasText ? Colors.white : colors.textSecondary,
                          size: 20,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
