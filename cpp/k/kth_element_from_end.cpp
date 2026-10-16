#include <cstddef>
#include <cstdint>
extern "C" std::int64_t kth_element_from_end(const std::int64_t*v,std::size_t n){if(!v||n<1||n>65||v[0]<=0||v[0]>=static_cast<std::int64_t>(n))return -1;for(std::size_t i=1;i<n;i++)if(v[i]<0||v[i]>100000)return -1;return v[n-static_cast<std::size_t>(v[0])];}
