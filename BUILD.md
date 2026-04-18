# lunyso-desktop — Build Reference

**Version**: 5.3.4 (fork of linphone-desktop 5.3.4)  
**Last updated**: 2026-04-18  

---

## Table of contents

1. [Project overview](#1-project-overview)
2. [Repository structure](#2-repository-structure)
3. [Build targets](#3-build-targets)
4. [Linux build (local — Docker)](#4-linux-build-local--docker)
5. [Linux build (GitHub Actions)](#5-linux-build-github-actions)
6. [Windows build (GitHub Actions)](#6-windows-build-github-actions)
7. [Windows build (manual — native Windows)](#7-windows-build-manual--native-windows)
8. [Branding reference](#8-branding-reference)
9. [Known issues and workarounds](#9-known-issues-and-workarounds)
10. [CI/CD notes](#10-cicd-notes)

---

## 1. Project overview

`lunyso-desktop` is a branded fork of [linphone-desktop 5.3.4](https://github.com/BelledonneCommunications/linphone-desktop/tree/5.3.4).

**Why 5.3.4 and not 6.x?**  
linphone-desktop 6.x has broken SIP calling on all Windows builds (upstream issues #968, #971, #972, open as of April 2026). Version 5.3.4 is the last stable release where Windows calling works correctly.

**Build system**: CMake ≥ 3.22 with Ninja generator  
**Qt version**: Qt 5.15.x (Qt5, not Qt6)  
**Compiler (Linux)**: GCC 11+ (Ubuntu 22.04 default)  
**Compiler (Windows)**: MSVC 2019 (x64)

---

## 2. Repository structure

```
lunyso-desktop/
├── CMakeLists.txt             ← root CMake (orchestrates everything)
├── linphone-app/              ← Qt5 application source
│   ├── application_info.cmake ← app name, ID, vendor (Lunyso branding)
│   ├── CMakeLists.txt
│   └── src/                  ← C++ sources
├── linphone-sdk/              ← git submodule — liblinphone + all deps
│   └── (recursive submodules: belle-sip, bctoolbox, liblinphone, …)
├── external/
│   ├── qtkeychain/            ← git submodule — Qt keychain support
│   └── ispell/                ← git submodule — spell check (Linux only, optional)
├── plugins/                   ← optional Qt plugins
├── .gitlab-ci.yml             ← GitLab CI (Windows + Linux jobs)
├── .github/workflows/build.yml← GitHub Actions (Windows + Linux jobs)
├── docker-build-linux.sh      ← standalone Docker build script (Linux)
└── BUILD.md                   ← this file
```

**Key submodule URLs** (from `.gitmodules`):

| Submodule | URL |
|-----------|-----|
| `linphone-sdk` | `https://gitlab.linphone.org/BC/public/linphone-sdk.git` |
| `external/qtkeychain` | `https://gitlab.linphone.org/BC/public/external/qtkeychain.git` |
| `external/ispell` | `https://gitlab.linphone.org/BC/public/external/ispell.git` |

> **Critical**: `gitlab.linphone.org` is only accessible from within Docker or CI environments on this machine. Direct access from the Arch Linux host is blocked at the network level.

---

## 3. Build targets

| Platform | Method | Status | Output |
|----------|--------|--------|--------|
| Linux | Docker (local) | ✅ Script ready, runs overnight | `build-linux/OUTPUT/bin/lunyso` |
| Linux | GitHub Actions | ✅ Workflow ready | Artifact in Actions |
| Windows | GitHub Actions | ✅ Workflow ready | `build-windows/OUTPUT/` + `.exe` installer |
| Windows | Native (manual) | 📄 Documented below | Requires Windows + MSVC |
| macOS | Not targeted | — | — |

---

## 4. Linux build (local — Docker)

This is the recommended local build method on the Arch Linux development machine.

### Prerequisites

- Docker installed and running (`docker ps` must work without sudo)
- Current user in `docker` group
- Internet access from Docker containers

### Run

```bash
cd /home/lunyso/lunyso-desktop

# One command — runs in Docker, writes to build-linux/
docker run --rm \
  --name lunyso-build-linux \
  -v "$(pwd)":/src \
  ubuntu:22.04 \
  bash /src/docker-build-linux.sh
```

Build takes **3–6 hours** on first run (submodule clones + full SDK compilation).

### What the script does

1. Installs all apt packages (Qt 5.15, build tools, dev libs) on Ubuntu 22.04
2. Initialises submodules from `gitlab.linphone.org` (accessible inside Docker)
3. Runs CMake configure with Ninja
4. Builds and installs to `build-linux/OUTPUT/`

### Output

After a successful build:

```
build-linux/OUTPUT/
├── bin/
│   └── lunyso              ← the application binary
├── lib/
│   └── *.so                ← linphone SDK shared libraries
└── share/
    └── lunyso/             ← QML, images, translations
```

### Run the binary

```bash
# On a machine with X11 or Wayland:
LD_LIBRARY_PATH="$(pwd)/build-linux/OUTPUT/lib" \
  ./build-linux/OUTPUT/bin/lunyso
```

### Monitor build progress

```bash
tail -f build-linux/build.log
docker logs lunyso-build-linux -f
```

---

## 5. Linux build (GitHub Actions)

Workflow: `.github/workflows/build.yml`, job `build-linux`

Triggered automatically on push to `main` or `lunyso-5.3.4`. Can also be triggered manually via `workflow_dispatch`.

To use, push the repo to a GitHub remote (create a new GitHub repo first):

```bash
git remote add github https://github.com/YOUR_ORG/lunyso-desktop.git
git push github main
```

Artifacts are retained for 30 days under the "Actions" tab.

---

## 6. Windows build (GitHub Actions)

Workflow: `.github/workflows/build.yml`, job `build-windows`

Runner: `windows-2019` (GitHub-hosted, free tier)

**Produces two artifacts:**
- `lunyso-desktop-windows-<sha>` — the raw binary tree (for testing)
- `lunyso-installer-windows-<sha>` — the NSIS `.exe` installer (for distribution)

**Trigger manually** (no push required once workflow is in the repo):

```
Actions → Build lunyso-desktop → Run workflow → build_target: windows
```

**CMake flags used for Windows:**

```
-DCMAKE_PREFIX_PATH=C:\Qt\5.15.2\msvc2019_64
-DLINPHONESDK_PLATFORM=Desktop
-DENABLE_APP_PACKAGING=ON
-DENABLE_GPL_THIRD_PARTIES=ON
-DENABLE_G729=OFF
-DENABLE_PQCRYPTO=OFF
-DENABLE_CSHARP_WRAPPER=NO
```

---

## 7. Windows build (manual — native Windows)

If you have a Windows 10/11 machine with MSVC 2019:

### Step 1 — Install tools

Via [Chocolatey](https://chocolatey.org/):

```powershell
choco install -y python cmake ninja nsis 7zip git git-lfs
```

### Step 2 — Install Qt 5.15.2

```cmd
pip install aqtinstall
aqt install-qt windows desktop 5.15.2 win64_msvc2019_64 -O C:\Qt -m qtmultimedia
```

### Step 3 — Open VS Developer Command Prompt

Start → "x64 Native Tools Command Prompt for VS 2019"

### Step 4 — Clone and init submodules

```cmd
git clone https://gitlab.com/lunyso/lunyso-desktop.git
cd lunyso-desktop
git submodule update --init external/qtkeychain
git submodule update --init --depth 1 linphone-sdk
git -C linphone-sdk submodule update --init --recursive --depth 1
```

### Step 5 — Build

```cmd
mkdir build-windows && cd build-windows

cmake .. -G Ninja ^
  -DCMAKE_BUILD_TYPE=RelWithDebInfo ^
  -DCMAKE_PREFIX_PATH=C:\Qt\5.15.2\msvc2019_64 ^
  -DLINPHONESDK_PLATFORM=Desktop ^
  -DENABLE_APP_PACKAGING=ON ^
  -DENABLE_UNIT_TESTS=OFF ^
  -DENABLE_G729=OFF ^
  -DENABLE_PQCRYPTO=OFF ^
  -DENABLE_GPL_THIRD_PARTIES=ON ^
  -DENABLE_CSHARP_WRAPPER=NO

cmake --build . --config RelWithDebInfo --parallel 4
cmake --build . --target install --config RelWithDebInfo
```

### Step 6 — Package (NSIS installer)

```cmd
cmake --build . --target package --config RelWithDebInfo
```

Output: `build-windows/*.exe`

### Estimated build time

| Machine | First build | Incremental |
|---------|-------------|-------------|
| 4-core / 16 GB RAM | 3–4 h | 15–30 min |
| 8-core / 32 GB RAM | 1.5–2.5 h | 10–20 min |

---

## 8. Branding reference

All branding overrides applied to the 5.3.4 upstream:

| File | Change |
|------|--------|
| `linphone-app/application_info.cmake` | App name `Lunyso`, ID `com.lunyso.lunyso`, vendor, URL |
| `linphone-app/CMakeLists.txt` | Executable name `lunyso` |
| `linphone-app/assets/` | Lunyso logo SVG + PNG (9 sizes) |

The `linphone-app/application_info.cmake` current values:

```cmake
set(APPLICATION_DESCRIPTION "Lunyso — RSSI à temps partagé")
set(APPLICATION_ID "com.lunyso.lunyso")
set(APPLICATION_NAME Lunyso)
set(APPLICATION_URL "https://lunyso.com")
set(APPLICATION_VENDOR "Lunyso")
set(EXECUTABLE_NAME lunyso)
```

---

## 9. Known issues and workarounds

### gitlab.linphone.org blocked from Arch Linux host

**Symptom**: `git submodule update --init` fails with "Could not connect to server".  
**Cause**: Outbound port 443 to `gitlab.linphone.org` is blocked at the host network level.  
**Fix**: Use Docker (port is open inside containers) — see Section 4.

### qt5-quickcontrols2 / qt5-tools / qt5-multimedia not installed on Arch

**Symptom**: CMake configure fails: `Could not find a package configuration file provided by "Qt5QuickControls2"`.  
**Fix**:
```bash
sudo pacman -S qt5-quickcontrols2 qt5-tools qt5-multimedia
```
Or use the Docker build which handles this automatically.

### linphone-sdk submodule clone rate-limited

**Symptom**: `git submodule update --init --recursive` fails mid-way.  
**Fix**: The Docker build script retries up to 5 times with 15-second delays. For manual retries:
```bash
git -C linphone-sdk submodule update --init --recursive --jobs 1
```

### Windows 6.x SIP calling broken

**Symptom**: Calls connect but audio/video never flows on Windows with linphone-desktop 6.x.  
**Root cause**: Upstream regression (issues #968, #971, #972, open April 2026).  
**Fix**: This repo pins to 5.3.4 which does not have this regression.

### Build fails: `ispell` submodule missing

**Symptom**: CMake error about `ISpell_FOUND`.  
**Fix**: Only init ispell if you actually need spell-check. The CI and Docker scripts skip it. To disable explicitly:
```cmake
-DENABLE_APP_SPELLING=OFF
```
(Ispell is on Linux only and optional.)

### Platform plugin `xcb`/`wayland` not found at runtime

**Symptom**: Binary crashes with "Could not load the Qt platform plugin".  
**Fix**: Qt platform plugins must be in `$QT_PLUGIN_PATH` or next to the binary.
```bash
export QT_QPA_PLATFORM_PLUGIN_PATH=/usr/lib/qt5/plugins/platforms
./build-linux/OUTPUT/bin/lunyso
```
Or install missing platform libs:
```bash
sudo pacman -S qt5-wayland
```

---

## 10. CI/CD notes

### GitLab CI (`.gitlab-ci.yml`)

- **Windows** job: `saas-windows-medium-amd64` runner, installs Chocolatey + Qt via aqtinstall
- **Linux** job: `ubuntu:22.04` Docker image, installs apt packages
- **Retry**: 2 retries on runner/network failures
- **Artifacts**: retained 2 weeks (binary) / 2 months (installer)

> Note: GitLab SaaS free tier has limited CI minutes. When minutes run out, use GitHub Actions instead.

### GitHub Actions (`.github/workflows/build.yml`)

- Uses `actions/checkout@v4` + `actions/upload-artifact@v4`
- Windows: `windows-2019` runner (free, unlimited minutes on public repos)
- Linux: `ubuntu-22.04` runner (free)
- `workflow_dispatch` allows manual trigger for either platform independently

### Self-hosted runner (planned)

A Windows GitLab Runner VM (VirtualBox) was in progress for local CI.  
Post-setup steps:
1. Install GitLab Runner on Windows VM
2. Register runner with `gitlab.com/lunyso/lunyso-desktop` project
3. Apply tag `lunyso-windows` to the job in `.gitlab-ci.yml`

This eliminates GitLab SaaS minute consumption for Windows builds.
