import 'package:material_ui/material_ui.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../telegram/models.dart';
import 'bubble_media.dart';
import 'bubble_shape.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.showSender,
    required this.isFirst,
    required this.isLast,
    required this.onLongPress,
    required this.onPhotoTap,
  });

  final Message message;
  final bool showSender;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onLongPress;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final bool outgoing = message.outgoing;
    final Color foreground = outgoing ? colors.onBubbleOut : colors.textPrimary;
    final bool hasMedia = message.kind != 'text' &&
        message.kind != 'service' &&
        message.kind != 'other';
    final BorderRadius radius = bubbleRadius(
      outgoing: outgoing,
      isFirst: isFirst,
      isLast: isLast,
    );

    if (message.kind == 'sticker') {
      return Align(
        alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
        child: GestureDetector(
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
            child: BubbleMedia(
              message: message,
              outgoing: outgoing,
              onPhotoTap: onPhotoTap,
            ),
          ),
        ),
      );
    }

    final Color background = outgoing ? colors.bubbleOut : colors.bubbleIn;

    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          6,
          isFirst ? 5 : 1,
          6,
          isLast ? 5 : 1,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.79,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              GestureDetector(
                onLongPress: onLongPress,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    hasMedia ? 5 : 11,
                    hasMedia ? 5 : 7,
                    hasMedia ? 5 : 11,
                    6,
                  ),
                  decoration: BoxDecoration(
                    color: outgoing ? null : background,
                    gradient: outgoing
                        ? LinearGradient(
                            colors: <Color>[
                              const Color(0xFF38AAF5),
                              colors.bubbleOut,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          )
                        : null,
                    borderRadius: radius,
                    border: outgoing
                        ? null
                        : Border.all(
                            color: colors.separator,
                            width: 0.6,
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (showSender && !outgoing && message.sender.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 1, 2, 3),
                          child: Text(
                            message.sender,
                            style: AppText.caption.copyWith(
                              color: colors.accent,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (message.replyToText.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                          decoration: BoxDecoration(
                            color: (outgoing ? Colors.black : colors.accent)
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(9),
                            border: Border(
                              left: BorderSide(
                                color: outgoing
                                    ? Colors.white
                                    : colors.accent,
                                width: 2.5,
                              ),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (message.replyToSender.isNotEmpty)
                                Text(
                                  message.replyToSender,
                                  style: AppText.caption.copyWith(
                                    color: outgoing
                                        ? Colors.white
                                        : colors.accent,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              Text(
                                message.replyToText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.caption.copyWith(
                                  color: outgoing
                                      ? Colors.white70
                                      : colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (hasMedia)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: message.text.isEmpty ? 2 : 5,
                          ),
                          child: BubbleMedia(
                            message: message,
                            outgoing: outgoing,
                            onPhotoTap: onPhotoTap,
                          ),
                        ),
                      if (message.text.isNotEmpty &&
                          message.kind != 'sticker')
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            hasMedia ? 7 : 0,
                            0,
                            hasMedia ? 7 : 0,
                            0,
                          ),
                          child: Text(
                            message.text,
                            style: AppText.body.copyWith(
                              color: foreground,
                              fontSize: 16,
                              height: 1.25,
                            ),
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 3,
                            left: hasMedia ? 7 : 0,
                            right: hasMedia ? 7 : 0,
                          ),
                          child: _footer(colors, outgoing),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isLast)
                Positioned(
                  bottom: 0,
                  right: outgoing ? -5.5 : null,
                  left: outgoing ? null : -5.5,
                  child: BubbleTail(color: background, outgoing: outgoing),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(AppColors colors, bool outgoing) {
    final Color tint = outgoing ? Colors.white70 : colors.textSecondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (message.edited)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              'edited',
              style: AppText.caption.copyWith(color: tint, fontSize: 10.5),
            ),
          ),
        Text(
          messageTime(message.date),
          style: AppText.caption.copyWith(color: tint, fontSize: 11),
        ),
        const SizedBox(width: 3),
        if (message.failed)
          const Icon(Icons.error_outline, size: 13, color: Colors.redAccent)
        else if (message.outgoing)
          Icon(
            message.pending
                ? Icons.schedule
                : (message.read ? Icons.done_all : Icons.done),
            size: 14,
            color: message.read ? Colors.white : Colors.white70,
          ),
      ],
    );
  }
}
