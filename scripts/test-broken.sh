#!/bin/bash
echo "=== Compiling test.c with conda-forge toolchain ==="
echo "CC=$CC"
echo "SDKROOT=$SDKROOT"
$CC test.c -o test_bin 2>&1 \
  && echo "UNEXPECTED: compilation succeeded (bug may be fixed already)" \
  || echo "EXPECTED: compilation failed (bug confirmed)"
