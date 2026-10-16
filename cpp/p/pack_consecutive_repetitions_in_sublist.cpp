#include <cstddef>
#include <cstdint>
namespace { std::uint32_t mix(std::uint32_t h,std::uint8_t b){return (h^b)*16777619u;} std::uint32_t feed(std::uint32_t h,std::uint32_t x){for(unsigned s=0;s<32;s+=8)h=mix(h,std::uint8_t(x>>s));return h;} }
extern "C" std::int64_t pack_consecutive_repetitions_in_sublist(const std::int64_t* v,std::size_t n) noexcept {
    if(!v||n<1||n>65||v[0]<0||v[0]>64||n!=std::size_t(v[0])+1)return -1;
    const auto count=std::size_t(v[0]);for(std::size_t i=0;i<count;++i)if(v[i+1]<INT32_MIN||v[i+1]>INT32_MAX)return -1;
    std::uint32_t h=2166136261u;
    for(std::size_t i=0;i<count;){const auto value=std::int32_t(v[i+1]);std::size_t j=i+1;while(j<count&&v[j+1]==value)++j;h=feed(h,std::uint32_t(value));h=feed(h,std::uint32_t(j-i));i=j;}
    return std::int64_t(h);
}
