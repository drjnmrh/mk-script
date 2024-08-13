#import "Foundation/Foundation.h"

#include <stdio.h>

#include "smile/logging.h"


void smile_DumpLogLine(SmileLogLevel lvl, char* line) {
    bool useAsl = false;
    const char* levelTag = "[UNK]";

    switch (lvl) {
        case eSmileLogLevel_Error  : useAsl = true; levelTag = "[ERR]"; break;
        case eSmileLogLevel_Info   : useAsl = true; levelTag = "[INF]"; break;
        case eSmileLogLevel_Warning: useAsl = true; levelTag = "[WRN]"; break;
        case eSmileLogLevel_Debug  : useAsl = false; levelTag = "[DBG]"; break;
    }

    if (useAsl) {
        NSLog(@"%s %s", levelTag, line);
    } else {
        printf("%s %s\n", levelTag, line);
    }
}

