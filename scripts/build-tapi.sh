#!/bin/bash
set -e

FEEDSTOCK_DIR="$PIXI_PROJECT_ROOT/build/tapi-feedstock"

if [ -d "$FEEDSTOCK_DIR" ]; then
  echo "tapi-feedstock already cloned, skipping..."
else
  echo "=== Cloning tapi-feedstock ==="
  mkdir -p "$PIXI_PROJECT_ROOT/build"
  git clone --depth 1 https://github.com/conda-forge/tapi-feedstock.git "$FEEDSTOCK_DIR"
fi

echo "=== Applying arm64e fallback patch ==="
cp "$PIXI_PROJECT_ROOT/patches/arm64e-fallback.patch" "$FEEDSTOCK_DIR/recipe/patches/"

# Add patch to recipe.yaml if not already added
if ! grep -q "arm64e-fallback" "$FEEDSTOCK_DIR/recipe/recipe.yaml"; then
  sed -i.bak '/cmake-darwin-linker.patch/a\
      - patches/arm64e-fallback.patch
' "$FEEDSTOCK_DIR/recipe/recipe.yaml"
fi

# Add missing variant config (normally provided by conda-forge CI pinning)
if ! grep -q "c_stdlib" "$FEEDSTOCK_DIR/recipe/conda_build_config.yaml"; then
  cat >> "$FEEDSTOCK_DIR/recipe/conda_build_config.yaml" <<'VARIANT'
c_stdlib:
  - macosx_deployment_target
c_stdlib_version:
  - "11.0"
macos_machine:
  - arm64
MACOSX_DEPLOYMENT_TARGET:
  - "11.0"
VARIANT
fi

echo "=== Updated recipe.yaml patches section ==="
grep -A5 "patches:" "$FEEDSTOCK_DIR/recipe/recipe.yaml"

echo "=== Building patched tapi (using 15.4 SDK to avoid LLVM build issues on 26.x SDK) ==="
cd "$FEEDSTOCK_DIR"
SDKROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  CONDA_BUILD_SYSROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk \
  rattler-build build --recipe recipe/recipe.yaml

echo "=== Build complete ==="
