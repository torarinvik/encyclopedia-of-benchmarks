/* Emit the median after each insertion into a fixed-width trailing window. */
#include <cstddef>
#include <cstdint>
#include <cstring>
namespace {void put(std::uint8_t*out,std::size_t at,double value){std::uint64_t bits;std::memcpy(&bits,&value,8);for(std::size_t b=0;b<8;++b)out[at+b]=static_cast<std::uint8_t>(bits>>(8*b));}}
extern "C" std::int64_t windowed_median(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap) noexcept {
 if(!in||len<3)return -1;auto w64=in[0],n64=in[1];if(w64<1||w64>64||n64<1||n64>128)return -1;auto w=static_cast<std::size_t>(w64),n=static_cast<std::size_t>(n64);if(len!=n+2)return -1;
 for(std::size_t i=0;i<n;++i)if(in[2+i]<-1000000||in[2+i]>1000000)return -1;if(cap<n*8||!out)return -2;
 std::int64_t sorted[64];std::size_t active=0;
 for(std::size_t i=0;i<n;++i){if(i>=w){auto old=in[2+i-w];std::size_t p=0;while(p<active&&sorted[p]!=old)++p;if(p==active)return -1;for(std::size_t j=p+1;j<active;++j)sorted[j-1]=sorted[j];--active;}
  auto value=in[2+i];std::size_t p=0;while(p<active&&sorted[p]<value)++p;for(std::size_t j=active;j>p;--j)sorted[j]=sorted[j-1];sorted[p]=value;++active;
  float median;if(active&1)median=static_cast<float>(sorted[active/2]);else median=0.5f*static_cast<float>(sorted[active/2-1])+0.5f*static_cast<float>(sorted[active/2]);put(out,i*8,static_cast<double>(median));}
 return static_cast<std::int64_t>(n*8);
}
