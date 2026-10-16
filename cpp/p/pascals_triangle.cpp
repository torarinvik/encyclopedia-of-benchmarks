#include <cstddef>
#include <cstdint>
extern "C" std::int64_t pascals_triangle(const std::int64_t*v,std::size_t n) noexcept {if(!v||n!=1||v[0]<1||v[0]>31)return -1;int rows=int(v[0]);std::int64_t a[31]{};a[0]=1;for(int r=1;r<rows;r++){a[r]=1;for(int j=r-1;j>0;j--)a[j]+=a[j-1];}std::int64_t h=0;for(int i=0;i<rows;i++)h=(h*31+a[i])%1000000007;return h;}
