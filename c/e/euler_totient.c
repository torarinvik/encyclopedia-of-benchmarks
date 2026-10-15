/* Euler's totient via distinct-prime factorization. */
#include <stdint.h>
int64_t euler_totient(int64_t n) {
    if (n < 1 || n > 1000000) return -1;
    int64_t result = n;
    int64_t remaining = n;
    for (int64_t factor = 2; factor <= remaining / factor; ++factor) {
        if (remaining % factor == 0) {
            do { remaining /= factor; } while (remaining % factor == 0);
            result -= result / factor;
        }
    }
    if (remaining > 1) result -= result / remaining;
    return result;
}
