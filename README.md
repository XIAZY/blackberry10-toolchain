# BB10 Cascades builder

This repository provides a Dockerized toolchain for building BlackBerry 10
ARMv7 applications and unsigned development `.bar` packages. The example in
`examples/calculator/` is a small Cascades application with native C++ logic
and a QML view.

## Prerequisites

- Docker with Buildx/Bake support
- A shell with the `docker` command available

The SDK, compiler, linker, packager, and build utilities are installed or
assembled inside the Docker image. The host needs no BB10 SDK, QNX compiler, or
cross-toolchain.

## Prebuilt image

GitHub Actions builds the image for amd64 and arm64 (`.github/workflows/image.yml`)
and publishes it as `ghcr.io/xiazy/blackberry10-toolchain`: `latest` follows
`main`, and every build is also tagged with its commit (`sha-<short>`) and any
`v*` tag. To use it instead of building locally:

```sh
docker pull ghcr.io/xiazy/blackberry10-toolchain:latest
BB10_BUILDER_IMAGE=ghcr.io/xiazy/blackberry10-toolchain:latest ./tools/docker-builder.sh build
```

## Build the builder image

From the repository root, run:

```sh
./tools/docker-builder.sh image
```

This builds the `bb10-builder:latest` image. The Docker build downloads the
archived BB10 SDK inputs and builds the QNX-targeted GNU Binutils linker. The
first build can take a while; later builds use Docker's layer cache.

## Build the calculator BAR

```sh
./tools/docker-builder.sh check
./tools/docker-builder.sh compile
./tools/docker-builder.sh build
```

`check` validates the CMake project and, if present, its BAR descriptor.
`compile` configures with CMake and compiles/links, but does not package. `build`
does the same and packages an unsigned development BAR when the project has a
`bar-descriptor.xml`. The calculator BAR is written to:

```text
examples/calculator/build/com.example.bbcalculator.bar
```

The project is mounted into the container, so build outputs remain in its local
`build/` directory. `doctor` checks the builder image, and `shell` opens a shell
inside it with the selected project mounted at `/src`:

```sh
./tools/docker-builder.sh doctor
./tools/docker-builder.sh shell
```

## Build another CMake project

Pass a project directory to use it instead of the calculator. It can be any
local directory accessible to Docker:

```sh
./tools/docker-builder.sh check /path/to/my-bb10-app
./tools/docker-builder.sh compile /path/to/my-bb10-app
./tools/docker-builder.sh build /path/to/my-bb10-app
```

The project must contain a `CMakeLists.txt`. Without a BAR descriptor, `build`
only compiles and links. To make a BAR, add `bar-descriptor.xml` at the project
root, with a valid application ID and an executable entry asset. The descriptor
should refer to the executable at
`build/cmake/arm/o.le-v7-g/<target-name>`; list icons and other assets using
paths relative to the project root. See `examples/calculator/` for a complete
working project.

CMake owns source/object-file tracking and incremental builds. Each application
defines its own source files, target name, include paths, and libraries; the
shared Docker build script does not need per-project edits. For example:

```cmake
cmake_minimum_required(VERSION 3.20)
project(my_app LANGUAGES CXX)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/arm/o.le-v7-g")

include(BB10Qt4)
qt4_wrap_cpp(MOC_SOURCES src/controller.h)

add_executable(my_app src/main.cpp src/controller.cpp ${MOC_SOURCES})
target_link_libraries(my_app PRIVATE bbcascades QtDeclarative QtCore)
```

### Qt classes: moc, rcc, uic

Signals, slots, `Q_PROPERTY` and `Q_INVOKABLE` (everything QML calls into C++)
need moc. The image has Qt 4.8.6's `moc`, `rcc` and `uic`, the Qt version on
BB10 10.3 devices, under `/opt/bb10-qt4/bin`. `include(BB10Qt4)` provides:

- `qt4_wrap_cpp(<var> <header>... [OPTIONS ...])` runs moc on headers that
  declare `Q_OBJECT` classes and adds the generated sources to `<var>`.
- `qt4_add_resources(<var> <qrc>... [OPTIONS ...])` compiles `.qrc` files.

QML files usually ship as plain assets (`asset:///main.qml`) and need neither.

### Other build tools: bb10-cc

`bb10-cc` and `bb10-c++` are gcc-compatible drivers for BB10, and the one place
that holds the compile and link flags. They compile with the image's clang and
link with the armnto GNU ld, adding the QNX loader, startup files, libraries and
runtime helpers. With `QNX_ARCH=x86` they build for the BB10 simulator
instead (see [Targets](#targets)). The CMake toolchain uses them, and so can anything else that
drives `cc`, such as cgo:

```sh
CC=bb10-cc CXX=bb10-c++ CGO_ENABLED=1 GOOS=qnx GOARCH=arm GOARM=7 go build
```

## Targets

The image builds for two systems, BlackBerry 10 and QNX 6.5.0, and system and
architecture are separate choices. BB10 is built on QNX Neutrino, but the two
are different systems with different SDKs.

| | ARM (ARMv7) | x86 |
|---|---|---|
| **BlackBerry 10** | `bb10-arm`, the phones. Provided; programs are tested on a phone. | `bb10-x86`, the BB10 simulator. Provided for building only: nothing built for it has been run, as there is no simulator here. |
| **QNX 6.5.0** | `qnx65-arm`. It exists, but is not provided: QNX's installer for x86 targets has no ARM target libraries. | `qnx65-x86`. Provided; programs are tested on QNX 6.5.0. |

One command per system, and `QNX_ARCH` chooses the architecture for both:

| Command | `QNX_ARCH` | Target | SDK | Runtime pieces |
|---|---|---|---|---|
| `bb10-cc`, `bb10-c++` | unset or `arm` | `bb10-arm` | `/opt/bb10-sdk/target/qnx6`, `armle-v7` | `/opt/bb10-toolchain/lib/bb10-arm` |
| `bb10-cc`, `bb10-c++` | `x86` | `bb10-x86` | `/opt/bb10-sdk/target/qnx6`, `x86` | `/opt/bb10-toolchain/lib/bb10-x86` |
| `qnx65-cc` | unset or `x86` | `qnx65-x86` | `/opt/qnx65-sdk` | from the SDK (gcc 4.4.2's) |
| `qnx65-cc` | `arm` | `qnx65-arm` | | refused, with the reason |

The CMake toolchain file, `bb10-build`, the packager and the Qt tools are for
`bb10-arm` only.

### bb10-x86

```sh
QNX_ARCH=x86 bb10-cc -O2 -o hello hello.c
```

It uses the x86 half of the BB10 SDK, which BlackBerry made for the BB10
simulator, with BB10's rules: the stack protector is on and constructors are in
`.init_array`, as on ARM. compiler-rt supplies what the SDK has no libgcc for.
Three things are assumptions, not measurements, because nothing has been run:
i686 as the processor, a 4-byte stack alignment, and that the x86 loader runs
`.init_array` as the ARM one does. The x86 Qt and Cascades libraries are not in
the image, so it is for C and C++ against the system libraries.

### qnx65-x86: qnx65-cc

```sh
qnx65-cc -O2 -o hello hello.c
qnx65-cc -O2 -fPIC -shared -Wl,-soname,libfoo.so.1 -o libfoo.so.1 foo.c
make CC=qnx65-cc AR=llvm-ar STRIP=llvm-strip
```

`qnx65-cc` is a gcc-compatible C driver for QNX 6.5.0. It builds against QNX
SDP 6.5.0's own headers, libraries and start-up files, with clang and lld; gcc
4.4.2's `crtbegin`/`crtend` and `libgcc`, from the same SDK, run the
constructors and supply the 64-bit arithmetic and the emulated thread-local
storage, as they do for QNX's own compiler. Because a program links against
6.5.0's libraries, a function that 6.5.0 lacks fails at link time.

What the driver sets, and why:

- **`-march=i486`**, no SSE: the default of QNX 6.5.0's own compiler. Pass
  `-march=i686 -msse2 -mfpmath=sse` for a Pentium 4 or later; later flags win.
- **`-fno-stack-protector`**: 6.5.0's libc has no `__stack_chk_fail`.
- **`-femulated-tls`**: the 6.5.0 loader has no thread-local storage segment.
- **`-fno-use-init-array`**: the 6.5.0 loader runs constructors from `.ctors`.
- **`-D_QNX_SOURCE`**: as `bb10-cc` passes it. Under a strict C standard
  (`-std=c11` rather than `gnu11`) QNX's headers hide POSIX without it.
- **`-mstack-alignment=4`**: 6.5.0 only guarantees a 4-byte aligned stack, so
  code that needs more, such as SSE code, realigns it itself.

Only C is supported.

`qnx65-check-names` lists what a program asks the loader for and fails if a
name is outside the libraries or lists given. `bb10-toolchain-doctor` uses it
to confirm what the link already guarantees:

```sh
qnx65-check-names hello libfoo.so.1 /opt/qnx65-sdk/qnx6/x86/lib/libc.so.3
```

### Where the QNX 6.5.0 SDK comes from

The image build downloads QNX's installer of SDP 6.5.0 for Linux hosts from
qnx.com (`qnxsdp-6.5.0-x86-201007091524-linux.bin`, checked against its
SHA-256) and takes 2,605 files from it: the headers
(`qnx6/usr/include`), the x86 libraries and start-up files (`qnx6/x86/lib`,
`qnx6/x86/usr/lib`), and gcc 4.4.2's `crtbegin.o`, `crtend.o` and `libgcc.a`.
`docker/qnx65-sdk.sha256` lists them with their SHA-256, and
`docker/qnx65-sdk-extract` writes exactly those, each checked. The installer is
an archive with nothing encrypted in it; the tool reads it and does not run it,
and no licence key is involved. Nothing of the SDK is in this repository.

QNX SDP 6.5.0 is QNX Software Systems' software under its own licence
agreement; the built image contains those files.

## Install on a phone

**If the phone is rooted with bb10mt, use the phone's own installer.** It is
preferred over the Java `blackberry-deploy` tool: it needs no Development Mode
password, no legacy-TLS workarounds and no Java on the host.
`tools/install-rooted.sh` copies the BAR over SSH and runs the installer script
the phone ships, `sud_install_package_2` from `/base/scripts/sudtools.sh`:

```sh
./tools/install-rooted.sh root@<phone-ip> examples/calculator/build/com.example.bbcalculator.bar
```

The SSH target must reach a root shell on the phone. A BAR installed this way is
an unsigned development package, and runs like any other app.

On a phone that is not rooted, use `blackberry-deploy` from the image. The
phone must be in Development Mode. BB10 only speaks TLS 1.0 with legacy ciphers,
so the image's Java needs its TLS restrictions lifted for that call.

The default package configuration is `Device-Debug`; override it with
`BB10_CONFIGURATION` if the descriptor defines a different configuration:

```sh
BB10_CONFIGURATION=Device-Debug \
  ./tools/docker-builder.sh build /path/to/my-bb10-app
```

## Toolchain and project layout

Clang compiles ARMv7 EABI objects, and GNU Binutils links them using its `armnto`
QNX Neutrino output profile. BB10 10.3.1 provides the target headers, Cascades
and Qt libraries, and CRT objects. The Linux native packager is included in the
image. The resulting native executable targets `/usr/lib/ldqnx.so.2` on the
device; the linker’s `armnto` emulation selects the QNX ARM object format and is
not CPU emulation.

`armv7-none-eabi` is a bare-metal triple, so the image fills what clang does not
assume about QNX:

- **OS macros.** The toolchain file defines `__QNX__`, `__QNXNTO__`, `__unix__`
  and `__unix`, as `qcc` does. Portable libraries pick their POSIX code from
  `__unix__`.
- **Run-time helpers.** Clang calls ARM run-time ABI functions for memory
  copies and 64-bit/floating-point conversions (`__aeabi_memcpy`,
  `__aeabi_memclr`, `__aeabi_d2lz`, `__aeabi_l2d`, ...). BB10's libc only
  exports the integer division ones. The image builds compiler-rt's builtins
  for the BB10 ABI (ARMv7, VFPv3-D16, softfp) and links them after `-lc`, so
  they only supply what libc lacks.
- **ABI check.** `bb10-toolchain-doctor` (also run while building the image)
  builds a probe with the real toolchain file. It checks QNX's ARM ABI sizes
  (4-byte enums and `wchar_t`, 8-byte `long long`/`double` alignment, softfp),
  runs moc on a `Q_OBJECT` class and links every runtime helper against Qt.

- `examples/calculator/` — example source, assets, CMake definition, and BAR descriptor
- `docker/` — shared compiler/linker setup and generic build helpers; the
  QNX 6.5.0 driver, its SDK's extractor and file list, and the name check
- `tools/` — host-side Docker wrapper, project checker and rooted-phone installer
- `Dockerfile` — self-contained builder image definition
- `docker-bake.hcl` — Buildx target for building/tagging the image

Generated build trees, `.bar` packages, extracted SDK payloads, caches, and
local signing credentials are excluded by `.gitignore`.
