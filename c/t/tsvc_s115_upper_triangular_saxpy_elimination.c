/* Clean-room TSVC s115 profile; see package rights note. */
#include <stddef.h>
#include <stdint.h>
static void put64(uint8_t*o,size_t p,int64_t v){uint64_t b=(uint64_t)v;for(size_t j=0;j<8;j++){o[p+j]=(uint8_t)b;b>>=8;}}
int64_t tsvc_s115_upper_triangular_saxpy_elimination(const int64_t*in,size_t len,uint8_t*out,size_t cap){if(!in||len<8||len>58)return -1;int64_t nr=in[0],pr=in[1];if(nr<2||nr>7||pr<1||pr>3)return -1;size_t n=(size_t)nr;if(len!=2+n+n*n)return -1;int64_t a[8],m[64];for(size_t i=0;i<n;i++){int64_t x=in[2+i];if(x< -1||x>1)return -1;a[i]=x;}for(size_t i=0;i<n*n;i++){int64_t x=in[2+n+i];if(x< -1||x>1)return -1;m[i]=x;}if(!out||cap<8*n)return -2;for(size_t p=0;p<(size_t)pr;p++)for(size_t j=0;j<n;j++)for(size_t i=j+1;i<n;i++)a[i]-=m[j*n+i]*a[j];for(size_t i=0;i<n;i++)put64(out,8*i,a[i]);return (int64_t)n;}
