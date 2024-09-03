#ifndef SMILE_LOG_HPP_

#include <cstdarg>
#include <cstring>
#include <sstream>

#include "smile/logging.h"


namespace smile {


template < typename T >
struct TypeUtils {
    static constexpr bool is_standard = false;

    using ValueType = T;
};

template <>
struct TypeUtils<int> {
    static constexpr bool is_standard = true;
    static constexpr char formatter[] = "%d";

    using ValueType = int;
};

template <>
struct TypeUtils<unsigned int> {
    static constexpr bool is_standard = true;
    static constexpr char formatter[] = "%u";

    using ValueType = unsigned int;
};

template <>
struct TypeUtils<long> {
    static constexpr bool is_standard = true;
    static constexpr char formatter[] = "%li";

    using ValueType = long;
};

template <>
struct TypeUtils<unsigned long> {
    static constexpr bool is_standard = true;
    static constexpr char formatter[] = "%lu";

    using ValueType = unsigned long;
};

template <>
struct TypeUtils<long long> {
    static constexpr bool is_standard = true;
    static constexpr char formatter[] = "%lli";

    using ValueType = long long;
};

template <>
struct TypeUtils<unsigned long long> {
    static constexpr bool is_standard = true;
    static constexpr char formatter[] = "%llu";

    using ValueType = unsigned long long;
};

template <>
struct TypeUtils<float> {
    static constexpr bool is_standard = true;
    static constexpr char formatter[] = "%f";

    using ValueType = float;
};

template <>
struct TypeUtils<double> {
    static constexpr bool is_standard = true;
    static constexpr char formatter[] = "%.9f";

    using ValueType = double;
};


template <std::size_t LogBufferSize>
class LogBase {
    LogBase(const LogBase&) = delete;
    LogBase& operator = (const LogBase&) = delete;

public:
    explicit LogBase(SmileLogLevel lvl) noexcept
        : _level(lvl)
    {
        _end = &_buffer[0];
        *_end = '\0';
    }

   ~LogBase() noexcept { dump(); }

    void format(const char* fmt, ...) noexcept {
        std::size_t busy = _end - &_buffer[0];
        std::size_t cap = LogBufferSize - busy;

        std::va_list args;
        va_start(args, fmt);
        int nb = std::vsnprintf(_end, cap, fmt, args);
        va_end(args);

        if (nb <= 0)
            return;

        _end = &_buffer[nb + busy];
        *_end = '\0';
    }

    LogBase& operator << (char c) noexcept {
        if (_end == &_buffer[LogBufferSize])
            return *this;

        *_end = c;
        ++_end;
        *_end = '\0';

        return *this;
    }

    inline LogBase& operator << (char const* msg) noexcept {
        format("%s", msg);
        return *this;
    }

    inline LogBase& operator << (const std::string& msg) noexcept {
        format("%s", msg.c_str());
        return *this;
    }

    template < typename T >
    inline LogBase& operator << (T t) noexcept {
        if constexpr(TypeUtils<T>::is_standard) {
            format(TypeUtils<T>::formatter, (typename TypeUtils<T>::ValueType)t);
        } else {
            std::stringstream str;
            str << t;
            format("%s", str.str().c_str());
        }

        return *this;
    }

    void dump() noexcept {
        char* pcurline = &_buffer[0];
        char* pcurchar = pcurline;
        while (pcurchar != _end) {
            if (*pcurchar == '\n') {
                *pcurchar = '\0';
                smile_DumpLogLine(_level, pcurline);
                pcurline = pcurchar+1;
            }

            ++pcurchar;
        }

        if (pcurline != pcurchar)
            smile_DumpLogLine(_level, pcurline);

        _end = &_buffer[0];
        *_end = '\0';
    }

private:
    SmileLogLevel _level;
    char _buffer[LogBufferSize+1];
    char* _end;

};


#define SMILE_LOG(Level) smile::LogBase<511>(eSmileLogLevel_ ## Level)


}


#define SMILE_LOG_HPP_
#endif
