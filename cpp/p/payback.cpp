#include <cstddef>
#include <cstdint>
extern "C" std::int64_t payback(const std::int64_t*v,std::size_t n)noexcept{if(!v||n<1||n>129||v[0]<0||v[0]>128||n!=static_cast<std::size_t>(v[0])+1)return -2;std::int64_t total=0;for(std::size_t i=1;i<n;i++){if(v[i]<-1000000||v[i]>1000000)return -2;total+=v[i];if(total>=0)return static_cast<std::int64_t>(i-1);}return -1;}
