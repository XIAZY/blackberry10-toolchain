# Link through bb10-cc/bb10-c++, which add the QNX loader, startup files,
# libraries and runtime helpers. CMake's Generic platform has no shared-library
# rule that passes -shared, so all rules are spelled out.
foreach(lang C CXX)
    set(CMAKE_${lang}_LINK_EXECUTABLE
        "<CMAKE_${lang}_COMPILER> <FLAGS> <CMAKE_${lang}_LINK_FLAGS> <LINK_FLAGS> <OBJECTS> -o <TARGET> <LINK_LIBRARIES>")
    set(CMAKE_${lang}_CREATE_SHARED_LIBRARY
        "<CMAKE_${lang}_COMPILER> -shared <LINK_FLAGS> -o <TARGET> <OBJECTS> <LINK_LIBRARIES>")
    set(CMAKE_${lang}_CREATE_SHARED_MODULE "${CMAKE_${lang}_CREATE_SHARED_LIBRARY}")
endforeach()
