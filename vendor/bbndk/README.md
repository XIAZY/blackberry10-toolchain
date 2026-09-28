# Obsolete host SDK staging directory

The Docker build no longer reads this directory. Downloading, checksum
verification, Linux-installer execution, extraction, and pruning now happen in
intermediate stages declared directly in `Dockerfile`. The modern QNX image is
built by Docker Bake from the pinned upstream Git repository.

Any payload remaining beside this file is a legacy local cache and can be
removed without affecting image builds.

## Provenance

The Momentics 2.1.2 Linux installer is only an IDE distribution. Inspection of
its extracted files shows no Cascades target headers, `libbbcascades.so`, QNX
target sysroot, `qcc`, or `blackberry-nativepackager`, so it cannot be used as
this context by itself.

The Docker stages combine:

- Linux host packaging tools from BlackBerry Native SDK 2.1.0.
- The host-independent QNX/Cascades target payload from SDK 10.3.1.995.

Only the target directory is taken from the archive whose filename says
`win32`; no Windows executable, compiler, linker, or packaging tool is copied
or run. Target headers and ARM libraries are not host executables.

The intermediate stages produce:

```text
target_10_3_1_*/qnx6/usr/include/bb/cascades/
target_10_3_1_*/qnx6/armle-v7/usr/lib/libbbcascades.so
host/linux/x86/usr/bin/blackberry-nativepackager
```

Sources pinned by the Dockerfile:

```text
Linux host tools:
https://web.archive.org/web/20220102083348/http://downloads.blackberry.com/upr/developers/downloads/installer-bbndk-2.1.0-linux-1032-201209271809-201209280007.bin
SHA-256 27876f2deab808902998c92062bd26f23564af30478f4908526031589cd6e135

10.3.1.995 target payload:
https://archive.org/download/bbdevtools/bbndk.win32.libraries.10.3.1.995.zip
SHA-256 0b2fd17e62eee6890ca0d470487bc2467ec97432538d04a7a1a299683978a33e
SHA-1 6a48b68b8e891656eb18083b06eb42192e0d8093
MD5 53d09d60a27b4c13edc464b5bd8f72b7
```

No installer or extracted SDK directory is required on the host. All download,
extraction, compilation, linking, and packaging steps execute in Linux
containers.
