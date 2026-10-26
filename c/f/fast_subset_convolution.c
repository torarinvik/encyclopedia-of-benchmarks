#include <stddef.h>
#include <stdint.h>

#define MOD INT64_C(998244353)
#define MAX_N 4
#define MAX_SIZE 16

static void put_i64_le(uint8_t *out, size_t off, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b=0;b<8;++b) out[off+b]=(uint8_t)(bits>>(8*b));
}

static int popcount_mask(size_t x) {
    int count=0;
    while (x) { count += (int)(x & 1U); x >>= 1; }
    return count;
}

int64_t fast_subset_convolution(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input==NULL || length<3 || length>33) return -1;
    int64_t n64=input[0];
    if (n64<0 || n64>MAX_N) return -1;
    size_t n=(size_t)n64, size=(size_t)1<<n;
    if (length!=1+2*size) return -1;
    for (size_t i=0;i<2*size;++i) if (input[1+i]<0 || input[1+i]>=MOD) return -1;
    int64_t f[MAX_N+1][MAX_SIZE]={{0}}, g[MAX_N+1][MAX_SIZE]={{0}}, h[MAX_N+1][MAX_SIZE]={{0}};
    for (size_t mask=0;mask<size;++mask) {
        int rank=popcount_mask(mask);
        f[rank][mask]=input[1+mask]; g[rank][mask]=input[1+size+mask];
    }
    for (size_t bit=0;bit<n;++bit) for (size_t mask=0;mask<size;++mask) if (mask & ((size_t)1<<bit)) {
        size_t other=mask ^ ((size_t)1<<bit);
        for (size_t rank=0;rank<=n;++rank) {
            f[rank][mask]=(f[rank][mask]+f[rank][other])%MOD;
            g[rank][mask]=(g[rank][mask]+g[rank][other])%MOD;
        }
    }
    for (size_t mask=0;mask<size;++mask) for (size_t rank=0;rank<=n;++rank) {
        int64_t sum=0;
        for (size_t i=0;i<=rank;++i) sum=(sum+f[i][mask]*g[rank-i][mask])%MOD;
        h[rank][mask]=sum;
    }
    for (size_t bit=0;bit<n;++bit) for (size_t mask=0;mask<size;++mask) if (mask & ((size_t)1<<bit)) {
        size_t other=mask ^ ((size_t)1<<bit);
        for (size_t rank=0;rank<=n;++rank) h[rank][mask]=(h[rank][mask]-h[rank][other]+MOD)%MOD;
    }
    size_t required=size*8;
    if (capacity<required || output==NULL) return -2;
    for (size_t mask=0;mask<size;++mask) put_i64_le(output,8*mask,h[popcount_mask(mask)][mask]);
    return (int64_t)required;
}
