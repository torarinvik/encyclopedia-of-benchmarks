/* Clean-room TSVC s232 profile; see package rights note. */
#include <stddef.h>
#include <stdint.h>
static void put64(uint8_t*o,size_t p,int64_t v){uint64_t b=(uint64_t)v;for(size_t j=0;j<8;j++){o[p+j]=(uint8_t)b;b>>=8;}}
int64_t tsvc_s232_triangular_row_square_recurrence(const int64_t*in,size_t len,uint8_t*out,size_t cap){if(!in||len<9||len>51)return -1;int64_t nr=in[0];if(nr<2||nr>5)return -1;size_t n=(size_t)nr,nn=n*n;if(len!=1+2*nn)return -1;int64_t a[25],b[25];for(size_t i=0;i<nn;i++){int64_t x=in[1+i],y=in[1+nn+i];if(x< -1||x>1||y< -1||y>1)return -1;a[i]=x;b[i]=y;}if(!out||cap<8*nn)return -2;for(size_t j=1;j<n;j++)for(size_t i=1;i<=j;i++)a[j*n+i]=a[j*n+i-1]*a[j*n+i-1]+b[j*n+i];for(size_t i=0;i<nn;i++)put64(out,8*i,a[i]);return (int64_t)nn;}
