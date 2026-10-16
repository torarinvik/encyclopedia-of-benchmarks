#include <cstddef>
#include <cstdint>
static constexpr std::int64_t MAX_COUNT=64, MOD=1000000007, BASE=2000000003;
extern "C" std::int64_t partition_linked_list(const std::int64_t*v,std::size_t n) noexcept{if(!v||n<2||n>66||v[0]<0||v[0]>MAX_COUNT||n!=std::size_t(v[0])+2||v[1]<INT32_MIN||v[1]>INT32_MAX)return -1;std::int64_t less[64],ge[64];std::size_t a=0,b=0;for(std::size_t i=0;i<std::size_t(v[0]);i++){auto x=v[i+2];if(x<INT32_MIN||x>INT32_MAX)return -1;if(x<v[1])less[a++]=x;else ge[b++]=x;}std::int64_t h=0;for(std::size_t i=0;i<a;i++)h=(h*BASE+less[i]-INT32_MIN)%MOD;for(std::size_t i=0;i<b;i++)h=(h*BASE+ge[i]-INT32_MIN)%MOD;return h;}
