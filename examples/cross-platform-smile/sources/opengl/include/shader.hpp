#ifndef OPENGL_SHADER_HPP_

#include <memory>
#include <string>
#include <unordered_map>

#include "glm/matrix.hpp"

#include "smile/smile.h"


namespace gl_utils {


class Shader {
public:
    Shader(const std::string& vshader_code, const std::string& pshader_code) noexcept;
   ~Shader() noexcept;

    bool valid() const noexcept;

    Rcode reload() noexcept;
    Rcode use() const noexcept;

    Rcode setUniform(std::string_view name, const glm::mat2& mat) noexcept;

private:
    static Rcode compile(u32 shader_id) noexcept;

    u32 getUniformLocation(std::string_view name) noexcept;

    std::string _vcode, _pcode;
    std::unique_ptr<const char*[]> _vcodes, _pcodes;

    std::unordered_map<std::string_view, u32> _locations;

    u32 _program_id;
};


}


#define OPENGL_SHADER_HPP_
#endif
