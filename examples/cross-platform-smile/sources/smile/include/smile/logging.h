#ifndef SMILE_LOGGING_H_


typedef enum {
    eSmileLogLevel_Error   = 0b0001
,   eSmileLogLevel_Info    = 0b0010
,   eSmileLogLevel_Warning = 0b0100
,   eSmileLogLevel_Debug   = 0b1000
} SmileLogLevel;


#if defined(__cplusplus)
extern "C"
#endif
void smile_DumpLogLine(SmileLogLevel lvl, char* line);


#define SMILE_LOGGING_H_
#endif
