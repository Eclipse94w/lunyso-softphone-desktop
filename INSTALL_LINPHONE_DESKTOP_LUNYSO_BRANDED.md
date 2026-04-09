# INSTALL_LUNYSO.md — Building and Installing Lunyso

Lunyso is a branded SIP client built on linphone-desktop. These instructions cover building from source on Linux, macOS, and Windows.

---

## System Requirements

- **CMake** 3.22+
- **Qt** 6.8+ (Qt Quick, Qt Multimedia, Qt WebSockets)
- **C++17** compiler (GCC 11+, Clang 13+, MSVC 2022+)
- **Python** 3.8+ (build scripts)
- **Git** with submodule support

---

## Linux (Arch / Debian / Ubuntu)

### Install dependencies

**Arch:**
```bash
sudo pacman -Syu cmake git python qt6-base qt6-quick3d qt6-multimedia \
  qt6-websockets qt6-tools qt6-svg librsvg
```

**Debian/Ubuntu:**
```bash
sudo apt update && sudo apt install -y cmake git python3 \
  qt6-base-dev qt6-quick3d-dev qt6-multimedia-dev \
  qt6-websockets-dev qt6-tools-dev libgl-dev
```

### Clone and build

```bash
git clone https://github.com/BelledonneCommunications/linphone-desktop.git lunyso-desktop
cd lunyso-desktop

# Redirect submodule mirrors (gitlab.linphone.org is private)
git submodule set-url external/linphone-sdk https://github.com/BelledonneCommunications/linphone-sdk.git
git submodule set-url external/google/gn https://gn.googlesource.com/gn
git submodule update --init --recursive

cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build --parallel $(nproc)
```

### Run

```bash
./build/lunyso
```

---

## macOS

### Install dependencies

```bash
brew install cmake git python qt@6 librsvg
export PATH="/opt/homebrew/opt/qt@6/bin:$PATH"
```

### Clone and build

```bash
git clone https://github.com/BelledonneCommunications/linphone-desktop.git lunyso-desktop
cd lunyso-desktop
git submodule set-url external/linphone-sdk https://github.com/BelledonneCommunications/linphone-sdk.git
git submodule set-url external/google/gn https://gn.googlesource.com/gn
git submodule update --init --recursive

cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo
cmake --build build --parallel $(sysctl -n hw.logicalcpu)
```

### Run

```bash
open build/Lunyso.app
```

---

## Windows

### Install dependencies

```powershell
winget install -e --id Kitware.CMake
winget install -e --id Git.Git
winget install -e --id Python.Python.3
winget install -e --id TheQtCompany.QtOnline  # Install Qt 6.8+ via Qt installer
```

### Clone and build (PowerShell)

```powershell
git clone https://github.com/BelledonneCommunications/linphone-desktop.git lunyso-desktop
cd lunyso-desktop
git submodule set-url external/linphone-sdk https://github.com/BelledonneCommunications/linphone-sdk.git
git submodule set-url external/google/gn https://gn.googlesource.com/gn
git submodule update --init --recursive

cmake -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_PREFIX_PATH="C:\Qt\6.8\msvc2022_64"
cmake --build build --config RelWithDebInfo
```

---

## First-Time SIP Account Setup

1. Launch Lunyso.
2. On the login screen, choose **Use a SIP account**.
3. Enter your SIP credentials:
   - **SIP address:** `sip:yourname@yourdomain`
   - **Password:** your SIP account password
   - **Transport:** TLS (recommended)
4. Click **Connect**.

> Contact support@lunyso.com if you need a SIP account provisioned by Lunyso.

---

## Troubleshooting

**Qt not found during cmake configure:**
```
CMake Error: Could not find Qt6
```
Set `CMAKE_PREFIX_PATH` to your Qt installation:
```bash
cmake -B build -DCMAKE_PREFIX_PATH=/path/to/qt6
```

**Submodule clone fails (gitlab.linphone.org unreachable):**
```bash
git submodule set-url external/linphone-sdk https://github.com/BelledonneCommunications/linphone-sdk.git
git submodule set-url external/google/gn https://gn.googlesource.com/gn
git submodule update --init --recursive
```

**Build fails with `linphone-sdk` errors:**
The SDK requires additional dependencies. On Arch:
```bash
sudo pacman -Syu bctoolbox bzrtp lime mediastreamer2 ortp
```

---

## Updating

```bash
git pull
git submodule update --init --recursive
cmake --build build --parallel $(nproc)
```
