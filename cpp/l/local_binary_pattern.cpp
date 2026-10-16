#include <cstddef>
#include <cstdint>
extern "C" std::int64_t local_binary_pattern(const std::int64_t*v,std::size_t n){if(!v||n!=9)return -1;for(std::size_t i=0;i<9;i++)if(v[i]<0||v[i]>255)return -1;const std::size_t ix[8]={2,5,1,8,7,6,3,0};std::int64_t out=0;for(std::size_t i=0;i<8;i++)if(v[ix[i]]>=v[4])out|=(std::int64_t)1<<i;return out;}
