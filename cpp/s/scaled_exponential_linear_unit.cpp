#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t scaled_exponential_linear_unit(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){if(!v||n<3||n>259||v[0]<0||v[0]>256||n!=std::size_t(v[0])+3)return -1;if(v[1]<-10000000||v[1]>10000000||v[2]<-10000000||v[2]>10000000)return -1;std::size_t count=std::size_t(v[0]),bytes=count*8;for(std::size_t i=0;i<count;i++)if(v[i+3]<-20000000||v[i+3]>20000000)return -1;if(!out||cap<bytes)return -2;double a=double(v[1])/1e6,l=double(v[2])/1e6;for(std::size_t i=0;i<count;i++){double x=double(v[i+3])/1e6;double y=l*(x>0.0?x:a*(std::exp(x)-1.0));std::uint64_t bits=std::uint64_t(std::int64_t(std::floor(y*1000000000.0+0.5)));for(int b=0;b<8;b++)out[i*8+b]=std::uint8_t(bits>>(8*b));}return std::int64_t(bytes);}
