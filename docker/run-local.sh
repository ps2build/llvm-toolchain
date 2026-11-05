#!/bin/bash
# Runs the toolchain build in the llvmtc-env image (docker build --platform linux/amd64 -f docker/build-env.Dockerfile -t llvmtc-env .).
# Sources and build trees live in the llvmtc-work volume; the install is bind-mounted to <out-dir>.
# Needs LLVM_SRC_DIR and NEWLIB_SRC_DIR pointing at local clones.
# On Apple silicon, the image must be built and run with --platform linux/amd64 (matches the release scripts); omitting it builds an arm64 image that can silently diverge from the released toolchain.
# Usage: run-local.sh <out-dir> [build.sh args...]
set -e
OUT="$1"; shift
HERE="$(cd "$(dirname "$0")/.." && pwd -W 2>/dev/null || pwd)"
docker run --rm --platform linux/amd64 --memory=12g --memory-swap=12g \
  -v llvmtc-work:/work \
  -v "$OUT:/opt/ps2dev-build" \
  -v "$HERE:/mnt/tc:ro" \
  -v "${LLVM_SRC_DIR:?}:/mnt/llvm-project:ro" \
  -v "${NEWLIB_SRC_DIR:?}:/mnt/newlib:ro" \
  -e PS2DEV=/opt/ps2dev-build \
  -e PS2_CROSS_HOST="${PS2_CROSS_HOST:-}" \
  -e LLVM_COMPILE_JOBS="${LLVM_COMPILE_JOBS:-6}" -e LLVM_LINK_JOBS="${LLVM_LINK_JOBS:-2}" \
  llvmtc-env bash -c '
    set -e
    git config --global --add safe.directory "*"
    rm -rf /work/llvm-toolchain/lib /work/llvm-toolchain/steps /work/llvm-toolchain/scripts /work/llvm-toolchain/wrappers
    mkdir -p /work/llvm-toolchain
    cd /mnt/tc && tar cf - build.sh config.sh lib steps scripts wrappers | tar xf - -C /work/llvm-toolchain
    cat > /work/override.sh <<OVR
LLVM_URL=file:///mnt/llvm-project
NEWLIB_URL=file:///mnt/newlib
OVR
    cd /work/llvm-toolchain
    CONFIG_OVERRIDE=/work/override.sh bash build.sh "$@"
  ' _ "$@"
