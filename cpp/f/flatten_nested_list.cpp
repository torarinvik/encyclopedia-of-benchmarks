#include <cstddef>
#include <cstdint>
#include <limits>
static std::int64_t signed_hash(std::uint64_t hash) noexcept {
 constexpr std::uint64_t sign = std::uint64_t{1} << 63;
 if (hash < sign) return static_cast<std::int64_t>(hash);
 const std::uint64_t magnitude = std::numeric_limits<std::uint64_t>::max() - hash + 1;
 if (magnitude == sign) return std::numeric_limits<std::int64_t>::min();
 return -static_cast<std::int64_t>(magnitude);
}
extern "C" std::int64_t flatten_nested_list(const std::int64_t *v,std::size_t n) noexcept {
 constexpr auto open=std::numeric_limits<std::int64_t>::min(),close=open+1;
 if(!v||n==0||n>255||v[0]!=open)return -1;int depth=0;bool closed=false;std::uint64_t h=0xcbf29ce484222325ULL;
 for(std::size_t i=0;i<n;++i){auto x=v[i];if(x==open){if(closed||(depth==0&&i!=0))return -1;if(++depth>16)return -1;}else if(x==close){if(depth==0)return -1;if(--depth==0){closed=true;if(i+1!=n)return -1;}}else{if(depth==0||x< -1000000||x>1000000)return -1;auto u=static_cast<std::uint64_t>(x);for(unsigned b=0;b<8;++b){h^=static_cast<std::uint8_t>(u>>(8*b));h*=0x100000001b3ULL;}}}
 if(depth||!closed)return -1;return signed_hash(h);
}
