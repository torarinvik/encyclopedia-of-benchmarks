#include <cstddef>
#include <cstdint>
extern "C" std::int64_t log_two(const std::int64_t*v,std::size_t n){if(!v||n!=1||v[0]<0||v[0]>2147483647)return -1;auto x=v[0];std::int64_t r=0;while(x>>1){x>>=1;++r;}return r;}
