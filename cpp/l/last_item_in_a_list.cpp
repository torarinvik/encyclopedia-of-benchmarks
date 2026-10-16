#include <cstddef>
#include <cstdint>
extern "C" std::int64_t last_item_in_a_list(const std::int64_t*v,std::size_t n){if(n>64)return -1;for(std::size_t i=0;i<n;i++)if(v[i]<0||v[i]>100000)return -1;return n?v[n-1]:-1;}
