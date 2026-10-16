#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>
extern "C" std::int64_t largest_divisible_subset(const std::int64_t*v,std::size_t n){if((!v&&n)||n>64)return -1;std::vector<std::int64_t>a;if(n)a.assign(v,v+n);for(auto x:a)if(x<1||x>50000)return -1;std::sort(a.begin(),a.end());std::vector<std::int64_t>d(n,1);std::int64_t best=0;for(std::size_t i=0;i<n;i++){for(std::size_t j=0;j<i;j++)if(a[i]%a[j]==0)d[i]=std::max(d[i],d[j]+1);best=std::max(best,d[i]);}return best;}
