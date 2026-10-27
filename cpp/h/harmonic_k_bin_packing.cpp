#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t MaxN=32,MaxK=8,MaxInput=34; constexpr std::int64_t Capacity=10000;
void store(std::uint8_t* out,std::size_t off,std::int64_t v) noexcept { auto bits=static_cast<std::uint64_t>(v);for(std::size_t b=0;b<8;++b){out[off+b]=static_cast<std::uint8_t>(bits&255U);bits>>=8;} } }
extern "C" std::int64_t harmonic_k_bin_packing(const std::int64_t* input,std::size_t length,std::uint8_t* output,std::size_t capacity) noexcept {
 if(!input||length<3||length>MaxInput)return -1;auto k64=input[0],n64=input[1];if(k64<3||k64>MaxK||n64<1||n64>MaxN||length!=2+static_cast<std::size_t>(n64))return -1;
 auto k=static_cast<std::size_t>(k64),n=static_cast<std::size_t>(n64);for(std::size_t i=0;i<n;++i)if(input[2+i]<1||input[2+i]>Capacity)return -1;
 auto bytes=8*(n+1);if(!output||capacity<bytes)return -2;std::int64_t current[MaxK],remaining[MaxK]{},assignment[MaxN]{};for(auto& x:current)x=-1;std::int64_t bins=0;
 for(std::size_t i=0;i<n;++i){auto size=input[2+i];std::size_t kind=k-1;for(std::size_t c=0;c<k-1;++c)if(size*static_cast<std::int64_t>(c+2)>Capacity){kind=c;break;}
  if(current[kind]<0||size>remaining[kind]){current[kind]=bins++;remaining[kind]=Capacity;}assignment[i]=current[kind];remaining[kind]-=size;}
 store(output,0,bins);for(std::size_t i=0;i<n;++i)store(output,8*(i+1),assignment[i]);return static_cast<std::int64_t>(bytes);
}
