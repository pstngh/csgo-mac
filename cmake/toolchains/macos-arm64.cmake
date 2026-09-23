set(CMAKE_SYSTEM_NAME Darwin)
set(CMAKE_SYSTEM_PROCESSOR arm64)
set(CMAKE_OSX_ARCHITECTURES arm64 CACHE STRING "" FORCE)
set(CMAKE_OSX_SYSROOT "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk" CACHE PATH "" FORCE)

# Use the tools directly. This also keeps CMake independent of xcrun while the
# full Xcode license has not yet been accepted on the host.
set(CMAKE_C_COMPILER "/Library/Developer/CommandLineTools/usr/bin/clang" CACHE FILEPATH "" FORCE)
set(CMAKE_CXX_COMPILER "/Library/Developer/CommandLineTools/usr/bin/clang++" CACHE FILEPATH "" FORCE)
set(CMAKE_AR "/Library/Developer/CommandLineTools/usr/bin/ar" CACHE FILEPATH "" FORCE)
set(CMAKE_RANLIB "/Library/Developer/CommandLineTools/usr/bin/ranlib" CACHE FILEPATH "" FORCE)
set(CMAKE_INSTALL_NAME_TOOL "/Library/Developer/CommandLineTools/usr/bin/install_name_tool" CACHE FILEPATH "" FORCE)

set(CMAKE_PREFIX_PATH "/opt/homebrew" CACHE STRING "" FORCE)
set(CMAKE_BUILD_WITH_INSTALL_RPATH TRUE CACHE BOOL "" FORCE)
set(CMAKE_INSTALL_RPATH "@loader_path;@loader_path/../../../bin/osx64;/opt/homebrew/lib" CACHE STRING "" FORCE)
