# Qt 4 code generation for BB10 projects, named after CMake's FindQt4 macros.
# The tools are Qt 4.8.6, the version on BB10 10.3 devices.
#
#   include(BB10Qt4)
#   qt4_wrap_cpp(MOC_SOURCES src/controller.h)    # headers with Q_OBJECT
#   qt4_add_resources(RCC_SOURCES assets.qrc)     # optional
#   add_executable(app src/main.cpp ${MOC_SOURCES} ${RCC_SOURCES})

foreach(_bb10_qt4_tool MOC RCC UIC)
    if(NOT QT_${_bb10_qt4_tool}_EXECUTABLE)
        string(TOLOWER "${_bb10_qt4_tool}" _bb10_qt4_name)
        set(QT_${_bb10_qt4_tool}_EXECUTABLE "/opt/bb10-qt4/bin/${_bb10_qt4_name}")
    endif()
endforeach()

# qt4_wrap_cpp(<out-var> <header>... [OPTIONS <moc option>...])
# Runs moc on each header and appends the generated moc_<name>.cpp to <out-var>.
function(qt4_wrap_cpp out)
    cmake_parse_arguments(PARSE_ARGV 1 arg "" "" "OPTIONS")
    set(generated)
    foreach(header ${arg_UNPARSED_ARGUMENTS})
        get_filename_component(abs "${header}" ABSOLUTE)
        get_filename_component(name "${header}" NAME_WE)
        set(moc_cpp "${CMAKE_CURRENT_BINARY_DIR}/moc_${name}.cpp")
        add_custom_command(
            OUTPUT "${moc_cpp}"
            COMMAND "${QT_MOC_EXECUTABLE}" ${arg_OPTIONS} -o "${moc_cpp}" "${abs}"
            DEPENDS "${abs}" "${QT_MOC_EXECUTABLE}"
            COMMENT "moc ${header}"
            VERBATIM)
        list(APPEND generated "${moc_cpp}")
    endforeach()
    set(${out} ${${out}} ${generated} PARENT_SCOPE)
endfunction()

# qt4_add_resources(<out-var> <qrc>... [OPTIONS <rcc option>...])
# Compiles each .qrc into qrc_<name>.cpp and appends it to <out-var>. Files
# listed in the .qrc are not tracked as dependencies; touch the .qrc after
# changing them.
function(qt4_add_resources out)
    cmake_parse_arguments(PARSE_ARGV 1 arg "" "" "OPTIONS")
    set(generated)
    foreach(qrc ${arg_UNPARSED_ARGUMENTS})
        get_filename_component(abs "${qrc}" ABSOLUTE)
        get_filename_component(name "${qrc}" NAME_WE)
        set(qrc_cpp "${CMAKE_CURRENT_BINARY_DIR}/qrc_${name}.cpp")
        add_custom_command(
            OUTPUT "${qrc_cpp}"
            COMMAND "${QT_RCC_EXECUTABLE}" ${arg_OPTIONS} -name "${name}" -o "${qrc_cpp}" "${abs}"
            DEPENDS "${abs}" "${QT_RCC_EXECUTABLE}"
            COMMENT "rcc ${qrc}"
            VERBATIM)
        list(APPEND generated "${qrc_cpp}")
    endforeach()
    set(${out} ${${out}} ${generated} PARENT_SCOPE)
endfunction()
