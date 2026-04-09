# LUNYSO_CHANGES.md

Rebranding changes applied to linphone-desktop to produce the Lunyso SIP client.

---

## Overview

This is a front-end-only rebrand of linphone-desktop. All C++ namespaces, CMake target names, library identifiers, and internal resource paths are intentionally unchanged. Only user-visible brand elements (name, colors, logo, URLs) have been modified.

---

## Files Modified

| File | Change |
|------|--------|
| `CMakeLists.txt` | `LINPHONEAPP_APPLICATION_NAME` → `"Lunyso"`, `LINPHONEAPP_EXECUTABLE_NAME` → `"lunyso"` |
| `Linphone/application_info.cmake` | Description, URL (`lunyso.com`), vendor (`Lunyso`), app ID (`com.lunyso.*`) |
| `Linphone/view/Style/Themes.qml` | Added `"lunyso"` theme entry |
| `Linphone/view/Style/DefaultStyle.qml` | Default theme → `"lunyso"`, full `main2_*` palette update, accent color update |
| `Linphone/view/Control/Popup/Notification/NotificationReceivedMessage.qml` | Hardcoded `"Linphone"` → `"Lunyso"` |
| `Linphone/view/Control/Popup/Notification/NotificationReceivedCall.qml` | Hardcoded `"Linphone"` → `"Lunyso"` |
| `Linphone/view/Page/Form/Login/SIPLoginPage.qml` | `linphone.org/contact` → `lunyso.com/contact` |
| `Linphone/data/languages/*.ts` (12 files) | `"Linphone"` → `"Lunyso"` in all `<translation>` tags |
| `Linphone/data/image/linphone.svg` | Replaced with Lunyso SVG logo |
| `Linphone/data/image/splashscreen-logo.svg` | Replaced with Lunyso SVG logo |
| `Linphone/data/image/logo.svg` | Replaced with Lunyso SVG logo |
| `Linphone/data/image/logo_margins.svg` | Replaced with Lunyso SVG logo |
| `Linphone/data/image/belledonne.svg` | Replaced with Lunyso SVG logo (was login page decorative background) |
| `Linphone/data/icon/hicolor/*/apps/icon.png` | Replaced at 16, 22, 24, 32, 64, 128, 256, 512, 1024px |
| `lunyso-logo.svg` | Added — Lunyso master logo at repo root |
| `Linphone/data/image/lunyso-logo.svg` | Added — Lunyso master logo in image assets |

---

## Color Mapping

### Primary theme: `"lunyso"` (added to Themes.qml)

| Token | Before (Linphone orange) | After (Lunyso blue) | Role |
|-------|--------------------------|---------------------|------|
| main100 | `#FFEACB` | `#D6E9FF` | Lightest tint |
| main200 | `#FFD098` | `#ADCFFF` | Light tint |
| main300 | `#FFB266` | `#7AB2FF` | Mid tint |
| main500 | `#FF5E00` | `#0068FF` | Brand primary |
| main600 | `#DA4400` | `#0054CC` | Hover/active |
| main700 | `#B72D00` | `#003D99` | Dark |

### Secondary palette: `main2_*` (DefaultStyle.qml)

| Token | Before | After | Role |
|-------|--------|-------|------|
| main2_0 | `#FAFEFF` | `#F5F7FA` | Near white |
| main2_100 | `#EEF6F8` | `#E8EDF3` | Background |
| main2_200 | `#DFECF2` | `#CDD6E3` | Border light |
| main2_300 | `#C0D1D9` | `#A8B8CC` | Border |
| main2_400 | `#9AABB5` | `#7A93AB` | Muted |
| main2_500_main | `#6C7A87` | `#44546A` | Brand secondary (exact) |
| main2_600 | `#4E6074` | `#374455` | Dark |
| main2_700 | `#364860` | `#2A3545` | Darker |
| main2_800 | `#22334D` | `#1E2A3A` | Very dark |
| main2_900 | `#2D3648` | `#141E2B` | Near black |

### Accent colors (DefaultStyle.qml)

| Property | Before | After |
|----------|--------|-------|
| `numericPadPressedButtonColor` | `#EEF7F8` | `#D6E9FF` |
| `groupCallButtonColor` | `#EEF7F8` | `#D6E9FF` |

---

## Logo Assets

| File | Usage | Source |
|------|-------|--------|
| `lunyso-logo.svg` | Master logo | `SVG V1.svg`, viewBox 499.5×299.43 |
| `Linphone/data/image/linphone.svg` | Welcome screen (`AppIcons.welcomeLinphoneLogo`) | Lunyso master |
| `Linphone/data/image/splashscreen-logo.svg` | Splash screen (`AppIcons.splashscreenLogo`) | Lunyso master |
| `Linphone/data/image/logo.svg` | Generic logo ref (`AppIcons.logo`) | Lunyso master |
| `Linphone/data/image/logo_margins.svg` | Logo with margins variant | Lunyso master |
| `Linphone/data/image/belledonne.svg` | Login page background (`AppIcons.belledonne`) | Lunyso master |
| `Linphone/data/icon/hicolor/{n}x{n}/apps/icon.png` | App icon at 9 sizes | Generated via rsvg-convert |

---

## Intentionally NOT Changed

- `import Linphone` — QML module namespace (internal, not user-visible)
- `qrc:/qt/qml/Linphone/` — resource path prefix
- `LinphoneEnums`, `LinphoneCpp`, `LinphoneCardDav` — C++ class names
- `linphonerc-factory` — config file name
- CMake target names and library names
- `<source>` and `<location>` tags in `.ts` files
- `sip.linphone.org` in `RegisterPage.qml` — not changed (Lunyso does not yet operate a SIP server; update when `sip.lunyso.com` is available)
- `<extracomment>` developer notes in `.ts` files (internal, not user-visible)

---

## How to Re-Apply (after upstream rebase)

1. `git fetch upstream && git rebase upstream/master`
2. Re-run the color edits (`Themes.qml`, `DefaultStyle.qml`) — these are pure additions/replacements with no structural conflicts.
3. Re-run name replacements in CMake files and QML notification/login files.
4. Re-run the Python one-liner for `.ts` files.
5. `cp lunyso-logo.svg Linphone/data/image/linphone.svg` etc. for logos.
6. Re-generate PNG icons with `rsvg-convert`.

---

## Known Limitations / TODOs

- **SIP domain:** `RegisterPage.qml` still shows `@sip.linphone.org` as default domain. Update to `@sip.lunyso.com` once Lunyso operates a SIP registrar.
- **macOS `.icns`:** Must be manually generated from `lunyso-logo.svg` using `iconutil`.
- **Windows `.ico`:** Must be manually generated and placed at `Linphone/data/icon/linphone.ico`.
- **belledonne.svg login background:** Was a decorative mountains image; now shows the Lunyso logo stretched. Consider designing a proper background for this slot.
- **Submodules:** `external/linphone-sdk` and `external/google/gn` point to unreachable `gitlab.linphone.org` — see separate task to redirect to GitHub/googlesource mirrors.
