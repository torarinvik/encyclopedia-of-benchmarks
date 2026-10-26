/* Clean-room TSVC s1111 profile; see package rights note. */
#include <stddef.h>
#include <stdint.h>
enum { MAX_N=32, MAX_INPUT_LENGTH=161 };
static void put64(uint8_t *o,size_t p,int64_t v){uint64_t b=(uint64_t)v;for(size_t j=0;j<8;++j){o[p+j]=(uint8_t)(b&255u);b>>=8;}}
int64_t tsvc_s1111_stride_two_polynomial_map(const int64_t *in,size_t len,uint8_t *out,size_t cap){
 if(!in||len<6||len>MAX_INPUT_LENGTH)return -1;int64_t nr=in[0];if(nr<1||nr>MAX_N)return -1;size_t n=(size_t)nr;if(len!=1+5*n)return -1;
 int64_t a[2*MAX_N],b[MAX_N],c[MAX_N],d[MAX_N];size_t off=1;for(size_t i=0;i<2*n;++i){int64_t x=in[off+i];if(x< -2||x>2)return -1;a[i]=x;}off+=2*n;
 int64_t *v[3]={b,c,d};for(size_t k=0;k<3;++k){for(size_t i=0;i<n;++i){int64_t x=in[off++];if(x< -2||x>2)return -1;v[k][i]=x;}}
 size_t bytes=16*n;if(!out||cap<bytes)return -2;
 for(size_t i=0;i<n;++i)a[2*i]=c[i]*b[i]+d[i]*b[i]+c[i]*c[i]+d[i]*b[i]+d[i]*c[i];
 for(size_t i=0;i<2*n;++i)put64(out,8*i,a[i]);return (int64_t)(2*n);
}
