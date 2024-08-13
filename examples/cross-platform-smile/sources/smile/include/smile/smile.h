#pragma once
#ifndef SMILE_SMILE_H_

#include <inttypes.h>


#if defined(__cplusplus)
#   define EXTERN_BEGIN extern "C" {
#   define EXTERN_END }
#else
#   define EXTERN_BEGIN
#   define EXTERN_END
#endif

#define TOSTR(Str) #Str

typedef uint8_t byte;
typedef uint32_t u32;
typedef int32_t i32;
typedef uint16_t u16;
typedef float f32;
typedef double f64;

typedef enum {
    eRcode_Ok = 0
,   eRcode_InvalidInput
,   eRcode_InternalError
,   eRcode_MemError
,   eRcode_Already
,   eRcode_LogicError
,   eRcode_NotInitialized
} Rcode;

#define RC(Code) eRcode_ ## Code

typedef struct {
    byte* data;
    u32 size;
} AssetData;

typedef struct {
    byte* data;
    u32 szdata;
    u32 width;
    u32 height;
    u32 szrow;
} ImageData;

struct SmileContextData;
struct GraphContext;
struct FrameEncoder;
struct ShaderBuffer;
struct TextureData;

typedef struct ShaderBuffer* ShaderBufferPtr;
typedef struct GraphContext* GraphContextPtr;
typedef struct FrameEncoder* FrameEncoderPtr;
typedef struct TextureData*  TextureDataPtr;


typedef enum {
    eBufferType_Geometry = 0
,   eBufferType_Uniforms = 1
,   eBufferType_Instance = 2
,   eBufferType_Indicies = 3
,   eBufferType_Unspecified
} BufferType;

// TODO(stoned_fox): Consider Argument buffers (https://developer.apple.com/documentation/metal/buffers/improving_cpu_performance_by_using_argument_buffers?language=objc)
typedef struct {
    Rcode (*CreateShaderBuffer)     (ShaderBufferPtr*, GraphContextPtr, u32, BufferType, char*);
    Rcode (*ReleaseShaderBuffer)    (ShaderBufferPtr);
    void* (*GetShaderBufferContent) (ShaderBufferPtr);
    Rcode (*CommitShaderBuffer)     (ShaderBufferPtr, u32, u32);
    Rcode (*SetVertexBuffer)        (FrameEncoderPtr, ShaderBufferPtr, u32);
    Rcode (*DrawIndexedPrimitive)   (FrameEncoderPtr, u32, u32, ShaderBufferPtr);
    Rcode (*LoadAsset)              (AssetData*, char*);
    Rcode (*FreeAsset)              (AssetData*);
    Rcode (*CreateTextureFromImage) (TextureDataPtr*, GraphContextPtr, ImageData*);
    Rcode (*ReleaseTexture)         (TextureDataPtr);
    Rcode (*SetTextureSlot)         (FrameEncoderPtr, TextureDataPtr);
    Rcode (*SetClearColor)          (FrameEncoderPtr, float, float, float);
} PlatformApi;

typedef struct {
    f32 x;
    f32 y;
    f32 texelx;
    f32 texely;
} Vertex;

typedef struct {
    f32 topx;
    f32 topy;
    f32 botx;
    f32 boty;
} GeomInstance;

typedef enum {
    eResourcesState_Unloaded
,   eResourcesState_Loaded
,   eResourcesState_Ready
} ResourcesState;

typedef struct {
    PlatformApi platform_api;
    struct SmileContextData* pdata;
    ResourcesState resources_state;
} SmileContext;

EXTERN_BEGIN

const char* smile_ToString(Rcode rc);

Rcode smile_SetUp(SmileContext* pCtx);
Rcode smile_TearDown(SmileContext* pCtx);

Rcode smile_Update(SmileContext* pCtx, float dT /*sec*/);
Rcode smile_Render(SmileContext* pCtx, FrameEncoderPtr pEncoder);

Rcode smile_ReloadResources(SmileContext* pCtx, GraphContextPtr pGraph);
Rcode smile_UnloadResources(SmileContext* pCtx);

EXTERN_END


#define SMILE_SMILE_H_
#endif
