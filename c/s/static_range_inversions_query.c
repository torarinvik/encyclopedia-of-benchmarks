#include <stddef.h>
#include <stdint.h>

#define MAX_N 128
#define MAX_Q 32

typedef struct { size_t left, right, id, block; } Query;

static size_t lower_bound_i64(const int64_t *a, size_t n, int64_t x) {
    size_t lo = 0, hi = n;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (a[mid] < x) lo = mid + 1; else hi = mid;
    }
    return lo;
}
static int64_t bit_sum(const int64_t bit[MAX_N + 1], size_t count) {
    int64_t sum = 0;
    while (count) { sum += bit[count]; count -= count & (~count + 1); }
    return sum;
}
static void bit_add(int64_t bit[MAX_N + 1], size_t rank, int delta) {
    for (size_t i = rank + 1; i <= MAX_N; i += i & (~i + 1)) bit[i] += delta;
}
static int before(const Query *a, const Query *b) {
    if (a->block != b->block) return a->block < b->block;
    if (a->right != b->right) return (a->block & 1) ? a->right > b->right : a->right < b->right;
    return a->id < b->id;
}
static void write_i64_le(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[at + b] = (uint8_t)(bits >> (8 * b));
}

int64_t static_range_inversions_query(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 195) return -1;
    int64_t n64=input[0],q64=input[1];
    if(n64<1||n64>MAX_N||q64<1||q64>MAX_Q)return -1;
    size_t n=(size_t)n64,q=(size_t)q64;
    if(length!=2+n+2*q)return -1;
    int64_t values[MAX_N],sorted[MAX_N];
    for(size_t i=0;i<n;++i){values[i]=input[2+i];if(values[i]<0||values[i]>1_000_000_000)return -1;sorted[i]=values[i];}
    for(size_t i=1;i<n;++i){int64_t x=sorted[i];size_t j=i;while(j&&sorted[j-1]>x){sorted[j]=sorted[j-1];--j;}sorted[j]=x;}
    size_t distinct=0;for(size_t i=0;i<n;++i)if(!distinct||sorted[i]!=sorted[distinct-1])sorted[distinct++]=sorted[i];
    size_t rank[MAX_N];for(size_t i=0;i<n;++i)rank[i]=lower_bound_i64(sorted,distinct,values[i]);
    Query queries[MAX_Q];size_t off=2+n,block=1;while((block+1)*(block+1)<=n)++block;
    for(size_t k=0;k<q;++k){int64_t l=input[off++],r=input[off++];if(l<0||l>=r||r>n64)return -1;queries[k]=(Query){(size_t)l,(size_t)r,k,(size_t)l/block};}
    for(size_t i=1;i<q;++i){Query x=queries[i];size_t j=i;while(j&&before(&x,&queries[j-1])){queries[j]=queries[j-1];--j;}queries[j]=x;}
    int64_t bit[MAX_N+1]={0},answers[MAX_Q]={0};size_t left=0,right=0,window=0;int64_t inversions=0;
    for(size_t qi=0;qi<q;++qi){Query z=queries[qi];
        while(left>z.left){--left;size_t x=rank[left];inversions+=bit_sum(bit,x);bit_add(bit,x,1);++window;}
        while(right<z.right){size_t x=rank[right];inversions+=(int64_t)window-bit_sum(bit,x+1);bit_add(bit,x,1);++window;++right;}
        while(left<z.left){size_t x=rank[left];inversions-=bit_sum(bit,x);bit_add(bit,x,-1);--window;++left;}
        while(right>z.right){--right;size_t x=rank[right];inversions-=(int64_t)window-bit_sum(bit,x+1);bit_add(bit,x,-1);--window;}
        answers[z.id]=inversions;
    }
    size_t bytes=8*q;if(!output||capacity<bytes)return -2;
    for(size_t k=0;k<q;++k)write_i64_le(output,8*k,answers[k]);
    return (int64_t)bytes;
}
