#include "smile/smile.h"

#include <assert.h>
#include <stdio.h>

#include <cmath>
#include <cstring>
#include <new>

#include "imageutils.hpp"

#include "smile/log.hpp"


extern "C"
const char* smile_ToString(Rcode rc) {
    switch(rc) {
        case eRcode_Ok            : return "Ok";
        case eRcode_InternalError : return "InternalError";
        case eRcode_InvalidInput  : return "InvalidInput";
        case eRcode_MemError      : return "MemError";
        case eRcode_Already       : return "Already";
        case eRcode_LogicError    : return "LogicError";
        case eRcode_NotInitialized: return "NotInitialized";
        default: return "Unknown";
    }
}


static constexpr f32 kG = 9.81f;
static constexpr f32 kSmileySize = 0.5f;
static constexpr f32 kK = 5000.0f;
static constexpr f32 kFloorY = -0.75f;
static constexpr f32 kFriction = 3.0f;

static const Vertex kQuadVertices[] = {
    { -kSmileySize/2.0f, -kSmileySize/2.0f, 0.0f, 0.0f },
    { -kSmileySize/2.0f, +kSmileySize/2.0f, 0.0f, 1.0f },
    { +kSmileySize/2.0f, +kSmileySize/2.0f, 1.0f, 1.0f },
    { +kSmileySize/2.0f, -kSmileySize/2.0f, 1.0f, 0.0f },
};

static const u16 kQuadIndicies[] = {
    0, 1, 2, 0, 2, 3,
};

static constexpr const char* kSmileyPng = "textures/smiley-face.png";


struct SmileContextData {
    ShaderBufferPtr smiley_vertices{0};
    ShaderBufferPtr smiley_indicies{0};

    ShaderBufferPtr geom_instances{0};

    TextureDataPtr smiley_texture{0};

    GeomInstance smiley_instance;

    f64 smiley_Vt{0.0f};
    f64 smiley_Vb{0.0f};

    f64 smiley_dx{0.0f};

    f32 T_elapsed{0.0f};

    f32 T{0.0f};

    bool ignore_frame{true};
};


extern "C"
Rcode smile_SetUp(SmileContext* pCtx) {
    if (!pCtx) {
        return eRcode_InvalidInput;
    }

    try {
        pCtx->pdata = new SmileContextData();
        if (!pCtx->pdata) {
            return eRcode_MemError;
        }

        pCtx->pdata->smiley_instance.botx = 0.0f;
        pCtx->pdata->smiley_instance.boty = kFloorY;
        pCtx->pdata->smiley_instance.topx = 0.0f;
        pCtx->pdata->smiley_instance.topy = kFloorY;

        pCtx->pdata->smiley_dx = pCtx->pdata->smiley_instance.topy - pCtx->pdata->smiley_instance.boty;

        pCtx->pdata->smiley_Vt = 0.0f;
    } catch (std::bad_alloc&) {
        return eRcode_MemError;
    } catch (...) {
        return eRcode_InternalError;
    }

    pCtx->resources_state = eResourcesState_Unloaded;

    return eRcode_Ok;
}


extern "C"
Rcode smile_TearDown(SmileContext* pCtx) {
    if (!pCtx) {
        return eRcode_InvalidInput;
    }

    if (!pCtx->pdata) {
        return eRcode_Already;
    }

    if (eResourcesState_Unloaded != pCtx->resources_state) {
        smile_UnloadResources(pCtx);
    }

    delete pCtx->pdata;
    pCtx->pdata = nullptr;

    return eRcode_Ok;
}


static bool is_equal(f64 a, f64 b, f64 tol = 1e-5) noexcept {
    return std::abs(a)-std::abs(b) <= tol;
}


static void compute_in_fly(SmileContextData& data, f64 dT) {
    f64 dXdt = data.smiley_Vt - data.smiley_Vb;

    const f64 Vt_0 = data.smiley_Vt;
    const f64 Vb_0 = data.smiley_Vb;

    const f64 At = -(kG + kK * data.smiley_dx + kFriction*dXdt);
    const f64 Ab = -(kG - kK * data.smiley_dx - kFriction*dXdt);

    const f64 Vt = Vt_0 + At * dT;
    const f64 Vb = Vb_0 + Ab * dT;

    f64 Tt1 = dT;
    if (!is_equal(Vt, 0.0) && Vt_0*Vt < 0.0 && !is_equal(At, 0.0)) {
        Tt1 = -Vt_0 / At;
    }
    f64 Tb1 = dT;
    if (!is_equal(Vb, 0.0) && Vb_0*Vb < 0.0 && !is_equal(Ab, 0.0)) {
        Tb1 = -Vb_0 / Ab;
    }

    f64 T[3] = { Tb1, Tt1 - Tb1, dT - Tt1 };
    if (Tt1 < Tb1) {
        T[0] = Tt1;
        T[1] = Tb1 - Tt1;
        T[2] = dT - Tb1;
    }
    if (T[0] < dT) {
        compute_in_fly(data, T[0]);
        if (!is_equal(T[1], 0.0)) {
            compute_in_fly(data, T[1]);
        }
        if (!is_equal(T[2], 0.0)) {
            compute_in_fly(data, T[2]);
        }
        return;
    }

    const f64 Ht = Vt_0 * dT + At * dT * dT / 2.0 + data.smiley_instance.topy;
    const f64 Hb = Vb_0 * dT + Ab * dT * dT / 2.0 + data.smiley_instance.boty;

    const f64 x = Ht - Hb;

    if (Hb < kFloorY) {
        f64 dH = kFloorY - data.smiley_instance.boty;
        f64 t1 = 0.0;

        if (!is_equal(data.smiley_Vb, 0.0)) {
            f64 t1 = (data.smiley_Vb/Ab)*(std::sqrt(1.0 + 2.0*dH*Ab/(data.smiley_Vb*data.smiley_Vb)) - 1.0);
            if (t1 < 0.0) {
                t1 = 0.0;
            }
            assert(t1 < dT);
        } else if (!is_equal(Ab, 0.0)){
            data.smiley_Vb = 0.0;
            f64 t1 = std::sqrt(2*dH/Ab);
            compute_in_fly(data, t1);
        }

        if (t1 > 0.0) {
            compute_in_fly(data, t1);
            assert(is_equal(data.smiley_instance.boty, kFloorY, 0.01));
        }
        data.smiley_Vb = -data.smiley_Vb;
        if (t1 > 0.0) {
            compute_in_fly(data, dT-t1);
        } else {
            data.smiley_dx = x;

            data.smiley_Vt = Vt;
            data.smiley_instance.topy = static_cast<f32>(Ht);
        }

        return;
    }

    data.smiley_dx = x;

    data.smiley_Vt = Vt;
    data.smiley_instance.topy = static_cast<f32>(Ht);

    data.smiley_Vb = Vb;
    data.smiley_instance.boty = static_cast<f32>(Hb);
}


extern "C"
Rcode smile_Update(SmileContext* pCtx, float dT) {
    if (!pCtx) {
        return eRcode_InvalidInput;
    }

    if (!pCtx->pdata) {
        return eRcode_NotInitialized;
    }

    if (eResourcesState_Unloaded == pCtx->resources_state) {
        return eRcode_Ok;
    }

    if (eResourcesState_Loaded == pCtx->resources_state) {
        // Here we should fill our smiley sprite quad with vertices
        void* contents;
        Rcode rc;

        SmileContextData* pdata = pCtx->pdata;

        contents = pCtx->platform_api.GetShaderBufferContent(pdata->smiley_vertices);
        std::memcpy(contents, kQuadVertices, sizeof(kQuadVertices));
        rc = pCtx->platform_api.CommitShaderBuffer(
                pdata->smiley_vertices, 0, sizeof(kQuadVertices));
        if (eRcode_Ok != rc) {
            return rc;
        }

        contents = pCtx->platform_api.GetShaderBufferContent(pdata->smiley_indicies);
        std::memcpy(contents, kQuadIndicies, sizeof(kQuadIndicies));
        rc = pCtx->platform_api.CommitShaderBuffer(
                pdata->smiley_indicies, 0, sizeof(kQuadIndicies));
        if (eRcode_Ok != rc) {
            return rc;
        }

        contents = pCtx->platform_api.GetShaderBufferContent(pdata->geom_instances);
        std::memcpy(contents, &pdata->smiley_instance, sizeof(pdata->smiley_instance));
        rc = pCtx->platform_api.CommitShaderBuffer(
                pdata->geom_instances, 0, sizeof(pdata->smiley_instance));
        if (eRcode_Ok != rc) {
            return rc;
        }

        pCtx->resources_state = eResourcesState_Ready;
        pCtx->pdata->ignore_frame = true;
        return eRcode_Ok;
    }

    SmileContextData& data = *pCtx->pdata;
    if (data.ignore_frame) {
        data.ignore_frame = false;
        return eRcode_Ok;
    }

    data.T_elapsed += dT;

    if (data.T_elapsed >= 1.0f) {
        f64 dt = dT * 0.001;
        for (f64 t0 = 0; t0 < dT; t0 += dt) {
            compute_in_fly(data, dt);
        }
        if (is_equal(data.smiley_instance.boty, kFloorY) &&
            is_equal(data.smiley_Vt, 0.0, 0.01) &&
            is_equal(data.smiley_Vb, 0.0, 0.01))
        {
            data.smiley_Vt = -12.0;
            data.smiley_Vb = 0.0;
        } else {
            const f64 ds = kSmileySize*kSmileySize/(kSmileySize-data.smiley_dx) - kSmileySize;
            data.smiley_instance.botx = ds/2.0;
            data.smiley_instance.topx = -ds/2.0;
        }
    }

    void* contents = pCtx->platform_api.GetShaderBufferContent(data.geom_instances);
    std::memcpy(contents, &data.smiley_instance, sizeof(data.smiley_instance));
    Rcode rc = pCtx->platform_api.CommitShaderBuffer(
            data.geom_instances, 0, sizeof(data.smiley_instance));
    if (eRcode_Ok != rc) {
        return rc;
    }

    return eRcode_Ok;
}


extern "C"
Rcode smile_Render(SmileContext* pCtx, FrameEncoderPtr pEncoder) {
    if (!pCtx) {
        return eRcode_InvalidInput;
    }

    if (!pCtx->pdata) {
        return eRcode_NotInitialized;
    }

    if (eResourcesState_Ready != pCtx->resources_state) {
        return eRcode_Ok;
    }
    SmileContextData& data = *pCtx->pdata;

    Rcode rc;
    
    rc = pCtx->platform_api.SetClearColor(pEncoder, 0.23f, 0.39f, 0.51f);
    if (eRcode_Ok != rc) return rc;

    rc = pCtx->platform_api.SetVertexBuffer(
        pEncoder, data.smiley_vertices, 0);
    if (eRcode_Ok != rc) return rc;

    rc = pCtx->platform_api.SetVertexBuffer(
        pEncoder, data.geom_instances, 0);
    if (eRcode_Ok != rc) return rc;

    rc = pCtx->platform_api.SetTextureSlot(
        pEncoder, data.smiley_texture);
    if (eRcode_Ok != rc) return rc;

    rc = pCtx->platform_api.DrawIndexedPrimitive(
        pEncoder, sizeof(kQuadIndicies)/sizeof(kQuadIndicies[0]),
        1, data.smiley_indicies);
    return rc;
}


struct _RaiiShaderBuffer {
    ShaderBufferPtr ptr{0};
    ShaderBufferPtr* owner{0};
    SmileContext* ctx{0};

    _RaiiShaderBuffer(SmileContext* pCtx, ShaderBufferPtr* pOwner)
        : owner(pOwner), ctx(pCtx)
    {}

    ~_RaiiShaderBuffer() noexcept {
        if (!ptr || !ctx)
            return;
        ctx->platform_api.ReleaseShaderBuffer(ptr);
    }

    void commit() noexcept {
        *owner = ptr;
        ptr = 0;
    }
};


extern "C"
Rcode smile_ReloadResources(SmileContext* pCtx, GraphContextPtr pGraph) {
    if (!pCtx) {
        return eRcode_InvalidInput;
    }

    if (eResourcesState_Unloaded != pCtx->resources_state) {
        return eRcode_Already;
    }

    if (!pCtx->pdata) {
        return eRcode_NotInitialized;
    }

    SmileContextData& data = *pCtx->pdata;

    Rcode rc;

    _RaiiShaderBuffer raiiVertices(pCtx, &data.smiley_vertices);
    _RaiiShaderBuffer raiiIndicies(pCtx, &data.smiley_indicies);
    _RaiiShaderBuffer raiiInstance(pCtx, &data.geom_instances);

    SMILE_LOG(Debug) << "Create vertices shader buffer";
    rc = pCtx->platform_api.CreateShaderBuffer(
            &raiiVertices.ptr, pGraph, sizeof(kQuadVertices), eBufferType_Geometry, 0);
    if (eRcode_Ok != rc) {
        return rc;
    }

    SMILE_LOG(Debug) << "Create indices shader buffer";
    rc = pCtx->platform_api.CreateShaderBuffer(
            &raiiIndicies.ptr, pGraph, sizeof(kQuadIndicies), eBufferType_Indicies, 0);
    if (eRcode_Ok != rc) {
        return rc;
    }

    SMILE_LOG(Debug) << "Create instances shader buffer";
    rc = pCtx->platform_api.CreateShaderBuffer(
            &raiiInstance.ptr, pGraph, sizeof(GeomInstance), eBufferType_Instance, 0);
    if (eRcode_Ok != rc) {
        return rc;
    }

    SMILE_LOG(Debug) << "load smiley texture asset";
    AssetData asset;
    rc = pCtx->platform_api.LoadAsset(
            &asset, const_cast<char*>(kSmileyPng));
    if (eRcode_Ok != rc) {
        return rc;
    }

    SMILE_LOG(Debug) << "load smiley texture png";
    imageutils::Png png;
    rc = png.load(asset);
    pCtx->platform_api.FreeAsset(&asset);
    if (eRcode_Ok != rc) {
        return rc;
    }

    rc = png.convert(imageutils::ColorFormat::R8G8B8A8);
    if (eRcode_Ok != rc) {
        return rc;
    }

    SMILE_LOG(Debug) << "Create texture from image";
    rc = pCtx->platform_api.CreateTextureFromImage(&data.smiley_texture, pGraph, &png.image());
    if (eRcode_Ok != rc) {
        return rc;
    }

    SMILE_LOG(Debug) << "Commit buffers";
    raiiVertices.commit();
    raiiIndicies.commit();
    raiiInstance.commit();

    pCtx->resources_state = eResourcesState_Loaded;

    return eRcode_Ok;
}


extern "C"
Rcode smile_UnloadResources(SmileContext* pCtx) {
    if (!pCtx) {
        return eRcode_InvalidInput;
    }

    if (!pCtx->pdata) {
        return eRcode_NotInitialized;
    }

    if (eResourcesState_Unloaded == pCtx->resources_state) {
        return eRcode_Already;
    }

    SmileContextData& data = *pCtx->pdata;

    pCtx->platform_api.ReleaseShaderBuffer(data.smiley_vertices);
    pCtx->platform_api.ReleaseShaderBuffer(data.smiley_indicies);
    pCtx->platform_api.ReleaseShaderBuffer(data.geom_instances);
    pCtx->platform_api.ReleaseTexture(data.smiley_texture);

    pCtx->resources_state = eResourcesState_Unloaded;

    return eRcode_Ok;
}

