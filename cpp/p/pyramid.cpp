#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" double pyramid(const std::int64_t*v,std::size_t n) noexcept {if(!v||n!=3||v[0]<0||v[0]>1||v[1]<1||v[1]>10000000||v[2]<1||v[2]>10000000)return -1e300;const double b=static_cast<double>(v[1])/1000.0,h=static_cast<double>(v[2])/1000.0,area=std::pow(b,2);if(v[0]==0)return (area*h)/3.0;return area+((b*4.0)/2.0)*std::sqrt(std::pow(b/2.0,2)+std::pow(h,2));}
