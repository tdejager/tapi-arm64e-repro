#!/bin/bash
echo "=== Compiling test.c with conda-forge toolchain ==="
echo "CC=$CC"
echo "SDKROOT=$SDKROOT"
echo "CONDA_PREFIX=$CONDA_PREFIX"
echo "libtapi: $(find "$CONDA_PREFIX/lib" -name 'libtapi*.dylib' 2>/dev/null)"
echo ""
$CC test.c -o test_bin 2>&1
if [ $? -eq 0 ]; then
  ./test_bin
  echo "RESULT: compilation and execution succeeded"
else
  echo "RESULT: compilation failed"
  exit 1
fi
