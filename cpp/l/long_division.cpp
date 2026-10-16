#include <cstddef>
#include <cstdint>
static std::int64_t core(std::int64_t a,std::int64_t b){if(b==0)return 0;bool neg=(a<0)!=(b<0);if(a<0)a=-a;if(b<0)b=-b;std::int64_t ds[16];std::size_t n=0;if(a==0)ds[n++]=0;while(a){ds[n++]=a%10;a/=10;}std::int64_t rem=0,q=0;while(n){rem=rem*10+ds[--n];std::int64_t d=0;while(rem>=b){rem-=b;++d;}q=q*10+d;}return neg?-q:q;}
extern "C" std::int64_t long_division(const std::int64_t*v,std::size_t n){if(!v||n!=2||v[0]<-1000000||v[0]>1000000||v[1]<-10000||v[1]>10000)return -1;return core(v[0],v[1]);}
