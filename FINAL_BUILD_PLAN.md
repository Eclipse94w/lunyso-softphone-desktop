# FINAL LUNYSO Desktop Build Plan

## Executive Summary

After extensive analysis of the linphone-desktop build system and the current state of the project, here is the definitive plan to generate `lunyso.exe`:

## Current State Analysis

### What We Have:
1. ✅ **Complete source code** - Found in git worktree at `/c/lunyso-desktop-new/`
2. ✅ **Working linphone-sdk** - All submodules present (chromium-depot-tools, crashpad, gn, linphone-sdk)
3. ✅ **Qt6 6.7.3** - Installed and configured
4. ✅ **Visual Studio BuildTools 2022** - Ready for compilation
5. ✅ **CMake 3.28** - Available
6. ✅ **LUNYSO branding** - Configured in CMakeLists.txt (lunyso.exe, Lunyso app name)

### Build Process Identified:
From the documentation and CMake analysis:
1. **Step 1**: Build SDK (`sdk` target)
2. **Step 2**: Build application (`Linphone` target)
3. **Step 3**: Install to OUTPUT directory
4. **Step 4**: Package with windeployqt

## Execution Plan

### Phase 1: Configure Build Environment
```bash
cd /c/lunyso-desktop-new
mkdir -p build
cd build
export Qt6_DIR="C:/Qt/6.7.3/msvc2019_64/lib/cmake/Qt6"
export PATH="C:/Qt/6.7.3/msvc2019_64/bin:$PATH"
```

### Phase 2: Configure CMake
```bash
cmake -G "Visual Studio 17 2022" -A x64 \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_PREFIX_PATH="C:/Qt/6.7.3/msvc2019_64" \
  -DENABLE_LIBOQS=OFF \
  -DENABLE_SRTP=OFF \
  -DENABLE_G729=OFF \
  -DENABLE_GPL_THIRD_PARTIES=OFF \
  ..
```

### Phase 3: Build SDK First
```bash
cmake --build . --target sdk --config RelWithDebInfo --parallel 4
```

### Phase 4: Build Application
```bash
cmake --build . --target Linphone --config RelWithDebInfo --parallel 4
```

### Phase 5: Install
```bash
cmake --install .
```

### Phase 6: Package
```bash
cd ..
cmake -B build -DENABLE_APP_PACKAGING=ON
cd build
cpack -G NSIS
```

## Expected Output
- **Executable**: `/c/lunyso-desktop-new/build/OUTPUT/bin/lunyso.exe`
- **Installer**: `/c/lunyso-desktop-new/build/OUTPUT/packages/LUNYSO-*.exe`

## Key Findings from Documentation
1. **Build order matters**: SDK must be built before application
2. **Install is required**: Files must be installed to OUTPUT directory to work
3. **Parallel builds**: Use `--parallel 4` for faster compilation
4. **Configuration**: RelWithDebInfo is the recommended build type

## Next Steps
Execute Phase 1 immediately to start the build process.