# LUNYSO Roadmap — Realism & Efficiency Review

**Companion to:** `LUNYSO_ROADMAP.md`
**Date:** 2026-04-10
**Purpose:** Sanity-check the "keep 100% of linphone-desktop features on XiVO" roadmap before committing engineering time.

---

## Is it realistic?

**Mostly yes, with one load-bearing assumption.**

### Solid points

- **Flexisip is literally built for this.** It's the exact software Belledonne runs at `sip.linphone.org`, it's open source, and the docs explicitly cover "front an existing SIP PBX". Group chat, presence, LIME compatibility, SIP MESSAGE relay — all first-class, no forking required.
- **The client side is trivial.** Phase 2 is ~15 string replacements in `Constants.hpp` + `linphonerc-factory`. No C++ logic changes, no UI hiding, no liblinphone patches. One day of work once the infra exists.
- **XiVO stays untouched.** We don't modify Wazo; we peer with it over a SIP trunk. Rollback = delete the trunk.
- **Zero user disruption during Phase 1** — infra can be built and tested in a lab before any client ships.

### Fragile points

- **The Flexisip ↔ XiVO interop spike is the whole plan's keystone.** XiVO generates its own Asterisk dialplan; shoving Flexisip in front can collide with how XiVO expects REGISTERs to land. If that spike fails, Phases 2–4 don't matter. This is why it's explicitly gated in the roadmap (Risk #1).
- **AGPL on Flexisip.** Running it as a service for paying customers triggers source-disclosure obligations. Not a blocker, but legal must sign off before production.
- **LIME server OSS maturity.** Belledonne's public LIME server is less battle-tested than Flexisip. Non-zero chance we'd end up maintaining a small patch set.

---

## Is it efficient?

**Yes — it's the cheapest path to "keep everything."** All alternatives are worse:

| Alternative | Problem |
|---|---|
| Fork liblinphone to rewire chat onto `wazo-chatd` | Multi-month C++ effort, permanent maintenance burden on every upstream rebase |
| Hide features | Fast but throws away half the product |
| QML-level chat adapter bypassing `ChatRoom` | Loses LIME, loses group rooms, still needs a backend |

This plan reuses Belledonne's own server code to serve Belledonne's own client code. Maximum leverage, minimum code written.

---

## Optimizations

Seven real wins worth applying to the base roadmap:

### 1. Start with Flexisip-only; defer LIME + file transfer to Phase 1.5/1.6

Chat and group rooms work over Flexisip alone. LIME and file attachments are *additive* — deferring them gets a usable build out in weeks instead of months. **Biggest scope cut available.**

### 2. Merge the provisioning bridge with `account.lunyso.com`

One HTTPS service, one auth flow, one TLS cert, one codebase — instead of two sibling services.

### 3. Skip DNS sprawl — use path-based routing

Serve everything from a single `api.lunyso.com` host:
- `/lime` → LIME X3DH
- `/files` → file transfer
- `/provisioning` → bridge
- `/account` → password recovery / wizard
- `/logs` → log upload
- `/updates` → updater feed

One cert, one reverse proxy instead of six subdomains. The client doesn't care — `Constants.hpp` takes a full URL either way.

### 4. Do the interop spike THIS WEEK, before committing to anything else

1–2 day lab test (Flexisip container + XiVO VM + test client) either unblocks the whole roadmap or kills it early. **Cheapest insurance in the plan.**

### 5. Keep CardDAV *and* add wazo-dird

CardDAV is free to leave enabled — no server to operate, users bring their own. wazo-dird is pure addition, not a replacement.

### 6. Postpone push entirely

Desktop doesn't need it. Flexisip's push module can stay disabled until/unless a mobile LUNYSO client appears. Removes FCM/APNs credential management from Phase 1.

### 7. Piggyback logs on existing object storage

`logs.lunyso.com` is just a presigned-URL uploader in front of the same bucket `files.lunyso.com` uses. No new service.

---

## Optimized Phase 1 footprint

With optimizations #1, #2, #3, #6, #7 applied, **Phase 1 shrinks from 5 services to 2**:

1. **Flexisip** (one container, edge SIP proxy)
2. **`api.lunyso.com`** (one FastAPI app fronting an S3 bucket, serves provisioning + account + logs + updates)

That's realistic for a small team.

LIME server and file transfer server are added in Phase 1.5 / 1.6 once the base product is shipping.

---

## Bottom line

The plan is sound. The single gating action is the **Flexisip ↔ XiVO interop spike** — run that first (1–2 days), and the rest follows naturally. If the spike fails, fall back to the "hide features" approach from `LUNYSO_FIT_ANALYSIS.md` §5.

---

## Day 1 Kickoff — "what do I need to start tomorrow?"

Starting the roadmap = running the interop spike. Everything else is blocked until it passes.

### Prerequisites

| # | Item | Notes |
|---|---|---|
| A | Lab machine / VM | Any Linux, 4 GB RAM minimum, Docker-capable. Internet-reachability NOT required — spike is lab-local. |
| B | XiVO instance | Throwaway Wazo VM from `wazo-platform.org` installers, OR peering (read-only) against existing LUNYSO XiVO. Create **one test user** in wazo-confd with a SIP line (G.711, no special routing). |
| C | Docker + docker-compose | On the lab machine. |
| D | Flexisip container image | Pull `gitlab.linphone.org/bc/public/flexisip:latest`, or build from source (standard CMake project) if the registry is unreachable. |
| E | Minimal `flexisip.conf` | Three keys: `global/transports=sip:*:5060;transport=tcp sips:*:5061;transport=tls`, `module::Registrar/reg-domains=lunyso.test`, `module::Router/static-targets=<XiVO_IP>:5060`. |
| F | SIP test client | Either `sipp` in UAC mode for scripted REGISTER/INVITE, or a fresh linphone-desktop build pointed at `flexisip.lunyso.test` via a hand-edited `linphonerc`. |

### Success criteria (run in order)

1. Flexisip starts cleanly; logs show TLS bound on 5061.
2. Test client REGISTERs through Flexisip → 200 OK.
3. Test client places an INVITE to an external number → Flexisip forwards to XiVO → XiVO places the PSTN leg → **two-way audio confirmed**.
4. Second test client REGISTERs; first client sends SIP MESSAGE to second → **delivered** (proves chat relay).
5. First client creates a chat room via conference factory URI on Flexisip → **room created** (proves group chat).

**All 5 pass → roadmap green-lit.** Proceed to Phase 1 proper.
**Any fail → stop.** Debug, or fall back to feature-hiding.

### What you do NOT need tomorrow

- Production DNS (`flexisip.lunyso.com`) → use `/etc/hosts` for the spike
- Let's Encrypt → self-signed cert, flip client cert verification off
- LIME server → defer to Phase 1.5
- File transfer server → defer to Phase 1.6
- Provisioning bridge → defer to Phase 1.7
- Any client code changes → spike uses a hand-edited `linphonerc`, not a patched build
- Legal review of AGPL → not needed until running Flexisip for real customers

### Effort estimate

- Environment setup (A–F): half a day if Docker is ready, full day if building a fresh lab VM
- Running the 5 success criteria: a couple of hours if Flexisip config is right, a full day of debugging if it isn't
- **Realistic total: 1–2 working days** to get a go/no-go on the entire roadmap

### After the spike (week 2+)

Once green-lit, the optimized Phase 1 ordering is:

1. Production Flexisip host with real TLS cert + monitoring
2. `api.lunyso.com` FastAPI app (provisioning + account + logs + updates bundled)
3. File transfer (S3 presigned URL upload)
4. LIME X3DH server
5. Client `Constants.hpp` repoint + rebuild + ship LUNYSO v1.0
