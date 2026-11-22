# UI parity notes

Courier ports the *product surface* of Telegram-iOS, not its Swift source. The
iOS repository is Swift/AsyncDisplayKit on Bazel; Courier is Flutter on Android
with TDLib.

## Reference points

- Four-tab shell: Contacts, Calls, Chats, Settings.
- 34 pt status/nav area, 44 pt navigation bars, 49 pt tab bar with a floating
  glass treatment.
- 54 pt avatars in the chat list, grouped by pinned/all.
- 17 pt semibold titles, 15 pt previews, 13 pt timestamps, 11 pt tab labels.
- `#007AFF` accent; iOS system greys and grouped-card backgrounds.
- 0.5 pt hairlines, 10–16 pt corner radii, 79 pt row height in the chat list.
- Message bubbles with a tail, 17 pt text, inline time and ticks, and a
  day-separator/unread-separator rhythm.
- Grouped settings cards with a profile header, destructive actions in red and
  chevrons on navigable rows.

## Liquid glass

`liquiglass` supplies `GlassSurface`, which renders the package's fragment
shader for refraction and a specular rim. Courier wraps it in:

- `GlassBar` for the tab bar, chat header and composer backdrop.
- `GlassCard` for grouped surfaces that need a lighter tint.
- `GlassField` for search and message inputs.
- `GlassCircleButton` for compose and back controls.
- `LiquidWallpaper` for the slowly drifting colour field behind the interface.

On devices where the shader cannot run, `liquiglass` degrades to a translucent
surface; the app still lays out correctly.

## Motion

- Press-scale springs on rows, tabs and buttons (`pressable.dart`).
- Tab switches and route pushes use fade/scale/slide transitions.
- Message bubbles enter with a short offset/fade.
- The wallpaper drifts continuously without rebuilds.

## Deliberate differences

- Android back gesture and predictive-back support instead of the iOS edge
  swipe alone.
- Material text selection and context menus are used where Flutter's platform
  integration is stronger.
- SF Pro is not bundled; the app uses the platform sans-serif with the iOS type
  scale and weights.
