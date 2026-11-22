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
`GlassCard` (sheets, photo viewer, form fields), `GlassCircleButton`
(compose, scroll-to-latest) and the chats header.

Telegram only puts material on bars, sheets and the composer, so Courier does
the same. `SettingsGroup`, `IosSearchField`, `NavIconButton` and empty states are
opaque: a settings card group used to carry its own backdrop filter, and the
chat header carried one per icon, which cost frames for no visual gain.

On devices where the shader cannot run (or below Android 13), `liquiglass`
degrades to a frosted, rim-lit surface; the same widgets pick it up and the app
still lays out correctly.

## Motion

- Press-scale springs on rows, tabs and buttons (`pressable.dart`).
- The tab bar is modelled on the liquidglass `held-drag` reference: touch-down
  swells the inset pill into a lens that stands 4 pt proud of the bar on each
  side and is 16 pt wider than a slot; the bar lifts to 1.05 and the tab under
  the lens grows to 1.18 and turns accent. Dragging follows the finger (keeping
  the grab offset up to half the lens width), ticks a selection haptic for each
  tab it crosses, previews that tab, and commits once on release. A release
  faster than 550 px/s throws it to the next tab; otherwise it settles on the
  nearest. Reduce Motion removes the lens, the stretch and the throw while taps
  and drags still select. The library's Flutter port ships only `GlassSurface`,
  so this interaction is implemented in `lib/ui/tab_bar.dart` against the
  Compose tab bar's published geometry.
- The 34 pt Chats title collapses into a centred nav-bar title as the list
  scrolls under the glass header.
- Scroll-to-latest fades in when the conversation leaves the bottom.
- Route pushes use the Cupertino slide; avatars use Hero between list and chat.
- The wallpaper is still. A drifting full-screen field forced every glass
  surface above it to re-run its backdrop filter continuously; the motion now
  comes from the content scrolling under the bars.
- The segmented control slides one pill between options instead of cross-fading
  a background per option.
- Tapping a tab glides the selection to it; the bar paints exactly one selection
  shape (an inset capsule at rest that swells into the lens), so a tap never
  shows a second tile.
- Settings → Appearance → Material switches between Liquid Glass and Classic
  iOS. Classic returns an opaque `Container` for every `GlassPanel` and a flat
  background in the shell and conversation, with no shader and no backdrop
  filter.

## Chats, Contacts and the tab bar

- Chats uses the current iOS bar: a grey Edit pill, centred 17 pt title, compose
  glyph, the search field under it, then filter chips with unread/group/private
  counts. Edit is real multi-select: rows grow a selection circle, the list
  becomes tappable-only, and a floating bar deletes the selection through
  `DeleteChat`.
- Contacts sorts by last seen by default (the screenshot's order) and the Sort
  pill switches to A–Z sections; rows show online or the last-seen label.
- The tab bar carries the trailing search accessory iOS shows; it sits outside
  the four lens slots, so the selection geometry is unchanged. It opens a local
  chat search that works from the synced list.

## Stories

The strip above the chat list follows the iOS layout: 66 pt circles with a
2.6 pt ring, the poster's 58 pt avatar inset 3.2 pt, the first name in 11 pt
grey and a 76 pt slot. An unviewed poster gets a `SweepGradient`
(blue → violet → pink → blue, rotated to start at twelve o'clock); a fully
viewed poster gets the separator colour. The row is absent when nobody has
active stories, and it scrolls horizontally with bouncing physics.

Data comes from TDLib, not a fixture: `GetChatActiveStories` for the chats the
engine already holds, cached in `TelegramEngine.activeStories` and republished
by `UpdateChatActiveStories`. `ChatActiveStories.maxReadStoryId` against the
newest `StoryInfo.storyId` decides the ring, and only `StoryListMain` entries are
shown. Tapping a circle opens that chat — the full-screen story player with
`OpenStory`/`GetStory` is not part of this build.

## Deliberate differences

- Android back gesture and predictive-back support instead of the iOS edge
  swipe alone.
- Material text selection and context menus are used where Flutter's platform
  integration is stronger.
- SF Pro is not bundled; the app uses the platform sans-serif with the iOS type
  scale and weights.
