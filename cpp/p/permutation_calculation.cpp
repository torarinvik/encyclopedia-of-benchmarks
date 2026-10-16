#include <cstddef>
#include <cstdint>
static std::int64_t factorial(std::int64_t n){std::int64_t x=1;for(std::int64_t i=1;i<=n;i++)x*=i;return x;}
extern "C" std::int64_t permutation_calculation(const std::int64_t*v,std::size_t n)noexcept{if(!v||n!=2||v[0]<0||v[0]>15||v[1]<0||v[1]>v[0])return -1;return factorial(v[0])/factorial(v[0]-v[1]);}
