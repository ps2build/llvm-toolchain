#!/bin/bash
# Shared by the release-*.sh scripts: parses "<tag> [--publish]", checks the tag out into a temporary worktree, builds the Linux image and toolchain, and uploads the zip.

release_init() {
  TAG=""
  PUBLISH=0
  for arg in "$@"; do
    case "$arg" in
      --publish) PUBLISH=1 ;;
      -*) echo "unknown argument: $arg" >&2; exit 2 ;;
      *) TAG="$arg" ;;
    esac
  done
  if test -z "$TAG"; then
    echo "usage: $0 <tag> [--publish]" >&2
    exit 2
  fi

  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[1]}")/.." && pwd)"
  VERSION="${TAG#v}"
  OUT_DIR="$REPO_ROOT/build/release"
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/ps2-llvm-toolchain-$VERSION.XXXXXX")"
  SRC="$WORK/src"
  trap 'git -C "$REPO_ROOT" worktree remove --force "$SRC" 2>/dev/null; rm -rf "$WORK"' EXIT

  git -C "$REPO_ROOT" fetch --tags --quiet origin
  git -C "$REPO_ROOT" worktree add --detach "$SRC" "refs/tags/$TAG"
  mkdir -p "$OUT_DIR" "$WORK/out"
}

# docker_run <script> <image-script-args...>: runs a docker/build-*.sh script in the build image with sources, output and a cache volume mounted.
docker_run() {
  local script="$1"
  docker build --platform linux/amd64 -f "$SRC/docker/build-env.Dockerfile" -t llvmtc-env "$SRC/docker"
  docker run --rm --platform linux/amd64 \
    -v ps2-llvmtc-work:/work \
    -v "$SRC:/src:ro" \
    -v "$WORK/out:/out" \
    -e HOST_UID="$(id -u)" -e HOST_GID="$(id -g)" \
    -e LLVM_COMPILE_JOBS -e LLVM_LINK_JOBS \
    llvmtc-env bash "/src/docker/$script"
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
