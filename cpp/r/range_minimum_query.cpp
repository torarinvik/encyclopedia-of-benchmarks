/* Static range minimum queries with a sparse table. */
#include <cstddef>
#include <cstdint>
namespace { constexpr std::size_t N=64,Q=64; constexpr std::int64_t invalid=INT64_MIN;
void put(std::uint8_t*out,std::size_t at,std::int64_t value){std::uint64_t bits=static_cast<std::uint64_t>(value);for(std::size_t b=0;b<8;++b)out[at+b]=static_cast<std::uint8_t>(bits>>(8*b));}}
extern "C" std::int64_t range_minimum_query(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap) noexcept {
 if(!in||len<4)return -1;auto n64=in[0];if(n64<1||n64>N)return -1;auto n=static_cast<std::size_t>(n64);auto qp=1+n;if(len<=qp)return -1;auto q64=in[qp];if(q64<1||q64>Q)return -1;auto q=static_cast<std::size_t>(q64);if(len!=qp+1+2*q)return -1;
 std::int64_t values[N];for(std::size_t i=0;i<n;++i){values[i]=in[1+i];if(values[i]<-1000||values[i]>1000)return -1;}if(cap<q*8||!out)return -2;
 std::size_t table[7][N]{};for(std::size_t i=0;i<n;++i)table[0][i]=i;
 for(std::size_t k=1;(std::size_t{1}<<k)<=n;++k){auto width=std::size_t{1}<<k,half=width>>1;for(std::size_t i=0;i+width<=n;++i){auto a=table[k-1][i],b=table[k-1][i+half];table[k][i]=values[a]<values[b]?a:b;}}
 for(std::size_t j=0;j<q;++j){auto l64=in[qp+1+2*j],r64=in[qp+2+2*j];std::int64_t ans=invalid;if(l64>=0&&r64>l64&&r64<=static_cast<std::int64_t>(n)){auto l=static_cast<std::size_t>(l64),r=static_cast<std::size_t>(r64),size=r-l;std::size_t k=0;while((std::size_t{1}<<(k+1))<=size)++k;auto width=std::size_t{1}<<k;auto a=table[k][l],b=table[k][r-width];ans=values[a]<values[b]?values[a]:values[b];}put(out,j*8,ans);}
 return static_cast<std::int64_t>(q*8);
}
