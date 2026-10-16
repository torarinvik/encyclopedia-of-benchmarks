#include <stdint.h>
#define MAX_DIGITS 8
static uint32_t mix(uint32_t h,uint8_t b){return (h^b)*16777619u;}
int64_t pi_generator(int64_t digits){if(digits<0||digits>MAX_DIGITS)return -1;int64_t q=1,r=0,t=1,k=1,n=3,m=3,counter=0;uint32_t h=2166136261u;while(counter!=digits+1){if(4*q+r-t<n*t){h=mix(h,(uint8_t)(48+n));if(counter==0)h=mix(h,'.');if(digits==counter)break;counter++;int64_t nr=10*(r-n*t);n=(10*(3*q+r))/t-10*n;q*=10;r=nr;}else{int64_t nr=(2*q+r)*m;int64_t nn=(q*(7*k)+2+(r*m))/(t*m);q*=k;t*=m;m+=2;k++;n=nn;r=nr;}}return (int64_t)h;}
