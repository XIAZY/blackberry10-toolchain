# Built by bb10-toolchain-doctor. It must configure, compile and link with the
# image's toolchain file, link rules, Qt 4 tools and runtime helpers.
cmake_minimum_required(VERSION 3.20)
project(bb10_selftest LANGUAGES C CXX)

include(BB10Qt4)
qt4_wrap_cpp(MOC_SOURCES probe.h)

add_executable(bb10-selftest main.cpp abi.c ${MOC_SOURCES})
target_link_libraries(bb10-selftest PRIVATE QtCore)
