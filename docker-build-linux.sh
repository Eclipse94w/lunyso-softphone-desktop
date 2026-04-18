#!/bin/bash
# Docker build script for lunyso-desktop 5.3.4 — Linux
# Runs inside lunyso-build-env:latest container (all deps pre-baked)
# Source mounted at /src, output written to /src/build-linux/

set -euo pipefail

LOG=/src/build-linux/build.log
mkdir -p /src/build-linux
exec > >(tee -a "$LOG") 2>&1

echo "=== [$(date)] lunyso-desktop Linux build starting ==="

# libglew-dev not in base image — quick install
apt-get update -qq && apt-get install -y --no-install-recommends libglew-dev libxinerama-dev libgles2-mesa-dev

cmake --version
qmake --version

# ── 1. Submodule init ────────────────────────────────────────────────────────
echo "=== [$(date)] Initialising submodules ==="
cd /src

git config --global --add safe.directory /src
git config --global --add safe.directory '*'

if [ ! -f external/qtkeychain/CMakeLists.txt ]; then
  git submodule update --init external/qtkeychain
fi

if [ ! -f external/ispell/CMakeLists.txt ]; then
  git submodule update --init external/ispell
fi

if [ ! -f linphone-sdk/CMakeLists.txt ]; then
  git submodule update --init --depth 1 linphone-sdk
fi

# Full recursive pass with retry
RETRIES=5
for i in $(seq 1 $RETRIES); do
  echo "--- recursive submodule pass $i/$RETRIES ---"
  if git -C linphone-sdk submodule update --init --recursive --depth 1 --jobs 4; then
    echo "--- pass complete ---"
    break
  fi
  [ "$i" -eq "$RETRIES" ] && { echo "ERROR: submodule init failed after $RETRIES attempts"; exit 1; }
  sleep 15
done

# Explicit re-init for any submodule dirs that are still empty
echo "=== [$(date)] Verifying critical submodules ==="
CRITICAL_SUBS=(
  "external/bv16-floatingpoint"
  "external/decaf"
  "external/ffmpeg"
  "external/jsoncpp"
  "external/libjpeg-turbo"
  "external/liboqs"
  "external/libvpx"
  "external/libyuv"
  "external/mbedtls"
  "external/opencore-amr"
  "external/srtp"
  "external/opus"
  "external/soci"
  "external/speex"
  "external/zlib"
  "external/zxing-cpp"
)
ALL_OK=1
for sub in "${CRITICAL_SUBS[@]}"; do
  if [ ! -f "linphone-sdk/$sub/CMakeLists.txt" ]; then
    echo "--- MISSING: linphone-sdk/$sub — force re-init ---"
    git -C linphone-sdk submodule update --init --depth 1 --force "$sub" || true
    ALL_OK=0
  fi
done
if [ ! -f "linphone-sdk/bcmatroska2/CMakeLists.txt" ]; then
  echo "--- MISSING: linphone-sdk/bcmatroska2 — force re-init ---"
  git -C linphone-sdk submodule update --init --depth 1 --force bcmatroska2 || true
  ALL_OK=0
fi
# mbedtls has a nested submodule (framework) that --recursive misses on shallow clones
if [ -f "linphone-sdk/external/mbedtls/CMakeLists.txt" ] && [ ! -f "linphone-sdk/external/mbedtls/framework/CMakeLists.txt" ]; then
  echo "--- MISSING: mbedtls/framework — force re-init ---"
  git -C linphone-sdk/external/mbedtls submodule update --init --depth 1 --force framework || true
fi

if [ "$ALL_OK" -eq 0 ]; then
  # Second recursive pass after targeted re-inits
  echo "--- running second recursive pass ---"
  for i in $(seq 1 $RETRIES); do
    if git -C linphone-sdk submodule update --init --recursive --depth 1 --jobs 2; then
      echo "--- second pass complete ---"
      break
    fi
    [ "$i" -eq "$RETRIES" ] && { echo "ERROR: second submodule pass failed"; exit 1; }
    sleep 15
  done
fi

echo "=== [$(date)] Submodules initialised ==="

# ── 2. CMake configure ───────────────────────────────────────────────────────
echo "=== [$(date)] CMake configure ==="
cd /src/build-linux

cmake /src -G Ninja \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DLINPHONESDK_PLATFORM=Desktop \
  -DLINPHONESDK_VERSION=5.3.4 \
  -DENABLE_APP_PACKAGING=OFF \
  -DENABLE_UNIT_TESTS=OFF \
  -DENABLE_G729=OFF \
  -DENABLE_PQCRYPTO=OFF \
  -DENABLE_GPL_THIRD_PARTIES=ON \
  -DENABLE_CSHARP_WRAPPER=NO \
  -DENABLE_BUILD_VERBOSE=OFF \
  -DENABLE_V4L=ON \
  -DENABLE_LDAP=OFF \
  -DENABLE_GLX=OFF \
  -DENABLE_GL=OFF \
  -DENABLE_QT_GL=OFF \
  2>&1

echo "=== [$(date)] CMake configure done ==="

# ── 3. Build ─────────────────────────────────────────────────────────────────
echo "=== [$(date)] Building (parallel=4) ==="
cmake --build . --target install --parallel 4

echo "=== [$(date)] BUILD COMPLETE ==="
ls /src/build-linux/OUTPUT/bin/ 2>/dev/null || echo "bin/ not found"
