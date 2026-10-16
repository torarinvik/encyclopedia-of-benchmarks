#include <cstddef>
#include <cstdint>
static std::int64_t power(std::int64_t a,std::int64_t e,std::int64_t m){if(e==0)return 1;if(e&1)return (power(a,e-1,m)*a)%m;auto h=power(a,e/2,m);return (h*h)%m;}
extern "C" std::int64_t modular_binary_exponentiation_recursive(const std::int64_t*v,std::size_t n)noexcept{if(!v||n!=3)return -1;auto a=v[0],e=v[1],m=v[2];if(a<0||a>1000000||e<0||e>60||m<2||m>1000000)return -1;return power(a,e,m);}
