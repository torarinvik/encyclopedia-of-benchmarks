#include <cstddef>
#include <cstdint>
#include <algorithm>
#include <array>
#include <vector>
static std::int64_t qs(const std::vector<std::int64_t>&a,std::int64_t k){if(a.size()==1)return a[0];auto p=a[0];std::vector<std::int64_t>s,b;for(std::size_t i=1;i<a.size();i++){if(a[i]<p)s.push_back(a[i]);else if(a[i]>p)b.push_back(a[i]);}if(k==static_cast<std::int64_t>(s.size()+1))return p;if(k<=static_cast<std::int64_t>(s.size()))return qs(s,k);return qs(b,k-static_cast<std::int64_t>(s.size())-1);}
extern "C" std::int64_t kth_order_statistic(const std::int64_t*v,std::size_t n){if(!v||n<2||n>65||v[0]<1||v[0]>=static_cast<std::int64_t>(n))return -1;std::vector<std::int64_t>a(v+1,v+n);for(auto x:a)if(x< -10000||x>10000)return -1;std::sort(a.begin(),a.end());if(std::adjacent_find(a.begin(),a.end())!=a.end())return -1;return qs(a,v[0]);}
