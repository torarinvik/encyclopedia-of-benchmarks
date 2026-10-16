#include <cstddef>
#include <cstdint>
extern "C" std::int64_t ibits(const std::int64_t*v,std::size_t n){if(!v||n!=1||v[0]<0||v[0]>=9007199254740992LL)return -1;auto x=v[0];std::int64_t c=0;while(x){c++;x>>=1;}return c;}
