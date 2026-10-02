# syntax=docker/dockerfile:1.7

ARG BINUTILS_VERSION=2.45
ARG BINUTILS_SHA256=c50c0e7f9cb188980e2cc97e4537626b1672441815587f1eab69d2a1bfbef5d2
# Must match the major version of Debian's clang in the final image.
ARG LLVM_VERSION=19.1.7

FROM debian:trixie-slim AS bbndk-linux-host

# The public Linux NDK is an InstallAnywhere self-extracting shell archive. Its
# payload is platform-independent ZIP/JAR data, so extract that data directly;
# never execute the installer's bundled 32-bit x86 JVM.
RUN apt-get update && \
    apt-get install -y --no-install-recommends unzip && \
    rm -rf /var/lib/apt/lists/*

ADD --checksum=sha256:27876f2deab808902998c92062bd26f23564af30478f4908526031589cd6e135 \
    https://web.archive.org/web/20220102083348id_/http://downloads.blackberry.com/upr/developers/downloads/installer-bbndk-2.1.0-linux-1032-201209271809-201209280007.bin \
    /tmp/bbndk-installer.bin

RUN dd if=/tmp/bbndk-installer.bin of=/tmp/resource.zip \
        bs=32768 skip=2162 count=18399 status=none && \
    truncate -s 602873484 /tmp/resource.zip && \
    echo "d723d49fa3bc8360ee15c78b0d36ff24954a58695ea959c3eedb257cce0dade8  /tmp/resource.zip" | sha256sum -c - && \
    unzip -p /tmp/resource.zip \
        '$IA_PROJECT_DIR$/manifest/linux.host.manifest_zg_ia_sf.jar' \
        > /tmp/linux-host.jar && \
    echo "c0ff039ddad3ce4f5e2d962eec7921afd9669e1f285e5a9cf8d4b61b0358860c  /tmp/linux-host.jar" | sha256sum -c - && \
    unzip -q /tmp/linux-host.jar \
        'host/linux/x86/usr/bin/blackberry-nativepackager' \
        'host/linux/x86/usr/bin/blackberry-deploy' \
        'host/linux/x86/usr/bin/blackberry-signer' \
        'host/linux/x86/usr/bin/blackberry-debugtokenrequest' \
        'host/linux/x86/usr/lib/*.jar' \
        -d /tmp/linux-host && \
    install -d /sdk/host/linux/x86/usr/bin /sdk/host/linux/x86/usr/lib && \
    for tool in \
        blackberry-nativepackager \
        blackberry-deploy \
        blackberry-signer \
        blackberry-debugtokenrequest; do \
        cp "/tmp/linux-host/host/linux/x86/usr/bin/$tool" \
            /sdk/host/linux/x86/usr/bin/; \
    done && \
    cp /tmp/linux-host/host/linux/x86/usr/lib/*.jar \
        /sdk/host/linux/x86/usr/lib/ && \
    chmod +x /sdk/host/linux/x86/usr/bin/* && \
    test -x /sdk/host/linux/x86/usr/bin/blackberry-nativepackager

FROM debian:trixie-slim AS bb10-target

# This archive contains the host-independent BB10 10.3.1 QNX sysroot:
# Cascades/Qt headers, ARM libraries, and the QNX CRT objects.
RUN apt-get update && \
    apt-get install -y --no-install-recommends unzip && \
    rm -rf /var/lib/apt/lists/*

ADD --checksum=sha256:0b2fd17e62eee6890ca0d470487bc2467ec97432538d04a7a1a299683978a33e \
    https://archive.org/download/bbdevtools/bbndk.win32.libraries.10.3.1.995.zip \
    /tmp/bbndk-libraries.zip

RUN mkdir -p /sdk && \
    unzip -q /tmp/bbndk-libraries.zip \
        'target_10_3_1_995/qnx6/usr/include/*' \
        'target_10_3_1_995/qnx6/armle-v7/*' \
        'target_10_3_1_995/target-override/usr/include/*' \
        'target_10_3_1_995/target-override/armle-v7/*' \
        -d /sdk && \
    test -f /sdk/target_10_3_1_995/qnx6/usr/include/bb/cascades/Application && \
    test -f /sdk/target_10_3_1_995/qnx6/armle-v7/lib/crt1.o && \
    test -e /sdk/target_10_3_1_995/qnx6/armle-v7/usr/lib/libbbcascades.so

FROM debian:trixie-slim AS binutils-build

ARG BINUTILS_VERSION
ARG BINUTILS_SHA256

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        xz-utils && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSLo /tmp/binutils.tar.xz \
        "https://ftp.gnu.org/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz" && \
    echo "${BINUTILS_SHA256}  /tmp/binutils.tar.xz" | sha256sum -c - && \
    mkdir -p /tmp/binutils-src /tmp/binutils-build && \
    tar -xJf /tmp/binutils.tar.xz -C /tmp/binutils-src --strip-components=1 && \
    cd /tmp/binutils-build && \
    /tmp/binutils-src/configure \
        --target=arm-unknown-nto-qnx6.5.0eabi \
        --prefix=/opt/bb10-toolchain \
        --disable-nls \
        --disable-werror \
        --disable-gdb \
        --disable-gprofng \
        --disable-sim \
        --without-zstd && \
    make -j"$(nproc)" all-binutils all-gas all-ld && \
    make install-binutils install-gas install-ld && \
    /opt/bb10-toolchain/bin/arm-unknown-nto-qnx6.5.0eabi-ld -V | grep -q armnto

FROM debian:trixie-slim AS qt4-host-tools

# The SDK has Qt 4.8.6 target libraries but no host tools. moc, rcc and uic are
# self-contained (libc, libstdc++, zlib), so take them from Debian's build of
# the same Qt version. Hashes match Debian's signed jessie package index.
ARG TARGETARCH
ADD --checksum=sha256:1cf6b7e3436a2c4d8df82d6021d884d6a73e353e9eec7c0b766d1d495ad01315 \
    https://archive.debian.org/debian/pool/main/q/qt4-x11/libqt4-dev-bin_4.8.6+git64-g5dc8b2b+dfsg-3+deb8u1_arm64.deb \
    /tmp/qt4-arm64.deb
ADD --checksum=sha256:df63aa981b8e3098984f340a97c0557d0290987298c5e48334ff89a311461224 \
    https://archive.debian.org/debian/pool/main/q/qt4-x11/libqt4-dev-bin_4.8.6+git64-g5dc8b2b+dfsg-3+deb8u1_amd64.deb \
    /tmp/qt4-amd64.deb

RUN case "$TARGETARCH" in \
        arm64) triplet=aarch64-linux-gnu ;; \
        amd64) triplet=x86_64-linux-gnu ;; \
        *) echo "no Qt 4 host tools for $TARGETARCH" >&2; exit 1 ;; \
    esac && \
    dpkg-deb -x "/tmp/qt4-$TARGETARCH.deb" /tmp/qt4 && \
    install -d /qt4/bin && \
    for tool in moc rcc uic; do \
        cp "/tmp/qt4/usr/lib/$triplet/qt4/bin/$tool" /qt4/bin/; \
    done && \
    /qt4/bin/moc -v 2>&1 | grep -q "Qt 4.8.6"

FROM debian:trixie-slim AS compiler-rt-build

# BB10's libc exports only the integer division helpers of the ARM run-time
# ABI. Clang also calls __aeabi_memcpy/memset/memclr, the 64-bit/floating-point
# conversions and others, which normally come from libgcc or compiler-rt. Build
# compiler-rt's builtins for the BB10 ABI (ARMv7, VFPv3-D16, softfp, PIC).
ARG LLVM_VERSION
ADD --checksum=sha256:c12b6e764202c615c1a3af9a13d477846878757ae0e29e5f8979215a6958fffc \
    https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/compiler-rt-${LLVM_VERSION}.src.tar.xz \
    /tmp/compiler-rt.tar.xz
ADD --checksum=sha256:11c5a28f90053b0c43d0dec3d0ad579347fc277199c005206b963c19aae514e3 \
    https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/cmake-${LLVM_VERSION}.src.tar.xz \
    /tmp/llvm-cmake.tar.xz
# Only llvm/cmake/modules is used (compiler-rt's standalone build needs it).
ADD --checksum=sha256:96f833c6ad99a3e8e1d9aca5f439b8fd2c7efdcf83b664e0af1c0712c5315910 \
    https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-${LLVM_VERSION}.src.tar.xz \
    /tmp/llvm.tar.xz

RUN apt-get update && \
    apt-get install -y --no-install-recommends clang cmake make xz-utils && \
    rm -rf /var/lib/apt/lists/*

COPY --from=binutils-build /opt/bb10-toolchain/ /opt/bb10-toolchain/

RUN mkdir -p /tmp/src && cd /tmp/src && \
    tar -xJf /tmp/compiler-rt.tar.xz && \
    tar -xJf /tmp/llvm-cmake.tar.xz && mv "cmake-${LLVM_VERSION}.src" cmake && \
    tar -xJf /tmp/llvm.tar.xz "llvm-${LLVM_VERSION}.src/cmake" && mv "llvm-${LLVM_VERSION}.src" llvm && \
    flags="-marm -mcpu=cortex-a9 -mfpu=vfpv3-d16 -mfloat-abi=softfp -fPIC -O2" && \
    cmake -S "compiler-rt-${LLVM_VERSION}.src/lib/builtins" -B /tmp/build \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SYSTEM_NAME=Generic \
        -DCMAKE_SYSTEM_PROCESSOR=arm \
        -DCMAKE_C_COMPILER=clang \
        -DCMAKE_ASM_COMPILER=clang \
        -DCMAKE_C_COMPILER_TARGET=armv7-none-eabi \
        -DCMAKE_ASM_COMPILER_TARGET=armv7-none-eabi \
        -DCMAKE_C_FLAGS="$flags" \
        -DCMAKE_ASM_FLAGS="$flags" \
        -DCMAKE_AR=/opt/bb10-toolchain/bin/arm-unknown-nto-qnx6.5.0eabi-ar \
        -DCMAKE_RANLIB=/opt/bb10-toolchain/bin/arm-unknown-nto-qnx6.5.0eabi-ranlib \
        -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
        -DCOMPILER_RT_BAREMETAL_BUILD=ON \
        -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
        -DCOMPILER_RT_OS_DIR=bb10 \
        -DLLVM_CMAKE_DIR=/tmp/src/llvm/cmake/modules && \
    cmake --build /tmp/build -j"$(nproc)" && \
    install -D -m 644 /tmp/build/lib/bb10/libclang_rt.builtins-armv7.a \
        /out/libclang_rt.builtins-armv7.a && \
    for helper in __aeabi_memcpy __aeabi_memset __aeabi_memclr __aeabi_d2lz __aeabi_l2d; do \
        /opt/bb10-toolchain/bin/arm-unknown-nto-qnx6.5.0eabi-nm /out/libclang_rt.builtins-armv7.a 2>/dev/null | \
            grep -q " T $helper\$" || { echo "missing $helper" >&2; exit 1; }; \
    done

FROM debian:trixie-slim AS bb10-builder

ARG BINUTILS_VERSION
ARG LLVM_VERSION

# Clang is the modern, multi-target compiler frontend. GNU binutils is copied
# from our own QNX-targeted build; no compiler or linker comes from Momentics,
# qcc, the host machine, or a third-party QNX toolchain image.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        clang \
        cmake \
        default-jre-headless \
        make \
        python3 \
        unzip \
        zip && \
    rm -rf /var/lib/apt/lists/*

COPY --from=binutils-build /opt/bb10-toolchain/ /opt/bb10-toolchain/
COPY --from=compiler-rt-build /out/ /opt/bb10-toolchain/lib/
COPY --from=qt4-host-tools /qt4/bin/ /opt/bb10-qt4/bin/
COPY --from=bbndk-linux-host /sdk/ /opt/bbndk/
COPY --from=bb10-target /sdk/ /opt/bbndk/

COPY docker/install-bb10-sdk.sh /usr/local/sbin/install-bb10-sdk
COPY docker/bb10-sdk-tool /usr/local/libexec/bb10-sdk-tool
COPY docker/bb10-build /usr/local/bin/bb10-build
COPY docker/bb10-toolchain-doctor /usr/local/bin/bb10-toolchain-doctor
COPY docker/bb10-toolchain.cmake /opt/bb10-toolchain.cmake
COPY docker/BB10LinkRules.cmake /opt/bb10-cmake/BB10LinkRules.cmake
COPY docker/BB10Qt4.cmake /opt/bb10-cmake/BB10Qt4.cmake
COPY docker/selftest/ /opt/bb10-cmake/selftest/
COPY tools/check-project.py /usr/local/bin/bb10-check-project

ENV BB10_HOST=/opt/bb10-host \
    BB10_TARGET_OVERRIDE=/opt/bb10-target-override \
    QNX_TARGET=/opt/bb10-sdk/target/qnx6 \
    PATH=/opt/bb10-toolchain/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    LD_LIBRARY_PATH=/opt/bb10-host/usr/lib \
    JAVA_TOOL_OPTIONS="-Djava.security.manager=allow --add-exports=java.xml/com.sun.org.apache.xerces.internal.parsers=ALL-UNNAMED"

RUN chmod +x \
        /usr/local/sbin/install-bb10-sdk \
        /usr/local/libexec/bb10-sdk-tool \
        /usr/local/bin/bb10-build \
        /usr/local/bin/bb10-toolchain-doctor \
        /usr/local/bin/bb10-check-project && \
    /usr/local/sbin/install-bb10-sdk && \
    clang --version | grep -q "clang version ${LLVM_VERSION%%.*}\." || \
        { echo "clang is not LLVM ${LLVM_VERSION%%.*}; update LLVM_VERSION" >&2; exit 1; } && \
    bb10-toolchain-doctor --image-build

LABEL org.opencontainers.image.description="Clang and GNU binutils ${BINUTILS_VERSION} BB10 cross-builder"

WORKDIR /src
CMD ["bash"]
