#!/bin/bash
# Shared by the release-*.sh scripts: parses "<tag> [--publish] [--docker|--native]", checks the tag out into a temporary worktree, builds the toolchain and uploads the zip.
# The build runs in Docker when it is installed and directly on the host otherwise; --docker and --native force one.

release_init() {
  TAG=""
  PUBLISH=0
  BACKEND=""
  for arg in "$@"; do
    case "$arg" in
      --publish) PUBLISH=1 ;;
      --docker) BACKEND=docker ;;
      --native) BACKEND=native ;;
      -*) echo "unknown argument: $arg" >&2; exit 2 ;;
      *) TAG="$arg" ;;
    esac
  done
  if test -z "$TAG"; then
    echo "usage: $0 <tag> [--publish] [--docker|--native]" >&2
    exit 2
  fi

  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[1]}")/.." && pwd)"
  VERSION="${TAG#v}"
  OUT_DIR="$REPO_ROOT/build/release"
  WORK="${TMPDIR:-/tmp}/ps2-llvm-toolchain-$VERSION.work"
  rm -rf "$WORK"; mkdir -p "$WORK"
  SRC="$WORK/src"
  trap 'git -C "$REPO_ROOT" worktree remove --force "$SRC" 2>/dev/null; rm -rf "$WORK"' EXIT

  if test -z "$BACKEND"; then
    if command -v docker >/dev/null 2>&1; then BACKEND=docker; else BACKEND=native; fi
  fi

  git -C "$REPO_ROOT" fetch --tags --quiet origin
  git -C "$REPO_ROOT" worktree add --detach "$SRC" "refs/tags/$TAG"
  mkdir -p "$OUT_DIR" "$WORK/out"
}

# docker_run <script>: runs a build step in the build image with sources, output and a cache volume mounted, or directly on the host.
docker_run() {
  local script="$1"
  if test "$BACKEND" = native; then
    native_run "$script"
    return
  fi
  docker build --platform linux/amd64 -f "$SRC/docker/build-env.Dockerfile" -t llvmtc-env "$SRC/docker"
  docker run --rm --platform linux/amd64 \
    -v ps2-llvmtc-work:/work \
    -v "$SRC:/src:ro" \
    -v "$WORK/out:/out" \
    -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
    -e LLVM_COMPILE_JOBS -e LLVM_LINK_JOBS \
    llvmtc-env bash "/src/docker/$script"
}

# native_run <script>: the host equivalent of docker/<script>; build trees are cached in $LLVMTC_WORK between runs.
native_run() {
  local cache="${LLVMTC_WORK:-$HOME/.cache/ps2-llvmtc-work}"
  mkdir -p "$cache"
  case "$1" in
    build-linux.sh)
      (
        export PS2DEV="$WORK/out/native" BUILD_ROOT="$cache/build"
        cd "$SRC"
        bash build.sh
        bash scripts/sanity-check.sh "$PS2DEV"
        scripts/bundle-licenses.sh "$BUILD_ROOT" "$PS2DEV"
        cp LICENSE "$PS2DEV/LICENSE"
      ) ;;
    build-windows.sh)
      (
        export PS2DEV="$WORK/out/windows" BUILD_ROOT="$cache/build-win" PS2_CROSS_HOST=x86_64-w64-mingw32
        mkdir -p "$PS2DEV/ee" "$PS2DEV/iop"
        cp -a "$WORK/out/native/ee/mips64r5900el-ps2-elf" "$PS2DEV/ee/"
        cp -a "$WORK/out/native/iop/mipsel-none-elf" "$PS2DEV/iop/"
        cd "$SRC"
        bash build.sh 1 2
        for f in clang ld.lld; do
          x86_64-w64-mingw32-objdump -f "$PS2DEV/llvm/bin/$f.exe" | grep -q "file format pei-x86-64"
        done
        scripts/bundle-licenses.sh "$BUILD_ROOT" "$PS2DEV" windows
        cp LICENSE "$PS2DEV/LICENSE"
      ) ;;
    *) echo "unknown build step: $1" >&2; return 1 ;;
  esac
}

# zip_install <install-dir> <zip-path> [zip flags]: zips an install as a top-level llvm-toolchain directory.
zip_install() {
  local dir="$1" zip="$2" flags="${3:--rq}"
  rm -f "$zip"
  mkdir -p "$WORK/staging"
  mv "$dir" "$WORK/staging/llvm-toolchain"
  (cd "$WORK/staging" && zip $flags "$zip" llvm-toolchain)
}

release_publish() {
  local zip="$1"
  echo "Built: $zip"
  if test "$PUBLISH" -eq 1; then
    gh release view "$TAG" --repo ps2build/llvm-toolchain >/dev/null 2>&1 \
      || gh release create "$TAG" --title "$TAG" --notes "" --verify-tag --repo ps2build/llvm-toolchain
    gh release upload "$TAG" "$zip" --clobber --repo ps2build/llvm-toolchain
  fi
}
