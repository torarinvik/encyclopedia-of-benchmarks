/* Clean-room TSVC s1213 profile; see package rights note. */
#include <stddef.h>
#include <stdint.h>
static void put64(uint8_t*o,size_t p,int64_t v){uint64_t b=(uint64_t)v;for(size_t j=0;j<8;j++){o[p+j]=(uint8_t)b;b>>=8;}}
int64_t tsvc_s1213_ordered_neighbor_array_map(const int64_t*in,size_t len,uint8_t*out,size_t cap){if(!in||len<13||len>129)return -1;int64_t nr=in[0];if(nr<3||nr>32)return -1;size_t n=(size_t)nr;if(len!=1+4*n)return -1;int64_t a[32],b[32],c[32],d[32];for(size_t i=0;i<n;i++){int64_t x=in[1+i],y=in[1+n+i],z=in[1+2*n+i],w=in[1+3*n+i];if(x< -1||x>1||y< -1||y>1||z< -1||z>1||w< -1||w>1)return -1;a[i]=x;b[i]=y;c[i]=z;d[i]=w;}if(!out||cap<16*n)return -2;for(size_t i=1;i<n-1;i++){a[i]=b[i-1]+c[i];b[i]=a[i+1]*d[i];}for(size_t i=0;i<n;i++){put64(out,8*i,a[i]);put64(out,8*(n+i),b[i]);}return (int64_t)(2*n);}
