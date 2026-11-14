#include <stddef.h>
#include <stdint.h>

static unsigned bucket_of(uint32_t key, uint32_t last) {
    uint32_t difference=key^last;
    unsigned bits=0;
    while (difference) { ++bits; difference>>=1; }
    return bits;
}

int64_t monotone_radix_heap(const int64_t *input, size_t length) {
    if (!input || length<1 || length>130 || input[0]<0 || input[0]>64) return -1;
    size_t q=(size_t)input[0];
    if (length!=1+2*q) return -1;
    int head[32], next[64];
    uint32_t keys[64], last=0;
    for (int i=0; i<32; ++i) head[i]=-1;
    int used=0, removals=0;
    int64_t result=0;
    for (size_t i=0; i<q; ++i) {
        int64_t op=input[1+2*i], key=input[2+2*i];
        if (op==0) {
            if (key<(int64_t)last || key>INT64_C(2147483647)) return -1;
            unsigned bucket=bucket_of((uint32_t)key,last);
            keys[used]=(uint32_t)key; next[used]=head[bucket]; head[bucket]=used++;
        } else if (op==1 && key==0) {
            if (head[0]<0) {
                int bucket=1;
                while (bucket<32 && head[bucket]<0) ++bucket;
                if (bucket==32) return -1;
                uint32_t smallest=UINT32_MAX;
                for (int node=head[bucket]; node>=0; node=next[node]) if (keys[node]<smallest) smallest=keys[node];
                last=smallest;
                int node=head[bucket]; head[bucket]=-1;
                while (node>=0) {
                    int following=next[node];
                    unsigned new_bucket=bucket_of(keys[node],last);
                    next[node]=head[new_bucket]; head[new_bucket]=node;
                    node=following;
                }
            }
            int node=head[0]; head[0]=next[node];
            result+=(int64_t)(++removals)*(int64_t)keys[node];
        } else return -1;
    }
    return result;
}
