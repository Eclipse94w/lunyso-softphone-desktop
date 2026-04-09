# LUNYSO Fit Analysis — linphone-desktop on XiVO IPBX

**Date:** 2026-04-09
**Scope:** Assess whether the rebranded linphone-desktop fork is a good fit as the LUNYSO desktop SIP client against a LUNYSO-operated **XiVO / Wazo IPBX**.
**Method:** Parallel code inventory of `/home/lunyso/linphone-desktop`, audit of hardcoded Belledonne-infra dependencies, and research of XiVO/Wazo server capabilities via official docs.

---

## 1. Executive Summary

linphone-desktop is a **technically solid Qt6/C++ SIP softphone** with a rich feature surface (audio/video, conference, ZRTP/SRTP, LDAP, CardDAV, remote provisioning, QML UI). As a pure SIP UAC against XiVO, **the calling core will work out of the box**: register, call, transfer, hold, voicemail MWI, BLF dialog subscriptions, DTMF RFC2833, and SRTP are all either native or configurable per-account.

However, linphone-desktop was built around **Belledonne's SaaS ecosystem** (`subscribe.linphone.org`, `sip.linphone.org`, `lime.linphone.org`, `files.linphone.org`, Flexisip). A substantial portion of the UX — group chat, LIME end-to-end encryption, account creation wizard, password recovery, log upload, conference factories, presence RLS, and version check — is **hardcoded to Linphone servers that do not exist on XiVO**. These features will silently fail or point users to a competitor's portal unless explicitly disabled or rewired.

**Verdict:** ✅ Good fit for **calling** and **basic SIP features**. ⚠️ Partial fit for **directory/contacts** (needs wazo-dird integration). ❌ Poor fit as-is for **chat, presence, push, account self-service, LIME E2E** — these require either removal, rewiring to XiVO REST APIs, or acceptance of a degraded UX.

A LUNYSO-branded release MUST ship with a cleaned `Constants.hpp` and `linphonerc-factory`, or users will see and hit Belledonne endpoints.

---

## 2. Feature Fit Matrix

Legend: ✅ Works · ⚠️ Works with config/caveats · 🟧 Partial/needs rework · ❌ Broken against XiVO

### 2.1 Calling (core telephony)

| Feature | linphone-desktop | XiVO / Wazo | Fit |
|---|---|---|---|
| SIP REGISTER (UDP/TCP/TLS) | yes | yes, TLS templates available | ✅ |
| Audio codecs (Opus, G.711, G.722, G.729) | yes | Opus on Asterisk 18+, others standard | ✅ |
| Video (VP8/VP9/H.264) | `ENABLE_VIDEO=YES`, OpenH264 downloaded at runtime | supported, line-dependent | ✅ |
| DTMF RFC 2833 | yes | recommended default | ✅ |
| DTMF SIP INFO | yes | supported but broken with direct media | ⚠️ prefer RFC2833 |
| Blind / attended transfer (REFER) | `CallModel::transferTo/transferToAnother` | `allowtransfer=yes` | ✅ |
| Hold / MoH | yes | yes | ✅ |
| Call parking / pickup | not exposed in UI | via feature codes / BLF | 🟧 reachable via DTMF but no dedicated UI |
| Call recording (client-side) | `CallModel::startRecording` (local file) | server-side flag; no SIP REC header | ✅ (local) / 🟧 (server) |
| Conference (local mixed) | ConferenceModel | ConfBridge rooms via wazo-confd | ✅ |
| SRTP (SDES) | per-account `MediaEncryption` | `media_encryption=sdes` | ✅ |
| ZRTP with SAS | CallModel ZRTP auth token flow | not mediated by server, E2E only | ✅ (direct media) |
| DTLS-SRTP (WebRTC) | supported in SDK | supported via `webrtc=yes` lines | ✅ |
| Voicemail MWI | `AccountModel::mwiServerAddress` | standard SIP NOTIFY | ✅ |

**Calling verdict:** ✅ **Excellent fit.** This is the area where linphone-desktop shines and XiVO cooperates fully.

### 2.2 Messaging / Chat

| Feature | linphone-desktop | XiVO / Wazo | Fit |
|---|---|---|---|
| 1:1 chat over SIP MESSAGE | `ChatModel`, `ChatRoom` | **no SIP MESSAGE routing** | ❌ |
| Group chat rooms | relies on Flexisip conference server | **no Flexisip** on XiVO | ❌ |
| File transfer in chat | HTTP file transfer server (`files.linphone.org`) | not supported | ❌ |
| Voice messages | `createVoiceRecordingMessage` | — | ❌ (no transport) |
| Read receipts (IMDN) | supported | — | ❌ |
| Reactions, replies, forward | supported | — | ❌ |
| LIME X3DH end-to-end encryption | `DefaultLimeServerURL=lime.linphone.org` | **no LIME key server** | ❌ |
| Wazo-native chat (`wazo-chatd` REST/websocket) | **no integration** | yes, used by wazo-euc | 🟧 would need a new module |

**Chat verdict:** ❌ **Poor fit as-is.** The entire chat stack is built for Belledonne's Flexisip + LIME backend. On XiVO, chat either has to be (a) disabled in UI, (b) rewired to `wazo-chatd`, or (c) left broken. Recommendation: **hide chat tab in LUNYSO build** until a wazo-chatd adapter is written.

### 2.3 Presence / BLF

| Feature | linphone-desktop | XiVO / Wazo | Fit |
|---|---|---|---|
| SIP SUBSCRIBE dialog event (BLF) | via friend lists | ✅ with `notifycid=yes` | ✅ |
| Presence event package (PUBLISH) | yes | limited server-side (Wazo does presence over REST) | ⚠️ partial |
| RLS aggregated subscribe | `DefaultRlsUri=sips:rls@sip.linphone.org` hardcoded | XiVO does not run this RLS | ❌ unless replaced |

**Presence verdict:** ⚠️ **Mixed.** BLF monitoring will work for individual extensions. Aggregated RLS must be removed/redirected. Rich presence (availability, status text) on XiVO flows over wazo-chatd websocket, which linphone-desktop doesn't speak.

### 2.4 Contacts / Directory

| Feature | linphone-desktop | XiVO / Wazo | Fit |
|---|---|---|---|
| Local vCard store | yes | n/a | ✅ |
| LDAP (bind, TLS, search) | `LdapModel` full configuration | Wazo exposes LDAP source natively | ✅ |
| CardDAV | `CarddavModel` | **not supported** by wazo-dird | 🟧 LUNYSO would need own CardDAV server |
| wazo-dird REST lookup | **not integrated** | yes, unified directory API | ❌ would need plugin |
| Magic search | yes, across local sources | — | ✅ (local only) |

**Directory verdict:** ⚠️ **Partial.** LDAP is the pragmatic bridge — point linphone-desktop LDAP at Wazo's LDAP directory source. Long-term a `wazo-dird` REST adapter would be cleaner and give click-to-call on incoming CLI resolution.

### 2.5 Provisioning / Accounts

| Feature | linphone-desktop | XiVO / Wazo | Fit |
|---|---|---|---|
| Manual SIP account entry | `SIPLoginPage` | admin-created in wazo-confd | ✅ |
| Remote provisioning URL (HTTP) | `RemoteProvisioningURL=subscribe.linphone.org` | **wazo-provd targets hard phones only**, no generic URL | 🟧 LUNYSO could host its own provisioning endpoint that serves a `linphonerc` pulled from wazo-confd REST |
| QR code provisioning | `ENABLE_QRCODE=OFF` (experimental) | n/a | ⚠️ |
| OAuth2 / OIDC | `OIDCModel`, `ENABLE_APP_OAUTH2=OFF` | wazo-auth issues tokens (not OIDC-standard by default) | 🟧 possible integration path |
| Account creation wizard | `DefaultXmlrpcUri=subscribe.linphone.org:444/wizard.php` | **not applicable**, accounts are admin-managed | ❌ disable |
| Password recovery | `PasswordRecoveryUrl=subscribe.linphone.org/recovery/email` | — | ❌ disable |

**Provisioning verdict:** 🟧 **Needs work.** Building a thin LUNYSO-side bridge (`https://provisioning.lunyso.com → wazo-confd`) that emits a `linphonerc` is the path of least resistance and future-proofs the fleet.

### 2.6 Push notifications

| Feature | linphone-desktop | XiVO / Wazo | Fit |
|---|---|---|---|
| Desktop push / wake | none (desktop stays connected) | — | ✅ (not needed) |
| System tray notifications | yes (Notifier backends) | — | ✅ |
| Mobile push gateway | Flexisip | wazo-webhookd (FCM/APNs) | n/a for desktop |

**Push verdict:** ✅ **Non-issue for desktop.** Desktop client keeps a persistent TLS SIP registration; push is a mobile concern.

### 2.7 Security

| Feature | linphone-desktop | XiVO / Wazo | Fit |
|---|---|---|---|
| TLS transport | yes, per-account | yes | ✅ |
| SRTP-SDES | yes | yes | ✅ |
| ZRTP E2E with SAS | yes | transparent (direct media) | ✅ |
| LIME X3DH chat encryption | yes, requires key server | **no key server** | ❌ |
| Certificate verification modes | yes | n/a | ✅ |
| Root CA management | `PathRootCa` | n/a | ✅ |

**Security verdict:** ✅ **Strong for voice**, ❌ **E2E chat is a non-starter** on XiVO.

### 2.8 External services baked in (must be reviewed)

| Service | URL | Used for | Disposition |
|---|---|---|---|
| Log upload | `files.linphone.org` | "Send logs" button | **replace or remove** |
| Crash reports | `*.bugsplat.com` (Crashpad) | `ENABLE_CRASH_HANDLER` off currently | leave off |
| Update check | `download.linphone.org/releases\|snapshots` | `ENABLE_UPDATE_CHECK=ON` | **disable at build, implement LUNYSO updater (TODO in CLAUDE.md)** |
| H.264 codec blob | `ciscobinary.openh264.org` | runtime download on first video call | acceptable (Cisco public CDN, license-driven) |
| Password recovery web | `subscribe.linphone.org/recovery/email` | login page link | **remove** |
| Register/login/logout web | `subscribe.linphone.org/*` | `ENABLE_APP_WEBVIEW=OFF` | leave off, remove constants |

---

## 3. Hardcoded Belledonne Endpoints — Remediation Checklist

All constants live in `Linphone/tool/Constants.hpp` unless noted. These MUST be audited before a LUNYSO public release.

### 🔴 CRITICAL (visible to users or breaks features)

| # | Location | Value | Action |
|---|---|---|---|
| 1 | `Constants.hpp:60` `DefaultXmlrpcUri` | `https://subscribe.linphone.org:444/wizard.php` | Remove, disable account wizard |
| 2 | `Constants.hpp:85` `DefaultFlexiAPIURL` | `https://subscribe.linphone.org/api/` | Remove |
| 3 | `Constants.hpp:86` `RemoteProvisioningURL` | `https://subscribe.linphone.org/api/provisioning` | Replace with `https://provisioning.lunyso.com` or blank |
| 4 | `Constants.hpp:113-115` assistant URLs | `subscribe.linphone.org/register\|login\|logout` | Remove |
| 5 | `Constants.hpp:116` `DefaultRouteAddress` | `sip:sip.linphone.org;transport=tls` | Replace with LUNYSO XiVO SIP proxy |
| 6 | `Constants.hpp:130` default domain | `sip.linphone.org` | Replace with `sip.lunyso.com` (or blank) |
| 7 | `Constants.hpp:134-137` conference factories | `sip:conference-factory@sip.linphone.org`, `sip:videoconference-factory@sip.linphone.org` | Blank or point to XiVO ConfBridge URI |
| 8 | `Constants.hpp:138-139` `DefaultLimeServerURL` | `https://lime.linphone.org/lime-server/lime-server.php` | Blank, disable LIME feature flag |
| 9 | `Linphone/model/setting/SettingsModel.cpp:868` default domain | `sip.linphone.org` | Replace |
| 10 | `Linphone/data/config/linphonerc-factory:4,46` | account_creator backend + `rls_uri` | Replace |
| 11 | `Linphone/model/account/AccountManager.cpp:71-88` | fallback domain logic | Replace |

### 🟠 HIGH (telemetry / branding leak)

| # | Location | Value | Action |
|---|---|---|---|
| 12 | `Constants.hpp:61-63` log upload servers | `files.linphone.org` | Disable log upload or host `logs.lunyso.com` |
| 13 | `Constants.hpp:82` `DefaultRlsUri` | `sips:rls@sip.linphone.org` | Remove |
| 14 | `Constants.hpp:69-70` update URLs | `download.linphone.org/*` | Disable via CMake `-DENABLE_UPDATE_CHECK=OFF` until LUNYSO updater lands |
| 15 | `Constants.hpp:71` password recovery | `subscribe.linphone.org/recovery/email` | Remove |
| 16 | `Constants.hpp:68,72-75` docs/legal URLs | `linphone.org/*` | Replace with `lunyso.com/*` or hide |

### 🟡 MEDIUM (cosmetic / CMake defaults)

| # | Location | Value | Action |
|---|---|---|---|
| 17 | `Constants.hpp:80-81` `LinphoneBZip2_*` | Windows bzip2 bootstrap | Cache internally, don't hit linphone.org |
| 18 | `Constants.hpp:163` `BugsplatUrl` | Crashpad endpoint | Already disabled via `ENABLE_CRASH_HANDLER=NO`; keep off |

---

## 4. Features to KEEP (good fit for LUNYSO)

- **Audio/video calling engine** — Qt6 UI, liblinphone core, excellent codec stack.
- **ZRTP/SRTP/DTLS-SRTP** — rare to get end-to-end voice encryption so cleanly; keep, advertise.
- **Multi-account support** — works for users who have both LUNYSO and external SIP accounts.
- **LDAP directory** — trivial wiring to Wazo's LDAP source.
- **Call transfer / hold / conference / call-forward settings** — all present and QML-configurable.
- **Voicemail MWI** — works with XiVO voicemails out of the box.
- **Settings UI infrastructure** — theming, security, network, account layouts.
- **Crash-free build on Windows via GitLab CI** — already working, ship it.

## 5. Features to DISABLE or HIDE (poor fit)

- **Account creation wizard** (`SIPLoginPage`, "S'inscrire" button) — there is no `subscribe.lunyso.com/wizard`; remove or replace with "Contact your LUNYSO admin".
- **Password recovery link** — no backing service.
- **LIME end-to-end chat encryption** — no key server.
- **Group chat rooms / chat tab** — no Flexisip/chatd backend. *Hide the entire chat surface in the default build until a wazo-chatd client is written.*
- **Linphone "About" docs links** (T&C, privacy policy, translation portal) — replace with LUNYSO URLs or remove.
- **Log upload button** — points to Belledonne's server.
- **Update check** — points to Belledonne releases; disable until LUNYSO ships its own.
- **Remote provisioning via `subscribe.linphone.org`** — disable or redirect.

## 6. Features to REBUILD (medium-term roadmap)

Ordered by user value vs implementation cost:

1. **LUNYSO provisioning endpoint** — small HTTPS service that takes a user token and returns a `linphonerc` fragment populated from wazo-confd. Unblocks painless fleet onboarding.
2. **wazo-dird REST directory source** — new `Linphone/model/contact/WazoDirdModel.cpp` that calls `/directories/lookup/default/dird` for reverse lookup and search; immediately replaces CardDAV for most use cases.
3. **wazo-chatd websocket bridge** — biggest effort; only if chat is a product requirement. Could be a QML-level adapter that pushes messages into a LUNYSO-native chat view, bypassing liblinphone's `ChatRoom` entirely.
4. **LUNYSO auto-updater** (already a TODO in `CLAUDE.md`) — Sparkle-style feed hosted at `updates.lunyso.com`.
5. **Call parking / pickup UI** — surface Wazo feature codes (`*1` transfer, park slots) as explicit UI buttons instead of DTMF string.
6. **Presence via wazo-chatd** — once chatd bridge exists, reuse the same websocket for rich presence.

## 7. Recommended immediate actions (this fork, this week)

In priority order, minimal changes for a shippable LUNYSO build against XiVO:

1. **Patch `Constants.hpp`** — replace the CRITICAL-severity entries in section 3 with blanks or LUNYSO values. Log each in `CHANGES_LINPHONE_DESKTOP_LUNYSO_BRANDED.md`.
2. **Patch `linphonerc-factory`** — replace account_creator backend URL and `rls_uri`.
3. **Patch `SettingsModel.cpp:868`** and `AccountManager.cpp:71-88` default domain fallbacks.
4. **Hide chat tab** in `MainLayout.qml` behind a `FEATURE_CHAT=OFF` define (or just comment out the tab loader) until wazo-chatd bridge exists.
5. **Hide "S'inscrire" / password recovery** buttons in `SIPLoginPage.qml`.
6. **Disable version check** via CMake: `-DENABLE_UPDATE_CHECK=OFF`.
7. **Replace about/docs URLs** (`Constants.hpp:68,72-75`) with `lunyso.com` or remove from the About dialog.
8. **Document XiVO-compatible account settings** (TLS port 5061, SRTP on, RFC2833 DTMF, no LIME) in a user-facing `INSTALL_LUNYSO.md`.

After these eight changes, the LUNYSO build is **honest about what it does and doesn't do**, stops leaking to Belledonne servers, and delivers a clean SIP client experience on XiVO.

---

## 8. Sources

**Codebase (local):**
- `Linphone/tool/Constants.hpp`
- `Linphone/model/setting/SettingsModel.cpp`
- `Linphone/core/CoreModel.cpp`
- `Linphone/model/account/AccountManager.cpp`
- `Linphone/data/config/linphonerc-factory`
- `Linphone/view/Page/**` (feature inventory)
- `CMakeLists.txt` (`ENABLE_*` flags)

**XiVO / Wazo documentation:**
- https://wazo-platform.org/uc-doc/administration/sip_templates/
- https://wazo-platform.org/documentation/overview/provisioning-admin.html
- https://wazo-platform.org/uc-doc/administration/voicemails/
- https://wazo-platform.org/uc-doc/api_sdk/mobile_push_notification/
- https://wazo.readthedocs.io/en/stable/api_sdk/rest_api/quickstart.html
- https://github.com/wazo-platform/wazo-confd
- https://github.com/wazo-platform/wazo-dird
- https://wazo.readthedocs.io/en/wazo-17.12/cti_client/cti_client.html

---
*Generated: 2026-04-09. Rebuild this analysis any time the upstream linphone-desktop diverges significantly or XiVO/Wazo publishes major new platform APIs.*
