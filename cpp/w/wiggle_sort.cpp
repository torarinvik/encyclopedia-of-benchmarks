// Portable signed-32-bit wiggle arrangement.
#include <cstddef>
#include <cstdint>
static constexpr std::size_t MAX_ARRAY_LENGTH=4096;

extern "C" std::int64_t wiggle_sort(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t output_capacity) noexcept {
    if(length>MAX_ARRAY_LENGTH||(length!=0&&input==nullptr))return -1;
    std::int64_t values[MAX_ARRAY_LENGTH];for(std::size_t i=0;i<length;++i){if(input[i]<INT32_MIN||input[i]>INT32_MAX)return -1;values[i]=input[i];}
    const std::size_t bytes=length*4;if(output_capacity<bytes||(bytes!=0&&output==nullptr))return -2;
        for(std::size_t i=1;i<length;++i){if(((i&1U)!=0U&&values[i-1]>values[i])||((i&1U)==0U&&values[i-1]<values[i])){auto t=values[i];values[i]=values[i-1];values[i-1]=t;}}

    for(std::size_t i=0;i<length;++i){const std::uint32_t bits=static_cast<std::uint32_t>(static_cast<std::int32_t>(values[i]));for(std::size_t b=0;b<4;++b)output[i*4+b]=static_cast<std::uint8_t>(bits>>(b*8));}
    return static_cast<std::int64_t>(length);
}
