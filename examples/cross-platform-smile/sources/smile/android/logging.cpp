#include "smile/logging.h"

#include <android/log.h>


extern "C"
void smile_DumpLogLine(SmileLogLevel lvl, char* line) {
    auto l = ANDROID_LOG_FATAL;
    switch (lvl) {
        case eSmileLogLevel_Error  : l = ANDROID_LOG_ERROR; break;
        case eSmileLogLevel_Info   : l = ANDROID_LOG_INFO; break;
        case eSmileLogLevel_Warning: l = ANDROID_LOG_WARN; break;
        case eSmileLogLevel_Debug  : l = ANDROID_LOG_DEBUG; break;
    }

    __android_log_print(l, "Smile", "%s\n", line);
}

