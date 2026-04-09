# CLAUDE.md — linphone-desktop (LUNYSO fork)

## Project Overview

LUNYSO-branded fork of **Linphone Desktop** — an open-source SIP softphone.
The fork replaces all Linphone branding with LUNYSO identity and is distributed as a standalone installer for Windows (CI-built) and as a manual build on Linux.

- **GitLab repo:** `https://gitlab.com/lunyso/linphone-desktop` (private)
- **Upstream:** [gitlab.linphone.org/BC/public/linphone-desktop](https://gitlab.linphone.org/BC/public/linphone-desktop)
- **Binary name:** `lunyso` / `lunyso.exe`
- **License:** GPLv3 (dual-license with Belledonne)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | C++17 |
| GUI | Qt 6.10+ (QML, MVVM) |
| Build system | CMake 3.22+, Ninja |
| SDK | `external/linphone-sdk` (git submodule) |
| Packaging | CPack + NSIS (Windows installer) |
| CI/CD | GitLab CI (saas-windows-medium-amd64 runner) |

---

## Key Files

| File | Purpose |
|------|---------|
| `Linphone/tool/Constants.hpp` | Compiled-in constants: URLs, paths, log email, codec URLs |
| `CMakeLists.txt` | Root build config — app name, version, packaging flags |
| `.gitlab-ci.yml` | Windows installer pipeline (Qt install → SDK build → NSIS package) |
| `CHANGES_LINPHONE_DESKTOP_LUNYSO_BRANDED.md` | Audit trail of all branding changes vs upstream |
| `BUILD_FROM_SCRATCH.md` | Full Arch Linux build guide with troubleshooting |
| `INSTALL_WINDOWS.md` | End-user Windows installation guide (non-technical) |

---

## Build (Arch Linux)

> **Note:** All `cmake --build` and `cmake --install` commands require `sudo` on this machine.

```bash
# Configure
cmake -B build -S . -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_INSTALL_PREFIX=build/OUTPUT

# Build SDK first (slow, ~30 min)
sudo cmake --build build --target sdk -j$(nproc)

# Build app
sudo cmake --build build --target Linphone -j$(nproc)

# Install
sudo cmake --install build

# Run
./build/OUTPUT/bin/lunyso
```

> See `BUILD_FROM_SCRATCH.md` for dependency list, SDK rate-limit workarounds, and troubleshooting.

---

## CI/CD — Windows Installer

**Trigger:** push to `main` or any git tag.

**Pipeline steps:**
1. Install Qt 6.7.3 via `aqtinstall` + CMake + NSIS
2. Clone/update `linphone-sdk` (sequential to avoid GitHub rate-limit)
3. Configure with `-DENABLE_APP_PACKAGING=YES`
4. Build & install
5. Bundle Qt DLLs via `windeployqt`
6. Generate NSIS `.exe` via `cpack`

**Artifact:** `build/OUTPUT/Packages/LUNYSO-*.exe` — retained 90 days.
**Cache:** SDK keyed by branch (`sdk-$CI_COMMIT_REF_SLUG`).

---

## LUNYSO Branding Rules

All branding changes must be logged in `CHANGES_LINPHONE_DESKTOP_LUNYSO_BRANDED.md`.

| What | Where | Value |
|------|-------|-------|
| App name | `CMakeLists.txt` | `LUNYSO` |
| Binary name | `CMakeLists.txt` | `lunyso` |
| Log contact email | `Linphone/tool/Constants.hpp` | `contact@lunyso.com` |
| Logo files | `Linphone/view/Image/` | `lunyso-logo.svg` etc. |
| App icon | `hicolor/*/apps/icon.png` | LUNYSO icon |
| Color palette | `DefaultStyle.qml` | LUNYSO blue |
| Theme name | `Themes.qml` | `lunyso` |
| UI strings | Various QML files | "Linphone" → "Lunyso" |

**Never revert the binary name back to `linphone`.**

---

## TODO

- [ ] **Auto-update mechanism** — implement in-app update check/download for new releases (Windows priority)

---

## Rules for This Project

1. Always update `CHANGES_LINPHONE_DESKTOP_LUNYSO_BRANDED.md` after any branding edit.
2. Commit messages in English, conventional commits format (`feat:`, `fix:`, `chore:` etc.).
3. Never commit build artifacts (`build/`, `*.exe`, `*.so`).
4. Test Windows builds via the GitLab CI pipeline — do not manually package.
5. Contact email is always `contact@lunyso.com` — never use upstream Linphone addresses.
