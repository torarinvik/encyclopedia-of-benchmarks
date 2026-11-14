#include <stddef.h>
#include <stdint.h>

enum { MOD = 998244353 };
static int64_t power(int64_t base, int exponent) {
    int64_t result=1;
    while (exponent) {
        if (exponent & 1) result=result*base%MOD;
        base=base*base%MOD; exponent >>= 1;
    }
    return result;
}
int64_t inv_of_formal_power_series_2d(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (!input || length<3 || length>66 || input[0]<1 || input[0]>8 || input[1]<1 || input[1]>8) return -1;
    int n=(int)input[0], m=(int)input[1];
    if (length != 2+(size_t)n*m || input[2]==0) return -1;
    for (int i=0; i<n*m; ++i) if (input[2+i]<0 || input[2+i]>=MOD) return -1;
    if (!output || capacity<8*(size_t)n*m) return -2;
    int64_t g[64]={0};
    int64_t inverse=power(input[2],MOD-2);
    g[0]=inverse;
    for (int i=0; i<n; ++i) for (int j=0; j<m; ++j) {
        if (i==0 && j==0) continue;
        int64_t sum=0;
        for (int a=0; a<=i; ++a) for (int b=0; b<=j; ++b) {
            if (a==0 && b==0) continue;
            sum=(sum+input[2+a*m+b]*g[(i-a)*m+j-b])%MOD;
        }
        g[i*m+j]=((MOD-sum)%MOD)*inverse%MOD;
    }
    for (int i=0; i<n*m; ++i)
        for (size_t byte=0; byte<8; ++byte) output[8*(size_t)i+byte]=(uint8_t)((uint64_t)g[i] >> (8*byte));
    return 8*n*m;
}
