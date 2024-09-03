#include "errors.hpp"


const char* gl_utils::to_string(GLenum err) noexcept {
    switch(err) {
        case GL_INVALID_ENUM: return "Invalid enum value";
        case GL_INVALID_VALUE: return "Invalid value is given";
        case GL_INVALID_OPERATION: return "Invalid operation";
        case GL_STACK_OVERFLOW: return "Stack overflow";
        case GL_STACK_UNDERFLOW: return "Stack underflow";
        case GL_OUT_OF_MEMORY: return "Out of memory";
#if !defined(PLATFORM_WINDOWS)
        case GL_INVALID_FRAMEBUFFER_OPERATION: return "Invalid framebuffer operation";
        case GL_CONTEXT_LOST: return "Context lost";
#endif
#if !defined(PLATFORM_WINDOWS) && !defined(PLATFORM_ANDROID)
        case GL_TABLE_TOO_LARGE: return "Table is too large";
#endif
        default: return "Unknown";
    }
}

