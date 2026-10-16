#include <cstddef>
#include <cstdint>
extern "C" std::int64_t kth_element_in_a_list(const std::int64_t*v,std::size_t n){if(n<3||n>34)return -1;auto k=v[0],pos=v[1];if(k<1||k>16||n!=static_cast<std::size_t>(k+2)||pos<1||pos>k)return -1;for(std::int64_t i=0;i<k;i++)if(v[i+2]<-10000||v[i+2]>10000)return -1;return v[pos+1];}
