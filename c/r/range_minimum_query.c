/* Static range minimum queries with a sparse table. */
#include <stddef.h>
#include <stdint.h>
#define MAX_N 64
#define MAX_Q 64
#define INVALID_QUERY INT64_MIN
static void put_i64_le(uint8_t *out, size_t off, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[off + b] = (uint8_t)(bits >> (8 * b));
}
int64_t range_minimum_query(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4) return -1;
    int64_t n64=input[0]; if(n64<1||n64>MAX_N)return -1; size_t n=(size_t)n64;
    size_t qpos=1+n; if(length<=qpos)return -1; int64_t q64=input[qpos];
    if(q64<1||q64>MAX_Q)return -1; size_t q=(size_t)q64;
    if(length!=qpos+1+2*q)return -1;
    int64_t values[MAX_N]; for(size_t i=0;i<n;++i){values[i]=input[1+i];if(values[i]<-1000||values[i]>1000)return -1;}
    if(capacity<q*8||output==NULL)return -2;
    size_t table[7][MAX_N]; for(size_t i=0;i<n;++i)table[0][i]=i;
    for(size_t k=1;(1u<<k)<=n;++k){size_t width=1u<<k,half=width>>1;
        for(size_t i=0;i+width<=n;++i){size_t a=table[k-1][i],b=table[k-1][i+half];table[k][i]=values[a]<values[b]?a:b;}}
    for(size_t j=0;j<q;++j){int64_t left=input[qpos+1+2*j],right=input[qpos+2+2*j];int64_t answer=INVALID_QUERY;
        if(left>=0&&right>left&&right<=(int64_t)n){size_t l=(size_t)left,r=(size_t)right,len=r-l,k=0;while((1u<<(k+1))<=len)++k;size_t width=1u<<k;
            size_t a=table[k][l],b=table[k][r-width];answer=values[a]<values[b]?values[a]:values[b];}
        put_i64_le(output,j*8,answer);}
    return (int64_t)(q*8);
}
