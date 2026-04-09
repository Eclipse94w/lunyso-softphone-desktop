# LUNYSO Desktop — Build from Scratch

Complete procedure to rebuild LUNYSO desktop (fork of linphone-desktop) from zero on Arch Linux.

---

## 1. System dependencies

```bash
sudo pacman -S --needed \
  base-devel cmake ninja git python python-pystache python-six nasm yasm \
  gdb \
  qt6-base qt6-declarative qt6-svg qt6-multimedia qt6-tools \
  qt6-quick3d qt6-websockets qt6-networkauth \
  glew mesa alsa-lib pulseaudio libpulse libv4l libxml2 xerces-c \
  sqlite openldap jsoncpp hidapi libvpx openh264
```

Minimum required versions: CMake ≥ 3.22, Qt 6.11, GCC 14+.

---

## 2. Clone sources

```bash
cd ~
git clone https://gitlab.com/lunyso/lunyso-desktop.git linphone-desktop
cd linphone-desktop
```

If starting from the upstream repo instead:

```bash
git clone https://github.com/BelledonneCommunications/linphone-desktop.git
cd linphone-desktop
```

---

## 3. Fetch the SDK (the painful part)

The `external/linphone-sdk` submodule has **many** nested submodules hosted at
`gitlab.linphone.org`, which rate-limits parallel clones and sometimes serves
stale `.gitmodules` with wrong URLs.

### 3a. Wipe and re-clone the SDK cleanly

```bash
cd ~/linphone-desktop/external
rm -rf linphone-sdk
git clone --recursive https://gitlab.linphone.org/BC/public/linphone-sdk.git linphone-sdk
```

### 3b. If clones fail mid-way (rate limiting)

Retry sequentially with `--jobs 1`. Save this as `/tmp/resume-sdk.sh`:

```bash
#!/bin/bash
cd ~/linphone-desktop/external/linphone-sdk
for i in 1 2 3 4 5 6 7 8 9 10; do
  echo "=== Attempt $i ==="
  if git submodule update --init --recursive --jobs 1; then
    echo "=== SDK submodules complete ==="
    exit 0
  fi
  echo "Retrying in 10s..."
  sleep 10
done
exit 1
```

Run: `bash /tmp/resume-sdk.sh`

### 3c. Force worktree checkout

After all submodules are cloned into `.git/modules`, their worktrees may be
empty. Force a checkout:

```bash
cd ~/linphone-desktop/external/linphone-sdk
git submodule foreach --recursive 'git checkout -f HEAD || true'
git submodule update --init --recursive --force
```

### 3d. If `aom` URL is broken

The upstream `.gitmodules` sometimes points `aom` at a dead URL. Correct
source: `https://gitlab.linphone.org/BC/public/external/aom.git`.

```bash
SDK=~/linphone-desktop/external/linphone-sdk
AOM=$SDK/external/aom
URL=https://gitlab.linphone.org/BC/public/external/aom.git
COMMIT=65ad4cd63cbe7f10eaa4b4af7f55fd540617516a

sed -i "s|url = .*/aom.*|url = $URL|g" $SDK/.gitmodules
rm -rf "$AOM"
git clone "$URL" "$AOM"
git -C "$AOM" checkout "$COMMIT"
```

---

## 4. Configure

```bash
cd ~/linphone-desktop
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
```

Common missing deps that surface here: `glew`, `qt6-networkauth`,
`qt6-quick3d`, `qt6-websockets`, `qt6-tools`. Install them via pacman and
re-run cmake.

---

## 5. Build

```bash
cmake --build build --parallel $(nproc)
```

Expect ~20–40 min on first build (full SDK compile).

---

## 6. Install (required!)

The build tree is **not runnable directly** — belcard/belr grammar files
(`vcard_grammar`, etc.) are only populated by the install step into
`build/OUTPUT/share/`.

```bash
cmake --install build
```

If you skip this, the app crashes on startup with:

```
bctbx-fatal-Unable to load VCARD grammar.
```

---

## 7. Run

```bash
./build/OUTPUT/bin/lunyso
```

---

## 8. LUNYSO branding — what was changed

All branding changes live in `linphone-desktop/` (not in the SDK).
Key files:

- `Linphone/application_info.cmake` — app name `lunyso`, display name `LUNYSO`
- `Linphone/data/image/logo*.svg`, `splashscreen-logo.svg`, `belledonne.svg`, `linphone.svg` — replaced with LUNYSO logo
- `Linphone/data/icon/hicolor/*/apps/icon.png` — replaced with LUNYSO icon
- `Linphone/view/Style/DefaultStyle.qml` — `main2_*` palette switched to LUNYSO blue
- `Linphone/view/Style/Themes.qml` — theme renamed to `"lunyso"`
- `Linphone/data/languages/*.ts` — strings "Linphone" → "Lunyso"
- `CMakeLists.txt` — project name
- Notification strings and login page URL updated

Branding audit lives in `CHANGES_LINPHONE_DESKTOP_LUNYSO_BRANDED.md`.

---

## 9. Troubleshooting

| Symptom | Fix |
|---|---|
| `Could NOT find GLEW` | `sudo pacman -S glew` |
| `Could NOT find Qt6NetworkAuth` | `sudo pacman -S qt6-networkauth` |
| `Could NOT find Qt6Quick3D` | `sudo pacman -S qt6-quick3d` |
| SDK submodule clone fails 443 | gitlab.linphone.org rate limit — retry sequentially with `--jobs 1` |
| Submodule dirs empty after clone | `git submodule foreach --recursive 'git checkout -f HEAD'` |
| `Unable to load VCARD grammar` at runtime | Run `cmake --install build`, launch from `build/OUTPUT/bin/lunyso` |
| Cross-user permissions (files owned by `lunyso`, shell is `eclipse`) | Prefix commands with `sudo -u lunyso` |

---

## 10. Full happy-path recap

```bash
sudo pacman -S --needed base-devel cmake ninja git python python-pystache python-six nasm yasm gdb qt6-base qt6-declarative qt6-svg qt6-multimedia qt6-tools qt6-quick3d qt6-websockets qt6-networkauth glew mesa alsa-lib pulseaudio libpulse libv4l libxml2 xerces-c sqlite openldap jsoncpp hidapi libvpx openh264

git clone https://gitlab.com/lunyso/lunyso-desktop.git ~/linphone-desktop
cd ~/linphone-desktop/external
rm -rf linphone-sdk
git clone --recursive https://gitlab.linphone.org/BC/public/linphone-sdk.git linphone-sdk
cd linphone-sdk && git submodule foreach --recursive 'git checkout -f HEAD || true'

cd ~/linphone-desktop
cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build --parallel $(nproc)
cmake --install build
./build/OUTPUT/bin/lunyso
```

---

## 11. CI/CD — Windows installer pipeline

The repo includes a `.gitlab-ci.yml` that automatically builds a Windows
installer (`.exe`) on every push to `main` or a tag.

**Pipeline triggers:**
- Push to `main` branch
- Any git tag (e.g. `v1.0.0`)

**What it does:**
1. Spins up a GitLab shared Windows runner (`saas-windows-medium-amd64`)
2. Installs Qt 6.7.3 via `aqtinstall`, cmake, NSIS
3. Clones/updates linphone-sdk submodules sequentially (avoids rate-limit)
4. Configures, builds, installs the app
5. Bundles Qt DLLs via `windeployqt`
6. Generates an NSIS installer via `cpack -G NSIS`
7. Uploads `LUNYSO-*.exe` as a downloadable artifact (kept 90 days)

**To get the installer:**
GitLab → CI/CD → Pipelines → click the job → Download artifacts

**First run is slow (~30–40 min)** — full SDK compile from scratch.
Subsequent runs are faster due to the SDK cache keyed on branch name.

**Note:** Users must re-download and reinstall manually for each update.
Auto-update is a planned future feature.

---

## TODO

- [ ] **Auto-update** — implement in-app update check and installer download
      so users get updates without manually re-downloading the `.exe`
