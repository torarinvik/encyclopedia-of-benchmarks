#include <stddef.h>
#include <stdint.h>
#include <string.h>
static void put_double(uint8_t*out,size_t off,double x){uint64_t bits;memcpy(&bits,&x,8);for(size_t k=0;k<8;k++)out[off+k]=(uint8_t)(bits>>(8*k));}
int64_t nesterov_accelerated_sgd(const int64_t*v,size_t n,uint8_t*out,size_t cap){
 if(!v||n<4)return -1;int64_t wi=v[0],si=v[1],lm=v[2],mm=v[3];if(wi<1||wi>8||si<1||si>8||lm<0||lm>1000||mm<0||mm>1000||n!=4+(size_t)wi*((size_t)si+1))return -1;size_t w=(size_t)wi,s=(size_t)si;
 for(size_t i=4;i<n;i++)if(v[i]<-10000||v[i]>10000)return -1;if(!out||cap<w*8)return -2;
 double p[8],vel[8]={0},lr=(double)lm/1000.0,m=(double)mm/1000.0;for(size_t i=0;i<w;i++)p[i]=(double)v[4+i]/1000.0;
 for(size_t t=0;t<s;t++)for(size_t i=0;i<w;i++){double prev=vel[i],g=(double)v[4+w+t*w+i]/1000.0;vel[i]=m*vel[i]-lr*g;p[i]=p[i]-m*prev+(1.0+m)*vel[i];}
 for(size_t i=0;i<w;i++)put_double(out,i*8,p[i]);return (int64_t)(w*8);
}
