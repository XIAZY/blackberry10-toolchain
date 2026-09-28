set(_bb10_target "${QNX_TARGET}")
if(NOT _bb10_target)
    set(_bb10_target "/opt/bb10-sdk/target/qnx6")
endif()

set(_bb10_lib "${_bb10_target}/armle-v7/lib")
set(_bb10_usr_lib "${_bb10_target}/armle-v7/usr/lib")
set(_bb10_qt_lib "${_bb10_usr_lib}/qt4/lib")
set(_bb10_ld "/opt/bb10-toolchain/bin/arm-unknown-nto-qnx6.5.0eabi-ld")
set(CMAKE_LINKER "${_bb10_ld}" CACHE FILEPATH "BB10 QNX ARM linker")

set(CMAKE_C_LINK_EXECUTABLE
    "${_bb10_ld} -m armnto --dynamic-linker /usr/lib/ldqnx.so.2 --hash-style=sysv -z noexecstack <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> -o <TARGET> ${_bb10_lib}/crt1.o ${_bb10_lib}/crti.o <OBJECTS> -rpath-link ${_bb10_lib} -rpath-link ${_bb10_usr_lib} -L${_bb10_lib} -L${_bb10_lib}/gcc/4.6.3 -L${_bb10_usr_lib} <LINK_LIBRARIES> -lm -lbps -lc ${_bb10_lib}/crtn.o")

set(CMAKE_CXX_LINK_EXECUTABLE
    "${_bb10_ld} -m armnto --dynamic-linker /usr/lib/ldqnx.so.2 --hash-style=sysv -z noexecstack <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> -o <TARGET> ${_bb10_lib}/crt1.o ${_bb10_lib}/crti.o <OBJECTS> -rpath-link ${_bb10_lib} -rpath-link ${_bb10_usr_lib} -rpath-link ${_bb10_qt_lib} -L${_bb10_lib} -L${_bb10_lib}/gcc/4.6.3 -L${_bb10_usr_lib} -L${_bb10_qt_lib} <LINK_LIBRARIES> -lcpp -lm -lbps -lc ${_bb10_lib}/crtn.o")

set(CMAKE_C_CREATE_SHARED_LIBRARY
    "${_bb10_ld} -m armnto -shared -z noexecstack -o <TARGET> <OBJECTS> -rpath-link ${_bb10_lib} -rpath-link ${_bb10_usr_lib} -L${_bb10_lib} -L${_bb10_usr_lib} <LINK_LIBRARIES>")
set(CMAKE_C_CREATE_SHARED_MODULE "${CMAKE_C_CREATE_SHARED_LIBRARY}")

set(CMAKE_CXX_CREATE_SHARED_LIBRARY
    "${_bb10_ld} -m armnto -shared -z noexecstack -o <TARGET> <OBJECTS> -rpath-link ${_bb10_lib} -rpath-link ${_bb10_usr_lib} -rpath-link ${_bb10_qt_lib} -L${_bb10_lib} -L${_bb10_lib}/gcc/4.6.3 -L${_bb10_usr_lib} -L${_bb10_qt_lib} <LINK_LIBRARIES>")
set(CMAKE_CXX_CREATE_SHARED_MODULE "${CMAKE_CXX_CREATE_SHARED_LIBRARY}")
