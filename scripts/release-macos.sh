#!/bin/bash
# Builds ps2-llvm-toolchain-<version>-darwin-arm64.zip for a tag on a Mac; --publish uploads it to the tag's release.
# Usage: scripts/release-macos.sh vYYYY.MM.DD [--publish]
set -e

if test "$(uname -s)" != "Darwin"; then
  echo "run this on macOS" >&2
  exit 1
fi
for tool in git cmake ninja python3 zip; do
  command -v "$tool" >/dev/null 2>&1 || { echo "missing tool: $tool (brew install cmake ninja python zip)" >&2; exit 1; }
done

source "$(dirname "$0")/release-lib.sh"
release_init "$@"

export PS2DEV="$WORK/ps2dev" BUILD_ROOT="$WORK/build"
(cd "$SRC" && bash build.sh)
bash "$SRC/scripts/sanity-check.sh" "$PS2DEV"
"$SRC/scripts/bundle-licenses.sh" "$BUILD_ROOT" "$PS2DEV"
cp "$SRC/LICENSE" "$PS2DEV/LICENSE"

ZIP="$OUT_DIR/ps2-llvm-toolchain-$VERSION-darwin-arm64.zip"
zip_install "$PS2DEV" "$ZIP" -rqy
release_publish "$ZIP"
