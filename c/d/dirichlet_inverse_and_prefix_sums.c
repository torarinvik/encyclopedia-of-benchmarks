#include <stddef.h>
#include <stdint.h>

enum { MOD = 998244353, MAX_QUOTIENTS = 15 };
static int64_t mod_pow(int64_t base, int exponent) {
    int64_t result = 1;
    while (exponent) {
        if (exponent & 1) result = result*base%MOD;
        base = base*base%MOD;
        exponent >>= 1;
    }
    return result;
}
static int index_of(const int *q, int count, int value) {
    int lo=0, hi=count;
    while (lo < hi) {
        int mid=lo+(hi-lo)/2;
        if (q[mid] < value) lo=mid+1; else hi=mid;
    }
    return lo<count && q[lo]==value ? lo : -1;
}
int64_t dirichlet_inverse_and_prefix_sums(const int64_t *input, size_t length,
                                           uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 16 || input[0] < 1 || input[0] > 64) return -1;
    int n=(int)input[0], q[MAX_QUOTIENTS], count=0;
    for (int i=n; i>=1; --i) {
        int x=n/i;
        if (!count || q[count-1] != x) q[count++]=x;
    }
    if (length != 1+(size_t)count) return -1;
    for (int i=0; i<count; ++i) if (input[1+i] < 0 || input[1+i] >= MOD) return -1;
    if (input[1] == 0) return -1;
    if (!output || capacity < 8*(size_t)count) return -2;
    int64_t g[MAX_QUOTIENTS] = {0};
    int64_t inverse=mod_pow(input[1], MOD-2);
    for (int i=0; i<count; ++i) {
        int x=q[i], left=2;
        int64_t total=0;
        while (left <= x) {
            int quotient=x/left, right=x/quotient;
            int hi=index_of(q,count,right), lo=index_of(q,count,left-1);
            int gi=index_of(q,count,quotient);
            if (hi < 0 || lo < 0 || gi < 0) return -1;
            int64_t interval=(input[1+hi]-input[1+lo]+MOD)%MOD;
            total=(total+interval*g[gi])%MOD;
            left=right+1;
        }
        g[i]=((1-total+MOD)%MOD)*inverse%MOD;
    }
    for (int i=0; i<count; ++i)
        for (size_t byte=0; byte<8; ++byte) output[8*(size_t)i+byte]=(uint8_t)((uint64_t)g[i] >> (8*byte));
    return 8*count;
}
