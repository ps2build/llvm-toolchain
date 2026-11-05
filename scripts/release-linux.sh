#!/bin/bash
# Builds ps2-llvm-toolchain-<version>-linux-amd64.zip for a tag in Docker; --publish uploads it to the tag's release.
# Usage: scripts/release-linux.sh vYYYY.MM.DD [--publish]
set -e
source "$(dirname "$0")/release-lib.sh"
release_init "$@"

docker_run build-linux.sh

ZIP="$OUT_DIR/ps2-llvm-toolchain-$VERSION-linux-amd64.zip"
zip_install "$WORK/out/native" "$ZIP" -rqy
release_publish "$ZIP"
