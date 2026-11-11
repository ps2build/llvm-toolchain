#!/bin/bash
# Builds ps2-llvm-toolchain-<version>-windows-amd64.zip for a tag, cross-compiled in Docker or directly on a Linux host with mingw; --publish uploads it to the tag's release.
# The Linux toolchain is built first because the Windows package reuses its target libraries.
# Usage: scripts/release-windows.sh vYYYY.MM.DD [--publish] [--docker|--native]
set -e
source "$(dirname "$0")/release-lib.sh"
release_init "$@"

docker_run build-linux.sh
docker_run build-windows.sh

ZIP="$OUT_DIR/ps2-llvm-toolchain-$VERSION-windows-amd64.zip"
zip_install "$WORK/out/windows" "$ZIP"
release_publish "$ZIP"
