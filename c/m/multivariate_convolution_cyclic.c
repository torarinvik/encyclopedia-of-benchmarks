#include <stddef.h>
#include <stdint.h>

enum { MAX_P=32, MAX_K=3, MAX_INPUT=70, MAX_OUTPUT=256 };
static void store_le(uint8_t *out,size_t at,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b){out[at+b]=(uint8_t)(bits&255u);bits>>=8;}}
static int is_prime(int p){if(p<2)return 0;for(int d=2;d*d<=p;++d)if(p%d==0)return 0;return 1;}
int64_t multivariate_convolution_cyclic(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<2||length>MAX_INPUT)return -1;
    int64_t p0=input[0],k0=input[1];if(p0<2||p0>97||!is_prime((int)p0)||k0<0||k0>MAX_K)return -1;
    size_t p=(size_t)p0,k=(size_t)k0;if(length<2+k)return -1;size_t dims[MAX_K],product=1;
    for(size_t axis=0;axis<k;++axis){int64_t d0=input[2+axis];if(d0<2||d0>MAX_P||(p-1)%(size_t)d0!=0||product>MAX_P/(size_t)d0)return -1;dims[axis]=(size_t)d0;product*=dims[axis];}
    size_t start=2+k;if(length!=start+2*product)return -1;
    for(size_t q=start;q<length;++q)if(input[q]<0||input[q]>=p0)return -1;
    size_t bytes=8*product;if(bytes>MAX_OUTPUT)return -1;if(!output||capacity<bytes)return -2;
    int64_t a[MAX_P],b[MAX_P],result[MAX_P]={0};for(size_t i=0;i<product;++i){a[i]=input[start+i];b[i]=input[start+product+i];}
    for(size_t i=0;i<product;++i)for(size_t j=0;j<product;++j){size_t target=0,stride=1;for(size_t axis=0;axis<k;++axis){size_t d=dims[axis],sum=((i/stride)%d+(j/stride)%d)%d;target+=sum*stride;stride*=d;}result[target]=(result[target]+a[i]*b[j])%p;}
    for(size_t i=0;i<product;++i)store_le(output,8*i,result[i]);return (int64_t)bytes;
}
