/* Last ten digits of the self-powers sum for bases 1 through 1000. */
#include <stdint.h>

#define MODULUS INT64_C(10000000000)

int64_t problem48(int64_t ignored)
{
    if (ignored != 0) return -1;
    int64_t total = 0;
    for (int64_t base = 1; base <= 1000; ++base) {
        int64_t term = 1;
        for (int64_t exponent = 0; exponent < base; ++exponent) {
            term = (term * base) % MODULUS;
        }
        total = (total + term) % MODULUS;
    }
    return total;
}
