#include <cstdint>
static std::uint32_t mix(std::uint32_t h,std::uint8_t b){return (h^b)*16777619u;}
extern "C" std::int64_t pi_generator(std::int64_t digits) noexcept{if(digits<0||digits>8)return -1;std::int64_t q=1,r=0,t=1,k=1,n=3,m=3,counter=0;std::uint32_t h=2166136261u;while(counter!=digits+1){if(4*q+r-t<n*t){h=mix(h,(std::uint8_t)(48+n));if(counter==0)h=mix(h,'.');if(digits==counter)break;counter++;auto nr=10*(r-n*t);n=(10*(3*q+r))/t-10*n;q*=10;r=nr;}else{auto nr=(2*q+r)*m;auto nn=(q*(7*k)+2+(r*m))/(t*m);q*=k;t*=m;m+=2;k++;n=nn;r=nr;}}return h;}
