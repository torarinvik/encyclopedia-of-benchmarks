#include <stddef.h>
#include <stdint.h>
#define BAD (-1.0e300)
double ic_555_timer(const int64_t*v,size_t n){if(!v||n!=4)return BAD;int64_t mode=v[0],r1=v[1],r2=v[2],c=v[3];if((mode!=0&&mode!=1)||r1<1||r1>1000000||r2<1||r2>1000000||(mode==0&&(c<1||c>1000000))||(mode==1&&(c<0||c>1000000)))return BAD;if(mode==0)return (1.44/((r1+2*r2)*(double)c))*1e6;return ((double)(r1+r2)/(r1+2*r2))*100.0;}
