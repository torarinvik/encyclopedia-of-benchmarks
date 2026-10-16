#include <stddef.h>
#include <stdint.h>
int64_t modular_multiplicative_inverse(const int64_t*v,size_t n){if(!v||n!=2)return -1;int64_t a=v[0],m=v[1];if(m<2||m>1000000||a<0||a>=m)return -1;int64_t r0=a,r1=m,s0=1,s1=0;while(r1){int64_t q=r0/r1,t=r0-q*r1;r0=r1;r1=t;t=s0-q*s1;s0=s1;s1=t;}return r0==1?(s0%m+m)%m:-1;}
