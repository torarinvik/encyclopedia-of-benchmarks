#include <cstddef>
#include <cstdint>
extern "C" std::int64_t jenkins_one_at_a_time(const std::int64_t *v,std::size_t n){if(v==NULL||n<1||n>65)return -1;std::int64_t count=v[0];if(count<0||count>64||n!=(std::size_t)count+1)return -1;std::int64_t h=0;for(std::size_t i=0;i<(std::size_t)count;i++){std::int64_t b=v[i+1];if(b<0||b>127)return -1;h=(h+b)&0xffffffffLL;h=(h+(h<<10))&0xffffffffLL;h=(h^(h>>6))&0xffffffffLL;}h=(h+(h<<3))&0xffffffffLL;h=(h^(h>>11))&0xffffffffLL;h=(h+(h<<15))&0xffffffffLL;return h;}
