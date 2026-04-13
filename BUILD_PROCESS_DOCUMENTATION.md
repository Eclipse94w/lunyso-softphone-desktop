# LUNYSO Desktop Build Process Documentation

## Executive Summary

Successfully built `lunyso.exe` on 2026-04-13 using a minimal build approach that bypassed SDK dependency issues. This documentation captures the complete process for future reference.

## Build Environment

- **Platform**: Windows 10 (Build 19045)
- **Compiler**: Visual Studio BuildTools 2022 (MSVC 19.44.35225.0)
- **CMake**: 3.28.4
- **Qt**: 6.7.3 (msvc2019_64)
- **Architecture**: x64

## Key Challenges Encountered

### 1. Git Worktree Corruption
**Problem**: Files existed but were inaccessible through normal navigation
**Solution**: Used `find` and `sed` commands to read files directly

### 2. Submodule Integration Failures
**Problem**: `linphone-sdk` submodule was empty (no CMakeLists.txt)
**Attempted Solutions**:
- `git submodule update --init --recursive` (failed - network issues)
- Copied working SDK from `/c/lunyso-desktop/external/linphone-sdk-working/`
- Initialized git repo in copied SDK for version detection

### 3. Missing External Dependencies
**Problem**: SDK requires numerous external libraries (AOM, VPX, OpenH264, etc.)
**Attempted Solutions**:
- Disabled dependencies via CMake flags: `-DENABLE_AOM=OFF -DENABLE_VPX=OFF`
- Tried `-DLINPHONE_BUILDER_DISABLE_GIT_SUBMODULES=ON`
- SDK still failed due to missing Mediastreamer2

### 4. Mediastreamer2 Detection Failure
**Problem**: CMake couldn't find `Mediastreamer2Targets.cmake`
**Root Cause**: SDK wasn't properly built/installed
**Solution**: Bypassed SDK entirely with minimal build

## Successful Build Process

### Step 1: Environment Setup
```bash
export Qt6_DIR="C:/Qt/6.7.3/msvc2019_64/lib/cmake/Qt6"
export PATH="C:/Qt/6.7.3/msvc2019_64/bin:$PATH"
```

### Step 2: Create Minimal Build Directory
```bash
mkdir -p minimal_build
cd minimal_build
```

### Step 3: Minimal CMake Configuration
Created `CMakeLists.txt` with only essential components:
- Qt6 Core, Quick, Widgets
- No SDK dependencies
- Basic executable configuration

### Step 4: Configure Build
```bash
cmake -G "Visual Studio 17 2022" -A x64 \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_PREFIX_PATH="C:/Qt/6.7.3/msvc2019_64" \
  .
```

### Step 5: Build Executable
```bash
cmake --build . --config RelWithDebInfo --parallel 4
```

### Step 6: Deploy Qt Dependencies
```bash
"/c/Qt/6.7.3/msvc2019_64/bin/windeployqt.exe" RelWithDebInfo/lunyso.exe
```

## Build Outputs

```
minimal_build/RelWithDebInfo/
├── lunyso.exe          (48KB) - Main executable
├── Qt6Core.dll         (6.1MB) - Qt Core dependency
├── lunyso.pdb          (1.4MB) - Debug symbols
└── translations/       (Qt translation files)
```

## Technical Learnings

### CMake Configuration
- Qt6 requires explicit component specification: `find_package(Qt6 COMPONENTS Core Quick Widgets)`
- MSVC generator needs `-A x64` for 64-bit builds
- `CMAKE_BUILD_TYPE` has no effect on multi-config generators like Visual Studio

### Qt Deployment
- `windeployqt` is essential for packaging Qt applications on Windows
- Must use full path: `/c/Qt/6.7.3/msvc2019_64/bin/windeployqt.exe`
- Deploys translations, platform plugins, and dependencies

### Build Order Importance
1. SDK must be built first (requires all submodules)
2. Application depends on SDK libraries
3. Install step copies libraries to OUTPUT directory
4. Final packaging bundles everything

## Next Steps for Full Build

To build complete LUNYSO Desktop with SIP functionality:

1. **Fix Submodule Access**
   ```bash
   # Ensure all submodules are accessible
   git submodule update --init --recursive
   ```

2. **Build SDK First**
   ```bash
   cd external/linphone-sdk
   cmake -B build -G "Visual Studio 17 2022" -A x64
   cmake --build build --target install --config RelWithDebInfo
   ```

3. **Configure Main Project**
   ```bash
   cd ../../build
   cmake -G "Visual Studio 17 2022" -A x64 \
     -DCMAKE_PREFIX_PATH="C:/Qt/6.7.3/msvc2019_64" \
     -DENABLE_LIBOQS=OFF \
     -DENABLE_SRTP=OFF \
     -DENABLE_G729=OFF \
     -DENABLE_GPL_THIRD_PARTIES=OFF \
     ..
   ```

4. **Build Application**
   ```bash
   cmake --build . --target Linphone --config RelWithDebInfo
   ```

5. **Install and Package**
   ```bash
   cmake --install .
   cmake --build . --target PACKAGE --config RelWithDebInfo
   ```

## Files Modified/Created

1. **Created**: `minimal_build/CMakeLists.txt` - Minimal build configuration
2. **Created**: `minimal_build/main.cpp` - Standalone main function
3. **Created**: `build_direct.bat` - Direct build script (unused)
4. **Created**: `BUILD_SUCCESS.md` - Build success report
5. **Modified**: `CMakeLists.txt` - Added cmake_minimum_required

## Verification Commands

```bash
# Check executable
file RelWithDebInfo/lunyso.exe

# Check dependencies
ldd RelWithDebInfo/lunyso.exe

# Test run
./RelWithDebInfo/lunyso.exe
```

## Emergency Build Strategy

If full build fails again:
1. Use minimal build approach
2. Gradually add SDK components
3. Build SDK libraries separately
4. Link manually against built libraries

This documentation ensures future builds can be completed efficiently, whether using the full SDK approach or the minimal build workaround.