#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t MM=8,MN=32,MI=34; void put64(std::uint8_t*o,std::size_t p,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t j=0;j<8;++j){o[p+j]=static_cast<std::uint8_t>(b&255U);b>>=8;}} }
extern "C" std::int64_t list_scheduling(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap) noexcept{
    if(!in||len<3||len>MI)return -1;auto m64=in[0],n64=in[1];if(m64<1||m64>MM||n64<1||n64>MN||len!=2+static_cast<std::size_t>(n64))return -1;
    auto m=static_cast<std::size_t>(m64),n=static_cast<std::size_t>(n64);for(std::size_t i=0;i<n;++i)if(in[2+i]<1||in[2+i]>10000)return -1;
    auto bytes=8*(1+n+m);if(!out||cap<bytes)return -2;std::int64_t load[MM]{},assign[MN]{};
    for(std::size_t i=0;i<n;++i){std::size_t best=0;for(std::size_t j=1;j<m;++j)if(load[j]<load[best])best=j;assign[i]=static_cast<std::int64_t>(best);load[best]+=in[2+i];}
    auto makespan=load[0];for(std::size_t j=1;j<m;++j)if(load[j]>makespan)makespan=load[j];
    put64(out,0,makespan);for(std::size_t i=0;i<n;++i)put64(out,8*(1+i),assign[i]);for(std::size_t j=0;j<m;++j)put64(out,8*(1+n+j),load[j]);return static_cast<std::int64_t>(bytes);
}
