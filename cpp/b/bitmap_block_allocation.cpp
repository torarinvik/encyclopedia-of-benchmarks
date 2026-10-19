#include <cstddef>
#include <cstdint>
static constexpr std::size_t MAX_BITS=4096, MAX_OPS=32, MAX_OUT=MAX_BITS/8;
extern "C" std::int64_t bitmap_block_allocation(const std::int64_t* values, std::size_t length,
    std::uint8_t* output, std::size_t capacity) {
    if (!values || length<2 || length>2+2*MAX_OPS) return -1;
    auto rb=values[0], ro=values[1];
    if (rb<1 || rb>MAX_BITS || ro<0 || ro>MAX_OPS || length!=2+2*static_cast<std::size_t>(ro)) return -1;
    auto bits=static_cast<std::size_t>(rb), ops=static_cast<std::size_t>(ro);
    std::size_t offsets[MAX_OPS]{}, runs[MAX_OPS]{};
    for(std::size_t i=0;i<ops;++i){auto o=values[2+2*i], n=values[3+2*i];
        if(o<0 || static_cast<std::uint64_t>(o)>bits || n<0 || static_cast<std::uint64_t>(n)>bits-static_cast<std::size_t>(o)) return -1;
        offsets[i]=static_cast<std::size_t>(o); runs[i]=static_cast<std::size_t>(n);
    }
    auto bytes=(bits+7)/8; std::uint8_t bitmap[MAX_OUT]{};
    for(std::size_t b=0;b<bits;++b) if((b&1u)==0) bitmap[b/8]|=static_cast<std::uint8_t>(1u<<(b%8));
    for(std::size_t i=0;i<ops;++i) for(std::size_t b=offsets[i];b<offsets[i]+runs[i];++b){
        auto mask=static_cast<std::uint8_t>(1u<<(b%8));
        if(i%3==0) bitmap[b/8]|=mask; else if(i%3==1) bitmap[b/8]&=static_cast<std::uint8_t>(~mask); else bitmap[b/8]^=mask;
    }
    if(!output || capacity<bytes) return -2;
    for(std::size_t i=0;i<bytes;++i) output[i]=bitmap[i];
    return static_cast<std::int64_t>(bytes);
}
