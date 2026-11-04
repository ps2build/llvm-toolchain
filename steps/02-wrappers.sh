#!/bin/bash
# Per-target compiler wrappers and binutils-named tools under $PS2DEV/{ee,iop}/bin.
# The wrappers run the one shared clang with the target's .cfg, found next to
# the wrapper, so the install can be moved anywhere.

source "$(dirname "$0")/../lib/common.sh"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
EXE=""
if test -n "$PS2_CROSS_HOST"; then EXE=".exe"; fi

install_target() {
  local dir="$1" prefix="$2" cfg="$3"
  mkdir -p "$PS2DEV/$dir/bin"

  sed "s|@PREFIX@|$prefix|g" "$ROOT/wrappers/$cfg" > "$PS2DEV/$dir/bin/$prefix-clang.cfg"

  if test -n "$PS2_CROSS_HOST"; then
    printf '@echo off\r\n"%%~dp0..\\..\\llvm\\bin\\clang.exe" --config="%%~dp0%s-clang.cfg" %%*\r\n' "$prefix" \
      > "$PS2DEV/$dir/bin/$prefix-clang.bat"
    local tool
    for tool in ar ranlib nm objcopy strip objdump size; do
      printf '@echo off\r\n"%%~dp0..\\..\\llvm\\bin\\llvm-%s.exe" %%*\r\n' "$tool" \
        > "$PS2DEV/$dir/bin/$prefix-$tool.bat"
    done
    printf '@echo off\r\n"%%~dp0..\\..\\llvm\\bin\\llvm-readobj.exe" --elf-output-style=GNU %%*\r\n' \
      > "$PS2DEV/$dir/bin/$prefix-readelf.bat"
  else
    cat > "$PS2DEV/$dir/bin/$prefix-clang" <<WRAP
#!/bin/sh
d="\$(cd "\$(dirname "\$0")" && pwd)"
exec "\$d/../../llvm/bin/clang" --config="\$d/$prefix-clang.cfg" "\$@"
WRAP
    chmod +x "$PS2DEV/$dir/bin/$prefix-clang"
    local tool
    for tool in ar ranlib nm objcopy strip objdump size; do
      ln -sf "../../llvm/bin/llvm-$tool" "$PS2DEV/$dir/bin/$prefix-$tool"
    done
    ln -sf "../../llvm/bin/llvm-readobj" "$PS2DEV/$dir/bin/$prefix-readelf"
  fi
}

install_target ee mips64r5900el-ps2-elf ee-clang.cfg.in
install_target iop mipsel-none-elf iop-clang.cfg.in
