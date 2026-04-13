# LUNYSO Desktop Build Troubleshooting Guide

## Quick Diagnosis

Run this first to check your environment:
```bash
echo "=== Environment Check ==="
echo "Qt6_DIR: $Qt6_DIR"
echo "PATH contains Qt: $(echo $PATH | grep -o 'Qt.*bin')"
echo "CMake: $(cmake --version | head -1)"
echo "VS BuildTools: $([ -d "/c/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools" ] && echo "OK" || echo "MISSING")"
echo "Qt Install: $([ -d "/c/Qt/6.7.3" ] && echo "OK" || echo "MISSING")"
```

## Common Issues and Solutions

### 1. Qt6 Not Found
**Error**: `Could not find a package configuration file provided by "Qt6"`
**Fix**:
```bash
export Qt6_DIR="C:/Qt/6.7.3/msvc2019_64/lib/cmake/Qt6"
export PATH="C:/Qt/6.7.3/msvc2019_64/bin:$PATH"
```

### 2. Visual Studio Not Found
**Error**: `No CMAKE_CXX_COMPILER could be found`
**Fix**: Install Visual Studio BuildTools 2022 with C++ workload

### 3. Submodule Failures
**Error**: `does not contain a CMakeLists.txt file` in external/
**Solutions**:
- Network issues: GitLab unreachable
- Use working SDK copy: `cp -r /c/lunyso-desktop/external/linphone-sdk-working external/`
- Initialize git in copied SDK for version detection

### 4. Mediastreamer2 Missing
**Error**: `Could NOT find Mediastreamer2`
**Root Cause**: SDK not built/installed
**Workaround**: Use minimal build without SDK
**Proper Fix**: Build SDK first, then application

### 5. MSBuild Errors
**Error**: `MSB1009: Le fichier projet n'existe pas`
**Cause**: Wrong directory or missing project files
**Fix**: Ensure you're in correct build directory

### 6. Git Describe Failures
**Error**: `fail to get GIT describe version`
**Fix**:
```bash
cd external/linphone-sdk
rm -rf .git
git init && git add . && git commit -m "Initial"
git tag -a 6.2.0 -m "Version 6.2.0"
```

### 7. External Dependencies Missing
**Error**: `No download info given for 'libaom'` etc.
**Fix**: Disable unused features:
```bash
cmake -DENABLE_AOM=OFF -DENABLE_VPX=OFF -DENABLE_OPENH264=OFF ...
```

### 8. Architecture Mismatch
**Error**: `module machine type 'x64' conflicts with target machine type 'x86'`
**Fix**: Always specify x64: `cmake -G "Visual Studio 17 2022" -A x64`

### 9. Missing Runtime Libraries
**Error**: `cannot open shared object file: No such file or directory`
**Fix**: Run windeployqt:
```bash
"/c/Qt/6.7.3/msvc2019_64/bin/windeployqt.exe" executable.exe
```

### 10. CMake Cache Issues
**Error**: Strange configuration errors
**Fix**: Clean cache:
```bash
rm -rf CMakeCache.txt CMakeFiles/
```

## Build Strategy Decision Tree

```
Build Failed?
├─ Qt6 errors? → Set Qt6_DIR and PATH
├─ SDK errors? → 
│  ├─ Submodule issues? → Copy working SDK
│  ├─ Missing dependencies? → Disable features
│  └─ Git version? → Initialize git repo
├─ Compiler errors? → Check VS BuildTools
└─ Still failing? → Use minimal build
```

## Recovery Procedures

### Complete Clean
```bash
# Save your work first!
git clean -xfd
git submodule foreach --recursive git clean -xfd
rm -rf build/ minimal_build/
```

### Emergency Build
```bash
# When everything else fails
mkdir emergency_build
cd emergency_build
# Create minimal CMakeLists.txt
echo 'cmake_minimum_required(VERSION 3.22)' > CMakeLists.txt
echo 'project(LUNYSO)' >> CMakeLists.txt
echo 'find_package(Qt6 REQUIRED COMPONENTS Core)' >> CMakeLists.txt
echo 'add_executable(lunyso main.cpp)' >> CMakeLists.txt
echo 'target_link_libraries(lunyso Qt6::Core)' >> CMakeLists.txt
# Create minimal main.cpp
echo '#include <QCoreApplication>' > main.cpp
echo '#include <iostream>' >> main.cpp
echo 'int main() { std::cout << "LUNYSO works!" << std::endl; return 0; }' >> main.cpp
# Build
cmake -G "Visual Studio 17 2022" -A x64 -DCMAKE_PREFIX_PATH="C:/Qt/6.7.3/msvc2019_64" .
cmake --build . --config Release
```

### SDK Build Issues
```bash
# If SDK won't build, try building components separately
cd external/linphone-sdk
# Build individual components
cmake --build . --target bctoolbox --config RelWithDebInfo
cmake --build . --target mediastreamer2 --config RelWithDebInfo
cmake --build . --target linphone --config RelWithDebInfo
```

## Diagnostic Commands

### Check Build System
```bash
# CMake generators
cmake -G

# Visual Studio installations
ls "/c/Program Files (x86)/Microsoft Visual Studio/"

# Qt installations
ls /c/Qt/

# Available compilers
gcc --version 2>/dev/null || echo "GCC not found"
cl 2>&1 | head -1 || echo "MSVC not in PATH"
```

### Check Project Structure
```bash
# Verify key files exist
ls -la CMakeLists.txt
ls -la external/linphone-sdk/CMakeLists.txt 2>/dev/null || echo "SDK missing"
ls -la Linphone/ 2>/dev/null || echo "Linphone dir missing"
```

### Check Dependencies
```bash
# Qt modules
find /c/Qt/ -name "Qt6*Config.cmake" | head -10

# Visual Studio tools
find "/c/Program Files (x86)/Microsoft Visual Studio/" -name "MSBuild.exe"
find "/c/Program Files (x86)/Microsoft Visual Studio/" -name "cl.exe" | head -5
```

## Build Log Analysis

### Success Indicators
- `-- Configuring done`
- `-- Generating done`
- `Build files have been written to:`
- `0 Error(s)` in MSBuild output

### Failure Patterns
- `CMake Error at` - Configuration issue
- `MSB1009` - Missing project file
- `error MSB4057` - Invalid target
- `Could NOT find` - Missing dependency
- `No such file or directory` - Missing file

## Performance Tips

### Faster Builds
```bash
# Use all CPU cores
cmake --build . --parallel $(nproc)

# Build specific targets only
cmake --build . --target lunyso --config RelWithDebInfo

# Skip install if just testing
cmake --build . --config RelWithDebInfo
```

### Reduce Dependencies
```bash
# Disable unused features
cmake -DENABLE_UNIT_TESTS=OFF \
      -DENABLE_DOC=OFF \
      -DENABLE_GPL_THIRD_PARTIES=OFF \
      ..
```

## Platform-Specific Notes

### Windows Paths
- Always use forward slashes in CMake
- Quote paths with spaces
- Use full paths for tools

### Git Bash vs PowerShell
- This guide uses Git Bash
- For PowerShell: Replace `/c/` with `C:\`
- Environment variables: `$env:PATH` in PowerShell

### MSVC Runtime
- windeployqt handles Qt runtime
- May need Visual C++ Redistributables for deployment

## When to Ask for Help

1. After trying minimal build and it fails
2. When SDK submodules won't clone at all
3. If CMake can't find any generators
4. When compiler crashes during build
5. After following this entire guide without success

Include in help request:
- Full error message
- Output of environment check
- What you've already tried
- Git commit hash you're building from

## Success Checklist

After build completes:
- [ ] `lunyso.exe` exists in build directory
- [ ] File size > 40KB (not empty)
- [ ] `windeployqt` ran successfully
- [ ] Qt6Core.dll present alongside executable
- [ ] Executable runs without errors
- [ ] Window appears (for GUI builds)
- [ ] No missing DLL errors

Remember: A working minimal build is better than a broken full build! Build incrementally and verify each step. This guide ensures you can recover from any failure state. Good luck! 🚀

---
*Last updated: 2026-04-13*
*Build system: CMake 3.28, Qt 6.7.3, VS BuildTools 2022*