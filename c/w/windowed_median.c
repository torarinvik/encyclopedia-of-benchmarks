/* Emit the median after each insertion into a fixed-width trailing window. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#define MAX_WINDOW 64
#define MAX_STREAM 128
static void put_f64_le(uint8_t *out,size_t offset,double value){uint64_t bits;memcpy(&bits,&value,8);for(size_t b=0;b<8;++b)out[offset+b]=(uint8_t)(bits>>(8*b));}
int64_t windowed_median(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
 if(!input||length<3)return -1;int64_t w64=input[0],n64=input[1];if(w64<1||w64>MAX_WINDOW||n64<1||n64>MAX_STREAM)return -1;size_t w=(size_t)w64,n=(size_t)n64;if(length!=n+2)return -1;
 for(size_t i=0;i<n;++i)if(input[2+i]<-1000000||input[2+i]>1000000)return -1;if(capacity<n*8||!output)return -2;
 int64_t sorted[MAX_WINDOW];size_t active=0;
 for(size_t i=0;i<n;++i){if(i>=w){int64_t old=input[2+i-w];size_t p=0;while(p<active&&sorted[p]!=old)++p;if(p==active)return -1;for(size_t j=p+1;j<active;++j)sorted[j-1]=sorted[j];--active;}
  int64_t value=input[2+i];size_t p=0;while(p<active&&sorted[p]<value)++p;for(size_t j=active;j>p;--j)sorted[j]=sorted[j-1];sorted[p]=value;++active;
  float median;if(active&1)median=(float)sorted[active/2];else median=0.5f*(float)sorted[active/2-1]+0.5f*(float)sorted[active/2];put_f64_le(output,i*8,(double)median);}
 return (int64_t)(n*8);
}
