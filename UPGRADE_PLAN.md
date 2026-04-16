# Upgrade Plan — lunyso-desktop to 5.3.4

## Decision

Target: **linphone-desktop 5.3.4** (latest stable 5.x, March 2026)

6.1.2 rejected — SIP calling is broken on all 6.x Windows builds (GitHub issues #968, #971, #972, still open as of April 2026). Multiple users confirm 5.3.x works correctly. 5.3.4 is the latest maintained release.

## Steps

1. Fork `https://github.com/BelledonneCommunications/linphone-desktop` at tag `5.3.4`
2. Replace current repo contents with 5.3.4 source
3. Re-apply branding from `CHANGES_LINPHONE_DESKTOP_LUNYSO_BRANDED.md`:
   - `CMakeLists.txt` — app name + executable name
   - `Linphone/application_info.cmake` — description, URL, vendor, app ID
   - `Linphone/view/Style/Themes.qml` — add `lunyso` theme, override `orange` palette
   - `Linphone/view/Style/DefaultStyle.qml` — default theme + full `main2_*` palette
   - `Linphone/model/setting/SettingsModel.cpp` — default theme value
   - `Linphone/core/setting/SettingsCore.cpp` — migration from `orange` → `lunyso`
   - `Linphone/view/Control/Popup/Notification/*.qml` — "Linphone" → "Lunyso"
   - `Linphone/view/Page/Form/Login/SIPLoginPage.qml` — contact URL
   - `Linphone/data/languages/*.ts` (12 files) — translation strings
   - All logo/icon assets (SVG + 9 PNG sizes)
   - `Linphone/view/Page/Layout/Login/LoginLayout.qml` — login logo layout
4. Port `.gitlab-ci.yml` Windows pipeline (adjust Qt version and toolchain if 5.x requires Qt5)
5. Commit, push, verify pipeline

## Notes

- 5.3.x uses Qt5 — CI pipeline will need Qt5 via aqtinstall instead of Qt6
- `sip.linphone.org` in `RegisterPage.qml` — leave unchanged until `sip.lunyso.com` is ready
- After rebase, delete all `BUILD_*.md` / `MONITORING_PLAN.md` docs (they document 6.x SDK issues, no longer relevant)
