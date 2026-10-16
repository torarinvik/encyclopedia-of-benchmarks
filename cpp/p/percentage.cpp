#include <cstddef>
#include <cstdint>
extern "C" std::int64_t percentage(const std::int64_t*v,std::size_t n)noexcept{if(!v||n!=3||v[0]<1||v[0]>100000||v[1]<1||v[1]>100000||v[2]<1||v[2]>4)return -1;std::int64_t scale=1;for(std::int64_t i=0;i<v[2];i++)scale*=10;auto product=v[0]*v[1]*scale;if(product<100)return -1;return product/100;}
