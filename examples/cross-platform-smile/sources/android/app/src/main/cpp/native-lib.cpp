#include <jni.h>

#include <chrono>
#include <memory>
#include <sstream>
#include <string>
#include <string_view>

#include <android/log.h>
#include <android/asset_manager_jni.h>

#include <EGL/egl.h>

#include "smile/smile.h"

#include "api.hpp"
#include "errors.hpp"
#include "shader.hpp"

#include "shaders.glsl.h"


using namespace std::string_view_literals;


#define JNI_FUNCTION_NAME(ReturnType, PackageName, Name) \
    extern "C" JNIEXPORT ReturnType JNICALL Java_ ## PackageName ## _ ## Name

#define JNI(ReturnType, Name) \
    JNI_FUNCTION_NAME(ReturnType, com_stoned_1fox_smile_SmileCore, Name)


#define LOG_FUNC(Fmt, ...) \
    do { \
        char buf[256]; \
        std::snprintf(buf, sizeof(buf)-1, Fmt, __VA_ARGS__); \
        __android_log_print(ANDROID_LOG_DEBUG, kTag, "%s(%s)\n", __func__, buf); \
    } while (0)


#define LOG_RCODE(Rc) \
    do { \
        __android_log_print( ANDROID_LOG_DEBUG, kTag \
                           , "%s: %s\n", __func__, smile_ToString(Rc)); \
    } while (0)


using default_clock_t = std::chrono::high_resolution_clock;


struct GraphContext {
    bool isViewDirty{true};

    std::unique_ptr<gl_utils::Shader> shader_ptr{nullptr};

    int view_width{0};
    int view_height{0};

    glm::mat2 view_matrix{1.0f};

    bool skip_frame{true};
    default_clock_t::time_point last_timepoint{};

    FrameEncoder frame;

    bool context_lost{true};
};


namespace {

static SmileContext sContext;
static GraphContext sGraphCtx;

static constexpr char kTag[] = "Smile";

static JavaVM* sJvm{nullptr};

static jclass sContextWrapperClass{nullptr};
static jobject sContextWrapper{nullptr};

}


static
JNIEnv* acquire_jni_env() {
    JNIEnv* env;
    jint r = sJvm->GetEnv((void**)&env, JNI_VERSION_1_6);
    if (JNI_OK != r) {
        if (JNI_EDETACHED == r) {
            r = sJvm->AttachCurrentThread(&env, nullptr);
        }

        if (JNI_OK != r)
            return nullptr;
    }

    return env;
}


static
Rcode LoadAsset(AssetData* out, char* assetname) {
    if (!assetname || !out)
        return RC(InvalidInput);

    if (!sContextWrapperClass || !sContextWrapper)
        return RC(InternalError);

    JNIEnv* env = acquire_jni_env();
    if (!env) {
        __android_log_print( ANDROID_LOG_ERROR, kTag
                            , "Failed to acquire JNI env\n");
        return RC(InternalError);
    }
    jmethodID method_getAssets = env->GetMethodID( sContextWrapperClass, "getAssets"
                                               , "()Landroid/content/res/AssetManager;");
    if (!method_getAssets) {
        __android_log_print( ANDROID_LOG_ERROR, kTag
                           , "Can't find method '%s%s'\n"
                           , "getAssets", "()Landroid/content/res/AssetManager;");
        return RC(InternalError);
    }
    jobject javaAm = env->CallObjectMethod(sContextWrapper, method_getAssets);
    if (!javaAm) {
        __android_log_print( ANDROID_LOG_ERROR, kTag
                           , "Failed to call getAssets method\n");
        return RC(InternalError);
    }

    AAssetManager* pAssetManager = AAssetManager_fromJava(env, javaAm);
    auto f = AAssetManager_open(pAssetManager, assetname, AASSET_MODE_UNKNOWN);
    if (!f) {
        env->DeleteLocalRef(javaAm);
        __android_log_print( ANDROID_LOG_ERROR, kTag
                           , "Failed to load asset: %s\n"
                           , assetname);
        return RC(InvalidInput);
    }

    out->size = (u32)AAsset_getLength(f);
    out->data = new byte[out->size];
    if (!out->data) {
        AAsset_close(f);
        env->DeleteLocalRef(javaAm);
        __android_log_print( ANDROID_LOG_ERROR, kTag
                           , "Error loading asset '%s': memory error\n"
                           , assetname);
        return RC(MemError);
    }
    AAsset_read(f, out->data, out->size);
    AAsset_close(f);
    env->DeleteLocalRef(javaAm);

    return RC(Ok);
}


static
Rcode FreeAsset(AssetData* data) {
    if (!data || !data->data)
        return RC(Already);

    delete[] data->data;
    data->data = 0;

    return RC(Ok);
}


extern "C" JNIEXPORT
jint JNICALL JNI_OnLoad(JavaVM* vm, void*) {
    sJvm = vm;

    return JNI_VERSION_1_6;
}


extern "C" JNIEXPORT
void JNICALL JNI_OnUnload(JavaVM*, void*) {
    sJvm = nullptr;
}


JNI(void, onSurfaceCreated)(JNIEnv* env, jclass) {
    LOG_FUNC("%s", "void");

    sGraphCtx.context_lost = true;
}


JNI(void, onSurfaceDestroyed)(JNIEnv* env, jclass) {
    LOG_FUNC("%s", "void");

    //sGraphCtx.shader_ptr.reset();
    sGraphCtx.skip_frame = true;

    Rcode rc = smile_UnloadResources(&sContext);
    LOG_RCODE(rc);
}


JNI(void, resizeSurface)(JNIEnv* env, jclass, jint width, jint height) {
    LOG_FUNC("width=%d, height=%d", width, height);

    sGraphCtx.view_width = width;
    sGraphCtx.view_height = height;

    sGraphCtx.isViewDirty = true;
}


JNI(void, setUp)(JNIEnv* env, jclass, jobject ctx) {
    LOG_FUNC("%s", "void");

    jclass cls;
    cls = env->FindClass("android/content/ContextWrapper");
    if (!cls) {
        __android_log_print( ANDROID_LOG_FATAL, kTag
                           , "Can't find class '%s'\n"
                           , "android/content/ContextWrapper");
        return;
    }
    sContextWrapperClass = static_cast<jclass>(env->NewGlobalRef(cls));

    sContextWrapper = env->NewGlobalRef(ctx);

    gl_utils::SetGraphicsApi(sContext.platform_api);
    sContext.platform_api.LoadAsset              = &LoadAsset;
    sContext.platform_api.FreeAsset              = &FreeAsset;

    sGraphCtx.context_lost = true;

    Rcode rc = smile_SetUp(&sContext);
    LOG_RCODE(rc);
}


JNI(void, tearDown)(JNIEnv* env, jclass) {
    LOG_FUNC("%s", "void");

    if (sContextWrapperClass) {
        env->DeleteGlobalRef(sContextWrapperClass);
        sContextWrapperClass = nullptr;
    }

    if (sContextWrapper) {
        env->DeleteGlobalRef(sContextWrapper);
        sContextWrapper = nullptr;
    }

    Rcode rc = smile_TearDown(&sContext);
    LOG_RCODE(rc);
}


JNI(void, onDrawFrame)(JNIEnv* env, jclass) {
    Rcode rc;
    if (sGraphCtx.context_lost) {
        sGraphCtx.context_lost = false;

        sGraphCtx.shader_ptr = std::make_unique<gl_utils::Shader>(
                std::string(shaders::kVertexShaderCode),
                std::string(shaders::kPixelShaderCode));

        __android_log_print(ANDROID_LOG_DEBUG, kTag, "reload shader\n");
        rc = sGraphCtx.shader_ptr->reload();
        if (eRcode_Ok != rc) {
            sGraphCtx.shader_ptr.reset();
            __android_log_print( ANDROID_LOG_ERROR, kTag
                    , "Failed to reload shader: %s"
                    , smile_ToString(rc));
            return;
        }

        __android_log_print(ANDROID_LOG_DEBUG, kTag, "setup VAO\n");
        CALL_GL_VOID(glGenVertexArrays, 1, &sGraphCtx.frame.main);
        CALL_GL_VOID(glBindVertexArray, sGraphCtx.frame.main);
        sGraphCtx.frame.current = sGraphCtx.frame.main;

        __android_log_print(ANDROID_LOG_DEBUG, kTag, "reload resources\n");
        rc = smile_ReloadResources(&sContext, &sGraphCtx);
        LOG_RCODE(rc);

        CALL_GL_VOID(glBindVertexArray, 0);
        sGraphCtx.frame.current = 0;
        return;
    }

    if (!sGraphCtx.shader_ptr) {
        return;
    }

    if (sGraphCtx.skip_frame) {
        sGraphCtx.last_timepoint = default_clock_t::now();
        sGraphCtx.skip_frame = false;
        return;
    }

    CALL_GL(, glBindVertexArray, sGraphCtx.frame.main);
    sGraphCtx.frame.current = sGraphCtx.frame.main;

    default_clock_t::time_point cur_timepoint = default_clock_t::now();
    std::chrono::duration<double> d = cur_timepoint - sGraphCtx.last_timepoint;
    sGraphCtx.last_timepoint = cur_timepoint;
    rc = smile_Update(&sContext, d.count());
    if (eRcode_Ok != rc) {
        __android_log_print( ANDROID_LOG_DEBUG, kTag
                           , "Failed to update: %s"
                           , smile_ToString(rc));
    }

    if (sGraphCtx.isViewDirty) {
        sGraphCtx.view_matrix = {1.0f};

        if (sGraphCtx.view_height > sGraphCtx.view_width) {
            sGraphCtx.view_matrix[1][1] =
                    (float)sGraphCtx.view_width/(float)sGraphCtx.view_height;
        } else {
            sGraphCtx.view_matrix[0][0] =
                    (float)sGraphCtx.view_height/(float)sGraphCtx.view_width;
        }

        sGraphCtx.isViewDirty = false;
    }

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    glClear(GL_COLOR_BUFFER_BIT);

    rc = sGraphCtx.shader_ptr->use();
    if (eRcode_Ok != rc) {
        __android_log_print(ANDROID_LOG_ERROR, kTag
                            , "Failed to use shader: %s\n"
                            , smile_ToString(rc));
        return;
    }

    rc = sGraphCtx.shader_ptr->setUniform("view"sv, sGraphCtx.view_matrix);
    if (eRcode_Ok != rc) {
        __android_log_print( ANDROID_LOG_ERROR, kTag
                           , "Failed to set uniform 'view': %s\n"
                           , smile_ToString(rc));
    }

    rc = smile_Render(&sContext, &sGraphCtx.frame);
    if (eRcode_Ok != rc) {
        __android_log_print( ANDROID_LOG_ERROR, kTag
                           , "Failed to render: %s\n"
                           , smile_ToString(rc));
    }

    CALL_GL(, glBindVertexArray, 0);
    sGraphCtx.frame.current = 0;
}

