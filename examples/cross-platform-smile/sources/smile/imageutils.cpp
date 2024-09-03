#include "imageutils.hpp"

#include <assert.h>

#include <cstring>
#include <functional>
#include <memory>
#include <new>
#include <tuple>
#include <vector>

#include "png.h"


using namespace imageutils;


namespace {

template <int...> struct seq {};

template <int N, int... S> struct gens : gens<N - 1, N - 1, S...> {};
template <int... S> struct gens<0, S...> { typedef seq<S...> type; };

template<typename... Params>
struct __raii_t {
    using Deleter = std::function<void(Params *...)>;

    __raii_t(Params *...params, Deleter deleter) noexcept
        : _data(params...), _deleter(deleter), _released(false)
    {}

    __raii_t(__raii_t && another) = default;

    ~__raii_t() noexcept {
        if (!_released) {
            doDelete(typename gens<sizeof...(Params)>::type());
        }
    }

    void release() noexcept { _released = true; }

    template <int... S> void doDelete(seq<S...>) noexcept {
        _deleter(std::get<S>(_data)...);
    }

    std::tuple<Params *...> _data;
    std::function<void(Params *...)> _deleter;
    bool _released;
};

template <typename... Params>
static __raii_t<Params...> __ToRaii(typename __raii_t<Params...>::Deleter deleter, Params *...params) noexcept {
    return __raii_t<Params...>(params..., deleter);
}

typedef struct {
    size_t offset;
    const byte*const* ppData;
} read_data_t;

static void read_png_data(png_structp pngPtr, png_bytep data, png_size_t len) {
    read_data_t& rd = *(read_data_t*)png_get_io_ptr(pngPtr);
    std::memcpy(data, *rd.ppData + rd.offset, len);
    rd.offset += len;
}


class ColorObject {
public:

    static
    ColorObject FromFormat(ColorFormat format) noexcept;

    ColorObject(u32 nbBitsR, u32 nbBitsG, u32 nbBitsB, u32 nbBitsA) noexcept;

    bool isValid() const noexcept { return _nbBits > 0 && _nbBits <= 32; }

    u32 size() const noexcept { return _nbBytes; }

    byte R() const noexcept { return _r; }
    byte G() const noexcept { return _g; }
    byte B() const noexcept { return _b; }
    byte A() const noexcept { return _a; }

    void set(byte r, byte g, byte b, byte a) noexcept;

    Rcode save(byte* pBuffer) const noexcept;
    Rcode load(const byte* pBuffer) noexcept;

private:

    u32 _nbBitsR;
    u32 _nbBitsG;
    u32 _nbBitsB;
    u32 _nbBitsA;

    u32 _nbBits;
    u32 _nbBytes;

    byte _r, _g, _b, _a;
};

/*static*/
ColorObject ColorObject::FromFormat(ColorFormat format) noexcept {

    switch (format) {
        case ColorFormat::R8G8B8X8 : return ColorObject(8, 8, 8, 8);
        case ColorFormat::R8G8B8A8 : return ColorObject(8, 8, 8, 8);
        case ColorFormat::R8G8B8   : return ColorObject(8, 8, 8, 0);
        case ColorFormat::R4G4B4A4 : return ColorObject(4, 4, 4, 4);
        case ColorFormat::R5G6B5   : return ColorObject(5, 6, 5, 0);
        case ColorFormat::A8       : return ColorObject(0, 0, 0, 8);
        case ColorFormat::Undefined: return ColorObject(0, 0, 0, 0);
    }

    return ColorObject(0, 0, 0, 0);
}


ColorObject::ColorObject(u32 nbBitsR, u32 nbBitsG, u32 nbBitsB, u32 nbBitsA) noexcept
    : _nbBitsR(nbBitsR), _nbBitsG(nbBitsG), _nbBitsB(nbBitsB), _nbBitsA(nbBitsA)
    , _nbBits(nbBitsA + nbBitsB + nbBitsG + nbBitsR)
    , _r(0), _g(0), _b(0), _a(0)
{
    _nbBytes = _nbBits / 8;
    if ((_nbBits % 8) != 0) {
        _nbBytes += 1;
    }
}


void ColorObject::set(byte r, byte g, byte b, byte a) noexcept {

    u32 maxR = (1 << _nbBitsR) - 1;
    u32 maxG = (1 << _nbBitsG) - 1;
    u32 maxB = (1 << _nbBitsB) - 1;
    u32 maxA = (1 << _nbBitsA) - 1;

    _r = static_cast<byte>(std::min((u32)r, maxR));
    _g = static_cast<byte>(std::min((u32)g, maxG));
    _b = static_cast<byte>(std::min((u32)b, maxB));
    _a = static_cast<byte>(std::min((u32)a, maxA));
}


Rcode ColorObject::save(byte* pBuffer) const noexcept {

    if (!isValid()) {
        return eRcode_InvalidInput;
    }

    assert(_nbBits <= 32);

    if (_nbBits <= 8) {
        byte colorval = (_r << (_nbBits-_nbBitsR))
                      | (_g << (_nbBitsB + _nbBitsA))
                      | (_b << _nbBitsA)
                      | (_a);
        *pBuffer = colorval;
    } else if (_nbBits <= 16) {
        u16 colorval = (static_cast<u16>(_r) << (_nbBits-_nbBitsR))
                     | (static_cast<u16>(_g) << (_nbBitsB + _nbBitsA))
                     | (static_cast<u16>(_b) << _nbBitsA)
                     | static_cast<u16>(_a);
        *reinterpret_cast<u16*>(pBuffer) = colorval;
    } else {
        u32 colorval = (static_cast<u32>(_r) << (_nbBits-_nbBitsR))
                     | (static_cast<u32>(_g) << (_nbBitsB + _nbBitsA))
                     | (static_cast<u32>(_b) << _nbBitsA)
                     | static_cast<u32>(_a);
        *reinterpret_cast<u32*>(pBuffer) = colorval;
    }

    return eRcode_Ok;
}


Rcode ColorObject::load(const byte* pBuffer) noexcept {

    if (!isValid()) {
        return eRcode_InvalidInput;
    }

    assert(_nbBits <= 32);

    u32 maxG = (1 << _nbBitsG) - 1;
    u32 maxB = (1 << _nbBitsB) - 1;
    u32 maxA = (1 << _nbBitsA) - 1;

    u32 colorval;
    if (_nbBits <= 8) {
        colorval = static_cast<u32>(*pBuffer);
    } else if (_nbBits <= 16) {
        colorval = static_cast<u32>(*reinterpret_cast<const u16*>(pBuffer));
    } else {
        colorval = *reinterpret_cast<const u32*>(pBuffer);
    }

    byte rv = _nbBitsR > 0 ? static_cast<byte>(colorval >> (_nbBits-_nbBitsR)) : 0;
    byte gv = _nbBitsG > 0 ? static_cast<byte>((colorval >> (_nbBitsB + _nbBitsA)) & maxG) : 0;
    byte bv = _nbBitsB > 0 ? static_cast<byte>((colorval >> _nbBitsA) & maxB) : 0;
    byte av = _nbBitsA > 0 ? static_cast<byte>(colorval & maxA) : 255;
    set(rv, gv, bv, av);

    return eRcode_Ok;
}

}


Png::Png() noexcept {
    _image.data = nullptr;
    _image.width = _image.height = _image.szdata = _image.szrow = 0;
    _format = ColorFormat::Undefined;
}


Png::~Png() noexcept {
    delete[] _image.data;
}


Rcode imageutils::Png::load(const AssetData& asset) noexcept
{
    if (!asset.data || png_sig_cmp(asset.data, 0, 8)) {
        return eRcode_InvalidInput;
    }

    read_data_t rd{8, &asset.data};

    png_structp pPng =
        png_create_read_struct(PNG_LIBPNG_VER_STRING, nullptr, nullptr, nullptr);
    if (!pPng) {
        return eRcode_MemError;
    }
    auto raii__pPng = __ToRaii([](png_structp* p) {
        png_destroy_read_struct(p, nullptr, nullptr);
    }, &pPng);

    png_infop pPngInfo = png_create_info_struct(pPng);
    if (!pPngInfo) {
       return eRcode_MemError;
    }
    raii__pPng.release();
    auto raii__pPngInfo = __ToRaii([](png_structp* p1, png_infop* p2){
        png_destroy_read_struct(p1, p2, nullptr);
    }, &pPng, &pPngInfo);

    png_uint_32 w, h;
    int bDepth, colorType, interlaceType;
    ColorFormat fmt = ColorFormat::Undefined;
    png_size_t szRowInBytes = 0;
    std::vector<uint8_t*> rows;

    if (setjmp(png_jmpbuf(pPng))) {
        return eRcode_LogicError;
    }

    png_set_read_fn(pPng, &rd, read_png_data);

    png_set_sig_bytes(pPng, 8);

    png_read_info(pPng, pPngInfo);

    png_get_IHDR(pPng, pPngInfo, &w, &h, &bDepth, &colorType, &interlaceType, NULL, NULL);

    rows.resize(static_cast<std::size_t>(h));
    std::memset(rows.data(), 0, rows.size() * sizeof(rows[0]));

    png_set_strip_16(pPng);

    // convert the grayscale image to the RGBA 8 bit image
    if (colorType == PNG_COLOR_TYPE_GRAY_ALPHA) {
        fmt = ColorFormat::R8G8B8A8;
        png_set_gray_to_rgb(pPng);
    }

    // extract multiple pixels with bit depths of 1, 2, and 4 from a single
    // byte into separate bytes (useful for paletted and grayscale images)
    png_set_packing(pPng);

    // expand paletted colors into true RGB triplets
    if (colorType == PNG_COLOR_TYPE_PALETTE) {
        fmt = ColorFormat::R8G8B8;
        png_set_palette_to_rgb(pPng);
    }

    // expand grayscale images to the full 8 bits from 1, 2, or 4 bits/pixel
    if (colorType == PNG_COLOR_TYPE_GRAY && bDepth < 8) {
        fmt = ColorFormat::A8;
        png_set_expand_gray_1_2_4_to_8(pPng);
    }

    // expand paletted or RGB images with transparency to full alpha channels
    // so the data will be available as RGBA quartets
    if (png_get_valid(pPng, pPngInfo, PNG_INFO_tRNS) != 0) {
        png_set_tRNS_to_alpha(pPng);
    }

    // set the background color to draw transparent and alpha images over.
    // It is possible to set the red, green, and blue components directly
    // for paletted images instead of supplying a palette index. Note that
    // even if the PNG file supplies a background, you are not required to
    // use it - you should use the (solid) application background if it has one.
    if (colorType != PNG_COLOR_TYPE_RGBA) {
        png_color_16 myBackground, *pImageBackground;

        if (png_get_bKGD(pPng, pPngInfo, &pImageBackground) != 0) {
            png_set_background(pPng, pImageBackground, PNG_BACKGROUND_GAMMA_FILE, 1, 1.0);
        } else {
            png_set_background(pPng, &myBackground, PNG_BACKGROUND_GAMMA_SCREEN, 0, 1.0);
        }
    }

    /* Optional call to gamma correct and add the background to the palette
     * and update info structure. REQUIRED if you are expecting libpng to
     * update the palette for you (ie you selected such a transform above). */
    png_read_update_info(pPng, pPngInfo);

    szRowInBytes = png_get_rowbytes(pPng, pPngInfo);

    _image.szdata = static_cast<u32>(h*szRowInBytes);
    std::unique_ptr<byte[]> data = std::make_unique<byte[]>(_image.szdata);
    if (!data.get()) {
        return eRcode_MemError;
    }

    for (png_uint_32 r = 0; r < h; r++) {
        rows[h - 1 - r] = data.get() + szRowInBytes * r;
    }

    png_read_image(pPng, rows.data());

    png_read_end(pPng, pPngInfo);

    raii__pPngInfo.release();
    png_destroy_read_struct(&pPng, &pPngInfo, NULL);

    if (ColorFormat::Undefined == fmt) {
        switch (colorType) {
            case PNG_COLOR_TYPE_GRAY     : fmt = ColorFormat::A8;       break;
            case PNG_COLOR_TYPE_RGB      : fmt = ColorFormat::R8G8B8;   break;
            case PNG_COLOR_TYPE_RGB_ALPHA: fmt = ColorFormat::R8G8B8A8; break;
            default: fmt = ColorFormat::Undefined;
        }
    }

    if (fmt == ColorFormat::Undefined || 8 != bDepth) {
        return eRcode_InvalidInput;
    }

    _image.data = data.release();
    _image.width = static_cast<u32>(w);
    _image.height = static_cast<u32>(h);
    _image.szrow = static_cast<u32>(szRowInBytes);

    _format = fmt;

    return eRcode_Ok;
}


Rcode Png::convert(ColorFormat target) noexcept {
    if (_format == target) {
        return eRcode_Ok;
    }

    Png tmp;
    Rcode rc = convert(tmp, *this, target);
    if (eRcode_Ok != rc) {
        return rc;
    }

    swap(tmp, *this);

    return eRcode_Ok;
}


/*static*/
void Png::swap(Png& a, Png& b) noexcept {
    std::swap(a._image.data, b._image.data);

    std::swap(a._image.szdata, b._image.szdata);
    std::swap(a._image.width, b._image.width);
    std::swap(a._image.height, b._image.height);
    std::swap(a._image.szrow, b._image.szrow);
    std::swap(a._format, b._format);
}

/*static*/
Rcode Png::convert_A8_to_RGBA(Png& dest, const Png& source) noexcept {
    assert(source._format == ColorFormat::A8);

    ColorObject srcColor = ColorObject::FromFormat(ColorFormat::A8);
    assert(srcColor.isValid());

    ColorObject dstColor = ColorObject::FromFormat(ColorFormat::R8G8B8A8);
    assert(srcColor.isValid());

    dest._image.szrow = source._image.width * dstColor.size();
    dest._image.width = source._image.width;
    dest._image.height = source._image.height;
    dest._format = ColorFormat::R8G8B8A8;
    dest._image.szdata = source._image.width * source._image.height * dstColor.size();

    try {
        dest._image.data = new byte[dest._image.szdata];
        if (!dest._image.data) {
            return eRcode_MemError;
        }
    } catch (std::bad_alloc&) {
        return eRcode_MemError;
    }

    for ( u32 y = 0, w = 0
        ; y < source._image.height * source._image.szrow
        ; y += source._image.szrow, w += dest._image.szrow)
    {
        for ( u32 x = 0, v = 0
            ; x < source._image.width * srcColor.size()
            ; x += srcColor.size(), v += dstColor.size())
        {
            assert(y + x < source._image.szdata);
            assert(w + v < dest._image.szdata);
            srcColor.load(&(source._image.data[y + x]));
            dstColor.set(srcColor.A(), srcColor.A(), srcColor.A(), 255);
            dstColor.save(&(dest._image.data[w + v]));
        }
    }

    return eRcode_Ok;
}

/*static*/
Rcode Png::convert_RGB_to_A8(Png& dest, const Png& source) noexcept {
    assert(source._format == ColorFormat::R8G8B8);

    ColorObject srcColor = ColorObject::FromFormat(ColorFormat::R8G8B8);
    assert(srcColor.isValid());

    ColorObject dstColor = ColorObject::FromFormat(ColorFormat::A8);
    assert(srcColor.isValid());

    dest._image.szrow = source._image.width * dstColor.size();
    dest._image.width = source._image.width;
    dest._image.height = source._image.height;
    dest._format = ColorFormat::A8;
    dest._image.szdata = source._image.width * source._image.height * dstColor.size();

    try {
        dest._image.data = new byte[dest._image.szdata];
        if (!dest._image.data) {
            return eRcode_MemError;
        }
    } catch (std::bad_alloc&) {
        return eRcode_MemError;
    }

    for ( u32 y = 0, w = 0
        ; y < source._image.height * source._image.szrow
        ; y += source._image.szrow, w += dest._image.szrow)
    {
        for ( u32 x = 0, v = 0
            ; x < source._image.width * srcColor.size()
            ; x += srcColor.size(), v += dstColor.size())
        {
            assert(y + x < source._image.szdata);
            assert(w + v < dest._image.szdata);
            srcColor.load(&(source._image.data[y + x]));
            float clr = 0.299 * srcColor.R() + 0.587 * srcColor.G() + 0.114 * srcColor.B();
            dstColor.set(clr, clr, clr, clr);
            dstColor.save(&(dest._image.data[w + v]));
        }
    }

    return eRcode_Ok;
}

/*static*/
Rcode Png::convert(Png& dest, const Png& source, ColorFormat target) noexcept {
    if (source._format == ColorFormat::A8 && target == ColorFormat::R8G8B8A8) {
        return convert_A8_to_RGBA(dest, source);
    }

    if (source._format == ColorFormat::R8G8B8 && target == ColorFormat::A8) {
        return convert_RGB_to_A8(dest, source);
    }

    ColorObject srcColor = ColorObject::FromFormat(source._format);
    if (!srcColor.isValid()) {
        return eRcode_InvalidInput;
    }

    ColorObject dstColor = ColorObject::FromFormat(target);
    if (!dstColor.isValid()) {
        return eRcode_InvalidInput;
    }

    dest._image.szrow = source._image.width * dstColor.size();
    dest._image.width = source._image.width;
    dest._image.height = source._image.height;
    dest._format = target;
    dest._image.szdata = source._image.width * source._image.height * dstColor.size();
    dest._image.data = new byte[dest._image.szdata];
    if (!dest._image.data) {
        return eRcode_MemError;
    }

    for ( u32 y = 0, w = 0
        ; y < source._image.height * source._image.szrow
        ; y += source._image.szrow, w += dest._image.szrow)
    {
        for ( u32 x = 0, v = 0
            ; x < source._image.width * srcColor.size()
            ; x += srcColor.size(), v += dstColor.size())
        {
            assert(y + x < source._image.szdata);
            assert(w + v < dest._image.szdata);
            srcColor.load(&(source._image.data[y + x]));
            dstColor.set(srcColor.R(), srcColor.G(), srcColor.B(), srcColor.A());
            dstColor.save(&(dest._image.data[w + v]));
        }
    }

    return eRcode_Ok;
}
