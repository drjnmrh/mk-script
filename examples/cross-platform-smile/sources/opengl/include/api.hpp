#ifndef OPENGL_API_HPP_

#if defined(PLATFORM_WINDOWS)
#   include <Windows.h>
#endif

#if defined(PLATFORM_ANDROID)
#   include <EGL/egl.h>
#   include <GLES3/gl3.h>
#else
#   include "GL/glew.h"
#   include "GLFW/glfw3.h"
#   include <GL/gl.h>
#endif

#include "smile/log.hpp"
#include "smile/smile.h"


#define CALL_GL(ReturnCode, Func, ...) \
    do { \
        Func(__VA_ARGS__); \
        std::stringstream ss; \
        if (gl_utils::dump_gl_errors(ss)) { \
            SMILE_LOG(Error).format( "%s, OpenGL error %s in %s\n" \
                                   , __func__, ss.str().c_str(), #Func); \
            return ReturnCode; \
        }\
    } while(0)


#define CALL_GL_VOID(Func, ...) \
    CALL_GL(, Func, __VA_ARGS__)


struct ShaderBuffer {
    GLuint index;
    BufferType type;
    byte* contents;
    GLenum target;
    GLenum usage;
    u32 size;
};


struct TextureData {
    GLuint index;
};


struct FrameEncoder {
    GLuint current{0};
    GLuint main{1};
};


namespace gl_utils {


void SetGraphicsApi(PlatformApi& api) noexcept;


}

#define OPENGL_API_HPP_
#endif
