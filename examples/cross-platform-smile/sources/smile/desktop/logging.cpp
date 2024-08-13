#include "smile/logging.h"

#include <iostream>


#define CASE_LOGLEVEL(Level) \
    case eSmileLogLevel_ ## Level: (*postr) << #Level << ": " << line << std::endl; break


extern "C"
void smile_DumpLogLine(SmileLogLevel lvl, char* line) {
    std::ostream* postr;
    if (eSmileLogLevel_Error == lvl)
        postr = &std::cerr;
    else
        postr = &std::cout;

    switch (lvl) {
        CASE_LOGLEVEL(Error);
        CASE_LOGLEVEL(Info);
        CASE_LOGLEVEL(Warning);
        CASE_LOGLEVEL(Debug);
    }
}

