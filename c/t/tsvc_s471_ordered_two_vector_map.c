/* Clean-room TSVC s471 profile; see package rights note. */
#include <stddef.h>
#include <stdint.h>
enum { MAX_N=32, MAX_INPUT_LENGTH=130 };
static void put64(uint8_t *o,size_t p,int64_t v){uint64_t b=(uint64_t)v;for(size_t j=0;j<8;++j){o[p+j]=(uint8_t)(b&255u);b>>=8;}}
int64_t tsvc_s471_ordered_two_vector_map(const int64_t *in,size_t len,uint8_t *out,size_t cap){
 if(!in||len<6||len>MAX_INPUT_LENGTH)return -1;
 if(in[0]<1||in[0]>MAX_N||in[1]<1||in[1]>4||len!=2+4*(size_t)in[0])return -1;
 size_t n=(size_t)in[0],passes=(size_t)in[1];double x[MAX_N],b[MAX_N],c[MAX_N],d[MAX_N],e[MAX_N];
 for(size_t i=0;i<n;++i){int64_t bv=in[2+i],cv=in[2+n+i],dv=in[2+2*n+i],ev=in[2+3*n+i];if(bv< -2||bv>2||cv< -2||cv>2||dv< -2||dv>2||ev< -2||ev>2)return -1;b[i]=(double)bv;c[i]=(double)cv;d[i]=(double)dv;e[i]=(double)ev;}
 size_t bytes=16*n;if(!out||cap<bytes)return -2;
 for(size_t p=0;p<passes;++p)for(size_t i=0;i<n;++i){x[i]=b[i]+d[i]*d[i];b[i]=c[i]+d[i]*e[i];}
 for(size_t i=0;i<n;++i){put64(out,8*i,(int64_t)x[i]);put64(out,8*(n+i),(int64_t)b[i]);}return (int64_t)bytes;
}
