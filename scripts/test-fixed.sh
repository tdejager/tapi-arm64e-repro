#!/bin/bash
set -e

echo "=== Finding built tapi package ==="
PKG=$(find "$PIXI_PROJECT_ROOT/build/tapi-feedstock/output" -name "tapi-*.conda" 2>/dev/null | head -1)
if [ -z "$PKG" ]; then
  echo "ERROR: could not find built tapi package. Run 'pixi run build-tapi' first."
  exit 1
fi
echo "Package: $PKG"

EXISTING=$(find "$CONDA_PREFIX/lib" -name "libtapi.dylib" | head -1)
echo "Existing libtapi: $EXISTING"
if [ -z "$EXISTING" ]; then
  echo "ERROR: could not find libtapi in conda environment"
  exit 1
fi

echo "=== Extracting patched libtapi from package ==="
EXTRACT_DIR="$PIXI_PROJECT_ROOT/build/extract"
rm -rf "$EXTRACT_DIR"
mkdir -p "$EXTRACT_DIR"
cd "$EXTRACT_DIR"

# .conda files are zip archives containing pkg-*.tar.zst
unzip -o "$PKG" 2>/dev/null || true
if ls pkg-*.tar.zst 1>/dev/null 2>&1; then
  tar --zstd -xf pkg-*.tar.zst
fi

NEW_LIB=$(find "$EXTRACT_DIR" -name "libtapi*.dylib" | head -1)
if [ -z "$NEW_LIB" ]; then
  echo "ERROR: could not find libtapi.dylib in built package"
  echo "Contents:"
  find "$EXTRACT_DIR" -type f | head -20
  exit 1
fi

echo "=== Swapping libtapi: $NEW_LIB -> $EXISTING ==="
cp "$NEW_LIB" "$EXISTING"

echo "=== Compiling test.c with patched tapi ==="
cd "$PIXI_PROJECT_ROOT"
$CC test.c -o test_bin && ./test_bin \
  && echo "SUCCESS: compilation and execution succeeded with patched tapi" \
  || { echo "FAILED: compilation still fails with patched tapi"; exit 1; }
