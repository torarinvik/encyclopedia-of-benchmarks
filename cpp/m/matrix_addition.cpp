#include <cstddef>
#include <cstdint>
#include <limits>

namespace {
void store_i32_le(std::uint32_t value, std::uint8_t* out, std::size_t offset) { for(std::size_t b=0;b<4;++b)out[offset+b]=static_cast<std::uint8_t>(value>>(8*b)); }
}
extern "C" std::int64_t matrix_addition(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity){
    if(input==nullptr||length<4)return -2;
    if(input[0]<0||input[0]>16||input[1]<0||input[1]>16)return -2;
    const auto ra=static_cast<std::size_t>(input[0]),ca=static_cast<std::size_t>(input[1]);if(ra==0&&ca!=0)return -2;
    const auto na=ra*ca,bd=2+na;if(bd+2>length||input[bd]<0||input[bd]>16||input[bd+1]<0||input[bd+1]>16)return -2;
    const auto rb=static_cast<std::size_t>(input[bd]),cb=static_cast<std::size_t>(input[bd+1]);if(rb==0&&cb!=0)return -2;
    const auto nb=rb*cb;if(length!=bd+2+nb)return -2;if(ra!=rb||ca!=cb)return -1;
    for(std::size_t i=0;i<na;++i)if(input[2+i]<std::numeric_limits<std::int32_t>::min()||input[2+i]>std::numeric_limits<std::int32_t>::max()||input[bd+2+i]<std::numeric_limits<std::int32_t>::min()||input[bd+2+i]>std::numeric_limits<std::int32_t>::max())return -2;
    if(capacity<na*4||(na!=0&&output==nullptr))return -3;
    for(std::size_t i=0;i<na;++i)store_i32_le(static_cast<std::uint32_t>(static_cast<std::int32_t>(input[2+i]))+static_cast<std::uint32_t>(static_cast<std::int32_t>(input[bd+2+i])),output,i*4);
    return static_cast<std::int64_t>(na);
}
