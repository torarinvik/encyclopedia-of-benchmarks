#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>
extern "C" std::int64_t kth_smallest_heap(const std::int64_t*v,std::size_t n){if(!v||n<2||n>65)return -1;auto k=v[0];if(k<1||k>=static_cast<std::int64_t>(n))return -1;std::vector<std::int64_t>h(v+1,v+1+k);for(auto x:h)if(x< -100000||x>100000)return -1;std::make_heap(h.begin(),h.end());for(std::size_t i=1+k;i<n;i++){auto x=v[i];if(x< -100000||x>100000)return -1;if(x<=h.front()){std::pop_heap(h.begin(),h.end());h.back()=x;std::push_heap(h.begin(),h.end());}}return h.front();}
