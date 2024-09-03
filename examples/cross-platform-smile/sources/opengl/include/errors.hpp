#ifndef OPENGL_ERRORS_HPP_

#include <ostream>

#if defined(PLATFORM_WINDOWS)
#    include <Windows.h>
#endif
#if defined(PLATFORM_ANDROID)
#   include <EGL/egl.h>
#   include <GLES3/gl32.h>
#else
#   include <GL/gl.h>
#endif


namespace gl_utils {


const char* to_string(GLenum err) noexcept;


template < class OStream >
bool dump_gl_errors(OStream& os) noexcept {
    GLenum err = glGetError();
    if (GL_NO_ERROR == err)
        return false;

    do {
        os << "OpenGL error: " << to_string(err) << "\n";
        err = glGetError();
    } while (err != GL_NO_ERROR);

    return true;
}

template < class OStream >
bool dump_gl_errors(OStream&& os) noexcept {
    GLenum err = glGetError();
    if (GL_NO_ERROR == err)
        return false;

    do {
        os << "OpenGL error: " << to_string(err) << "\n";
        err = glGetError();
    } while (err != GL_NO_ERROR);

    return true;
}


}


#define OPENGL_ERRORS_HPP_
#endif
