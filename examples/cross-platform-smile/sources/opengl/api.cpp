#include "api.hpp"

#include "smile/log.hpp"

#include "errors.hpp"


static constexpr GLuint kPosTexelsVectorIndex = 0;
static constexpr GLuint kInstancePosVectorIndex = 1;


static
Rcode CreateShaderBuffer( ShaderBufferPtr* outbuf, GraphContextPtr
                        , u32 size, BufferType type, char*)
{
    ShaderBufferPtr sbuf = new ShaderBuffer;
    if (!sbuf) {
        return eRcode_MemError;
    }

    sbuf->type = type;
    sbuf->size = size;

    sbuf->contents = new byte[size];
    if (!sbuf->contents) {
        delete sbuf;
        return RC(MemError);
    }

    CALL_GL(RC(InternalError), glGenBuffers, 1, &sbuf->index);

    switch (type) {
        case eBufferType_Geometry:
        case eBufferType_Instance:
        case eBufferType_Uniforms:
        case eBufferType_Unspecified: sbuf->target = GL_ARRAY_BUFFER; break;
        case eBufferType_Indicies: sbuf->target = GL_ELEMENT_ARRAY_BUFFER; break;
        default: SMILE_LOG(Error) << "Unknown buffer type";
                 return RC(InvalidInput);
    }

    if (eBufferType_Instance == type)
        sbuf->usage = GL_DYNAMIC_DRAW;
    else
        sbuf->usage = GL_STATIC_DRAW;

    CALL_GL(RC(InternalError), glBindBuffer, sbuf->target, sbuf->index);

    if (eBufferType_Geometry == type) {
        CALL_GL(RC(InternalError), glEnableVertexAttribArray, kPosTexelsVectorIndex);
        CALL_GL(RC(InternalError), glVertexAttribPointer, kPosTexelsVectorIndex,
                4, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*4, NULL);
    } else if (eBufferType_Instance == type) {
        CALL_GL(RC(InternalError), glEnableVertexAttribArray, kInstancePosVectorIndex);
        CALL_GL(RC(InternalError), glVertexAttribPointer, kInstancePosVectorIndex,
                4, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*4, NULL);
        CALL_GL(RC(InternalError), glVertexAttribDivisor, kInstancePosVectorIndex, 1);

        CALL_GL(RC(InternalError), glBufferData,
                sbuf->target, size, sbuf->contents, sbuf->usage);
    }

    *outbuf = sbuf;

    CALL_GL(RC(InternalError), glBindBuffer, sbuf->target, 0);

    return RC(Ok);
}


static
Rcode ReleaseShaderBuffer(ShaderBufferPtr pbuf) {
    if (!pbuf) {
        return eRcode_InvalidInput;
    }

    glDeleteBuffers(1, &pbuf->index);

    delete[] pbuf->contents;
    delete pbuf;

    return RC(Ok);
}


static
void* GetShaderBufferContent(ShaderBufferPtr pbuf) {
    if (!pbuf) return nullptr;
    return pbuf->contents;
}


static
Rcode CommitShaderBuffer(ShaderBufferPtr pbuf, u32 offset, u32 size) {
    if (!pbuf) {
        return RC(InvalidInput);
    }

    CALL_GL(RC(InternalError), glBindBuffer, pbuf->target, pbuf->index);

    if (pbuf->usage == GL_STATIC_DRAW) {
        if (offset != 0 || pbuf->size != size) {
            // We only modify static data once and with one commit operation.
            SMILE_LOG(Error) << "Wrong commit for the static data";
            return RC(InvalidInput);
        }
        CALL_GL(RC(InternalError), glBufferData,
                pbuf->target, size, pbuf->contents, pbuf->usage);
    } else {
        if (offset + size > size) {
            SMILE_LOG(Error) << "Wrong commit range";
            return RC(InvalidInput);
        }
        CALL_GL(RC(InternalError), glBufferSubData,
                pbuf->target, offset, size, pbuf->contents);
    }

    CALL_GL(RC(InternalError), glBindBuffer, pbuf->target, 0);

    return RC(Ok);
}


static
Rcode SetVertexBuffer(FrameEncoderPtr pframe, ShaderBufferPtr pbuf, u32) {
    if (!pbuf || !pframe) {
        return RC(InvalidInput);
    }

    if (pframe->current != pframe->main) {
        CALL_GL(RC(InternalError), glBindVertexArray, pframe->main);
        pframe->current = pframe->main;
    }

    return eRcode_Ok;
}


static
Rcode DrawIndexedPrimitive(FrameEncoderPtr pframe,
        u32 nbIndices, u32 nbInstances, ShaderBufferPtr pIndiciesBuffer)
{
    if (!pframe || !pIndiciesBuffer)
        return RC(InvalidInput);

    CALL_GL(RC(InternalError), glBindBuffer,
            pIndiciesBuffer->target, pIndiciesBuffer->index);
    CALL_GL(RC(InternalError), glDrawElementsInstanced,
            GL_TRIANGLES, nbIndices, GL_UNSIGNED_SHORT, 0, nbInstances);

    return RC(Ok);
}


template <typename T>
static bool is_power_of_2(T v) noexcept { return v > 0 && (v & (v - 1)) == 0; }


static
Rcode CreateTextureFromImage(TextureDataPtr* out, GraphContextPtr, ImageData* data) {
    if (!out || !data)
        return RC(InvalidInput);

    TextureDataPtr ptex = new TextureData;
    if (!ptex)
        return RC(MemError);

    CALL_GL(RC(InternalError), glGenTextures, 1, &ptex->index);
    CALL_GL(RC(InternalError), glBindTexture, GL_TEXTURE_2D, ptex->index);

    GLint wrap_mode;
    if (!is_power_of_2(data->width) || !is_power_of_2(data->height))
        wrap_mode = GL_CLAMP_TO_EDGE;
    else
        wrap_mode = GL_REPEAT;

    CALL_GL(RC(InternalError), glTexParameteri,
            GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrap_mode);
    CALL_GL(RC(InternalError), glTexParameteri,
            GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrap_mode);

    CALL_GL(RC(InternalError), glTexParameteri,
            GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    CALL_GL(RC(InternalError), glTexParameteri,
            GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    CALL_GL(RC(InternalError), glTexImage2D,
            GL_TEXTURE_2D, 0, GL_RGBA, data->width, data->height,
            0, GL_RGBA, GL_UNSIGNED_BYTE, data->data);

    CALL_GL(RC(InternalError), glBindTexture, GL_TEXTURE_2D, 0);
    *out = ptex;

    return RC(Ok);
}


static
Rcode ReleaseTexture(TextureDataPtr tex) {
    if (!tex) return RC(Already);

    glDeleteTextures(1, &tex->index);

    return RC(Ok);
}


static
Rcode SetTextureSlot(FrameEncoderPtr, TextureDataPtr tex) {
    if (!tex) return RC(InvalidInput);

    CALL_GL(RC(InternalError), glActiveTexture, GL_TEXTURE0);
    CALL_GL(RC(InternalError), glBindTexture, GL_TEXTURE_2D, tex->index);

    return RC(Ok);
}


static
Rcode SetClearColor(FrameEncoderPtr, float R, float G, float B) {
    glClearColor(R, G, B, 1.0f);
    return RC(Ok);
}


void gl_utils::SetGraphicsApi(PlatformApi& api) noexcept {
    api.CreateShaderBuffer     = &CreateShaderBuffer;
    api.ReleaseShaderBuffer    = &ReleaseShaderBuffer;
    api.GetShaderBufferContent = &GetShaderBufferContent;
    api.CommitShaderBuffer     = &CommitShaderBuffer;
    api.SetVertexBuffer        = &SetVertexBuffer;
    api.DrawIndexedPrimitive   = &DrawIndexedPrimitive;
    api.CreateTextureFromImage = &CreateTextureFromImage;
    api.ReleaseTexture         = &ReleaseTexture;
    api.SetTextureSlot         = &SetTextureSlot;
    api.SetClearColor          = &SetClearColor;
}

