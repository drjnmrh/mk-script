set(CMAKE_C_COMPILER /usr/local/gcc-14.1.0/bin/gcc-14.1.0)
set(CMAKE_CXX_COMPILER /usr/local/gcc-14.1.0/bin/g++-14.1.0)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -Wl,-rpath -Wl,/usr/local/gcc-14.1.0/lib64")

