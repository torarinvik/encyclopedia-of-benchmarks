#include <cstddef>
#include <cstdint>
extern "C" std::int64_t intensity_based_segmentation(const std::int64_t*v,std::size_t n){if(!v||n<2||n>12)return -1;auto k=v[0];if(k<0||k>4||n<=static_cast<std::size_t>(k)+1||n>static_cast<std::size_t>(k)+8)return -1;for(std::size_t j=1;j<n;j++)if(v[j]<0||v[j]>255)return -1;std::int64_t out=0,place=1;for(std::size_t p=k+1;p<n;p++){std::int64_t label=0;for(std::int64_t i=0;i<k;i++)if(v[p]>v[1+i])label=i+1;out+=label*place;place*=5;}return out;}
