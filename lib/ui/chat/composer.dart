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
    required this.onAttach,
    required this.onTyping,
    this.sendingAttachment = false,
    this.onOpenStickers,
    this.onVoiceStart,
    this.onVoiceFinish,
  });

  final TextEditingController controller;
  final Message? replyTo;
  final VoidCallback onCancelReply;
  final ValueChanged<String> onSend;
  final VoidCallback onAttach;
  final ValueChanged<bool> onTyping;
  final bool sendingAttachment;

  /// Opens the sticker keyboard. Falls back to the built-in emoji sheet when a
  /// caller does not provide one.
  final Future<void> Function()? onOpenStickers;

  /// Starts a voice recording. Returns false when the microphone was denied,
  /// so the composer never shows a recording that is not happening.
  final Future<bool> Function()? onVoiceStart;

  /// Stops the recording. [send] is false when the gesture was cancelled.
  final Future<void> Function(bool send)? onVoiceFinish;

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  Timer? _typingTimer;
  Timer? _recordTimer;
  bool _typing = false;
  bool _recording = false;
  int _recordSeconds = 0;

  @override
  void dispose() {
    _typingTimer?.cancel();
    _recordTimer?.cancel();
    if (_recording) widget.onVoiceFinish?.call(false);
    super.dispose();
  }

  void _notice(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  Future<void> _beginRecording() async {
    final Future<bool> Function()? start = widget.onVoiceStart;
    if (start == null) {
      _notice('Hold the microphone to record a voice message');
      return;
    }
    try {
      final bool started = await start();
      if (!started || !mounted) return;
      setState(() {
        _recording = true;
        _recordSeconds = 0;
      });
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _recordSeconds++);
      });
    } catch (error) {
      if (mounted) _notice('Could not record: $error');
    }
  }

  Future<void> _finishRecording(bool send) async {
    if (!_recording) return;
    _recordTimer?.cancel();
    setState(() {
      _recording = false;
      _recordSeconds = 0;
    });
    try {
      await widget.onVoiceFinish?.call(send);
    } catch (error) {
      if (mounted) _notice('Could not send the voice message: $error');
    }
  }

  String get _recordLabel {
    final String seconds = (_recordSeconds % 60).toString().padLeft(2, '0');
    return '${_recordSeconds ~/ 60}:$seconds';
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
      '😀',
      '😂',
      '🥹',
      '😍',
      '😘',
      '😎',
      '🤔',
      '😴',
      '👍',
      '👏',
      '🙏',
      '💪',
      '🔥',
      '💙',
      '🎉',
      '✨',
      '❤️',
      '😭',
      '😅',
      '🤯',
      '🥳',
      '😇',
      '🤝',
      '👀',
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

  Widget _actionButton({required bool hasText, required AppColors colors}) {
    if (_recording) {
      return GestureDetector(
        onTap: () => _finishRecording(true),
        child: Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.only(left: 1, bottom: 1),
          decoration: const BoxDecoration(
            color: Colors.redAccent,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.stop, color: Colors.white, size: 20),
        ),
      );
    }
    if (hasText) {
      return GestureDetector(
        onTap: () {
          Haptics.light();
          _send();
        },
        child: Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.only(left: 1, bottom: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.accent,
          ),
          child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
        ),
      );
    }
    // iOS records while the microphone is held; releasing sends.
    return GestureDetector(
      onTap: () => _notice('Hold the microphone to record a voice message'),
      onLongPressStart: (LongPressStartDetails _) => _beginRecording(),
      onLongPressEnd: (LongPressEndDetails _) => _finishRecording(true),
      onLongPressCancel: () => _finishRecording(false),
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.only(left: 1, bottom: 1),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colors.textSecondary.withValues(alpha: 0.16),
        ),
        child: Icon(Icons.mic_none, color: colors.textSecondary, size: 20),
      ),
    );
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
                      icon: Icon(
                        Icons.close,
                        size: 17,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_recording)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recording  $_recordLabel',
                      style: AppText.subhead.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Release to send',
                      style: AppText.caption.copyWith(
                        color: colors.textSecondary,
                      ),
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
                  onPressed: widget.sendingAttachment ? null : widget.onAttach,
                  icon: widget.sendingAttachment
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
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    padding: const EdgeInsets.only(left: 13, right: 1),
                    decoration: BoxDecoration(
                      color: colors.textSecondary.withValues(
                        alpha: colors.dark ? 0.20 : 0.11,
                      ),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
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
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: widget.onOpenStickers == null
                              ? _emojiGrid
                              : () {
                                  widget.onOpenStickers!();
                                },
                          icon: Icon(
                            Icons.emoji_emotions_outlined,
                            color: colors.textSecondary,
                            size: 21,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: widget.controller,
                  builder: (BuildContext context, TextEditingValue value, _) {
                    final bool hasText = value.text.trim().isNotEmpty;
                    return _actionButton(hasText: hasText, colors: colors);
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
