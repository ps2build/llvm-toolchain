#!/bin/bash
# Image entrypoint: builds the Linux-hosted toolchain from /src into /out/native and fixes ownership for the host user.
set -e
git config --global --add safe.directory '*'
export PS2DEV=/out/native BUILD_ROOT=/work/build
cd /src
bash build.sh
bash scripts/sanity-check.sh "$PS2DEV"
scripts/bundle-licenses.sh "$BUILD_ROOT" "$PS2DEV"
cp LICENSE "$PS2DEV/LICENSE"
chown -R "$HOST_UID:$HOST_GID" /out
