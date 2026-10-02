cmake_minimum_required(VERSION 3.20)
project(bb_calculator LANGUAGES CXX)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/arm/o.le-v7-g")

include(BB10Qt4)
qt4_wrap_cpp(MOC_SOURCES src/calculatorcontroller.h)

add_executable(bb_hello
    src/main.cpp
    src/calculatorcontroller.cpp
    ${MOC_SOURCES}
)

target_include_directories(bb_hello PRIVATE src)

target_link_libraries(bb_hello PRIVATE
    bbcascades
    QtDeclarative
    QtScript
    QtSvg
    QtSql
    sqlite3
    z
    QtXmlPatterns
    QtGui
    QtNetwork
    socket
    QtCore
)
