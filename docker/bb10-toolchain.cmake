set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR armv7)

set(CMAKE_C_COMPILER clang)
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_C_COMPILER_TARGET armv7-none-eabi)
set(CMAKE_CXX_COMPILER_TARGET armv7-none-eabi)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(_bb10_target "$ENV{QNX_TARGET}")
if(NOT _bb10_target)
    set(_bb10_target "/opt/bb10-sdk/target/qnx6")
endif()
execute_process(COMMAND clang++ -print-resource-dir
    OUTPUT_VARIABLE _bb10_clang_resource
    OUTPUT_STRIP_TRAILING_WHITESPACE
    COMMAND_ERROR_IS_FATAL ANY)
# armv7-none-eabi is a bare-metal triple, so clang predefines no OS macros.
# Define the ones qcc defines for QNX; portable code keys its POSIX paths off
# __unix__.
set(_bb10_common_flags
    "-O0 -g3 -fPIC -marm -mcpu=cortex-a9 -mfpu=vfpv3-d16 -mfloat-abi=softfp -mno-unaligned-access -Wno-pragma-pack -fno-exceptions -fno-rtti -fstack-protector -nostdinc -D__QNX__ -D__QNXNTO__ -D__unix__ -D__unix -D__ARM__ -D__LITTLEENDIAN__ -D_QNX_SOURCE -DQT_NO_EXCEPTIONS -isystem ${_bb10_clang_resource}/include -isystem /opt/bb10-target-override/usr/include -isystem ${_bb10_target}/usr/include/cpp -isystem ${_bb10_target}/usr/include/cpp/c -isystem ${_bb10_target}/usr/include -isystem ${_bb10_target}/usr/include/qt4 -isystem ${_bb10_target}/usr/include/qt4/QtCore -isystem ${_bb10_target}/usr/include/qt4/QtDeclarative")
set(CMAKE_C_FLAGS_INIT "${_bb10_common_flags}")
set(CMAKE_CXX_FLAGS_INIT "-std=gnu++98 ${_bb10_common_flags}")

set(_bb10_binutils /opt/bb10-toolchain/bin/arm-unknown-nto-qnx6.5.0eabi)
set(CMAKE_AR "${_bb10_binutils}-ar" CACHE FILEPATH "BB10 target archiver")
set(CMAKE_RANLIB "${_bb10_binutils}-ranlib" CACHE FILEPATH "BB10 target ranlib")

set(CMAKE_USER_MAKE_RULES_OVERRIDE_C "/opt/bb10-cmake/BB10LinkRules.cmake")
set(CMAKE_USER_MAKE_RULES_OVERRIDE_CXX "/opt/bb10-cmake/BB10LinkRules.cmake")

# Qt 4.8.6 host tools (moc, rcc, uic) and the qt4_wrap_cpp()/qt4_add_resources()
# helpers: include(BB10Qt4) in a project.
list(APPEND CMAKE_MODULE_PATH /opt/bb10-cmake)
set(QT_MOC_EXECUTABLE /opt/bb10-qt4/bin/moc)
set(QT_RCC_EXECUTABLE /opt/bb10-qt4/bin/rcc)
set(QT_UIC_EXECUTABLE /opt/bb10-qt4/bin/uic)
