/* Clean-room TSVC s116 profile; see package rights note. */
#include <stddef.h>
#include <stdint.h>
static void put64(uint8_t*o,size_t p,int64_t v){uint64_t b=(uint64_t)v;for(size_t j=0;j<8;j++){o[p+j]=(uint8_t)b;b>>=8;}}
int64_t tsvc_s116_unrolled_product_chain(const int64_t*in,size_t len,uint8_t*out,size_t cap){if(!in||len<8||len>23)return -1;int64_t nr=in[0],pr=in[1];if(nr<6||nr>21||(nr-1)%5||pr<1||pr>4)return -1;size_t n=(size_t)nr;if(len!=2+n)return -1;int64_t a[21];for(size_t k=0;k<n;k++){if(in[2+k]!=-1&&in[2+k]!=1)return -1;a[k]=in[2+k];}if(!out||cap<8*n)return -2;for(size_t p=0;p<(size_t)pr;p++)for(size_t i=0;i<n-5;i+=5){a[i]=a[i+1]*a[i];a[i+1]=a[i+2]*a[i+1];a[i+2]=a[i+3]*a[i+2];a[i+3]=a[i+4]*a[i+3];a[i+4]=a[i+5]*a[i+4];}for(size_t k=0;k<n;k++)put64(out,8*k,a[k]);return (int64_t)n;}
