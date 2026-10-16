#include <stddef.h>
#include <stdint.h>
static int64_t gcdv(int64_t a,int64_t b){if(a<0)a=-a;if(b<0)b=-b;while(b){int64_t r=a%b;a=b;b=r;}return a;}
int64_t linear_diophantine_eqn(const int64_t*v,size_t n){if(!v||n!=3||v[0]<-100000||v[0]>100000||v[1]==0||v[1]<-100000||v[1]>100000||v[2]<-1000000||v[2]>1000000)return -1;return v[2]%gcdv(v[0],v[1])==0?1:0;}
