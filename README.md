## Introduction

Small reproducer to run the modified tapi in a toolchain so you can test the before and after state. You need pixi.

```bash
pixi r -e broken test
pixi r -e fixed  test
```

The above commands simulate both a broken and working installation, will only fail reliably when on 24.6+ please.
