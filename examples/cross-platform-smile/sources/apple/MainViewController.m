#if defined(PLATFORM_MACOSX)
@import AppKit;
#else
@import UIKit;
#endif

@import MetalKit;
@import simd;

#include <time.h>

#include "smile/smile.h"

#include "ShaderTypes.h"


@interface BufferInfo : NSObject
{
    @public id<MTLBuffer> buffer;
    @public BufferType type;
}
@end
@implementation BufferInfo
@end

struct FrameEncoder {
    void* encoder;
    void* view;
};

@interface FrameInfo : NSObject
{
    @public id<MTLRenderCommandEncoder> encoder;
    @public MTKView* view;
}
@end
@implementation FrameInfo
@end


static Rcode
CreateShaderBuffer( ShaderBufferPtr* outBuffer
                  , GraphContextPtr grCtx
                  , u32 szBuffer, BufferType type, char* label)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)grCtx;

#if defined(PLATFORM_MACOSX)
    id<MTLBuffer> buffer = [device newBufferWithLength:szBuffer
                                               options:MTLResourceStorageModeManaged];
#else
    id<MTLBuffer> buffer = [device newBufferWithLength:szBuffer
                                               options:MTLResourceStorageModeShared];
#endif
    if (label != 0) {
        [buffer setLabel:[NSString stringWithUTF8String: label]];
    }

    BufferInfo* pinfo = [[BufferInfo alloc] init];
    if (!pinfo) {
        return eRcode_MemError;
    }

    pinfo->buffer = buffer;
    pinfo->type = type;

    *outBuffer = (ShaderBufferPtr)CFBridgingRetain(pinfo);

    return eRcode_Ok;
}


static Rcode
ReleaseShaderBuffer(ShaderBufferPtr pBuffer)
{
    BufferInfo* b = (BufferInfo*)CFBridgingRelease(pBuffer);
    b->buffer = nil;
    b = nil;

    return eRcode_Ok;
}


static void*
GetShaderBufferContent(ShaderBufferPtr pBuffer)
{
    BufferInfo* info = (__bridge BufferInfo*)pBuffer;
    return (void*)[info->buffer contents];
}


static Rcode
CommitShaderBuffer(ShaderBufferPtr pBuffer, u32 offset, u32 size)
{
#if defined(PLATFORM_MACOSX)
    id<MTLBuffer> b = ((__bridge BufferInfo*)pBuffer)->buffer;
    NSRange range;
    range.location = offset;
    range.length = size;
    [b didModifyRange:range];
#endif

    return eRcode_Ok;
}


static Rcode
SetVertexBuffer(FrameEncoderPtr pEncoder, ShaderBufferPtr pBuffer, u32 offset)
{
    id<MTLRenderCommandEncoder> encoder = (__bridge id<MTLRenderCommandEncoder>)pEncoder->encoder;
    BufferInfo* info = (__bridge BufferInfo*)pBuffer;

    [encoder setVertexBuffer:info->buffer offset:offset atIndex:(int)info->type];

    return eRcode_Ok;
}


static Rcode
DrawIndexedPrimitive( FrameEncoderPtr pEncoder
                    , u32 nbIndices, u32 nbInstances
                    , ShaderBufferPtr pIndexBuffer)
{
    id<MTLRenderCommandEncoder> encoder = (__bridge id<MTLRenderCommandEncoder>)pEncoder->encoder;
    BufferInfo* info = (__bridge BufferInfo*)pIndexBuffer;
    if (info->type != eBufferType_Indicies) {
        return eRcode_InvalidInput;
    }

    [encoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                        indexCount:nbIndices
                         indexType:MTLIndexTypeUInt16
                       indexBuffer:info->buffer
                 indexBufferOffset:0
                     instanceCount:nbInstances];

    return eRcode_Ok;
}


static Rcode
LoadAsset(AssetData* outData, char* assetPath)
{
    NSBundle* mainBundle = [NSBundle mainBundle];
    NSString* bundlePath = [mainBundle resourcePath];
    NSString* assetsPath = [bundlePath stringByAppendingPathComponent:@"assets"];
    char s[512];
    snprintf(s, 512, "%s/%s", assetsPath.UTF8String, assetPath);

    FILE* f = fopen(s, "rb");
    if (!f) {
        return eRcode_InvalidInput;
    }

    fseek(f, 0L, SEEK_END);
    u32 sz = (u32)ftell(f);
    fseek(f, 0L, SEEK_SET);

    outData->size = sz;
    outData->data = malloc(sz);
    if (!outData->data) {
        fclose(f);
        return eRcode_MemError;
    }

    fread(outData->data, 1, sz, f);

    fclose(f);

    return eRcode_Ok;
}


static Rcode
FreeAsset(AssetData* data)
{
    if (!data) {
        return eRcode_InvalidInput;
    }

    if (!data->data) {
        return eRcode_Already;
    }

    free(data->data);
    data->data = 0;

    return eRcode_Ok;
}


static Rcode
CreateTextureFromImage( TextureDataPtr* outTexture
                      , GraphContextPtr grCtx
                      , ImageData* pImageData)
{
    id<MTLDevice> device = (__bridge id<MTLDevice>)grCtx;

    MTLTextureDescriptor* textureDesc = [[MTLTextureDescriptor alloc] init];
    textureDesc.pixelFormat = MTLPixelFormatRGBA8Unorm;
    textureDesc.width = pImageData->width;
    textureDesc.height = pImageData->height;

    id<MTLTexture> texture = [device newTextureWithDescriptor:textureDesc];

    NSUInteger bytesPerRow = 4 * pImageData->width;

    MTLRegion region = {
        { 0, 0, 0 },
        { pImageData->width, pImageData->height, 1 }
    };

    [texture replaceRegion:region
               mipmapLevel:0
                 withBytes:pImageData->data
               bytesPerRow:bytesPerRow];

    *outTexture = (TextureDataPtr)CFBridgingRetain(texture);

    return eRcode_Ok;
}


static Rcode
ReleaseTexture(TextureDataPtr texture)
{
    id<MTLTexture> b = (id<MTLTexture>)CFBridgingRelease(texture);
    b = nil;

    return eRcode_Ok;
}


static Rcode
SetTextureSlot(FrameEncoderPtr pEncoder, TextureDataPtr pTexture)
{
    id<MTLRenderCommandEncoder> encoder = (__bridge id<MTLRenderCommandEncoder>)pEncoder->encoder;
    id<MTLTexture> texture = (__bridge id<MTLTexture>)pTexture;

    [encoder setFragmentTexture:texture atIndex:0];

    return eRcode_Ok;
}


static Rcode
SetClearColor(FrameEncoderPtr pEncoder, float R, float G, float B)
{
    MTKView* view = (__bridge MTKView*)pEncoder->view;
    view.clearColor = MTLClearColorMake(R, G, B, 1.0);
    
    return eRcode_Ok;
}


@interface MetalViewDelegate : NSObject<MTKViewDelegate>

- (nonnull instancetype)init;

- (BOOL)setUp:(nonnull MTKView *)mtkView;
- (void)tearDown;
- (BOOL)reloadResources;
- (BOOL)unloadResources;
- (void)pauseUpdate;
- (void)unpauseUpdate;

@end

@implementation MetalViewDelegate
{
    id<MTLDevice> _device;

    id<MTLRenderPipelineState> _pipeline;
    id<MTLCommandQueue> _commands;

    id<MTLBuffer> _uniforms;

    vector_uint2 _viewSize;

    SmileContext _smileCtx;

    struct timespec _lastFrameTime;

    BOOL _isViewMatrixDirty;
    int _pauseState; // 0 - unpaused, 1 - paused, 2 - getting of the pause
}

- (nonnull instancetype)init
{
    self = [super init];
    return self;
}

- (BOOL)setUp:(MTKView *)mtkView
{
    mtkView.paused = NO;
    mtkView.enableSetNeedsDisplay = NO;

    _pauseState = 0;

    mtkView.device = MTLCreateSystemDefaultDevice();
    if (mtkView.device == nil) {
        NSLog(@"Metal - Failed to create system default device!");
        return NO;
    }
    _device = mtkView.device;

    id<MTLLibrary> library = [_device newDefaultLibrary];

    id<MTLFunction> projector = [library newFunctionWithName:@"vertex_textured"];
    id<MTLFunction> shader    = [library newFunctionWithName:@"fragment_textured"];

    MTLRenderPipelineDescriptor* pipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDesc.label = @"Textured2DVertexPipeline";
#if defined(MAC_OS_X_VERSION_MIN_REQUIRED) && MAC_OS_X_VERSION_MIN_REQUIRED >= 101300
    pipelineDesc.rasterSampleCount = mtkView.sampleCount;
#else
    pipelineDesc.sampleCount = mtkView.sampleCount;
#endif
    pipelineDesc.vertexFunction = projector;
    pipelineDesc.fragmentFunction = shader;
    pipelineDesc.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
    pipelineDesc.colorAttachments[0].blendingEnabled = YES;
    pipelineDesc.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    pipelineDesc.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    pipelineDesc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineDesc.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    pipelineDesc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    pipelineDesc.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

    NSError* error = NULL;
    _pipeline = [_device newRenderPipelineStateWithDescriptor:pipelineDesc error:&error];
    if (!_pipeline) {
        NSLog(@"Metal - Failed to create pipeline state, error %@", error);
        return NO;
    }

    _commands = [_device newCommandQueue];

    mtkView.delegate = self;

    _smileCtx.platform_api.CreateShaderBuffer = &CreateShaderBuffer;
    _smileCtx.platform_api.ReleaseShaderBuffer = &ReleaseShaderBuffer;
    _smileCtx.platform_api.GetShaderBufferContent = &GetShaderBufferContent;
    _smileCtx.platform_api.CommitShaderBuffer = &CommitShaderBuffer;
    _smileCtx.platform_api.SetVertexBuffer = &SetVertexBuffer;
    _smileCtx.platform_api.DrawIndexedPrimitive = &DrawIndexedPrimitive;
    _smileCtx.platform_api.LoadAsset = &LoadAsset;
    _smileCtx.platform_api.FreeAsset = &FreeAsset;
    _smileCtx.platform_api.CreateTextureFromImage = &CreateTextureFromImage;
    _smileCtx.platform_api.ReleaseTexture = &ReleaseTexture;
    _smileCtx.platform_api.SetTextureSlot = &SetTextureSlot;
    _smileCtx.platform_api.SetClearColor = &SetClearColor;

    Rcode rc = smile_SetUp(&_smileCtx);
    if (rc != eRcode_Ok) {
        NSLog(@"Failed to set up the core lib");
        return NO;
    }

    _isViewMatrixDirty = YES;

    [self mtkView:mtkView drawableSizeWillChange:mtkView.drawableSize];

    return YES;
}

- (void)tearDown
{
    _commands = nil;
    _pipeline = nil;
    _device = nil;
}

- (BOOL)reloadResources
{
    NSLog(@"Reload Resources");

    _isViewMatrixDirty = YES;

#if defined(PLATFORM_MACOSX)
    _uniforms = [_device newBufferWithLength:sizeof(MetalSharedUniforms)
                                     options:MTLResourceStorageModeManaged];
#else
    _uniforms = [_device newBufferWithLength:sizeof(MetalSharedUniforms)
                                     options:MTLResourceStorageModeShared];
#endif
    [_uniforms setLabel:@"Uniforms Buffer"];

    Rcode rc = smile_ReloadResources(&_smileCtx, (__bridge GraphContextPtr)_device);
    if (rc != eRcode_Ok) {
        NSLog(@"Failed to reload resources %d", (int)rc);
        return NO;
    }
    return YES;
}

- (BOOL)unloadResources
{
    NSLog(@"Unload Resources");

    Rcode rc = smile_UnloadResources(&_smileCtx);
    if (rc != eRcode_Ok) {
        NSLog(@"Failed to unload resources %d", (int)rc);
    }

    _uniforms = nil;

    return YES;
}

- (void)pauseUpdate
{
    NSLog(@"Pause Update");

    _pauseState = 1;
}

- (void)unpauseUpdate
{
    NSLog(@"Unpause Update");

    _pauseState = 2;
}

- (BOOL)updateViewMatrix
{
    if (eResourcesState_Unloaded == _smileCtx.resources_state) {
        return NO;
    }

    if (_isViewMatrixDirty == YES) {
        simd_float2 e0 = { 1.0, 0.0 };
        simd_float2 e1 = { 0.0, 1.0 };

        if (_viewSize.x > _viewSize.y) {
            e0.x = (float)_viewSize.y / (float)_viewSize.x;
        } else {
            e1.y = (float)_viewSize.x / (float)_viewSize.y;
        }

        matrix_float2x2 view = { e0, e1 };
        memcpy([_uniforms contents], &view, sizeof(view));

#if defined(PLATFORM_MACOSX)
        NSRange range;
        range.length = sizeof(view);
        range.location = 0;
        [_uniforms didModifyRange:range];
#endif

        _isViewMatrixDirty = NO;
    }
}

- (BOOL)updateFrame:(float)dT
{
    Rcode rc = smile_Update(&_smileCtx, dT);
    if (rc != eRcode_Ok) {
        NSLog(@"Failed to update frame %d", (int)rc);
        return NO;
    }
    return YES;
}

- (BOOL)renderFrame:(nonnull id<MTLRenderCommandEncoder>)commandEncoder mtkView:(MTKView*)mtkView
{
    if (eResourcesState_Ready != _smileCtx.resources_state) {
        return YES;
    }

    [commandEncoder setRenderPipelineState:_pipeline];

    [commandEncoder setVertexBuffer:_uniforms
                             offset:0
                            atIndex:1];
    
    struct FrameEncoder encoder;
    encoder.encoder = (__bridge void*)commandEncoder;
    encoder.view = (__bridge void*)mtkView;

    smile_Render(&_smileCtx, &encoder);

    return YES;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    NSLog(@"View size change");
    _viewSize.x = size.width;
    _viewSize.y = size.height;

    _isViewMatrixDirty = TRUE;
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    [self updateViewMatrix];

    struct timespec timePoint;
    clock_gettime(CLOCK_REALTIME, &timePoint);
    double dT = (timePoint.tv_sec - _lastFrameTime.tv_sec) +
                (timePoint.tv_nsec - _lastFrameTime.tv_nsec) / 1000000000.0;

    if (_pauseState == 0) {
        [self updateFrame:(float)dT];
    } else if (_pauseState == 2) {
        _pauseState = 0;
    }
    _lastFrameTime = timePoint;

    @autoreleasepool {
        id<MTLCommandBuffer> cmdbuffer = [_commands commandBuffer];
        [cmdbuffer setLabel:@"CommandBuffer"];

        MTLRenderPassDescriptor* renderPassDesc = view.currentRenderPassDescriptor;
        if (renderPassDesc != nil) {
            id<MTLRenderCommandEncoder> commandEncoder =
                [cmdbuffer renderCommandEncoderWithDescriptor:renderPassDesc];

            [self renderFrame:commandEncoder mtkView:view];

            [commandEncoder endEncoding];

            [cmdbuffer presentDrawable:view.currentDrawable];
        }

        [cmdbuffer commit];
    }
}

@end

#if defined(PLATFORM_MACOSX)
@interface MainViewController : NSViewController
#else
@interface MainViewController : UIViewController
#endif
@end

@interface MainViewController()
- (void)onAppTerminate;
#if !defined(PLATFORM_MACOSX)
- (void)onOrientationDidChange;
#endif
@end


@implementation MainViewController
{
    MetalViewDelegate* _viewDelegate;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    MetalViewDelegate* viewDelegate = [[MetalViewDelegate alloc] init];
    BOOL ok = [viewDelegate setUp:(MTKView*)self.view];
    if (ok != YES) {
        NSLog(@"Failed to load metal render!");
        return;
    }

    _viewDelegate = viewDelegate;

    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(onAppTerminate)
#if defined(PLATFORM_MACOSX)
                                               name:NSApplicationWillTerminateNotification
#else
                                               name:UIApplicationWillTerminateNotification
#endif
                                             object:nil];
#if !defined(PLATFORM_MACOSX)
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(onOrientationDidChange)
                                               name:UIDeviceOrientationDidChangeNotification
                                             object:nil];
#endif
}

#if defined(PLATFORM_MACOSX)
- (void)viewWillAppear
{
    [super viewWillAppear];
#else
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
#endif

    [_viewDelegate reloadResources];
}

#if defined(PLATFORM_MACOSX)
- (void)viewWillDisappear
{
    [super viewWillDisappear];
#else
- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
#endif

    [_viewDelegate unloadResources];
}

#if !defined(PLATFORM_MACOSX)
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size
          withTransitionCoordinator:coordinator];

    [_viewDelegate pauseUpdate];
}

- (void)onOrientationDidChange
{
    [_viewDelegate unpauseUpdate];
}
#endif

- (void)onAppTerminate
{
    [_viewDelegate tearDown];
}

@end

