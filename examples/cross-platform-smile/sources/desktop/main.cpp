#include <chrono>
#include <string_view>
#include <iostream>

#if defined(PLATFORM_WINDOWS)
#    include <Windows.h>
#endif

#include "api.hpp"
#include "shader.hpp"
#include "errors.hpp"

#include "smile/smile.h"

using namespace std::string_view_literals;


static
Rcode LoadAsset(AssetData* out, char* assetname) {
    if (!assetname || !out)
        return eRcode_InvalidInput;

    std::string assetpath = std::string("assets/") + std::string(assetname);

    FILE* f = fopen(assetpath.c_str(), "rb");
    if (!f) {
        std::cerr << "Failed to load asset: " << assetpath << std::endl;
        return eRcode_InvalidInput;
    }

    fseek(f, 0L, SEEK_END);
    u32 sz = (u32)ftell(f);
    fseek(f, 0L, SEEK_SET);

    out->size = sz;
    out->data = (byte*)malloc(sz);
    if (!out->data) {
        fclose(f);
        return eRcode_MemError;
    }

    size_t nb = fread(out->data, 1, sz, f);
    if (nb != sz) {
        std::cerr << "WARNING: read wrong number of bytes from " << assetname << std::endl;
    }

    fclose(f);

    return eRcode_Ok;
}

static
Rcode FreeAsset(AssetData* data) {
    if (!data || !data->data)
        return eRcode_Already;

    free(data->data);
    data->data = 0;

    return eRcode_Ok;
}


int main() {
    std::cout << "Smile App Launched" << std::endl;

    if (!glfwInit()) {
        std::cerr << "Failed to init GLFW!" << std::endl;
        return 1;
    }

    int glfwver[3];
    glfwGetVersion(glfwver, glfwver+1, glfwver+2);
    std::cout << "GLFW v" << glfwver[0] << "." << glfwver[1] << "." << glfwver[2] << std::endl;

    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 1);
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE);

    int count;
    GLFWmonitor** monitors = glfwGetMonitors(&count);
    for (int i = 0; i < count; ++i) {
        const char* name = glfwGetMonitorName(monitors[i]);
        std::cout << "monitor[" << i << "] name: " << name << std::endl;
    }
    GLFWwindow* pwnd = glfwCreateWindow(600, 800, "Smile", nullptr, nullptr);
    if (!pwnd) {
        const char* buffer;
        glfwGetError(&buffer);
        std::cerr << "Failed to create window: " << buffer << std::endl;
        return 1;
    }

    glfwMakeContextCurrent(pwnd);

    glewExperimental = GL_TRUE;
    GLenum glewError = glewInit();
    if (glewError != GLEW_OK) {
        std::cout << "Failed to initialize GLEW: " << glewGetErrorString(glewError) << std::endl;
        return 1;
    }
    std::cout << "GLEW v" << glewGetString(GLEW_VERSION) << std::endl;

    static const char* kVertexShader = "shaders/vshader-2d.glsl";
    static const char* kPixelShader = "shaders/pshader-2d.glsl";

    AssetData vshader_asset;
    Rcode rc = LoadAsset(&vshader_asset, const_cast<char*>(kVertexShader));
    if (eRcode_Ok != rc) {
        std::cerr << "Failed to load asset shaders/vshader-2d.glsl: " << smile_ToString(rc) << std::endl;
        glfwTerminate();
        return 1;
    }

    AssetData pshader_asset;
    rc = LoadAsset(&pshader_asset, const_cast<char*>(kPixelShader));
    if (eRcode_Ok != rc) {
        std::cerr << "Failed to load asset shaders/pshader-2d.glsl: " << smile_ToString(rc) << std::endl;
        FreeAsset(&vshader_asset);
        glfwTerminate();
        return 1;
    }
    gl_utils::Shader shader( std::string((const char*)vshader_asset.data, vshader_asset.size)
                           , std::string((const char*)pshader_asset.data, pshader_asset.size));
    FreeAsset(&vshader_asset);
    FreeAsset(&pshader_asset);

    rc = shader.reload();
    if (eRcode_Ok != rc) {
        std::cerr << "Failed to reload shader: " << smile_ToString(rc) << std::endl;
        glfwTerminate();
        return 1;
    }

    rc = shader.use();
    if (eRcode_Ok != rc) {
        std::cerr << "Failed to set shader: " << smile_ToString(rc) << std::endl;
        glfwTerminate();
        return 1;
    }

    SmileContext smile_ctx;
    gl_utils::SetGraphicsApi(smile_ctx.platform_api);
    smile_ctx.platform_api.LoadAsset              = &LoadAsset;
    smile_ctx.platform_api.FreeAsset              = &FreeAsset;

    rc = smile_SetUp(&smile_ctx);
    if (eRcode_Ok != rc) {
        std::cerr << "Failed to set up smile engine: " << smile_ToString(rc) << std::endl;
        glfwTerminate();
        return 1;
    }

    FrameEncoder frame;
    CALL_GL(1, glGenVertexArrays, 1, &frame.main);
    CALL_GL(1, glBindVertexArray, frame.main);
    frame.current = frame.main;

    rc = smile_ReloadResources(&smile_ctx, 0);
    if (eRcode_Ok != rc) {
        std::cerr << "Failed to reload resources: " << smile_ToString(rc) << std::endl;
        glfwTerminate();
        return 1;
    }

    glm::mat2 view_matrix(1.0f);
    view_matrix[1][1] = 600.0f/800.0f;

    CALL_GL(1, glBindVertexArray, 0);
    frame.current = 0;

    glClearColor(0.23f, 0.39f, 0.51f, 1.0f);

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    using default_clock = std::chrono::high_resolution_clock;
    default_clock::time_point last = default_clock::now();

    while(!glfwWindowShouldClose(pwnd)) {
        glfwPollEvents();

        default_clock::time_point now = default_clock::now();
        std::chrono::duration<double> d = now - last;
        if (d.count() >= 1.000 / 60.0) {
            last = now;

            glClear(GL_COLOR_BUFFER_BIT);

            shader.use();
            rc = shader.setUniform("view"sv, view_matrix);
            if (eRcode_Ok != rc) {
                std::cerr << "WARNING: failed to set uniform variable 'view': "
                          << smile_ToString(rc) << std::endl;
            }

            glBindVertexArray(frame.main);
            frame.current = frame.main;

            rc = smile_Update(&smile_ctx, d.count());
            if (eRcode_Ok != rc) {
                std::cerr << "WARNING: failed to update frame: "
                          << smile_ToString(rc) << " (state == "
                          << (int)smile_ctx.resources_state << ")"
                          << std::endl;
            }

            rc = smile_Render(&smile_ctx, &frame);
            if (eRcode_Ok != rc) {
                std::cerr << "WARNING: failed to render frame: "
                          << smile_ToString(rc) << std::endl;
            }


            glBindVertexArray(0);
            frame.current = 0;

            glfwSwapBuffers(pwnd);
        }
    }

    rc = smile_UnloadResources(&smile_ctx);
    if (eRcode_Ok != rc) {
        std::cerr << "WARNING: failed to unload resources: "
                  << smile_ToString(rc) << std::endl;
    }

    rc = smile_TearDown(&smile_ctx);
    if (eRcode_Ok != rc) {
        std::cerr << "Error while tearing down smile engine: "
                  << smile_ToString(rc) << std::endl;
    }

    glfwTerminate();

    std::cout << "Smile App Finished" << std::endl;

    return 0;
}

