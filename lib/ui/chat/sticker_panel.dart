import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../telegram/models.dart';
import '../../telegram/telegram_store.dart';
import '../components/ios_ui.dart';
import '../components/pressable.dart';

/// The sticker keyboard iOS shows above the composer: GIFs, Stickers and Emoji
/// tabs. GIFs are the account's saved animations, stickers are the recent and
/// installed sets, and emoji types into the draft.
Future<void> showStickerPanel(
  BuildContext context, {
  required TelegramStore store,
  required ValueChanged<StickerItem> onSticker,
  required ValueChanged<String> onEmoji,
  ValueChanged<GifItem>? onGif,
}) async {
  // Open immediately and let the grids fill in: TDLib answers the sticker and
  // GIF queries a moment later, and waiting on them would leave the button
  // feeling dead.
  unawaited(store.loadStickers());
  unawaited(store.loadGifs());
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext sheetContext) => _StickerSheet(
      store: store,
      onSticker: onSticker,
      onEmoji: onEmoji,
      onGif: onGif,
    ),
  );
}

const List<String> _emoji = <String>[
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
  '😢',
  '😡',
  '🤗',
  '🤩',
  '😜',
  '🙃',
  '😬',
  '🫠',
  '💀',
  '🤡',
  '👻',
  '🎃',
  '🌚',
  '🌝',
  '☀️',
  '🌧️',
  '🍀',
  '🌸',
  '🍕',
  '☕',
  '🎮',
  '🎧',
  '🚀',
  '⚡',
];

class _StickerSheet extends StatefulWidget {
  const _StickerSheet({
    required this.store,
    required this.onSticker,
    required this.onEmoji,
    this.onGif,
  });

  final TelegramStore store;
  final ValueChanged<StickerItem> onSticker;
  final ValueChanged<String> onEmoji;
  final ValueChanged<GifItem>? onGif;

  @override
  State<_StickerSheet> createState() => _StickerSheetState();
}

class _StickerSheetState extends State<_StickerSheet> {
  /// 0 GIFs, 1 Stickers, 2 Emoji. iOS opens on Stickers.
  int _tab = 1;

  void _send(StickerItem sticker) {
    Navigator.of(context).pop();
    widget.onSticker(sticker);
  }

  void _sendGif(GifItem gif) {
    Navigator.of(context).pop();
    widget.onGif?.call(gif);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        0,
        8,
        8 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ColoredBox(
          color: colors.card,
          child: SizedBox(
            height: 396,
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 6),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: IosSegmented<int>(
                          values: const <int>[0, 1, 2],
                          labels: const <String>['GIFs', 'Stickers', 'Emoji'],
                          selected: _tab,
                          onChanged: (int value) =>
                              setState(() => _tab = value),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: switch (_tab) {
                    0 => _gifs(colors),
                    1 => _stickers(context, colors),
                    _ => _emojiGrid(colors),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stickers(BuildContext context, AppColors colors) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (BuildContext context, Widget? child) {
        final List<StickerItem> recent = widget.store.recentStickers;
        final List<StickerPack> packs = widget.store.stickerPacks;
        if (recent.isEmpty && packs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'No stickers yet. Install a sticker set in Telegram and it '
                'appears here.',
                textAlign: TextAlign.center,
                style: AppText.subhead.copyWith(color: colors.textSecondary),
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 14),
          children: <Widget>[
            if (recent.isNotEmpty) ...<Widget>[
              _section('Recent', colors),
              _grid(recent),
            ],
            for (final StickerPack pack in packs) ...<Widget>[
              _section(pack.title, colors),
              _grid(pack.stickers),
            ],
          ],
        );
      },
    );
  }

  Widget _gifs(AppColors colors) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (BuildContext context, Widget? child) {
        final List<GifItem> gifs = widget.store.savedGifs;
        if (gifs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                widget.onGif == null
                    ? 'GIFs are available in chats.'
                    : 'No saved GIFs yet. GIFs you save in Telegram appear here.',
                textAlign: TextAlign.center,
                style: AppText.subhead.copyWith(color: colors.textSecondary),
              ),
            ),
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 14),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.5,
          ),
          itemCount: gifs.length,
          itemBuilder: (BuildContext context, int index) => _GifCell(
            gif: gifs[index],
            store: widget.store,
            onTap: () => _sendGif(gifs[index]),
          ),
        );
      },
    );
  }

  Widget _section(String title, AppColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
      child: Text(
        title.toUpperCase(),
        style: AppText.sectionHeader.copyWith(
          fontSize: 11.5,
          color: colors.textSecondary,
        ),
      ),
    );
  }

  Widget _grid(List<StickerItem> stickers) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: stickers.length,
      itemBuilder: (BuildContext context, int index) => _StickerCell(
        sticker: stickers[index],
        store: widget.store,
        onTap: () => _send(stickers[index]),
      ),
    );
  }

  Widget _emojiGrid(AppColors colors) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: _emoji.length,
      itemBuilder: (BuildContext context, int index) => Pressable(
        onTap: () => widget.onEmoji(_emoji[index]),
        scale: 0.85,
        child: Center(
          child: Text(_emoji[index], style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}

class _GifCell extends StatefulWidget {
  const _GifCell({required this.gif, required this.store, required this.onTap});

  final GifItem gif;
  final TelegramStore store;
  final VoidCallback onTap;

  @override
  State<_GifCell> createState() => _GifCellState();
}

class _GifCellState extends State<_GifCell> {
  @override
  void initState() {
    super.initState();
    if (widget.gif.thumbnailFileId > 0) {
      widget.store.ensureFile(widget.gif.thumbnailFileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final String path = widget.gif.thumbnailPath.isNotEmpty
        ? widget.gif.thumbnailPath
        : widget.store.filePaths[widget.gif.thumbnailFileId] ?? '';
    return Pressable(
      onTap: widget.onTap,
      scale: 0.95,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ColoredBox(
          color: colors.dark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.04),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (path.isEmpty)
                Center(
                  child: Icon(
                    Icons.gif_box_outlined,
                    size: 28,
                    color: colors.textTertiary,
                  ),
                )
              else
                Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (BuildContext _, Object __, StackTrace? ___) =>
                      Center(
                        child: Icon(
                          Icons.gif_box_outlined,
                          size: 28,
                          color: colors.textTertiary,
                        ),
                      ),
                ),
              if (widget.gif.duration > 0)
                Positioned(
                  left: 5,
                  bottom: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      durationLabel(widget.gif.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String durationLabel(int seconds) {
  final int minutes = seconds ~/ 60;
  final int rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

class _StickerCell extends StatefulWidget {
  const _StickerCell({
    required this.sticker,
    required this.store,
    required this.onTap,
  });

  final StickerItem sticker;
  final TelegramStore store;
  final VoidCallback onTap;

  @override
  State<_StickerCell> createState() => _StickerCellState();
}

class _StickerCellState extends State<_StickerCell> {
  @override
  void initState() {
    super.initState();
    if (widget.sticker.thumbnailFileId > 0) {
      widget.store.ensureFile(widget.sticker.thumbnailFileId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppColors colors = AppColors.of(context);
    final String path = widget.sticker.thumbnailPath.isNotEmpty
        ? widget.sticker.thumbnailPath
        : widget.store.filePaths[widget.sticker.thumbnailFileId] ?? '';
    final Widget fallback = Text(
      widget.sticker.emoji.isEmpty ? '🌟' : widget.sticker.emoji,
      style: const TextStyle(fontSize: 26),
    );
    return Pressable(
      onTap: widget.onTap,
      scale: 0.9,
      child: Container(
        decoration: BoxDecoration(
          color: colors.dark
              ? Colors.white.withValues(alpha: 0.045)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: path.isEmpty
            ? fallback
            : Image.file(
                File(path),
                fit: BoxFit.contain,
                errorBuilder: (BuildContext _, Object __, StackTrace? ___) =>
                    fallback,
              ),
      ),
    );
  }
}
