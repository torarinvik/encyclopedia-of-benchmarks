#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
std::int32_t from_u32(std::uint32_t bits){return bits<=INT32_MAX?static_cast<std::int32_t>(bits):static_cast<std::int32_t>(static_cast<std::int64_t>(bits)-INT64_C(4294967296));}
std::int32_t add32(std::int32_t a,std::int32_t b){return from_u32(static_cast<std::uint32_t>(a)+static_cast<std::uint32_t>(b));}
std::int32_t mul32(std::int32_t a,std::int32_t b){return from_u32(static_cast<std::uint32_t>(a)*static_cast<std::uint32_t>(b));}
std::int64_t pack(std::int32_t n,std::int32_t d){return static_cast<std::int64_t>(n)*INT64_C(4294967296)+static_cast<std::uint32_t>(d);}
}
extern "C" std::int64_t adtfraction(const std::int64_t* a,std::size_t len) noexcept {
    if(!a||len!=5)return -1;for(std::size_t i=0;i<5;++i)if(a[i]<-100000||a[i]>100000)return -1;
    if(a[0]<0||a[0]>4)return -1;
    auto op=static_cast<std::int32_t>(a[0]),n=static_cast<std::int32_t>(a[1]),d=static_cast<std::int32_t>(a[2]);
    auto m=static_cast<std::int32_t>(a[3]),e=static_cast<std::int32_t>(a[4]);
    if(op==0){if(!d||!e)return -1;auto od=mul32(d,e);return od?pack(add32(mul32(d,m),mul32(n,e)),od):-1;}
    if(op==1)return d?pack(mul32(n,m),d):-1;
    if(op==2){if(!d||!e)return -1;auto od=mul32(d,e);return od?pack(mul32(n,m),od):-1;}
    if(op==3)return n?pack(d,n):-1;
    if(!d)return -1;float value=static_cast<float>(n)/static_cast<float>(d);std::uint32_t bits;std::memcpy(&bits,&value,sizeof(bits));return bits;
}
