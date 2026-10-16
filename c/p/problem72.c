#include <stdint.h>

int64_t problem72(int64_t limit)
{
    if (limit < 0 || limit > 1000000) return -1;
    if (limit < 2) return 0;
    uint32_t phi[1000001];
    phi[0] = 0;
    if (limit >= 1) phi[1] = 1;
    for (int64_t value = 2; value <= limit; ++value) phi[value] = (uint32_t)value;
    for (int64_t prime = 2; prime <= limit; ++prime) {
        if (phi[prime] == (uint32_t)prime) {
            for (int64_t multiple = prime; multiple <= limit; multiple += prime)
                phi[multiple] -= phi[multiple] / (uint32_t)prime;
        }
    }
    int64_t total = 0;
    for (int64_t denominator = 2; denominator <= limit; ++denominator) total += phi[denominator];
    return total;
}
