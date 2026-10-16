#include <cstddef>
#include <cstdint>
extern "C" std::int64_t perfect_numbers(const std::int64_t*v,std::size_t n) noexcept {if(!v||n!=1||v[0]<0||v[0]>1000000000)return -1;auto x=v[0];if(x<=1)return 0;std::int64_t sum=1;for(std::int64_t d=2;d<=x/d;d++)if(x%d==0){sum+=d;if(d!=x/d)sum+=x/d;}return sum==x;}
