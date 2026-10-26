/* Clean-room implementation of TSVC vtv; see package rights note. */
#include <stddef.h>
#include <stdint.h>
enum { MAX_N = 32, MAX_INPUT_LENGTH = 66 };
static void store_i64_le(uint8_t *o, size_t p, int64_t v) { uint64_t b=(uint64_t)v; for(size_t j=0;j<8;++j){o[p+j]=(uint8_t)(b&255u);b>>=8;} }
int64_t tsvc_vtv_elementwise_product(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
 if(!input||length<4||length>MAX_INPUT_LENGTH)return -1;
 if(input[0]<1||input[0]>MAX_N||input[1]<1||input[1]>8||length!=2+2*(size_t)input[0])return -1;
 size_t n=(size_t)input[0],passes=(size_t)input[1];double a[MAX_N],b[MAX_N];
 for(size_t i=0;i<n;++i){int64_t av=input[2+i],bv=input[2+n+i];if(av< -2||av>2||bv< -2||bv>2)return -1;a[i]=(double)av;b[i]=(double)bv;}
 size_t bytes=8*n;if(!output||capacity<bytes)return -2;
 for(size_t p=0;p<passes;++p)for(size_t i=0;i<n;++i)a[i]*=b[i];
 for(size_t i=0;i<n;++i)store_i64_le(output,8*i,(int64_t)a[i]);return (int64_t)bytes;
}
