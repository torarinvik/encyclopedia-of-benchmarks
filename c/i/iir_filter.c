#include <stddef.h>
#include <stdint.h>
#include <string.h>
static void put64(uint8_t*o,size_t i,double x){uint64_t b;memcpy(&b,&x,8);for(size_t k=0;k<8;k++)o[i*8+k]=(uint8_t)(b>>(8*k));}
int64_t iir_filter(const int64_t*v,size_t n,uint8_t*out,size_t cap){
 if(!v||n<7||n>26||v[0]<1||v[0]>3||v[1]<1||v[1]>16)return -1;size_t order=(size_t)v[0],samples=(size_t)v[1];if(n!=4+2*order+samples)return -1;
 double a[4],b[4],xh[3]={0},yh[3]={0};for(size_t i=0;i<=order;i++){int64_t av=v[2+i],bv=v[3+order+i];if(av < -500||av>2000||bv < -500||bv>500)return -1;a[i]=(double)av/1000.0;b[i]=(double)bv/1000.0;}if(a[0]<0.5)return -1;for(size_t i=0;i<samples;i++)if(v[4+2*order+i]<-1000||v[4+2*order+i]>1000)return -1;
 size_t bytes=samples*8;if(!out||cap<bytes)return -2;for(size_t sample=0;sample<samples;sample++){double x=(double)v[4+2*order+sample]/1000.0;double result=0.0;for(size_t i=1;i<=order;i++)result+=b[i]*xh[i-1]-a[i]*yh[i-1];result=(result+b[0]*x)/a[0];for(size_t i=order-1;i>0;i--){xh[i]=xh[i-1];yh[i]=yh[i-1];}xh[0]=x;yh[0]=result;put64(out,sample,result);}return (int64_t)bytes;
}
