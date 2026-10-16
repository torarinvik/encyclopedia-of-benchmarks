#include <cstddef>
#include <cstdint>
extern "C" double pow_algorithm(const std::int64_t*v,std::size_t n)noexcept{if(!v||n!=2||v[0]<-1000||v[0]>1000||v[1]<-8||v[1]>12)return -1.0e300;double result=1.0;for(std::int64_t i=1;i<=v[1];i++)result*=static_cast<double>(v[0]);return result;}
