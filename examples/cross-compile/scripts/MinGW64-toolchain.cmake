set(CMAKE_SYSTEM_NAME "Windows")

set(CMAKE_C_COMPILER x86_64-w64-mingw32-gcc)
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++)

set(CMAKE_FIND_ROOT_PATH /usr/x86_64-w64-mingw32 /opt/homebrew/Cellar/mingw-w64/12.0.0)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

set(CMAKE_EXE_LINKER_FLAGS "-static-libgcc -static-libstdc++ -static")

