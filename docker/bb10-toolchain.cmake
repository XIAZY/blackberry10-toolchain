set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR armv7)

# bb10-cc and bb10-c++ (docker/bb10-cc) hold every BB10 compile and link flag,
# so CMake, cgo and anything else that drives "cc" build the same way.
set(CMAKE_C_COMPILER bb10-cc)
set(CMAKE_CXX_COMPILER bb10-c++)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
set(CMAKE_C_FLAGS_INIT "-O0 -g3")
set(CMAKE_CXX_FLAGS_INIT "-O0 -g3")

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
