#ifndef NATIVE_LIB_PIXEL_2D_GLSL_H_

#include "smile/smile.h"


namespace shaders {


static constexpr char kVertexShaderCode[] = "#version 300 es\n" TOSTR(

layout (location = 0) in vec4 pos_texels;
layout (location = 1) in vec4 instance_pos;

out vec2 texels_out;

uniform mat2 view;

void main() {
    texels_out = pos_texels.zw;

    vec2 delta = instance_pos.zw * (1.0-texels_out.y) + instance_pos.xy * texels_out.y;
    delta.x = instance_pos.z * (1.0-texels_out.x) + instance_pos.x * texels_out.x;

    vec2 pos = view * (pos_texels.xy + delta);
    gl_Position = vec4(pos, 0.0, 1.0);
}
);


static constexpr char kPixelShaderCode[] = "#version 300 es\n" TOSTR(
precision mediump float;

in vec2 texels_out;

out vec4 fragColor;

uniform sampler2D sprite;

void main() {
    vec4 c = texture(sprite, texels_out);
    fragColor = c;
}
);


}

#define NATIVE_LIB_PIXEL_2D_GLSL_H_
#endif
