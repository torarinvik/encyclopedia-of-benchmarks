#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_items=12;
constexpr std::int64_t max_safe=9'007'199'254'740'991;
void put32(std::uint8_t *out, std::size_t &pos, std::uint32_t value) { for(int i=0;i<4;i++){out[pos++]=static_cast<std::uint8_t>(value);value>>=8;} }
void put64(std::uint8_t *out, std::size_t &pos, std::int64_t value) { auto bits=static_cast<std::uint64_t>(value); for(int i=0;i<8;i++){out[pos++]=static_cast<std::uint8_t>(bits);bits>>=8;} }
}

extern "C" std::int64_t generate_sub_sets(const std::int64_t *input, std::size_t length, std::uint8_t *output, std::size_t capacity) noexcept
{
    if(!input || length<1 || length>max_items+1 || input[0]<0 || input[0]>static_cast<std::int64_t>(max_items)) return -1;
    const auto n=static_cast<std::size_t>(input[0]); if(length!=n+1) return -1;
    for(std::size_t i=0;i<n;i++) if(input[i+1]<-max_safe || input[i+1]>max_safe) return -1;
    const std::size_t subsets=std::size_t{1}<<n;
    const std::size_t total_items=n==0?0:n*(subsets/2);
    const std::size_t needed=4+4*subsets+8*total_items;
    if(!output || capacity<needed) return -2;
    std::size_t pos=0; put32(output,pos,static_cast<std::uint32_t>(subsets));
    for(std::size_t mask=0;mask<subsets;mask++){
        std::uint32_t count=0; for(std::size_t j=0;j<n;j++) if(mask&(std::size_t{1}<<j)) ++count;
        put32(output,pos,count);
        for(std::size_t j=0;j<n;j++) if(mask&(std::size_t{1}<<j)) put64(output,pos,input[j+1]);
    }
    return static_cast<std::int64_t>(pos);
}
