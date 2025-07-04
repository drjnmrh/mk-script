define_property(TARGET PROPERTY ATTACHED_ASSETS
    BRIEF_DOCS "Attached assets folder to the target"
    FULL_DOCS "Attached assets folder to the target")

function(set_common_flags inTargetName)
    if (MSVC)
        target_compile_options(${inTargetName} PRIVATE
            -W4 -WX -MD
        )

        target_compile_definitions(${inTargetName} PRIVATE
            _CRT_SECURE_NO_WARNINGS _ITERATOR_DEBUG_LEVEL=0
        )
    else()
        target_compile_options(${inTargetName} PRIVATE
            -Wall -Werror -Wunused-variable -static-libstdc++
        )
    endif()

    if (ENABLE_PROFILER)
        debug_message("Enable Profiler for ${inTargetName}")

        target_compile_definitions(${inTargetName} PRIVATE
            ENABLE_PROFILER
        )
    endif()
endfunction()


function(add_grpc_generated_sources inTargetName inProtoSourcesList)
    if (NOT EXISTS "${_PROTOBUF_PROTOC}")
        find_program(_PROTOBUF_PROTOC protoc
            REQUIRED
            PATHS "${THIRDPARTY_DIR}/${HOST_PREFIX}"
            PATH_SUFFIXES "bin"
            NO_DEFAULT_PATH
        )
        message(STATUS "protoc used is ${_PROTOBUF_PROTOC}")
    endif()

    if (NOT EXISTS "${_GRPC_CPP_PLUGIN_EXECUTABLE}")
        find_program(_GRPC_CPP_PLUGIN_EXECUTABLE grpc_cpp_plugin
            REQUIRED
            PATHS "${THIRDPARTY_DIR}/${HOST_PREFIX}"
            PATH_SUFFIXES "bin"
        )
        message(STATUS "grpc C++ plugin used is ${_GRPC_CPP_PLUGIN_EXECUTABLE}")
    endif()

    set(_grpc_generated_sources "")
    foreach(_proto_source ${inProtoSourcesList})
        get_filename_component(_proto_source_absolute "${_proto_source}" ABSOLUTE)
        get_filename_component(_proto_source_path "${_proto_source_absolute}" PATH)
        get_filename_component(_proto_source_name "${_proto_source}" NAME_WE)

        set(_grpc_generated_source_cc      "${CMAKE_CURRENT_BINARY_DIR}/${_proto_source_name}.pb.cc")
        set(_grpc_generated_source_h       "${CMAKE_CURRENT_BINARY_DIR}/${_proto_source_name}.pb.h")
        set(_grpc_generated_source_grpc_cc "${CMAKE_CURRENT_BINARY_DIR}/${_proto_source_name}.grpc.pb.cc")
        set(_grpc_generated_source_grpc_h  "${CMAKE_CURRENT_BINARY_DIR}/${_proto_source_name}.grpc.pb.h")

        list(APPEND _grpc_generated_sources
            ${_grpc_generated_source_cc}
            ${_grpc_generated_source_h}
            ${_grpc_generated_source_grpc_cc}
            ${_grpc_generated_source_grpc_h})

        add_custom_command(
            OUTPUT "${_grpc_generated_source_cc}" "${_grpc_generated_source_h}" "${_grpc_generated_source_grpc_cc}" "${_grpc_generated_source_grpc_h}"
            COMMAND ${_PROTOBUF_PROTOC}
            ARGS --grpc_out "${CMAKE_CURRENT_BINARY_DIR}"
                 --cpp_out "${CMAKE_CURRENT_BINARY_DIR}"
                 -I "${_proto_source_path}"
                 --plugin=protoc-gen-grpc="${_GRPC_CPP_PLUGIN_EXECUTABLE}"
                 "${_proto_source_absolute}"
            DEPENDS "${_proto_source_absolute}"
        )

        if (NOT TARGET GenerateProtos)
            add_custom_target(GenerateProtos ALL DEPENDS "${_grpc_generated_source_cc}")
        endif()
    endforeach()

    add_library(${inTargetName}-grpc STATIC ${_grpc_generated_sources})

    if (MSVC)
        target_compile_definitions(${inTargetName}-grpc PRIVATE
            _CRT_SECURE_NO_WARNINGS _ITERATOR_DEBUG_LEVEL=0
        )

        target_compile_options(${inTargetName}-grpc PRIVATE
            -MD
        )
    endif()

    target_include_directories(${inTargetName}-grpc PUBLIC ${CMAKE_CURRENT_BINARY_DIR})
    target_link_libraries(${inTargetName}-grpc PUBLIC gRPC::grpc++)

    target_link_libraries(${inTargetName} PRIVATE ${inTargetName}-grpc)

    add_dependencies(${inTargetName}-grpc GenerateProtos)
endfunction()


macro(debug_message inMessage)
    if (${VERBOSE})
        message(STATUS "* ${inMessage}")
    endif()
endmacro()


function(copy_crosscompile_artifacts inTargetName inDestPath)
    # Check if we are in a crosscompile mode
    if (${CMAKE_CROSSCOMPILING})
        set(_filesToCopy "")
        get_target_property(_linkedLibs ${inTargetName} LINK_LIBRARIES)
        if (_linkedLibs)
            debug_message("${inTargetName} LINK_LIBRARIES = ${_linkedLibs}")

            foreach(_lib ${_linkedLibs})
                get_target_property(_libType ${_lib} TYPE)
                if (NOT ${_libType} STREQUAL "SHARED_LIBRARY")
                    debug_message("skipping non-shared ${_lib}")
                    continue()
                endif()

                get_target_property(_isImported ${_lib} IMPORTED)

                if (_isImported)
                    get_target_property(_location ${_lib} IMPORTED_LOCATION)
                else()
                    get_target_property(_location ${_lib} LOCATION)
                endif()

                debug_message("${_lib} LOCATION = ${_location}")
                list(APPEND _filesToCopy "${_location}")
            endforeach()
        endif()

        debug_message("${inTargetName} FILES_TO_COPY = ${_filesToCopy}\n    TO ${inDestPath}")
        add_custom_command(TARGET ${inTargetName} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${inTargetName}> ${inDestPath})
        foreach(_filePath ${_filesToCopy})
            add_custom_command(TARGET ${inTargetName} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy ${_filePath} ${inDestPath})
        endforeach()

        if (MSVC)
            add_custom_command(TARGET ${inTargetName} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_PDB_FILE:${inTargetName}> ${inDestPath})
        endif()

        get_target_property(_attachedAssets ${inTargetName} ATTACHED_ASSETS)
        debug_message("${inTargetName} ATTACHED_ASSETS = ${ATTACHED_ASSETS}")
        if (_attachedAssets)
            add_custom_command(TARGET ${inTargetName} POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy_directory
                ${_attachedAssets} ${inDestPath}/assets)
        endif()
    endif()
endfunction()


# Configures .vimrc and compiles_commands.json to correctly relfect compiling includes
# for the VIM YCM and ALE plugins to work properly.
# Specifies ALE build folder and YCM compile commands folder, uses compdb to add headers
# compile command to the compile_commands.json, patches resulting compile_commands.json
# using special Python 3 script to enable ALE and YCM to recognize special case include
# folders.
# @param inTargetName
#   specify a target to create a dependency on patching scripts.
function(set_vim_ycm_settings inTargetName)
    set(_vimrc_content "")

    if (EXISTS "${CMAKE_SOURCE_DIR}/../.vimrc")
        file(READ "${CMAKE_SOURCE_DIR}/../.vimrc" _vimrc_content)
        debug_message(".vimrc=${_vimrc_content}")

        string(REGEX MATCH
            "([ \t\n]*let g[:]ale_c_build_dir_names[ ]*[=][ ]*[[].*[]][ \t]*[\n]*)"
            _tmp
            "${_vimrc_content}"
        )
        debug_message("_tmp=${_tmp}")

        string(REPLACE "${_tmp}" "" _vimrc_content "${_vimrc_content}")
        debug_message("_vimrc_content=${_vimrc_content}")

        string(REGEX MATCH
            "([ \t\n]*let g[:]ycm_clangd_args=[[].*[]][ \t]*[\n]*)"
            _tmp
            "${_vimrc_content}"
        )

        string(REPLACE "${_tmp}" "" _vimrc_content "${_vimrc_content}")
    endif()

    set(_vimrc_extra_content "
let g:ale_c_build_dir_names = ['${CMAKE_BINARY_DIR}']
let g:ycm_clangd_args = ['--compile-commands-dir=${CMAKE_SOURCE_DIR}']")

    file(WRITE "${CMAKE_SOURCE_DIR}/../.vimrc" "${_vimrc_content} ${_vimrc_extra_content}")

    set(_clangd_config_content "
CompileFlags:
  CompilationDatabase: ${CMAKE_SOURCE_DIR}")

    file(WRITE "${CMAKE_SOURCE_DIR}/../.clangd" "${_clangd_config_content}")

    add_custom_command(
        OUTPUT ${CMAKE_BINARY_DIR}/compile_commands_fixed.json
        COMMAND python3 ${MK_UTILS_DIR}/fix-compile-commands.py ${CMAKE_BINARY_DIR}
        DEPENDS ${CMAKE_BINARY_DIR}/compile_commands.json
    )
    # Add a target to make sure the custom command runs
    add_custom_target(FixCompileCommands ALL
        DEPENDS ${CMAKE_BINARY_DIR}/compile_commands_fixed.json
    )

    add_dependencies(FixCompileCommands UpdateCompileCommands)

    # https://stackoverflow.com/questions/78443870/cmake-automaticaly-update-compilation-database-with-compdb
    add_custom_command(
        OUTPUT ${CMAKE_SOURCE_DIR}/compile_commands.json
        COMMAND compdb -p ${CMAKE_BINARY_DIR} list > ${CMAKE_SOURCE_DIR}/compile_commands.json
        DEPENDS ${CMAKE_BINARY_DIR}/compile_commands_fixed.json
    )

    add_custom_target(UpdateCompileCommands ALL
        DEPENDS ${CMAKE_SOURCE_DIR}/compile_commands.json)

    if (TARGET GenerateProtos)
        add_dependencies(FixCompileCommands GenerateProtos)
    endif()

    add_dependencies(${inTargetName} FixCompileCommands)
endfunction()


function(add_doxygen_generation inConfigFile)
  configure_file(${inConfigFile} ${CMAKE_BINARY_DIR}/Doxyfile @ONLY)

  add_custom_target(DoxygenDocs ALL
    COMMAND doxygen Doxyfile
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    DEPENDS ${CMAKE_BINARY_DIR}/Doxyfile
  )
endfunction()


function(add_poxy_generation inConfigFile)
  configure_file(${inConfigFile} ${CMAKE_BINARY_DIR}/poxy.toml @ONLY)

  if (VERBOSE)
    set(_poxy_verbose_flag "-v ")
  else()
    set(_poxy_verbose_flag "")
  endif()

  add_custom_target(PoxyDocs ALL
    COMMAND poxy ${_poxy_verbose_flag}--html --no-xml poxy.toml
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    DEPENDS ${CMAKE_BINARY_DIR}/poxy.toml
  )
endfunction()


# Adds a CTest target for the given source of the given target.
# @param inTarget
#   a target which source needs to be tested; can be executable, in this case this
#   function will expect ${inTarget}_SOURCES to contain all needed executable sources
#   for compiling tests.
# @param inSourceToTest
#   a path to the source relative to the CMAKE_CURRENT_SOURCE_DIR folder;
#   this function expects that this path contains ${inSourceToTest}_tests.cpp file
#   with C++ main and testing code.
function(add_target_test inTarget inSourceToTest)
    string(REPLACE "/" "-" _execName ${inSourceToTest})

    get_target_property(_targetType ${inTarget} TYPE)
    if (_targetType STREQUAL "EXECUTABLE")
        add_executable(${_execName}_tests
            ${${inTarget}_SOURCES}
            "${CMAKE_CURRENT_SOURCE_DIR}/${inSourceToTest}_tests.cpp"
        )

        get_target_property(_libs ${inTarget} LINK_LIBRARIES)
        target_link_libraries(${_execName}_tests PRIVATE ${_libs})
    else()
        add_executable(${_execName}_tests
            "${CMAKE_CURRENT_SOURCE_DIR}/${inSourceToTest}_tests.cpp"
        )

        target_link_libraries(${_execName}_tests PRIVATE ${inTarget})
    endif()

    target_include_directories(${_execName}_tests
        PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
    )

    set_common_flags(${_execName}_tests)

    add_test(NAME ${_execName}-tests
       COMMAND valgrind
           --leak-check=full
           --show-leak-kinds=all
           --track-origins=yes
           --error-exitcode=1
           $<TARGET_FILE:${_execName}_tests>
    )
endfunction()

