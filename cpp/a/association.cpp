#include <cstddef>
#include <cstdint>

namespace {
unsigned popcount(unsigned value) { unsigned count=0; while(value){ count+=value&1u; value>>=1; } return count; }
void put_i64_le(std::uint8_t *out, std::size_t offset, std::int64_t value) { auto bits=static_cast<std::uint64_t>(value); for(std::size_t b=0;b<8;++b) out[offset+b]=static_cast<std::uint8_t>(bits>>(8*b)); }
}

extern "C" std::int64_t association(const std::int64_t *input, std::size_t length,
                                      std::uint8_t *output, std::size_t capacity) noexcept {
    if(!input||length<2||input[0]<1||input[0]>64||input[1]<1||input[1]>11) return -1;
    const auto transactions=static_cast<std::size_t>(input[0]), items=static_cast<std::size_t>(input[1]);
    if(length!=2+transactions) return -1;
    const unsigned limit=1u<<items, valid_bits=limit-1;
    for(std::size_t t=0;t<transactions;++t) if(input[2+t]<0||static_cast<std::uint64_t>(input[2+t])>valid_bits) return -1;
    bool frequent[2048]={}; std::uint64_t masks[2047]; std::int64_t supports[2047]; std::size_t count=0;
    for(unsigned size=1;size<=items;++size) for(unsigned mask=1;mask<limit;++mask){
        if(popcount(mask)!=size) continue;
        if(size>1){ bool ok=true; for(unsigned bit=0;bit<items;++bit) if((mask&(1u<<bit))&&!frequent[mask^(1u<<bit)]) ok=false; if(!ok) continue; }
        std::int64_t support=0; for(std::size_t t=0;t<transactions;++t) if((static_cast<unsigned>(input[2+t])&mask)==mask) ++support;
        if(support>0){ frequent[mask]=true; masks[count]=mask; supports[count++]=support; }
    }
    const std::size_t required=count*16;
    if(capacity<required||(required!=0&&!output)) return -2;
    for(std::size_t i=0;i<count;++i){ put_i64_le(output,i*16,static_cast<std::int64_t>(masks[i])); put_i64_le(output,i*16+8,supports[i]); }
    return static_cast<std::int64_t>(required);
}
