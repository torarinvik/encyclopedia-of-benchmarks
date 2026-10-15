#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INPUT = 4096;
constexpr std::size_t MAX_PADDED = 4160;
std::uint32_t rol(std::uint32_t value, unsigned shift) noexcept {
    return (value << shift) | (value >> (32 - shift));
}
}

extern "C" std::int64_t sha1(const std::int64_t* input, std::size_t length,
                              std::uint8_t* output, std::size_t capacity) noexcept {
    if (length > MAX_INPUT || (length > 0 && input == nullptr)) return -1;
    for (std::size_t i = 0; i < length; ++i)
        if (input[i] < 0 || input[i] > 255) return -1;
    std::uint8_t padded[MAX_PADDED]{};
    for (std::size_t i = 0; i < length; ++i) padded[i] = static_cast<std::uint8_t>(input[i]);
    padded[length] = 0x80;
    const std::size_t blocks = (length + 9 + 63) / 64;
    const std::size_t padded_length = blocks * 64;
    const std::uint64_t bit_length = static_cast<std::uint64_t>(length) * 8;
    for (std::size_t i = 0; i < 8; ++i)
        padded[padded_length - 1 - i] = static_cast<std::uint8_t>(bit_length >> (8 * i));
    std::uint32_t h0=0x67452301, h1=0xEFCDAB89, h2=0x98BADCFE, h3=0x10325476, h4=0xC3D2E1F0;
    for (std::size_t block=0; block<blocks; ++block) {
        std::uint32_t w[80];
        for (std::size_t i=0;i<16;++i) {
            const std::size_t p=block*64+i*4;
            w[i]=(std::uint32_t(padded[p])<<24)|(std::uint32_t(padded[p+1])<<16)|
                 (std::uint32_t(padded[p+2])<<8)|padded[p+3];
        }
        for (std::size_t i=16;i<80;++i) w[i]=rol(w[i-3]^w[i-8]^w[i-14]^w[i-16],1);
        std::uint32_t a=h0,b=h1,c=h2,d=h3,e=h4;
        for (std::size_t i=0;i<80;++i) {
            std::uint32_t f,k;
            if(i<20){f=(b&c)|((~b)&d);k=0x5A827999;}
            else if(i<40){f=b^c^d;k=0x6ED9EBA1;}
            else if(i<60){f=(b&c)|(b&d)|(c&d);k=0x8F1BBCDC;}
            else{f=b^c^d;k=0xCA62C1D6;}
            const std::uint32_t temp=rol(a,5)+f+e+k+w[i];e=d;d=c;c=rol(b,30);b=a;a=temp;
        }
        h0+=a;h1+=b;h2+=c;h3+=d;h4+=e;
    }
    if(output==nullptr||capacity<20)return -2;
    const std::uint32_t digest[5]={h0,h1,h2,h3,h4};
    for(std::size_t i=0;i<5;++i)for(std::size_t byte=0;byte<4;++byte)
        output[i*4+byte]=static_cast<std::uint8_t>(digest[i]>>(24-8*byte));
    return 20;
}
