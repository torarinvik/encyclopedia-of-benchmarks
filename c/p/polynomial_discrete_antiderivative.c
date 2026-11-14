#include <stddef.h>
#include <stdint.h>

enum { MOD = 998244353, MAX_N = 32 };
int64_t polynomial_discrete_antiderivative(const int64_t *input, size_t length,
                                            uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 33 || input[0] < 1 || input[0] > MAX_N) return -1;
    int n=(int)input[0];
    if (length != (size_t)(n+1)) return -1;
    for (int i=0; i<n; ++i) if (input[1+i] < 0 || input[1+i] >= MOD) return -1;
    if (!output || capacity < 8*(size_t)(n+1)) return -2;
    int64_t choose[33][33] = {{0}}, inverse[33] = {0}, g[33] = {0};
    choose[0][0]=1;
    for (int k=1; k<=n; ++k) {
        choose[k][0]=choose[k][k]=1;
        for (int j=1; j<k; ++j) choose[k][j]=(choose[k-1][j-1]+choose[k-1][j])%MOD;
    }
    inverse[1]=1;
    for (int k=2; k<=n; ++k) inverse[k]=MOD-(MOD/k)*inverse[MOD%k]%MOD;
    for (int j=n-1; j>=0; --j) {
        int64_t sum=0;
        for (int k=j+2; k<=n; ++k) sum=(sum+choose[k][j]*g[k])%MOD;
        g[j+1]=((input[1+j]-sum+MOD)%MOD)*inverse[j+1]%MOD;
    }
    for (int i=0; i<=n; ++i)
        for (size_t byte=0; byte<8; ++byte) output[8*(size_t)i+byte]=(uint8_t)((uint64_t)g[i] >> (8*byte));
    return 8*(n+1);
}
