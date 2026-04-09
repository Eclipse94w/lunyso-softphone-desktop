# LUNYSO Roadmap — Keep 100% of linphone-desktop Features on XiVO

**Status:** Proposed
**Created:** 2026-04-10
**Companion doc:** `LUNYSO_FIT_ANALYSIS.md`
**Goal:** Ship a LUNYSO-branded linphone-desktop client where **every single upstream feature still works**, backed by LUNYSO-operated infrastructure around our XiVO IPBX.

---

## Context

`LUNYSO_FIT_ANALYSIS.md` concluded that the linphone-desktop calling core works fine against XiVO, but ~40% of the UX (group chat, LIME E2E, file transfer, presence RLS, push, account wizard, provisioning, log upload, update check) is hardwired to Belledonne's SaaS (`*.linphone.org`). The "easy" path is to hide those features. This roadmap takes the **opposite** path: **stand up the Belledonne server stack ourselves as a sidecar to XiVO**, and repoint the client. No features are hidden. No liblinphone fork.

All three Belledonne server components are open source (Flexisip AGPL, LIME server, file transfer server) and designed to front any SIP PBX.

---

## Architecture

```
            ┌────────────────────────────────────────┐
            │           LUNYSO desktop client        │
            │        (rebranded linphone-desktop)    │
            └────────────┬─────────────┬─────────────┘
                         │ SIP/TLS     │ HTTPS (chat/LIME/files/prov)
                         ▼             ▼
           ┌─────────────────────┐   ┌──────────────────────────┐
           │   Flexisip (edge)   │   │   LUNYSO service plane   │
           │ proxy + presence +  │   │ - lime.lunyso.com (X3DH) │
           │ conference + push   │   │ - files.lunyso.com       │
           │ registrar           │   │ - provisioning.lunyso... │
           └──────────┬──────────┘   │ - updates.lunyso.com     │
                      │ SIP          │ - logs.lunyso.com        │
                      ▼              │ - account.lunyso.com     │
           ┌─────────────────────┐   └──────────────────────────┘
           │   XiVO / Wazo PBX   │
           │ Asterisk, voicemail,│
           │ wazo-dird, LDAP     │
           └─────────────────────┘
```

- **Voice / PSTN / voicemail / BLF** → XiVO (unchanged).
- **Flexisip** edge SIP proxy: REGISTER, route INVITEs to XiVO via static route, native group chat rooms (conference factory), presence RLS, push gateway, SIP MESSAGE relay.
- **LIME X3DH server** (self-hosted) → end-to-end encrypted chat.
- **File transfer HTTP server** → chat attachments + voice messages.
- **Provisioning bridge** → small service that authenticates via `wazo-auth` and returns a `linphonerc` fragment built from `wazo-confd` data.
- **Client** → patched `Constants.hpp` + `linphonerc-factory` pointing at LUNYSO endpoints. No feature hidden.

---

## Phase 1 — Stand up the Belledonne sidecar (infra)

Deliverable: a LUNYSO-operated server bundle matching what `*.linphone.org` provides.

| # | Component | Host | Notes |
|---|---|---|---|
| 1.1 | Flexisip | `flexisip.lunyso.com` | Debian pkg or Docker from `gitlab.linphone.org/BC/public/flexisip`. Modules: `Registrar`, `Router` (static route → XiVO), `Presence`, `Conference`, `PushNotification` (off). TLS 5061 + WSS 443. |
| 1.2 | LIME X3DH server | `lime.lunyso.com` | Belledonne reference server. PostgreSQL backend. |
| 1.3 | File transfer server | `files.lunyso.com` | Belledonne HTTP file transfer server. S3/minio backend. |
| 1.4 | XiVO interop | wazo-confd | SIP trunk peering Flexisip ↔ XiVO. Unified user realm `sip:<user>@lunyso.com`. |
| 1.5 | Provisioning bridge | `provisioning.lunyso.com` | FastAPI/Go. Accepts `wazo-auth` token → returns `linphonerc` fragment assembled from `wazo-confd` SIP line data. Replaces `subscribe.linphone.org/api/provisioning`. |

## Phase 2 — Repoint the client (code)

Every change is a single-value replacement. No new C++ modules, no feature hiding.

### Critical files

| File | Change |
|---|---|
| `Linphone/tool/Constants.hpp` | 17+ URL constants → LUNYSO |
| `Linphone/data/config/linphonerc-factory` | `account_creator` backend, `rls_uri`, default route, conference factory, LIME URL |
| `Linphone/model/setting/SettingsModel.cpp:868` | Default domain → `lunyso.com` |
| `Linphone/model/account/AccountManager.cpp:71-88` | Domain fallback → `lunyso.com` |
| `CMakeLists.txt` | Keep chat/LIME/conference/update check **ON** |
| `CHANGES_LINPHONE_DESKTOP_LUNYSO_BRANDED.md` | Log every replacement |

### `Constants.hpp` replacement table

| Constant | From | To |
|---|---|---|
| `DefaultXmlrpcUri` | `subscribe.linphone.org:444/wizard.php` | `https://provisioning.lunyso.com/wizard` |
| `DefaultFlexiAPIURL` | `subscribe.linphone.org/api/` | `https://provisioning.lunyso.com/api/` |
| `RemoteProvisioningURL` | `subscribe.linphone.org/api/provisioning` | `https://provisioning.lunyso.com/api/provisioning` |
| assistant URLs (`:113-115`) | `subscribe.linphone.org/*` | `https://account.lunyso.com/*` |
| `DefaultRouteAddress` | `sip:sip.linphone.org;transport=tls` | `sip:flexisip.lunyso.com;transport=tls` |
| default domain (`:130`) | `sip.linphone.org` | `lunyso.com` |
| conference factory (`:134`) | `sip:conference-factory@sip.linphone.org` | `sip:conference-factory@flexisip.lunyso.com` |
| videoconference factory (`:135`) | `sip:videoconference-factory@sip.linphone.org` | `sip:videoconference-factory@flexisip.lunyso.com` |
| `DefaultLimeServerURL` | `lime.linphone.org/lime-server/lime-server.php` | `https://lime.lunyso.com/lime-server/lime-server.php` |
| `DefaultRlsUri` | `sips:rls@sip.linphone.org` | `sips:rls@flexisip.lunyso.com` |
| log upload (`:61-63`) | `files.linphone.org` | `https://logs.lunyso.com` |
| update URLs (`:69-70`) | `download.linphone.org/*` | `https://updates.lunyso.com/*` |
| password recovery (`:71`) | `subscribe.linphone.org/recovery/email` | `https://account.lunyso.com/recovery` |
| docs/legal (`:68,72-75`) | `linphone.org/*` | `https://lunyso.com/*` |

## Phase 3 — Directory integration

- **Short term:** point existing `LdapModel` at XiVO's LDAP source. Zero code changes.
- **Medium term:** add `Linphone/model/contact/WazoDirdModel.cpp` — sibling to `CarddavModel`, calls `wazo-dird` `/directories/lookup/default/dird`. Wired into Magic search. CardDAV stays available.

## Phase 4 — Polish (non-blocking)

- Auto-updater (`updates.lunyso.com`) — closes the `CLAUDE.md` TODO.
- Call park / pickup QML UI over Wazo feature codes.
- OIDC via `wazo-auth` bridge for the dormant `OIDCModel` slot.

---

## Feature parity matrix

| Feature | Hide-it approach | This roadmap |
|---|---|---|
| 1:1 chat | removed | Flexisip SIP MESSAGE |
| Group chat rooms | removed | Flexisip conference factory |
| LIME E2E encryption | removed | self-hosted LIME X3DH |
| File transfer / voice msg | removed | self-hosted file transfer server |
| Presence RLS | removed | Flexisip presence module |
| Account wizard | removed | provisioning bridge |
| Password recovery | removed | `account.lunyso.com` |
| Remote provisioning | removed | provisioning bridge |
| Log upload | removed | `logs.lunyso.com` |
| Update check | disabled | `updates.lunyso.com` (Phase 4) |
| Voice / video / BLF / voicemail | ok | ok (XiVO) |

---

## Risks & open questions

1. **Flexisip ↔ XiVO interop spike** — Belledonne docs describe Flexisip fronting Asterisk; XiVO adds its own dialplan generator. Phase 1.0 lab spike: deploy Flexisip, register a client, place a PSTN call through XiVO. **Block Phase 2 on this succeeding.**
2. **User realm** — SIP AoRs on `lunyso.com` (served by Flexisip) vs XiVO domain affects REGISTER flow and provisioning mapping. Decide before writing the provisioning bridge.
3. **Flexisip ops cost** — PostgreSQL + Redis + TLS + monitoring. Need an ops plan.
4. **LIME server maturity** — confirm production readiness of the OSS distribution.
5. **AGPL compliance** — Flexisip is AGPL; running it as a network service for customers triggers AGPL obligations. Legal review needed.

---

## Verification checklist

### Phase 1 (infra)
- [ ] `sipp` REGISTER against `flexisip.lunyso.com:5061` ok
- [ ] Call through Flexisip → XiVO → PSTN, two-way audio
- [ ] LIME `/keys` returns a bundle for a test user
- [ ] File transfer server accepts POST and serves download
- [ ] Provisioning bridge returns valid `linphonerc` for a wazo-confd user

### Phase 2 (client)
- [ ] `sudo cmake --build build --target Linphone` clean
- [ ] Client launches with default domain `lunyso.com`
- [ ] REGISTER → Flexisip ok
- [ ] PSTN outbound via XiVO, two-way audio
- [ ] 1:1 SIP MESSAGE delivered
- [ ] Group chat room: invites delivered
- [ ] Chat file attachment uploads + downloads
- [ ] LIME handshake completes, messages marked encrypted
- [ ] Presence status visible for another user
- [ ] "Send logs" uploads to `logs.lunyso.com`
- [ ] `strings build/OUTPUT/bin/lunyso | grep linphone.org` → **zero hits**

### Phase 3 (directory)
- [ ] LDAP search returns a XiVO directory entry
- [ ] `wazo-dird` adapter results visible in Magic search

---

## Critical files summary

| File | Phase | Purpose |
|---|---|---|
| `Linphone/tool/Constants.hpp` | 2 | URL constants → LUNYSO |
| `Linphone/data/config/linphonerc-factory` | 2 | Default config |
| `Linphone/model/setting/SettingsModel.cpp:868` | 2 | Default domain |
| `Linphone/model/account/AccountManager.cpp:71-88` | 2 | Domain fallback |
| `CHANGES_LINPHONE_DESKTOP_LUNYSO_BRANDED.md` | 2 | Audit log |
| `Linphone/model/contact/WazoDirdModel.cpp` (new) | 3 | wazo-dird source |
| `CLAUDE.md` | 4 | Close auto-updater TODO |

Infra (Phase 1) lives outside this repo — LUNYSO ops repo.
