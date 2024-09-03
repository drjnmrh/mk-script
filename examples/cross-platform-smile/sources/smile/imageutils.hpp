#ifndef SMILE_IMAGEUTILS_HPP_

#include "smile/smile.h"


namespace imageutils {

enum class ColorFormat {
    Undefined = 0
,   R8G8B8A8
,   R8G8B8
,   R8G8B8X8
,   R4G4B4A4
,   R5G6B5
,   A8
};

class Png {
public:
    Png() noexcept;
   ~Png() noexcept;
    
    Rcode load(const AssetData& asset) noexcept;
    Rcode convert(ColorFormat target) noexcept;
    
    ImageData& image() noexcept { return _image; }
    const ImageData& image() const noexcept { return _image; }
    
    ColorFormat format() const noexcept { return _format; }
    
private:
    static void swap(Png& a, Png& b) noexcept;

    static Rcode convert_A8_to_RGBA(Png& dest, const Png& source) noexcept;
    static Rcode convert_RGB_to_A8(Png& dest, const Png& source) noexcept;
    static Rcode convert(Png& dest, const Png& source, ColorFormat target) noexcept;
    
    ImageData _image;
    ColorFormat _format;
};

}


#define SMILE_IMAGEUTILS_HPP_
#endif
