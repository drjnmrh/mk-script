#include "ShaderTypes.h"

#include "smile/smile.h"


static_assert(sizeof(Vertex) == sizeof(MetalTexturedVertex));
static_assert(sizeof(GeomInstance) == sizeof(MetalGeomInstance));

static_assert((int)eBufferType_Geometry == (int)eMetalBufferType_Geometry);
static_assert((int)eBufferType_Uniforms == (int)eMetalBufferType_Uniforms);
static_assert((int)eBufferType_Instance == (int)eMetalBufferType_Instance);
