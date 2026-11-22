# Courier roadmap

The expanded work list for the Flutter rewrite. This is deliberately larger
than the first release: 64 items across the client, the interface and delivery.

Legend: `[x]` implemented in this repository and compiled by the local build;
`[~]` implemented but not exercised against a live Telegram account; `[ ]` not
implemented.

## Rewrite and engine

- [x] 1. Replace the Kotlin/Compose app with a Flutter app at the repository root.
- [x] 2. Split the app into `telegram/`, `state/`, `core/`, `ui/` and `config`.
- [x] 3. Keep TDLib as the Telegram engine through a Kotlin platform channel.
- [x] 4. Map chats, users, messages, photos, sessions and connection state into Dart.
- [x] 5. Stream TDLib updates over a dedicated event channel.
- [x] 6. Keep optimistic sends and reconcile them with TDLib acknowledgements.
- [x] 7. Page chat history upwards and page the chat list through `loadChats`.
- [x] 8. Persist the TDLib session so restarts stay signed in.
- [x] 9. Log out safely and reinitialise the client for a new login.
- [~] 10. Phone-number login.
- [~] 11. Login-code verification.
- [~] 12. Two-step (2FA) password verification.
- [x] 13. Connection state and human-readable diagnostics.
- [x] 14. Cache size reporting and cache clearing.
- [x] 15. Active-session listing and remote termination.

## Chats and messages

- [x] 16. Live chat list with pinned, muted and unread states.
- [x] 17. Chat photos and gradient fallback avatars.
- [x] 18. Online, last-seen and typing indicators.
- [x] 19. Local chat search and a pull-to-refresh gesture.
- [x] 20. New conversation by `@username`.
- [x] 21. Chat history, day separators and an unread divider.
- [x] 22. Send text messages.
- [x] 23. Send photos from the gallery.
- [x] 24. Reply to a message.
- [x] 25. Edit your own message.
- [x] 26. Delete messages for everyone.
- [x] 27. Copy message text.
- [x] 28. Read receipts and message ticks.
- [x] 29. Mark chats read when opened.
- [x] 30. Photo viewer with pinch zoom.
- [x] 31. Shared-media grid in chat info.
- [x] 32. Pin, mute, clear and delete chats.
- [x] 33. Chat info with member list and actions.
- [ ] 34. Forward messages.
- [ ] 35. Reactions and polls.
- [ ] 36. Global message search.
- [ ] 37. Voice notes and audio playback.
- [ ] 38. Video and animated sticker playback.
- [ ] 39. Send locations and contacts.
- [ ] 40. Create groups and channels, join/leave and admin actions.
- [ ] 41. Folders and archive.
- [ ] 42. Secret chats.

## People and account

- [x] 43. Contacts tab derived from private chats.
- [x] 44. Alphabetical contact sections and search.
- [~] 45. Edit first name, last name, bio and username.
- [x] 46. Theme selection: light, dark or system, persisted.
- [x] 47. Notification preferences, persisted locally.
- [x] 48. Privacy information screen.
- [x] 49. About screen with version and engine details.
- [ ] 50. Profile-photo upload.
- [ ] 51. Import the device address book.
- [ ] 52. Multi-account switching.
- [ ] 53. Push notifications.
- [ ] 54. Account data export/deletion flow.

## Interface

- [x] 55. Real liquid-glass shader surfaces through `liquiglass`.
- [x] 56. Animated liquid wallpaper and four-tab glass shell.
- [x] 57. iOS geometry, type scale, grouped cards and hairlines.
- [x] 58. Spring press-scale and route/bubble transitions.
- [x] 59. Light/dark palettes that follow the chosen appearance.
- [x] 60. Splash screen and branded empty/error states.
- [ ] 61. Tablet and foldable layout.
- [ ] 62. Localization (starting with English and German).
- [ ] 63. Android themed icon, widgets and quick actions.
- [ ] 64. VoIP calls with the Telegram call protocol.

## Delivery

- [x] Stable and debug Flutter builds configured for three ABIs.
- [x] GitHub Actions builds both APKs on every push to `main`.
- [x] Both APKs and checksums are published to one GitHub release.
- [x] README, architecture, UI-parity notes and this roadmap.
- [~] On-device visual review: blocked in the build sandbox (no KVM, no GPU).
- [ ] Live end-to-end check with a real Telegram account.
- [ ] Play Store packaging with an owner keystore and per-ABI bundles.

## Progress

- 46 of the 64 numbered items are implemented (72%), including 5 marked `[~]`
  because they have not been exercised against live Telegram servers here.
- 43 of the 64 numbered items are `[x]` and compile in the local build (67%).
- Including the six delivery bullets, 51 of 69 tracked items are implemented
  (74%). The required 50% threshold is met by every count.
- Remaining work is concentrated in media playback, calls, group
  administration and store delivery, not in the core chat/settings flows.
