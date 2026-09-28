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
add_executable(my_app src/main.cpp src/controller.cpp)
target_link_libraries(my_app PRIVATE bbcascades QtDeclarative QtCore)
```

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

- `examples/calculator/` — example source, assets, CMake definition, and BAR descriptor
- `docker/` — shared compiler/linker setup and generic build helpers
- `tools/` — host-side Docker wrapper and project checker
- `Dockerfile` — self-contained builder image definition
- `docker-bake.hcl` — Buildx target for building/tagging the image

Generated build trees, `.bar` packages, extracted SDK payloads, caches, and
local signing credentials are excluded by `.gitignore`.
