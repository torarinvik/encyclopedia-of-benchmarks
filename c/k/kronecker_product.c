#include <stddef.h>
#include <stdint.h>
int64_t kronecker_product(const int64_t*v,size_t n){if(n!=6)return -1;for(size_t i=0;i<6;i++)if(v[i]<-10||v[i]>10)return -1;int64_t x[8]={v[0]*v[4],v[0]*v[5],v[1]*v[4],v[1]*v[5],v[2]*v[4],v[2]*v[5],v[3]*v[4],v[3]*v[5]},r=0;for(int i=0;i<8;i++)r=r*201+x[i]+100;return r;}
