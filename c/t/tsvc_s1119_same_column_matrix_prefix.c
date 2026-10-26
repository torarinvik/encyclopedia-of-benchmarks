/* Clean-room TSVC s1119 profile; see package rights note. */
#include <stddef.h>
#include <stdint.h>
static void put64(uint8_t*o,size_t p,int64_t v){uint64_t b=(uint64_t)v;for(size_t j=0;j<8;j++){o[p+j]=(uint8_t)b;b>>=8;}}
int64_t tsvc_s1119_same_column_matrix_prefix(const int64_t*in,size_t len,uint8_t*out,size_t cap){if(!in||len<10||len>130)return -1;int64_t nr=in[0],pr=in[1];if(nr<2||nr>8||pr<1||pr>4)return -1;size_t n=(size_t)nr,nn=n*n;if(len!=2+2*nn)return -1;int64_t a[64],b[64];for(size_t i=0;i<nn;i++){int64_t x=in[2+i],y=in[2+nn+i];if(x< -1||x>1||y< -1||y>1)return -1;a[i]=x;b[i]=y;}if(!out||cap<8*nn)return -2;for(size_t p=0;p<(size_t)pr;p++)for(size_t i=1;i<n;i++)for(size_t j=0;j<n;j++)a[i*n+j]=a[(i-1)*n+j]+b[i*n+j];for(size_t i=0;i<nn;i++)put64(out,8*i,a[i]);return (int64_t)nn;}
