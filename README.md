# llvm-toolchain

Build scripts for the LLVM-based PS2 toolchain (Emotion Engine and IOP). A build produces:

- clang, lld and the LLVM binutils replacements from [ps2build/llvm](https://github.com/ps2build/llvm) (`r5900-ee`)
- compiler-rt builtins and the emulated-TLS runtime
- newlib and newlib-nano from [ps2build/newlib-llvm](https://github.com/ps2build/newlib-llvm) (`ee-v4.6.0-llvm`)
- pthread-embedded
- libc++, libc++abi, libunwind and libatomic for the EE
- `libiopmini`, the string functions a freestanding IOP module links against

## Requirements

`git`, `make`, `gcc`, `cmake`, `ninja` and `python3`. The Windows-hosted compiler also needs the mingw-w64 cross toolchain (see [docker/build-env.Dockerfile](docker/build-env.Dockerfile)).

## Building

```sh
PS2DEV=/opt/ps2dev-llvm ./build.sh        # all steps
PS2DEV=/opt/ps2dev-llvm ./build.sh 3 4    # only steps 3 and 4
```

| Step | Builds |
|---|---|
| 1 | LLVM (clang, lld, binutils replacements) |
| 2 | Per-target compiler wrappers |
| 3 | compiler-rt builtins |
| 4 | newlib |
| 5 | newlib-nano |
| 6 | pthread-embedded |
| 7 | libc++, libc++abi, libunwind, libatomic |
| 8 | Emulated-TLS runtime |
| 9 | libiopmini |

Source repositories and refs are pinned in `config.sh`; set `CONFIG_OVERRIDE` to a file that re-exports any of them. Set `PS2_CROSS_HOST=x86_64-w64-mingw32` to build the Windows-hosted compiler from Linux (steps 1 and 2; the target libraries come from a native build).

## Install layout

| Path | Contents |
|---|---|
| `llvm/bin` | clang, lld and LLVM tools |
| `ee/bin`, `iop/bin` | Target-prefixed wrappers (`mips64r5900el-ps2-elf-clang`, `-ar`, ...) and their `.cfg` files |
| `ee/mips64r5900el-ps2-elf` | EE sysroot |
| `iop/mipsel-none-elf` | IOP sysroot |

The install is relocatable.

## Usage

Point `CC` at `ee/bin/mips64r5900el-ps2-elf-clang` or `iop/bin/mipsel-none-elf-clang`. The wrapper applies the target configuration, so `mips64r5900el-ps2-elf-clang foo.c -c` needs no further flags. Compile C++ with `--driver-mode=g++`.

- newlib-nano installs `libc_nano.a`, `libm_nano.a` and `libg_nano.a` beside the full libraries; link with `-lc_nano -lm_nano`.
- C++ links with `-lc++ -lc++abi -lunwind -latomic`. Programs that use exceptions need the `.eh_frame` rules from the SDK linkfile. Build libc++ without exceptions with `LIBCXX_EXCEPTIONS=OFF`.
- `thread_local` uses emulated TLS (`-femulated-tls`); step 8 adds the runtime to `libclang_rt.builtins-mips64el.a`.

`scripts/sanity-check.sh <install-dir>` compiles and links small EE (C and C++) and IOP programs against an install.

## Local Linux build in Docker

```sh
docker build -f docker/build-env.Dockerfile -t llvmtc-env .
LLVM_SRC_DIR=/path/to/llvm NEWLIB_SRC_DIR=/path/to/newlib-llvm docker/run-local.sh <out-dir> [steps]
```

Sources and build trees live in a Docker volume; the install is bind-mounted to `<out-dir>`. The container is limited to 12 GB of memory and `LLVM_COMPILE_JOBS` (default 6) parallel compiles.

## Workflows

Build and release workflows are in `.github/workflows` and are currently disabled; releases are built in house.

## License

[CC0 1.0](LICENSE). Built components keep their own licenses, bundled into `LICENSES/` by `scripts/bundle-licenses.sh`.
