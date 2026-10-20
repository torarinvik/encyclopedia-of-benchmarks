/* New bounded relaxed-convolution schedule; source attribution/license: benchmarks/r/relaxed_convolution/README.md and LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>
#define RC_MOD INT64_C(998244353)
#define RC_MAX 16

int64_t relaxed_convolution(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 3 || length > 33) return -1;
    int64_t n0=input[0]; if(n0<1||n0>RC_MAX||length!=1+2*(size_t)n0)return -1;
    size_t n=(size_t)n0; int64_t a[RC_MAX]={0},b[RC_MAX]={0},c[RC_MAX]={0};
    for(size_t i=0;i<n;i++){a[i]=input[1+i];b[i]=input[1+n+i];if(a[i]<0||a[i]>=RC_MOD||b[i]<0||b[i]>=RC_MOD)return -1;}
    if(!output||capacity<4*n)return -2;
    for(size_t index=0;index<n;index++){
        c[index]=(c[index]+a[index]*b[0]+(index?b[index]*a[0]:0))%RC_MOD;
        size_t q=index+1;
        for(size_t d=1;d<=q;d*=2){if(q%(2*d)!=d)continue;
            size_t end=q+d<n?q+d:n;
            if(q==d){for(size_t i=q;i<end;i++){size_t target=d+i-q;for(size_t r=0;r<d;r++){size_t y=target-r;if(y<d)c[i]=(c[i]+a[r]*b[y])%RC_MOD;}}}
            else {for(size_t i=q;i<end;i++){size_t target=d+i-q;for(size_t r=0;r<d;r++){size_t y=target-r;if(y<2*d)c[i]=(c[i]+a[q-d+r]*b[y]+b[q-d+r]*a[y])%RC_MOD;}}}
        }
    }
    for(size_t i=0;i<n;i++){uint32_t x=(uint32_t)c[i];for(size_t j=0;j<4;j++)output[4*i+j]=(uint8_t)(x>>(8*j));}
    return (int64_t)(4*n);
}
