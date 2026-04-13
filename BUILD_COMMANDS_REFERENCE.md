# LUNYSO Desktop Build Commands Reference

## Environment Setup (Always Required)
```bash
export Qt6_DIR="C:/Qt/6.7.3/msvc2019_64/lib/cmake/Qt6"
export PATH="C:/Qt/6.7.3/msvc2019_64/bin:$PATH"
```

## Minimal Build (Quick Success)
```bash
# Create build directory
mkdir minimal_build && cd minimal_build

# Configure (no SDK dependencies)
cmake -G "Visual Studio 17 2022" -A x64 -DCMAKE_PREFIX_PATH="C:/Qt/6.7.3/msvc2019_64" .

# Build
cmake --build . --config RelWithDebInfo --parallel 4

# Deploy Qt dependencies
"/c/Qt/6.7.3/msvc2019_64/bin/windeployqt.exe" RelWithDebInfo/lunyso.exe
```

## Full Build (With SDK)
```bash
# Configure with SDK
cd build
cmake -G "Visual Studio 17 2022" -A x64 \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DCMAKE_PREFIX_PATH="C:/Qt/6.7.3/msvc2019_64" \
  -DENABLE_LIBOQS=OFF \
  -DENABLE_SRTP=OFF \
  -DENABLE_G729=OFF \
  -DENABLE_GPL_THIRD_PARTIES=OFF \
  ..

# Build SDK first
cmake --build . --target sdk --config RelWithDebInfo --parallel 4

# Build application
cmake --build . --target Linphone --config RelWithDebInfo --parallel 4

# Install
cmake --install .

# Package
cmake --build . --target PACKAGE --config RelWithDebInfo
```

## Troubleshooting Commands

### Check Qt Installation
```bash
ls -la /c/Qt/6.7.3/msvc2019_64/bin/
ls -la /c/Qt/6.7.3/msvc2019_64/lib/cmake/Qt6/
```

### Verify Visual Studio
```bash
ls -la "/c/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/VC/Tools/MSVC/"
"/c/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/MSBuild/Current/Bin/MSBuild.exe" -version
```

### Check CMake
```bash
cmake --version
cmake -G
```

### Find Built Files
```bash
find . -name "*.exe" -type f
find . -name "*.dll" -type f
find . -name "*.lib" -type f
```

### Deploy Qt Dependencies
```bash
# For any Qt executable
"/c/Qt/6.7.3/msvc2019_64/bin/windeployqt.exe" path/to/executable.exe

# Deploy with specific options
"/c/Qt/6.7.3/msvc2019_64/bin/windeployqt.exe" --release --no-translations executable.exe
```

### Git Submodule Issues
```bash
# Check submodule status
git submodule status

# Update submodules
git submodule update --init --recursive

# Force update
git submodule foreach --recursive git clean -xfd
git submodule foreach --recursive git reset --hard
```

### Clean Build
```bash
# Remove all build artifacts
rm -rf build/
rm -rf CMakeCache.txt CMakeFiles/

# Clean and reconfigure
mkdir build && cd build
cmake ..
```

### SDK Build Issues
```bash
# Check SDK directory
ls -la external/linphone-sdk/

# Find CMake files in SDK
find external/linphone-sdk/ -name "CMakeLists.txt"

# Check SDK build output
ls -la external/linphone-sdk/build/ 2>/dev/null || echo "No SDK build found"
```

## Quick Verification
```bash
# Check if executable works
./RelWithDebInfo/lunyso.exe

# Check dependencies
ldd RelWithDebInfo/lunyso.exe

# Check file info
file RelWithDebInfo/lunyso.exe
```

## Common Error Fixes

### "Cannot find Qt6"
```bash
export Qt6_DIR="C:/Qt/6.7.3/msvc2019_64/lib/cmake/Qt6"
```

### "MSBuild not found"
```bash
# Use full path
"/c/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/MSBuild/Current/Bin/MSBuild.exe"
```

### "Cannot find Mediastreamer2"
```bash
# SDK not built - build SDK first or use minimal build
cmake --build . --target sdk
```

### "Git describe failed"
```bash
# In SDK directory
cd external/linphone-sdk
git init && git add . && git commit -m "Initial"
git tag 6.2.0
```

## Build Types
- `Debug` - Debug symbols, no optimization
- `Release` - Optimized, no debug symbols
- `RelWithDebInfo` - Optimized with debug symbols (recommended)
- `MinSizeRel` - Minimum size release

## Architecture Options
- `x64` - 64-bit (recommended)
- `Win32` - 32-bit
- `ARM64` - ARM 64-bit (if supported)