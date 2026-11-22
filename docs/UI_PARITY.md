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
shader for refraction. `GlassPanel` (`lib/ui/components/glass.dart`) wraps it
with the material behaviour iOS adds around the shader:

- light from straight overhead (`Offset(0, -1)`), the iOS 27 measurement;
- materialisation from 0 to 1 instead of a fade-in;
- a 0.7 pt gradient contour — bright top-left, cool bottom — instead of a flat
  1 px border, plus a diagonal sheen between the glass and its content;
- Increase Contrast forwarded as the shader's `increasedContrast`;
- Reduce Motion skips materialisation, press springs and wallpaper drift.

Surfaces built on it: `GlassBar` (tab bar, conversation bar, composer),
`GlassCard` (grouped settings, sheets), `GlassField` (search and message
inputs), `GlassCircleButton` (compose, back, info, scroll-to-latest) and
`LiquidWallpaper`.

On devices where the shader cannot run (or below Android 13), `liquiglass`
degrades to a frosted, rim-lit surface; the same widgets pick it up and the app
still lays out correctly.

## Motion

- Press-scale springs on rows, tabs and buttons (`pressable.dart`).
- The tab selection is a lens that slides between slots over 260 ms instead of a
  per-tab tint fading in place.
- The 34 pt Chats title collapses into a centred nav-bar title as the list
  scrolls under the glass header.
- Scroll-to-latest fades in when the conversation leaves the bottom.
- Route pushes use the Cupertino slide; avatars use Hero between list and chat.
- The wallpaper drifts continuously without rebuilding widgets and stops under
  Reduce Motion.

## Deliberate differences

- Android back gesture and predictive-back support instead of the iOS edge
  swipe alone.
- Material text selection and context menus are used where Flutter's platform
  integration is stronger.
- SF Pro is not bundled; the app uses the platform sans-serif with the iOS type
  scale and weights.
