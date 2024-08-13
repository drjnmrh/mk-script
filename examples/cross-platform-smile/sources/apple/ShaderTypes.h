#ifndef SMILE_OSX_SHADERTYPES_H_

#include <simd/simd.h>


typedef struct {
    vector_float2 position;
    vector_float2 texels;
} MetalTexturedVertex;


typedef struct {
    vector_float2 top;
    vector_float2 bot;
} MetalGeomInstance;


typedef struct {
    matrix_float2x2 view;
} MetalSharedUniforms;


typedef enum {
    eMetalBufferType_Geometry = 0
,   eMetalBufferType_Uniforms = 1
,   eMetalBufferType_Instance = 2
} MetalBufferType;

#define MB(Type) eMetalBufferType_ ## Type


#define SMILE_OSX_SHADERTYPES_H_
#endif
