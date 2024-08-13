#version 410

in vec2 texels_out;

out vec4 fragColor;

uniform sampler2D sprite;

void main() {
    vec4 c = texture(sprite, texels_out);
    fragColor = c;
}

