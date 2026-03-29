#!/bin/bash
set -x

# This LLVM version can't compile against macOS 26+ SDKs (missing getpagesize).
# If we're on 26+, find an older SDK to build with. The resulting libtapi.dylib
# works fine at runtime regardless of which SDK was used to compile it.
SDK_DIR="/Library/Developer/CommandLineTools/SDKs"
if [ -d "$SDK_DIR" ]; then
  OLDER_SDK=$(ls -d "$SDK_DIR"/MacOSX1[0-9]*.sdk 2>/dev/null | sort -V | tail -1)
  if [ -n "$OLDER_SDK" ]; then
    echo "Using older SDK for build: $OLDER_SDK"
    export SDKROOT="$OLDER_SDK"
    export CONDA_BUILD_SYSROOT="$OLDER_SDK"
    # Update CMAKE_ARGS to use the older sysroot
    CMAKE_ARGS="${CMAKE_ARGS//-DCMAKE_OSX_SYSROOT=*-DCMAKE_OSX_SYSROOT=/-DCMAKE_OSX_SYSROOT=}"
    CMAKE_ARGS="${CMAKE_ARGS} -DCMAKE_OSX_SYSROOT=${OLDER_SDK}"
  fi
fi

mkdir build
cd build

if [[ "$CONDA_BUILD_CROSS_COMPILATION" == "1" ]]; then
  NATIVE_FLAGS="-DCMAKE_C_COMPILER=$CC_FOR_BUILD;-DCMAKE_CXX_COMPILER=$CXX_FOR_BUILD"
  NATIVE_FLAGS="${NATIVE_FLAGS};-DCMAKE_C_FLAGS=-O2;-DCMAKE_CXX_FLAGS=-O2"
  NATIVE_FLAGS="${NATIVE_FLAGS};-DCMAKE_EXE_LINKER_FLAGS=-Wl,-rpath,${BUILD_PREFIX}/lib"
  NATIVE_FLAGS="${NATIVE_FLAGS};-DCMAKE_MODULE_LINKER_FLAGS=;-DCMAKE_SHARED_LINKER_FLAGS="
  NATIVE_FLAGS="${NATIVE_FLAGS};-DCMAKE_STATIC_LINKER_FLAGS=;-DCMAKE_PREFIX_PATH=${BUILD_PREFIX}"
  NATIVE_FLAGS="${NATIVE_FLAGS};-DLLVM_DIR=$BUILD_PREFIX/lib/cmake/llvm"
  NATIVE_FLAGS="${NATIVE_FLAGS};-DCLANG_INCLUDE_TESTS=OFF;-DLLVM_INCLUDE_TESTS=OFF"
  NATIVE_FLAGS="${NATIVE_FLAGS};-DLLVM_INCLUDE_DOCS=OFF;-DLLVM_INCLUDE_BENCHMARKS=OFF"
  NATIVE_FLAGS="${NATIVE_FLAGS};-DLLVM_INCLUDE_EXAMPLES=OFF"
  CMAKE_ARGS="${CMAKE_ARGS} -DCROSS_TOOLCHAIN_FLAGS_NATIVE=${NATIVE_FLAGS}"
  CMAKE_ARGS="${CMAKE_ARGS} -DLLVM_HOST_TRIPLE=$(echo $HOST | sed s/conda/unknown/g) -DLLVM_DEFAULT_TARGET_TRIPLE=$(echo $HOST | sed s/conda/unknown/g)"
fi

cmake ${CMAKE_ARGS} \
    -G Ninja \
    -DCMAKE_ASM_COMPILER=$CC \
    -DCMAKE_NM=$BUILD_PREFIX/bin/$NM \
    -DTAPI_REPOSITORY_STRING="https://github.com/tpoechtrager/apple-libtapi/commit/$GIT_COMMIT" \
    -DLLVM_ENABLE_PROJECTS="tapi;clang" \
    -DLLVM_TARGETS_TO_BUILD=host \
    -DTAPI_FULL_VERSION=${PKG_VERSION} \
    -DTAPI_VENDOR="conda-forge " \
    -DCLANG_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    $SRC_DIR/src/llvm

ninja clangBasic vt_gen -j${CPU_COUNT}
ninja libtapi -j${CPU_COUNT}
ninja install-libtapi install-tapi-headers -j${CPU_COUNT}
