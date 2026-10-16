#include <cstddef>
#include <cstdint>
extern "C" std::int64_t kronecker_product(const std::int64_t*v,std::size_t n){if(n!=6)return -1;for(std::size_t i=0;i<6;i++)if(v[i]<-10||v[i]>10)return -1;std::int64_t x[8]={v[0]*v[4],v[0]*v[5],v[1]*v[4],v[1]*v[5],v[2]*v[4],v[2]*v[5],v[3]*v[4],v[3]*v[5]},r=0;for(auto z:x)r=r*201+z+100;return r;}
