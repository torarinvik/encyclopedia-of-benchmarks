#include <cstddef>
#include <cstdint>
namespace { void put(std::uint8_t *o,std::size_t p,std::int64_t x){auto u=static_cast<std::uint64_t>(x);for(std::size_t b=0;b<8;++b)o[p+b]=std::uint8_t(u>>(8*b));} }
extern "C" std::int64_t first_fit_bin_packing(const std::int64_t *in,std::size_t len,std::uint8_t *out,std::size_t cap) noexcept {
    if(!in||len<1||len>65)return -1;auto n0=in[0];if(n0<0||n0>64||len!=std::size_t(1+n0))return -1;auto n=std::size_t(n0);
    for(std::size_t i=0;i<n;++i)if(in[i+1]<1||in[i+1]>1000000)return -1;
    std::int64_t loads[64]{},ids[64]{};std::size_t bins=0;
    for(std::size_t i=0;i<n;++i){auto size=in[i+1];std::size_t b=0;while(b<bins&&loads[b]+size>1000000)++b;if(b==bins)loads[bins++]=size;else loads[b]+=size;ids[i]=static_cast<std::int64_t>(b);}
    auto required=(n+1)*8;if(cap<required||!out)return -2;put(out,0,static_cast<std::int64_t>(bins));for(std::size_t i=0;i<n;++i)put(out,8*(i+1),ids[i]);return static_cast<std::int64_t>(required);
}
