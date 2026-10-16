#include <cstddef>
#include <cstdint>
extern "C" std::int64_t length_of_list(const std::int64_t*v,std::size_t n){if(n>64)return -1;for(std::size_t i=0;i<n;i++)if(v[i]<0||v[i]>100000)return -1;return static_cast<std::int64_t>(n);}
