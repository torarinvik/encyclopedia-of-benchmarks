#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define MAX_N 256
int64_t scaled_exponential_linear_unit(const int64_t *v,size_t n,uint8_t*out,size_t cap){if(!v||n<3||n>259||v[0]<0||v[0]>MAX_N||n!=(size_t)v[0]+3)return -1;if(v[1]<-10000000||v[1]>10000000||v[2]<-10000000||v[2]>10000000)return -1;size_t count=(size_t)v[0],bytes=count*8;for(size_t i=0;i<count;i++)if(v[i+3]<-20000000||v[i+3]>20000000)return -1;if(!out||cap<bytes)return -2;double a=(double)v[1]/1e6,l=(double)v[2]/1e6;for(size_t i=0;i<count;i++){double x=(double)v[i+3]/1e6;double y=l*(x>0.0?x:a*(exp(x)-1.0));int64_t q=(int64_t)floor(y*1000000000.0+0.5);uint64_t bits=(uint64_t)q;for(int b=0;b<8;b++)out[i*8+b]=(uint8_t)(bits>>(8*b));}return (int64_t)bytes;}
