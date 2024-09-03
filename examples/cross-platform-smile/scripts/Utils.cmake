function(debug_message inMessage)
    if (${VERBOSE})
        message(STATUS "* ${inMessage}")
    endif()
endfunction()

function(set_vim_ycm_settings inTargetName)
    if (EXISTS "${CMAKE_SOURCE_DIR}/../.vimrc")
        file(READ "${CMAKE_SOURCE_DIR}/../.vimrc" _vimrc_content)
        debug_message(".vimrc=${_vimrc_content}")
        string(REGEX MATCH "([ \t\n]*let g[:]ale_c_build_dir_names[ ]*[=][ ]*[[].*[]][ \t]*[\n]*)" _tmp "${_vimrc_content}")
        debug_message("_tmp=${_tmp}")
        string(REPLACE "${_tmp}" "" _vimrc_content "${_vimrc_content}")
        debug_message("_vimrc_content=${_vimrc_content}")

        string(REGEX MATCH "([ \t\n]*let g[:]ycm_clangd_args=[[].*[]][ \t]*[\n]*)" _tmp "${_vimrc_content}")
        string(REPLACE "${_tmp}" "" _vimrc_content "${_vimrc_content}")
    endif()

    set(_vimrc_extra_content "
let g:ale_c_build_dir_names = ['${CMAKE_BINARY_DIR}']
let g:ycm_clangd_args = ['--compile-commands-dir=${CMAKE_BINARY_DIR}']")

    file(WRITE "${CMAKE_SOURCE_DIR}/../.vimrc" "${_vimrc_content} ${_vimrc_extra_content}")
endfunction()

