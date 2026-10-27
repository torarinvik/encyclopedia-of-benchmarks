#include <array>
#include <cstddef>
#include <cstdint>
namespace { constexpr int K=8,N=32; void put(std::uint8_t*o,std::size_t p,std::int64_t x){auto b=static_cast<std::uint64_t>(x);for(std::size_t i=0;i<8;i++)o[p+i]=static_cast<std::uint8_t>(b>>(8*i));} }
extern "C" std::int64_t min_hash_k_partition(const std::int64_t* in,std::size_t len,std::uint8_t*out,std::size_t cap){
 if(!in||len<2||len>66)return -1;auto k0=in[0],n0=in[1];if(k0<1||k0>K||n0<0||n0>N||len!=2+2*static_cast<std::size_t>(n0))return -1;
 std::array<std::int64_t,K> ids,ranks;ids.fill(-1);ranks.fill(1001);
 for(int id=0;id<n0;id++){auto b=in[2+2*id],r=in[3+2*id];if(b<0||b>=k0||r<0||r>1000)return -1;auto x=static_cast<int>(b);if(ids[x]<0||r<ranks[x]||(r==ranks[x]&&id<ids[x])){ids[x]=id;ranks[x]=r;}}
 std::array<std::int64_t,2*K> staged{};for(int b=0;b<k0;b++){staged[2*b]=ids[b];staged[2*b+1]=ranks[b];}
 auto required=static_cast<std::size_t>(2*k0)*8;if(!out||cap<required)return -2;for(std::size_t i=0;i<2*k0;i++)put(out,i*8,staged[i]);return static_cast<std::int64_t>(required);
}
