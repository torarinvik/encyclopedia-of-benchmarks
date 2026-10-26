/* Clean-room TSVC s1112 profile; see package rights note. */
#include <stddef.h>
#include <stdint.h>
static void put64(uint8_t*o,size_t p,int64_t v){uint64_t b=(uint64_t)v;for(size_t j=0;j<8;j++){o[p+j]=(uint8_t)b;b>>=8;}}
int64_t tsvc_s1112_reverse_constant_offset_map(const int64_t*in,size_t len,uint8_t*out,size_t cap){if(!in||len<3||len>129)return -1;int64_t nr=in[0];if(nr<1||nr>64)return -1;size_t n=(size_t)nr;if(len!=1+2*n)return -1;int64_t a[64],b[64];for(size_t i=0;i<n;i++){int64_t x=in[1+i],y=in[1+n+i];if(x< -2||x>2||y< -2||y>2)return -1;a[i]=x;b[i]=y;}if(!out||cap<8*n)return -2;for(size_t i=n;i-- >0;)a[i]=b[i]+1;for(size_t i=0;i<n;i++)put64(out,8*i,a[i]);return (int64_t)n;}
