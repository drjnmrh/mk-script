#include "shader.hpp"

#include <limits>

#if defined(PLATFORM_WINDOWS)
#    include <Windows.h>
#    undef max
#endif

#if defined(PLATFORM_ANDROID)
#   include <EGL/egl.h>
#else
#   include "GL/glew.h"
#endif

#include "glm/gtc/type_ptr.hpp"

#include "errors.hpp"

#include "smile/log.hpp"


#define CALL_GL(Func, ...) \
    do { \
        Func(__VA_ARGS__); \
        if (dump_gl_errors(SMILE_LOG(Error))) \
            return eRcode_InternalError; \
    } while(0)

static constexpr u32 kInvalidId = std::numeric_limits<u32>::max();

using namespace gl_utils;


Shader::Shader(const std::string& vshader_code, const std::string& pshader_code) noexcept
    : _vcode(vshader_code), _pcode(pshader_code)
    , _vcodes(std::make_unique<const char*[]>(1)), _pcodes(std::make_unique<const char*[]>(1))
    , _program_id(kInvalidId)
{
    _vcodes[0] = _vcode.c_str();
    _pcodes[0] = _pcode.c_str();
}


Shader::~Shader() noexcept {
    if (valid()) {
        glDeleteProgram(_program_id);
    }
}


bool Shader::valid() const noexcept { return _program_id != kInvalidId; }


Rcode Shader::reload() noexcept {
    SMILE_LOG(Debug) << "Create vertex shader";
    GLuint vshader_id = glCreateShader(GL_VERTEX_SHADER);
    if (!vshader_id) {
        dump_gl_errors(SMILE_LOG(Error));
        return eRcode_InternalError;
    }

    SMILE_LOG(Debug) << "Set shader source";
    CALL_GL(glShaderSource, vshader_id, 1, _vcodes.get(), nullptr);

    Rcode rc;
    SMILE_LOG(Debug) << "Compile vertex shader";
    rc = compile(vshader_id);
    if (eRcode_Ok != rc)
        return eRcode_InternalError;

    SMILE_LOG(Debug) << "Create fragment shader";
    GLuint pshader_id = glCreateShader(GL_FRAGMENT_SHADER);
    if (!pshader_id) {
        dump_gl_errors(SMILE_LOG(Error));
        return eRcode_InternalError;
    }

    SMILE_LOG(Debug) << "Set shader source";
    CALL_GL(glShaderSource, pshader_id, 1, _pcodes.get(), nullptr);

    SMILE_LOG(Debug) << "Compile fragment shader";
    rc = compile(pshader_id);
    if (eRcode_Ok != rc)
        return eRcode_InternalError;

    SMILE_LOG(Debug) << "Create program";
    u32 program_id = glCreateProgram();
    if (!program_id) {
        dump_gl_errors(SMILE_LOG(Error));
        return eRcode_InternalError;
    }

    CALL_GL(glAttachShader, program_id, vshader_id);
    CALL_GL(glAttachShader, program_id, pshader_id);

    SMILE_LOG(Debug) << "Link program";
    CALL_GL(glLinkProgram, program_id);

    GLint compile_status;
    CALL_GL(glGetProgramiv, program_id, GL_LINK_STATUS, &compile_status);
    if (GL_FALSE == compile_status) {
        GLchar message[1024];
        glGetProgramInfoLog(program_id, sizeof(message), 0, &message[0]);
        SMILE_LOG(Error) << "Program Link Error:\n" << message << "\n";
        return eRcode_InternalError;
    }

    glDeleteShader(vshader_id);
    glDeleteShader(pshader_id);

    _program_id = program_id;

    return eRcode_Ok;
}


Rcode Shader::use() const noexcept {
    if (!valid())
        return eRcode_NotInitialized;

    CALL_GL(glUseProgram, _program_id);
    return eRcode_Ok;
}


Rcode Shader::setUniform(std::string_view name, const glm::mat2& mat) noexcept {
    u32 loc = getUniformLocation(std::move(name));
    CALL_GL(glUniformMatrix2fv, loc, 1, GL_FALSE, glm::value_ptr(mat));
    return eRcode_Ok;
}


/*static*/
Rcode Shader::compile(u32 shader_id) noexcept {
    glCompileShader(shader_id);

    GLint compile_status;
    CALL_GL(glGetShaderiv, shader_id, GL_COMPILE_STATUS, &compile_status);
    if (GL_FALSE == compile_status) {
        GLchar message[1024];
        glGetShaderInfoLog(shader_id, sizeof(message), 0, &message[0]);
        SMILE_LOG(Error) << "Shader Compile Error:\n" << message;
        return eRcode_InternalError;
    }

    return eRcode_Ok;
}


u32 Shader::getUniformLocation(std::string_view name) noexcept {
    auto foundIt = _locations.find(name);
    if (_locations.end() == foundIt) {
        u32 loc = glGetUniformLocation(_program_id, name.data());
        auto [it, ok] = _locations.insert(std::make_pair(name, loc));
        if (!ok) {
            return 0;
        }
        return loc;
    }
    return foundIt->second;
}

