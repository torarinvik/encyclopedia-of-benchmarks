#include <stddef.h>
#include <stdint.h>

enum { MOD = 998244353 };
int64_t log_of_set_power_series(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (!input || length<2 || length>33 || input[0]<0 || input[0]>5) return -1;
    int n=(int)input[0], size=1<<n;
    if (length != 1+(size_t)size || input[1]!=1) return -1;
    for (int i=0;i<size;++i) if (input[1+i]<0 || input[1+i]>=MOD) return -1;
    if (!output || capacity<8*(size_t)size) return -2;
    int64_t result[32]={0};
    for (int mask=1;mask<size;++mask) {
        int pivot=mask & -mask;
        int64_t sum=0;
        for (int sub=(mask-1)&mask;sub;sub=(sub-1)&mask) {
            if (sub & pivot) sum=(sum+result[sub]*input[1+(mask^sub)])%MOD;
        }
        result[mask]=(input[1+mask]-sum+MOD)%MOD;
    }
    for (int i=0;i<size;++i)
        for (size_t byte=0;byte<8;++byte) output[8*(size_t)i+byte]=(uint8_t)((uint64_t)result[i] >> (8*byte));
    return 8*size;
}
