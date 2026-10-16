#include <cmath>
#include <cstddef>
#include <cstdint>
namespace{void store(std::int64_t x,std::uint8_t*out){auto u=static_cast<std::uint64_t>(x);for(std::size_t b=0;b<8;b++)out[b]=static_cast<std::uint8_t>(u>>(8*b));}}
extern "C" std::int64_t midpoint_integration(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap)noexcept{if(!v||n!=4)return -1;auto f=v[0],steps=v[1],aa=v[2],bb=v[3];if(f<0||f>2||steps<1||steps>256||aa< -1000000||aa>1000000||bb<aa||bb>1000000)return -1;if(!out||cap<8)return -2;double a=double(aa)/1e6,b=double(bb)/1e6,h=(b-a)/double(steps),sum=0;for(std::int64_t i=0;i<steps;i++){double x=a+double(i)*h+h/2;double y=f==0?1.0:(f==1?x:x*x);sum+=y;}store(static_cast<std::int64_t>(std::floor(h*sum*1e9+0.5)),out);return 8;}
