#include <cstddef>
#include <cstdint>
namespace{constexpr std::size_t N=12,L=25;void put64(std::uint8_t*o,std::size_t p,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t j=0;j<8;++j){o[p+j]=static_cast<std::uint8_t>(b&255U);b>>=8;}}}
extern "C" std::int64_t smith_weighted_completion_time(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap)noexcept{
 if(!in||len<3||len>L)return -1;auto n64=in[0];if(n64<1||n64>N||len!=1+2*static_cast<std::size_t>(n64))return -1;auto n=static_cast<std::size_t>(n64);
 std::int64_t p[N]{},w[N]{},order[N]{};for(std::size_t i=0;i<n;++i){p[i]=in[1+2*i];w[i]=in[2+2*i];if(p[i]<1||p[i]>10000||w[i]<1||w[i]>10000)return -1;order[i]=static_cast<std::int64_t>(i);}
 auto bytes=8*(n+1);if(!out||cap<bytes)return -2;
 for(std::size_t i=1;i<n;++i){auto key=order[i];auto j=i;while(j>0){auto prev=static_cast<std::size_t>(order[j-1]);bool before=w[key]*p[prev]>w[prev]*p[key]||(w[key]*p[prev]==w[prev]*p[key]&&key<static_cast<std::int64_t>(prev));if(!before)break;order[j]=order[j-1];--j;}order[j]=key;}
 std::int64_t time=0,total=0;for(std::size_t i=0;i<n;++i){auto job=static_cast<std::size_t>(order[i]);time+=p[job];total+=w[job]*time;}put64(out,0,total);for(std::size_t i=0;i<n;++i)put64(out,8*(i+1),order[i]);return static_cast<std::int64_t>(bytes);
}
