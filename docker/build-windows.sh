#!/bin/bash
# Image entrypoint: cross-builds the Windows-hosted compiler into /out/windows, reusing the target libraries from /out/native.
set -e
git config --global --add safe.directory '*'
export PS2DEV=/out/windows BUILD_ROOT=/work/build-win PS2_CROSS_HOST=x86_64-w64-mingw32
mkdir -p "$PS2DEV/ee" "$PS2DEV/iop"
cp -r /out/native/ee/mips64r5900el-ps2-elf "$PS2DEV/ee/"
cp -r /out/native/iop/mipsel-none-elf "$PS2DEV/iop/"
cd /src
bash build.sh 1 2
for f in clang ld.lld; do
  x86_64-w64-mingw32-objdump -f "$PS2DEV/llvm/bin/$f.exe" | grep -q "file format pei-x86-64"
done
scripts/bundle-licenses.sh "$BUILD_ROOT" "$PS2DEV" windows
cp LICENSE "$PS2DEV/LICENSE"
chown -R "$HOST_UID:$HOST_GID" /out
