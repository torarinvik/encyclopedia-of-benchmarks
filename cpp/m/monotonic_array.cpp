#include <cstddef>
#include <cstdint>
extern "C" std::int64_t monotonic_array(const std::int64_t *v,std::size_t n) noexcept {
 if(n>256||(!v&&n>0))return -1;
 bool inc=true,dec=true;
 for(std::size_t i=0;i<n;++i)if(v[i]<-1000000000LL||v[i]>1000000000LL)return -1;
 for(std::size_t i=1;i<n;++i){if(v[i-1]>v[i])inc=false;if(v[i-1]<v[i])dec=false;}
 return inc||dec;
}
