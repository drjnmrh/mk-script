#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

#import "ShaderTypes.h"


typedef struct {
    float4 position [[position]];
    float2 texels;
} RasterizerData;


vertex RasterizerData
vertex_textured( uint vid [[vertex_id]], uint iid [[instance_id]]
               , constant MetalTexturedVertex* vertices  [[buffer(MB(Geometry))]]
               , constant MetalSharedUniforms& uniforms  [[buffer(MB(Uniforms))]]
               , constant MetalGeomInstance*   instances [[buffer(MB(Instance))]])
{
    constant MetalGeomInstance&   gi = instances[iid];
    constant MetalTexturedVertex& tv = vertices[vid];
    
    RasterizerData out;
    
    vector_float2 delta = gi.bot * (1-tv.texels.y) + gi.top * tv.texels.y;
    delta.x = gi.bot.x * (1-tv.texels.x) + gi.top.x * tv.texels.x;

    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = uniforms.view * (tv.position + delta);
    out.texels = tv.texels;

    return out;
}


fragment float4
fragment_textured( RasterizerData in [[stage_in]]
                 , texture2d<half> tex [[ texture(0) ]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);

    const half4 colorSample = tex.sample(textureSampler, in.texels);

    return float4(colorSample);
}

