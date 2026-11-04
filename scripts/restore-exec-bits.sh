#!/bin/sh
# Usage: restore-exec-bits.sh <install-root>
# Artifact upload drops file modes; this restores them on the executable directories.
set -e

for p in llvm/bin ee/bin iop/bin; do
    if [ -d "$1/$p" ]; then
        chmod -R +x "$1/$p"
    fi
done
